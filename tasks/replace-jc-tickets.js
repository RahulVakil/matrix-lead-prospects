// Wipes JC-1511..JC-1532 children of epic JC-1510, then pushes 19 fresh tickets
// from tasks/dev-19-tickets-draft.md with assignees + points (in description) +
// labels.

const fs = require('fs');
const path = require('path');
const https = require('https');

const HOST = 'jmfldev.atlassian.net';
const USER = 'vinit.mehta@jmfl.com';
const TOKEN = process.env.JIRA_API_TOKEN;
if (!TOKEN) { console.error('JIRA_API_TOKEN not set'); process.exit(1); }
const AUTH = 'Basic ' + Buffer.from(`${USER}:${TOKEN}`).toString('base64');

const PROJECT = 'JC';
const EPIC_KEY = 'JC-1510';
const STORY_TYPE_ID = '10012';
const FILE = path.join(__dirname, 'dev-19-tickets-draft.md');

// Locked from discovery — name-to-accountId
const ASSIGNEES = {
  Omkar: '6246a870247a4b00691de10c',                                  // Omkar Prabhu
  Forum: '712020:29dfa9bf-d49a-446e-bf27-efe9b0914338',                // Forum Patel
  Gopinath: '712020:d1ff8916-3c6b-4fec-acdf-675899a154dc',             // Gopinath
  Vishwas: '712020:23c50843-09a9-495f-8015-1e5c0889e1f2',              // vishwaschandra vishwakarma
  Vaibhav: '712020:47c49b58-3453-495b-88f8-a443764e2cea',              // Vaibhav Kumbharkar
  Arsh: '712020:f203810d-b9a4-489f-b203-d137fcd8ceb7',                 // Arsh Ghate
};

// ──────────────────────────────────────────────────────────────────────
function req(method, pathName, body) {
  return new Promise((resolve, reject) => {
    const data = body ? JSON.stringify(body) : null;
    const opts = { host: HOST, path: pathName, method, headers: { Authorization: AUTH, Accept: 'application/json', 'Content-Type': 'application/json' } };
    if (data) opts.headers['Content-Length'] = Buffer.byteLength(data);
    const r = https.request(opts, (res) => {
      let chunks = '';
      res.on('data', (d) => (chunks += d));
      res.on('end', () => {
        const parsed = chunks ? (() => { try { return JSON.parse(chunks); } catch { return chunks; } })() : null;
        if (res.statusCode >= 400) reject(new Error(`HTTP ${res.statusCode}: ${typeof parsed === 'string' ? parsed.slice(0, 400) : JSON.stringify(parsed).slice(0, 400)}`));
        else resolve(parsed);
      });
    });
    r.on('error', reject);
    if (data) r.write(data);
    r.end();
  });
}

// ──────────────────────────────────────────────────────────────────────
// Markdown → ADF (same converter as before).

function parseInline(text) {
  const out = [];
  const re = /(\*\*[^*]+\*\*)|(`[^`]+`)|((?:[^*`]|(?:\*(?!\*)))+)/g;
  let m;
  while ((m = re.exec(text)) !== null) {
    if (m[1]) out.push({ type: 'text', text: m[1].slice(2, -2), marks: [{ type: 'strong' }] });
    else if (m[2]) out.push({ type: 'text', text: m[2].slice(1, -1), marks: [{ type: 'code' }] });
    else if (m[3]) out.push({ type: 'text', text: m[3] });
  }
  return out.length ? out : [{ type: 'text', text }];
}
function isTableSeparator(line) { return /^\s*\|?\s*[-:]+\s*(\|\s*[-:]+\s*)+\|?\s*$/.test(line); }
function splitRow(line) { const trimmed = line.trim().replace(/^\|/, '').replace(/\|$/, ''); return trimmed.split('|').map((c) => c.trim()); }

function mdToAdf(md) {
  const blocks = []; const lines = md.replace(/\r\n/g, '\n').split('\n'); let i = 0;
  while (i < lines.length) {
    const line = lines[i];
    if (line.trim() === '') { i++; continue; }
    const h = line.match(/^(#{1,6})\s+(.*)$/);
    if (h) { blocks.push({ type: 'heading', attrs: { level: Math.min(h[1].length, 6) }, content: parseInline(h[2]) }); i++; continue; }
    if (/^```/.test(line)) { const code = []; i++; while (i < lines.length && !/^```/.test(lines[i])) { code.push(lines[i]); i++; } blocks.push({ type: 'codeBlock', content: [{ type: 'text', text: code.join('\n') }] }); i++; continue; }
    if (line.trim().startsWith('|') && i + 1 < lines.length && isTableSeparator(lines[i + 1])) {
      const header = splitRow(lines[i]); i++; i++; const rows = [];
      while (i < lines.length && lines[i].trim().startsWith('|')) { rows.push(splitRow(lines[i])); i++; }
      const tableRows = [];
      tableRows.push({ type: 'tableRow', content: header.map((c) => ({ type: 'tableHeader', attrs: {}, content: [{ type: 'paragraph', content: parseInline(c || ' ') }] })) });
      for (const row of rows) tableRows.push({ type: 'tableRow', content: row.map((c) => ({ type: 'tableCell', attrs: {}, content: [{ type: 'paragraph', content: parseInline(c || ' ') }] })) });
      blocks.push({ type: 'table', attrs: { isNumberColumnEnabled: false, layout: 'default' }, content: tableRows });
      continue;
    }
    if (/^\s*[-*]\s+/.test(line)) { const items = []; while (i < lines.length && /^\s*[-*]\s+/.test(lines[i])) { const text = lines[i].replace(/^\s*[-*]\s+/, ''); items.push({ type: 'listItem', content: [{ type: 'paragraph', content: parseInline(text) }] }); i++; while (i < lines.length && /^\s{2,}\S/.test(lines[i])) { const last = items[items.length - 1]; last.content[0].content.push({ type: 'text', text: ' ' + lines[i].trim() }); i++; } } blocks.push({ type: 'bulletList', content: items }); continue; }
    if (/^\s*\d+\.\s+/.test(line)) { const items = []; while (i < lines.length && /^\s*\d+\.\s+/.test(lines[i])) { const text = lines[i].replace(/^\s*\d+\.\s+/, ''); items.push({ type: 'listItem', content: [{ type: 'paragraph', content: parseInline(text) }] }); i++; } blocks.push({ type: 'orderedList', attrs: { order: 1 }, content: items }); continue; }
    if (/^-{3,}$/.test(line.trim())) { blocks.push({ type: 'rule' }); i++; continue; }
    const para = [];
    while (i < lines.length && lines[i].trim() !== '' && !/^#{1,6}\s/.test(lines[i]) && !/^```/.test(lines[i]) && !lines[i].trim().startsWith('|') && !/^\s*[-*]\s+/.test(lines[i]) && !/^\s*\d+\.\s+/.test(lines[i]) && !/^-{3,}$/.test(lines[i].trim())) { para.push(lines[i]); i++; }
    if (para.length) blocks.push({ type: 'paragraph', content: parseInline(para.join(' ')) });
  }
  return { type: 'doc', version: 1, content: blocks };
}

// ──────────────────────────────────────────────────────────────────────
// Parse the dev-19 markdown into 19 tickets.
//
// Format:
//   # 1. Matrix Wealth CRM FE:RM New Lead
//   - **Points**: 5 · **Assignee**: Omkar · **Depends on**: ...
//   <body>

function parseTickets(md) {
  const lines = md.replace(/\r\n/g, '\n').split('\n');
  const tickets = [];
  let i = 0;
  while (i < lines.length) {
    const line = lines[i];
    const m = line.match(/^#\s+(\d+)\.\s+(.+)$/);
    if (!m) { i++; continue; }
    const num = parseInt(m[1], 10);
    const title = m[2].trim();
    const body = [];
    i++;
    while (i < lines.length && !/^#\s+\d+\.\s+/.test(lines[i]) && !/^#\s+Push process/.test(lines[i])) {
      body.push(lines[i]);
      i++;
    }
    while (body.length && body[body.length - 1].trim() === '') body.pop();
    const bodyText = body.join('\n');
    // Extract points + assignee from the meta line.
    const meta = bodyText.match(/\*\*Points\*\*:\s*(\d+)\s*·\s*\*\*Assignee\*\*:\s*(\w+)/);
    const points = meta ? parseInt(meta[1], 10) : null;
    const assignee = meta ? meta[2] : null;
    tickets.push({ num, title, body: bodyText, points, assignee });
  }
  return tickets;
}

function isFE(title) { return /\bFE:/i.test(title); }

// ──────────────────────────────────────────────────────────────────────
async function main() {
  const md = fs.readFileSync(FILE, 'utf8');
  const tickets = parseTickets(md);
  console.log(`Parsed ${tickets.length} tickets from draft.`);
  if (tickets.length !== 19) { console.error('Expected 19 tickets!'); process.exit(1); }

  // Sanity-check assignees are all known
  const unknown = tickets.filter((t) => !ASSIGNEES[t.assignee]).map((t) => `#${t.num} (${t.assignee})`);
  if (unknown.length) { console.error('Unknown assignees:', unknown); process.exit(1); }

  // ── Step 1: Delete the 22 existing children (JC-1511..JC-1532) ──
  console.log('\n═══ DELETING 22 CHILD TICKETS ═══');
  for (let n = 1511; n <= 1532; n++) {
    const k = `JC-${n}`;
    process.stdout.write(`  Deleting ${k}… `);
    try {
      await req('DELETE', `/rest/api/3/issue/${k}`);
      console.log('✓');
    } catch (e) {
      console.log(`FAILED — ${e.message.slice(0, 200)}`);
    }
  }

  // ── Step 2: Create 19 fresh under epic JC-1510 ──
  console.log('\n═══ CREATING 19 FRESH TICKETS ═══');
  const created = [];
  for (const t of tickets) {
    const labels = [
      'lead-prospects',
      'sprint-1',
      isFE(t.title) ? 'fe' : 'be',
      `pts-${t.points ?? 0}`,
    ];
    // Prepend a small "Story Points: N" header to the description body so
    // the points are visible even though there's no SP custom field on the
    // JC project's Story issuetype.
    const desc = `**Story Points**: ${t.points} · **Assignee**: ${t.assignee}\n\n${t.body}`;
    const description = mdToAdf(desc);
    process.stdout.write(`  [${String(t.num).padStart(2, '0')}/19] "${t.title}" → ${t.assignee} (${t.points} pts)… `);
    try {
      const resp = await req('POST', '/rest/api/3/issue', {
        fields: {
          project: { key: PROJECT },
          summary: t.title,
          issuetype: { id: STORY_TYPE_ID },
          description,
          labels,
          assignee: { accountId: ASSIGNEES[t.assignee] },
          parent: { key: EPIC_KEY },
        },
      });
      console.log(`→ ${resp.key}`);
      created.push({ num: t.num, key: resp.key, title: t.title, points: t.points, assignee: t.assignee });
    } catch (e) {
      console.log(`FAILED — ${e.message.slice(0, 250)}`);
      created.push({ num: t.num, key: 'FAILED', title: t.title, error: e.message });
    }
  }

  // ── Mapping output ──
  console.log('\n══════════════════════════════════════════════════════════════════');
  console.log('FINAL MAPPING');
  console.log('══════════════════════════════════════════════════════════════════');
  console.log(`Epic: ${EPIC_KEY}  →  Wealth CRM - Lead & Prospect`);
  console.log('');
  for (const c of created) {
    const ptStr = `${c.points ?? '?'}pt`.padEnd(4);
    const asg = (c.assignee ?? '').padEnd(10);
    console.log(`${c.key.padEnd(8)} #${String(c.num).padStart(2, '0')} ${ptStr} ${asg} ${c.title}`);
  }
  const failed = created.filter((c) => c.key === 'FAILED');
  if (failed.length) { console.log(`\n${failed.length} FAILED — review above.`); process.exit(2); }
}

main().catch((e) => { console.error('Fatal:', e.message); process.exit(1); });

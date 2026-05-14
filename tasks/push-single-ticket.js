// Push a single named ticket from the backlog to Jira, linked to the existing epic.
// Usage: node push-single-ticket.js "<exact ticket title>" "<epic key>"

const fs = require('fs');
const path = require('path');
const https = require('https');

const JIRA_HOST = 'jmfldev.atlassian.net';
const JIRA_USER = 'vinit.mehta@jmfl.com';
const TOKEN = process.env.JIRA_API_TOKEN;
if (!TOKEN) { console.error('JIRA_API_TOKEN not set'); process.exit(1); }
const AUTH = 'Basic ' + Buffer.from(`${JIRA_USER}:${TOKEN}`).toString('base64');
const PROJECT_KEY = 'JC';
const FILE = path.join(__dirname, 'backlog-jc-productionisation.md');

const TARGET_TITLE = process.argv[2];
const EPIC_KEY = process.argv[3];
if (!TARGET_TITLE || !EPIC_KEY) { console.error('Args: "<title>" "<epic_key>"'); process.exit(1); }

// reuse helpers from push-to-jira.js
function req(method, pathName, body) {
  return new Promise((resolve, reject) => {
    const data = body ? JSON.stringify(body) : null;
    const opts = { host: JIRA_HOST, path: pathName, method, headers: { Authorization: AUTH, Accept: 'application/json', 'Content-Type': 'application/json' } };
    if (data) opts.headers['Content-Length'] = Buffer.byteLength(data);
    const r = https.request(opts, (res) => { let chunks = ''; res.on('data', (d) => (chunks += d)); res.on('end', () => { const parsed = chunks ? (() => { try { return JSON.parse(chunks); } catch { return chunks; } })() : null; if (res.statusCode >= 400) reject(new Error(`HTTP ${res.statusCode}: ${JSON.stringify(parsed)}`)); else resolve(parsed); }); });
    r.on('error', reject);
    if (data) r.write(data);
    r.end();
  });
}

function parseInline(text) { const out = []; const re = /(\*\*[^*]+\*\*)|(`[^`]+`)|((?:[^*`]|(?:\*(?!\*)))+)/g; let m; while ((m = re.exec(text)) !== null) { if (m[1]) out.push({ type: 'text', text: m[1].slice(2, -2), marks: [{ type: 'strong' }] }); else if (m[2]) out.push({ type: 'text', text: m[2].slice(1, -1), marks: [{ type: 'code' }] }); else if (m[3]) out.push({ type: 'text', text: m[3] }); } return out.length ? out : [{ type: 'text', text }]; }
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

function parseBacklog(md) {
  const lines = md.replace(/\r\n/g, '\n').split('\n');
  const tickets = []; let i = 0;
  while (i < lines.length) {
    const line = lines[i];
    const m = line.match(/^##\s+((?:RM|TL|ADMIN|IB|LEADERSHIP|COMPLIANCE|PLATFORM)-.*)$/);
    if (m) {
      const title = m[1].trim(); const bodyLines = []; i++;
      while (i < lines.length && !/^##\s+/.test(lines[i]) && !/^#\s+/.test(lines[i])) { bodyLines.push(lines[i]); i++; }
      while (bodyLines.length && bodyLines[bodyLines.length - 1].trim() === '') bodyLines.pop();
      while (bodyLines.length && /^-{3,}\s*$/.test(bodyLines[bodyLines.length - 1].trim())) bodyLines.pop();
      tickets.push({ title, body: bodyLines.join('\n').trim() });
    } else { i++; }
  }
  return tickets;
}
function priorityFromBody(body) { const m = body.match(/\*\*Priority\*\*:\s*([A-Za-z]+)/); if (!m) return 'Medium'; const p = m[1]; if (/highest/i.test(p)) return 'Highest'; if (/high/i.test(p)) return 'High'; if (/medium/i.test(p)) return 'Medium'; if (/low/i.test(p)) return 'Low'; return 'Medium'; }
function roleLabel(title) { return 'role-' + title.split('-')[0].toLowerCase(); }

async function main() {
  const md = fs.readFileSync(FILE, 'utf8');
  const tickets = parseBacklog(md);
  const t = tickets.find((x) => x.title === TARGET_TITLE);
  if (!t) { console.error(`Ticket "${TARGET_TITLE}" not found in backlog. Found titles:`); tickets.forEach((x) => console.error(' -', x.title)); process.exit(1); }
  const priority = priorityFromBody(t.body);
  const labels = ['lead-prospects', roleLabel(t.title)];
  const description = mdToAdf(t.body);
  console.log(`Creating "${t.title}" (priority ${priority}, parent ${EPIC_KEY})…`);
  const resp = await req('POST', '/rest/api/3/issue', {
    fields: {
      project: { key: PROJECT_KEY },
      summary: t.title,
      issuetype: { id: '10012' },
      description,
      priority: { name: priority },
      labels,
      parent: { key: EPIC_KEY },
    },
  });
  console.log(`✓ Created: ${resp.key}`);
  console.log(`  https://${JIRA_HOST}/browse/${resp.key}`);
}

main().catch((e) => { console.error('Fatal:', e.message); process.exit(1); });

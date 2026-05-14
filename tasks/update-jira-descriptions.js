// Updates the description on every existing Jira ticket from the backlog file.
// Reuses the markdown-to-ADF converter from push-to-jira.js.
// PUT /rest/api/3/issue/{key} with { fields: { description } }

const fs = require('fs');
const path = require('path');
const https = require('https');

const JIRA_HOST = 'jmfldev.atlassian.net';
const JIRA_USER = 'vinit.mehta@jmfl.com';
const TOKEN = process.env.JIRA_API_TOKEN;
if (!TOKEN) { console.error('JIRA_API_TOKEN not set'); process.exit(1); }
const AUTH = 'Basic ' + Buffer.from(`${JIRA_USER}:${TOKEN}`).toString('base64');
const FILE = path.join(__dirname, 'backlog-jc-productionisation.md');

// Title → Jira key mapping
const MAPPING = {
  'RM-Lead creation and editing': 'JC-1511',
  'RM-Duplicate lead prevention': 'JC-1512',
  'RM-Mobile with country code': 'JC-1513',
  'RM-Claim from pool': 'JC-1514',
  'RM-Lead temperature bands': 'JC-1515',
  'RM-Profiling wizard resume': 'JC-1516',
  'TL-Lead ageing and SLA': 'JC-1517',
  'TL-Role based access': 'JC-1518',
  'ADMIN-Reassignment queue': 'JC-1519',
  'ADMIN-Bulk lead upload': 'JC-1520',
  'ADMIN-Orphan lead handling': 'JC-1521',
  'LEADERSHIP-Funnel dashboard': 'JC-1522',
  'COMPLIANCE-Consent capture': 'JC-1523',
  'COMPLIANCE-PII privacy and audit': 'JC-1524',
  'PLATFORM-Org hierarchy': 'JC-1525',
  'PLATFORM-Lead history audit trail': 'JC-1526',
  'PLATFORM-Mobile number standard': 'JC-1527',
  'PLATFORM-Notifications': 'JC-1528',
  'PLATFORM-Crash and error reporting': 'JC-1529',
  'PLATFORM-Mobile build pipeline': 'JC-1530',
  'PLATFORM-Funnel analytics': 'JC-1531',
  'IB-Checker workflow and dashboards': 'JC-1532',
};

function req(method, pathName, body) {
  return new Promise((resolve, reject) => {
    const data = body ? JSON.stringify(body) : null;
    const opts = { host: JIRA_HOST, path: pathName, method, headers: { Authorization: AUTH, Accept: 'application/json', 'Content-Type': 'application/json' } };
    if (data) opts.headers['Content-Length'] = Buffer.byteLength(data);
    const r = https.request(opts, (res) => {
      let chunks = '';
      res.on('data', (d) => (chunks += d));
      res.on('end', () => {
        const parsed = chunks ? (() => { try { return JSON.parse(chunks); } catch { return chunks; } })() : null;
        if (res.statusCode >= 400) reject(new Error(`HTTP ${res.statusCode}: ${typeof parsed === 'string' ? parsed.slice(0, 500) : JSON.stringify(parsed)}`));
        else resolve(parsed);
      });
    });
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

async function main() {
  const md = fs.readFileSync(FILE, 'utf8');
  const tickets = parseBacklog(md);
  console.log(`Parsed ${tickets.length} tickets from backlog`);
  if (tickets.length !== 22) { console.error('Expected 22 tickets!'); process.exit(1); }

  let n = 1;
  const failed = [];
  for (const t of tickets) {
    const key = MAPPING[t.title];
    if (!key) { console.error(`No mapping for "${t.title}"`); failed.push(t.title); n++; continue; }
    const description = mdToAdf(t.body);
    process.stdout.write(`  [${String(n).padStart(2, '0')}/22] Updating ${key} (${t.title})… `);
    try {
      await req('PUT', `/rest/api/3/issue/${key}`, { fields: { description } });
      console.log('✓');
    } catch (e) {
      console.log(`FAILED — ${e.message.slice(0, 200)}`);
      failed.push(`${key} (${t.title}): ${e.message.slice(0, 100)}`);
    }
    n++;
  }

  console.log('\n──────────────────────────────────────────────────────────────────');
  if (failed.length) {
    console.log(`${tickets.length - failed.length} updated, ${failed.length} FAILED:`);
    failed.forEach((f) => console.log(' -', f));
    process.exit(2);
  } else {
    console.log(`All ${tickets.length} tickets updated successfully.`);
  }
}

main().catch((e) => { console.error('Fatal:', e.message); process.exit(1); });

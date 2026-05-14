// One-shot pusher for the Wealth CRM - Lead & Prospect backlog.
// Reads backlog-jc-productionisation.md, creates the parent epic, then 21 stories.
// Outputs the ID mapping at the end.

const fs = require('fs');
const path = require('path');
const https = require('https');

const JIRA_HOST = 'jmfldev.atlassian.net';
const JIRA_USER = 'vinit.mehta@jmfl.com';
const TOKEN = process.env.JIRA_API_TOKEN;
if (!TOKEN) { console.error('JIRA_API_TOKEN not set'); process.exit(1); }
const AUTH = 'Basic ' + Buffer.from(`${JIRA_USER}:${TOKEN}`).toString('base64');

const PROJECT_KEY = 'JC';
const EPIC_NAME = 'Wealth CRM - Lead & Prospect';
const FILE = path.join(__dirname, 'backlog-jc-productionisation.md');

// ──────────────────────────────────────────────────────────────────────
// HTTP helper

function req(method, pathName, body) {
  return new Promise((resolve, reject) => {
    const data = body ? JSON.stringify(body) : null;
    const opts = {
      host: JIRA_HOST,
      path: pathName,
      method,
      headers: {
        Authorization: AUTH,
        Accept: 'application/json',
        'Content-Type': 'application/json',
      },
    };
    if (data) opts.headers['Content-Length'] = Buffer.byteLength(data);
    const r = https.request(opts, (res) => {
      let chunks = '';
      res.on('data', (d) => (chunks += d));
      res.on('end', () => {
        const parsed = chunks ? (() => { try { return JSON.parse(chunks); } catch { return chunks; } })() : null;
        if (res.statusCode >= 400) reject(new Error(`HTTP ${res.statusCode}: ${JSON.stringify(parsed)}`));
        else resolve(parsed);
      });
    });
    r.on('error', reject);
    if (data) r.write(data);
    r.end();
  });
}

// ──────────────────────────────────────────────────────────────────────
// Markdown → ADF (limited but covers our backlog: paragraphs, headings,
// bullet/ordered lists, tables, code fences, inline bold + code).

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

function splitRow(line) {
  const trimmed = line.trim().replace(/^\|/, '').replace(/\|$/, '');
  return trimmed.split('|').map((c) => c.trim());
}

function mdToAdf(md) {
  const blocks = [];
  const lines = md.replace(/\r\n/g, '\n').split('\n');
  let i = 0;

  while (i < lines.length) {
    const line = lines[i];
    if (line.trim() === '') { i++; continue; }

    // Heading
    const h = line.match(/^(#{1,6})\s+(.*)$/);
    if (h) {
      blocks.push({ type: 'heading', attrs: { level: Math.min(h[1].length, 6) }, content: parseInline(h[2]) });
      i++; continue;
    }

    // Code fence
    if (/^```/.test(line)) {
      const code = [];
      i++;
      while (i < lines.length && !/^```/.test(lines[i])) { code.push(lines[i]); i++; }
      blocks.push({ type: 'codeBlock', content: [{ type: 'text', text: code.join('\n') }] });
      i++; continue;
    }

    // Table
    if (line.trim().startsWith('|') && i + 1 < lines.length && isTableSeparator(lines[i + 1])) {
      const header = splitRow(lines[i]); i++;
      i++; // skip separator
      const rows = [];
      while (i < lines.length && lines[i].trim().startsWith('|')) {
        rows.push(splitRow(lines[i])); i++;
      }
      const tableRows = [];
      tableRows.push({
        type: 'tableRow',
        content: header.map((c) => ({ type: 'tableHeader', attrs: {}, content: [{ type: 'paragraph', content: parseInline(c || ' ') }] })),
      });
      for (const row of rows) {
        tableRows.push({
          type: 'tableRow',
          content: row.map((c) => ({ type: 'tableCell', attrs: {}, content: [{ type: 'paragraph', content: parseInline(c || ' ') }] })),
        });
      }
      blocks.push({ type: 'table', attrs: { isNumberColumnEnabled: false, layout: 'default' }, content: tableRows });
      continue;
    }

    // Bullet list
    if (/^\s*[-*]\s+/.test(line)) {
      const items = [];
      while (i < lines.length && /^\s*[-*]\s+/.test(lines[i])) {
        const text = lines[i].replace(/^\s*[-*]\s+/, '');
        items.push({ type: 'listItem', content: [{ type: 'paragraph', content: parseInline(text) }] });
        i++;
        // continuation indented lines
        while (i < lines.length && /^\s{2,}\S/.test(lines[i])) {
          const last = items[items.length - 1];
          last.content[0].content.push({ type: 'text', text: ' ' + lines[i].trim() });
          i++;
        }
      }
      blocks.push({ type: 'bulletList', content: items });
      continue;
    }

    // Ordered list
    if (/^\s*\d+\.\s+/.test(line)) {
      const items = [];
      while (i < lines.length && /^\s*\d+\.\s+/.test(lines[i])) {
        const text = lines[i].replace(/^\s*\d+\.\s+/, '');
        items.push({ type: 'listItem', content: [{ type: 'paragraph', content: parseInline(text) }] });
        i++;
      }
      blocks.push({ type: 'orderedList', attrs: { order: 1 }, content: items });
      continue;
    }

    // Horizontal rule
    if (/^-{3,}$/.test(line.trim())) { blocks.push({ type: 'rule' }); i++; continue; }

    // Paragraph (may span multiple lines until blank / structural)
    const para = [];
    while (i < lines.length && lines[i].trim() !== '' && !/^#{1,6}\s/.test(lines[i]) && !/^```/.test(lines[i]) && !lines[i].trim().startsWith('|') && !/^\s*[-*]\s+/.test(lines[i]) && !/^\s*\d+\.\s+/.test(lines[i]) && !/^-{3,}$/.test(lines[i].trim())) {
      para.push(lines[i]); i++;
    }
    if (para.length) blocks.push({ type: 'paragraph', content: parseInline(para.join(' ')) });
  }

  return { type: 'doc', version: 1, content: blocks };
}

// ──────────────────────────────────────────────────────────────────────
// Parse the backlog file into ticket sections.

function parseBacklog(md) {
  const lines = md.replace(/\r\n/g, '\n').split('\n');
  const tickets = [];
  let i = 0;
  while (i < lines.length) {
    const line = lines[i];
    const m = line.match(/^##\s+((?:RM|TL|ADMIN|LEADERSHIP|COMPLIANCE|PLATFORM)-.*)$/);
    if (m) {
      const title = m[1].trim();
      const bodyLines = [];
      i++;
      while (i < lines.length && !/^##\s+/.test(lines[i]) && !/^#\s+/.test(lines[i])) {
        bodyLines.push(lines[i]);
        i++;
      }
      // Trim trailing blank lines and leading "---"
      while (bodyLines.length && bodyLines[bodyLines.length - 1].trim() === '') bodyLines.pop();
      while (bodyLines.length && /^-{3,}\s*$/.test(bodyLines[bodyLines.length - 1].trim())) bodyLines.pop();
      tickets.push({ title, body: bodyLines.join('\n').trim() });
    } else {
      i++;
    }
  }
  return tickets;
}

function priorityFromBody(body) {
  const m = body.match(/\*\*Priority\*\*:\s*([A-Za-z]+)/);
  if (!m) return 'Medium';
  const p = m[1];
  if (/highest/i.test(p)) return 'Highest';
  if (/high/i.test(p)) return 'High';
  if (/medium/i.test(p)) return 'Medium';
  if (/low/i.test(p)) return 'Low';
  return 'Medium';
}

function roleLabel(title) {
  const role = title.split('-')[0].toLowerCase();
  return 'role-' + role;
}

// ──────────────────────────────────────────────────────────────────────
// Create epic + stories.

async function main() {
  const md = fs.readFileSync(FILE, 'utf8');
  const tickets = parseBacklog(md);
  console.log(`Parsed ${tickets.length} ticket sections from backlog`);
  if (tickets.length !== 21) { console.error('Expected 21 tickets!'); process.exit(1); }

  // 1. Create epic
  console.log(`\nCreating epic "${EPIC_NAME}"…`);
  const epicDescription = mdToAdf(
    `Production backlog for the Wealth CRM Lead & Prospect module.\n\n` +
    `Single parent epic for **21 stories** spanning RM, TL, Admin, IB, Leadership, Compliance, and Platform.\n\n` +
    `Source: \`matrix-lead-prospects\` prototype @ \`7aeb871\`. Target: production MATRIX (\`compass_v2_mobile\` + \`jmatrix_api\`).\n\n` +
    `Full backlog document: \`tasks/backlog-jc-productionisation.md\` in the prototype repo.`
  );
  const epicResp = await req('POST', '/rest/api/3/issue', {
    fields: {
      project: { key: PROJECT_KEY },
      summary: EPIC_NAME,
      issuetype: { id: '10000' }, // Epic
      description: epicDescription,
      labels: ['lead-prospects', 'epic'],
    },
  });
  console.log(`✓ Epic created: ${epicResp.key}`);
  const EPIC_KEY = epicResp.key;

  // 2. Create stories
  const created = [];
  let n = 1;
  for (const t of tickets) {
    const priority = priorityFromBody(t.body);
    const labels = ['lead-prospects', roleLabel(t.title)];
    const description = mdToAdf(t.body);
    process.stdout.write(`  [${String(n).padStart(2, '0')}/21] Creating "${t.title}" (priority ${priority})… `);
    try {
      const resp = await req('POST', '/rest/api/3/issue', {
        fields: {
          project: { key: PROJECT_KEY },
          summary: t.title,
          issuetype: { id: '10012' }, // Story
          description,
          priority: { name: priority },
          labels,
          parent: { key: EPIC_KEY },
        },
      });
      console.log(`→ ${resp.key}`);
      created.push({ id: t.title, key: resp.key, priority });
    } catch (e) {
      console.log(`FAILED`);
      console.error(`    ${e.message}`);
      created.push({ id: t.title, key: 'FAILED', priority, error: e.message });
    }
    n++;
  }

  // 3. Output mapping
  console.log('\n──────────────────────────────────────────────────────────────────');
  console.log('Push complete. Mapping:');
  console.log('──────────────────────────────────────────────────────────────────');
  console.log(`Epic: ${EPIC_KEY}  →  ${EPIC_NAME}`);
  console.log('');
  for (const c of created) {
    console.log(`${c.key.padEnd(8)} [${c.priority.padEnd(7)}]  ${c.id}`);
  }
  const failed = created.filter((c) => c.key === 'FAILED');
  if (failed.length) {
    console.log(`\n${failed.length} ticket(s) FAILED — review errors above.`);
    process.exit(2);
  }
}

main().catch((e) => { console.error('Fatal:', e.message); process.exit(1); });

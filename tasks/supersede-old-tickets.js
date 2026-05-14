// Adds a "Superseded by …" comment to each of the 22 old tickets so the
// canonical sprint backlog is unambiguous. Doesn't change status (TODO stays)
// because workflow doesn't expose Cancelled / Done from TODO and we lack
// delete permission.

const https = require('https');

const HOST = 'jmfldev.atlassian.net';
const USER = 'vinit.mehta@jmfl.com';
const TOKEN = process.env.JIRA_API_TOKEN;
if (!TOKEN) { console.error('JIRA_API_TOKEN not set'); process.exit(1); }
const AUTH = 'Basic ' + Buffer.from(`${USER}:${TOKEN}`).toString('base64');

function req(method, pathName, body) {
  return new Promise((resolve, reject) => {
    const data = body ? JSON.stringify(body) : null;
    const opts = { host: HOST, path: pathName, method, headers: { Authorization: AUTH, Accept: 'application/json', 'Content-Type': 'application/json' } };
    if (data) opts.headers['Content-Length'] = Buffer.byteLength(data);
    const r = https.request(opts, (res) => {
      let chunks = ''; res.on('data', (d) => (chunks += d));
      res.on('end', () => {
        if (res.statusCode >= 400) reject(new Error(`HTTP ${res.statusCode}: ${chunks.slice(0, 300)}`));
        else resolve(chunks ? JSON.parse(chunks) : null);
      });
    });
    r.on('error', reject);
    if (data) r.write(data);
    r.end();
  });
}

// Best-effort old → new mapping. Old tickets without a 1:1 successor are
// labelled "Future-sprint scope" so the dev team knows it's intentional.
const MAP = {
  'JC-1511': { msg: 'Superseded. See JC-1534 (FE New Lead) and JC-1535 (BE New Lead) for the active sprint backlog.' },
  'JC-1512': { msg: 'Superseded. See JC-1535 (BE dedup) and JC-1534 (FE coverage UI on Save) for the active sprint backlog.' },
  'JC-1513': { msg: 'Superseded. See JC-1534 (FE — country code is part of New Lead) and JC-1552 (BE master data).' },
  'JC-1514': { msg: 'Superseded. See JC-1536 (FE Lead Request) and JC-1537 (BE Lead Request).' },
  'JC-1515': { msg: 'Superseded. Temperature feature is rolled into JC-1538 (FE list filter), JC-1539 (BE list endpoint), JC-1540 (FE detail header).' },
  'JC-1516': { msg: 'Future-sprint scope. Profiling wizard is not in the current sprint backlog (JC-1534..JC-1552). Will be pushed when scoped.' },
  'JC-1517': { msg: 'Future-sprint scope. TL SLA timers are not in the current sprint (RM-only slice).' },
  'JC-1518': { msg: 'Future-sprint scope. Cross-cutting role enforcement comes with platform sprints.' },
  'JC-1519': { msg: 'Future-sprint scope. Admin Reassignment queue belongs to the Admin sprint.' },
  'JC-1520': { msg: 'Future-sprint scope. Bulk lead upload belongs to the Admin sprint.' },
  'JC-1521': { msg: 'Future-sprint scope. Orphan handling belongs to the Admin sprint.' },
  'JC-1522': { msg: 'Superseded by JC-1546 (FE RM Dashboard) and JC-1547 (BE RM Dashboard) for the RM-personal scope. Org-wide Leadership Dashboard remains future-sprint scope.' },
  'JC-1523': { msg: 'Superseded. Consent capture is part of JC-1534 (FE New Lead) and JC-1535 (BE New Lead).' },
  'JC-1524': { msg: 'Superseded by JC-1540 (FE Lead Details — PII masking + unmask) and JC-1541 (BE Lead Details — audit log on unmask).' },
  'JC-1525': { msg: 'Future-sprint scope. Org hierarchy sync is platform work.' },
  'JC-1526': { msg: 'Superseded. Activity log work is in JC-1548 (FE Log Capture), JC-1549 (BE Log Capture), JC-1551 (BE Activity Request — state transitions).' },
  'JC-1527': { msg: 'Superseded by JC-1535 (BE handles canonical phone storage as part of dedup); migration script is future scope.' },
  'JC-1528': { msg: 'Future-sprint scope. Push + email notifications are platform work.' },
  'JC-1529': { msg: 'Future-sprint scope. Crash + error reporting is platform work.' },
  'JC-1530': { msg: 'Future-sprint scope. Build pipeline is DevOps work.' },
  'JC-1531': { msg: 'Future-sprint scope. Funnel analytics events are platform work.' },
  'JC-1532': { msg: 'Superseded by JC-1542 (FE Convert to IB) and JC-1543 (BE Convert to IB) for the RM-side IB submit. Full IB checker queue + dashboards remain future-sprint scope.' },
};

async function main() {
  console.log('Adding supersede comments to 22 old tickets…\n');
  const failures = [];
  for (const [key, { msg }] of Object.entries(MAP)) {
    process.stdout.write(`  ${key} … `);
    const body = {
      body: {
        type: 'doc',
        version: 1,
        content: [
          { type: 'paragraph', content: [{ type: 'text', text: msg }] },
          { type: 'paragraph', content: [{ type: 'text', text: 'Active sprint-1 backlog: JC-1534 to JC-1552 (under epic JC-1510).' }] },
        ],
      },
    };
    try {
      await req('POST', `/rest/api/3/issue/${key}/comment`, body);
      console.log('✓');
    } catch (e) {
      console.log(`FAILED — ${e.message.slice(0, 200)}`);
      failures.push(key);
    }
  }
  console.log(failures.length ? `\n${failures.length} failed: ${failures.join(', ')}` : '\nAll 22 supersede comments added.');
}

main().catch((e) => { console.error('Fatal:', e.message); process.exit(1); });

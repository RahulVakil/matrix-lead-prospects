// Discovery script: confirms epic state, finds the story-points custom field,
// and looks up the 6 dev assignees by name. No mutations.

const https = require('https');

const HOST = 'jmfldev.atlassian.net';
const USER = 'vinit.mehta@jmfl.com';
const TOKEN = process.env.JIRA_API_TOKEN;
if (!TOKEN) { console.error('JIRA_API_TOKEN not set'); process.exit(1); }
const AUTH = 'Basic ' + Buffer.from(`${USER}:${TOKEN}`).toString('base64');

function req(method, path) {
  return new Promise((resolve, reject) => {
    const r = https.request({ host: HOST, path, method, headers: { Authorization: AUTH, Accept: 'application/json' } }, (res) => {
      let chunks = '';
      res.on('data', (d) => (chunks += d));
      res.on('end', () => {
        if (res.statusCode >= 400) reject(new Error(`HTTP ${res.statusCode}: ${chunks.slice(0, 300)}`));
        else resolve(chunks ? JSON.parse(chunks) : null);
      });
    });
    r.on('error', reject);
    r.end();
  });
}

async function main() {
  console.log('═══ EPIC JC-1510 ═══');
  try {
    const epic = await req('GET', '/rest/api/3/issue/JC-1510?fields=summary,issuetype,status');
    console.log(`✓ ${epic.key} · "${epic.fields.summary}" · ${epic.fields.issuetype.name} · ${epic.fields.status.name}`);
  } catch (e) {
    console.log(`✗ ${e.message}`);
  }

  console.log('\n═══ 22 CHILD TICKETS (JC-1511..JC-1532) ═══');
  const childKeys = [];
  for (let n = 1511; n <= 1532; n++) childKeys.push(`JC-${n}`);
  for (const k of childKeys) {
    try {
      const t = await req('GET', `/rest/api/3/issue/${k}?fields=summary,status`);
      console.log(`  ${t.key} · ${t.fields.status.name} · "${t.fields.summary}"`);
    } catch (e) {
      console.log(`  ${k} · ${e.message}`);
    }
  }

  console.log('\n═══ STORY POINTS CUSTOM FIELD ═══');
  const fields = await req('GET', '/rest/api/3/field');
  const sp = fields.filter((f) => /story\s*point/i.test(f.name));
  sp.forEach((f) => console.log(`  ${f.id} · "${f.name}" · type=${f.schema?.type ?? '?'}`));

  console.log('\n═══ ASSIGNEE LOOKUP ═══');
  const names = ['Omkar', 'Forum', 'Gopinath', 'Vishwas', 'Vaibhav', 'Arsh'];
  for (const n of names) {
    try {
      const matches = await req('GET', `/rest/api/3/user/search?query=${encodeURIComponent(n)}`);
      console.log(`\n  Query "${n}":`);
      if (!matches.length) {
        console.log('    (no matches)');
      } else {
        matches.slice(0, 5).forEach((u) => {
          console.log(`    accountId=${u.accountId} · displayName="${u.displayName}" · email=${u.emailAddress ?? '<hidden>'} · active=${u.active}`);
        });
      }
    } catch (e) {
      console.log(`  Query "${n}": ${e.message}`);
    }
  }
}

main().catch((e) => { console.error('Fatal:', e.message); process.exit(1); });

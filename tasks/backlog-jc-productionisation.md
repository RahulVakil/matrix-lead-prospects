# Wealth CRM — Lead & Prospect (Project JC)

> **Status**: In Jira · **Date**: 2026-04-30 · **Owner**: Vinit Mehta
> **Target codebases**: production MATRIX — `compass_v2_mobile` + `jmatrix_api`
> **Project key**: `JC` · **Epic**: `Wealth CRM - Lead & Prospect` (`JC-1510`) — single parent epic for all 22 tickets
> **Total**: 22 stories. No tasks. No spikes.

---

## How to read this document

- **Single epic**: every ticket sits under **Wealth CRM — Lead & Prospect**. Role groupings are for navigation only.
- **Ticket ID format**: `ROLE-FeatureName`.
- **Self-contained**: each ticket carries the data shape, business rules, validation, error UX, and sample payloads needed to build it. Devs have access to the existing code base only — no running app to inspect — so behaviour is described explicitly here.
- **Sample payloads** in each ticket are illustrative — exact field names follow JSON conventions but can be adjusted to match existing API conventions on `jmatrix_api`.

## What every story includes (definition of done)

Applies to every ticket below — no need to repeat per ticket:

1. **Tested**: unit tests on logic + widget tests on screens; coverage ≥ 60% for repos and cubits.
2. **Logged**: state-changing actions write an activity entry (per `PLATFORM-Lead history audit trail`).
3. **Observed**: errors and crashes report to the crash tool with PII redacted (per `PLATFORM-Crash and error reporting`).
4. **Role-gated**: every endpoint sits behind the right role check (per `TL-Role based access`).
5. **PII-safe**: phone, email, PAN, DOB never leave the device or server unmasked unless role + audit allow.
6. **Error UX**: every failure mode listed in the ticket has a defined user-visible state — no silent failures.

## Code reference paths

- `lib/core/models/` — domain models (lead, consent, contact, coverage, family group, reassignment).
- `lib/core/repositories/` — repository interfaces.
- `lib/core/widgets/key_contacts_field.dart` — Key Contacts shape.
- `lib/core/services/mock/mock_coverage_repository.dart` — coverage match algorithm.
- `lib/features/create_lead/presentation/pages/create_lead_screen.dart` — country code component reference.

## Assumptions (locked)

1. **MATRIX login is already live in production.** Existing app handles SSO and profile load; tickets do not need a login ticket. User profile carries: employee ID, name, role (RM/TL/Admin/IB/Leadership), vertical (EWG/PWG), zone, branch, team, email. *Confirm with platform that login already exposes zone + team.*
2. **Mobile-only target.** No web build.
3. **Wealth Spectrum integration is already in production.** Coverage tickets reuse the existing API-token-based integration.
4. **Dedupe rule matrix signed off**: PWG = Name+Email+Mobile+Company; EWG = Name+Email+Mobile; IB-side capture = Name+Email+Mobile. No cross-vertical special cases. **Pool**: Wealth Spectrum client master + MATRIX internal lead table; both hard-block save.
5. **Designation values signed off**: Promoter, Founder, CEO, Family Office Head, Others (free text, max 60 chars).
6. **Activity logs are retained indefinitely.** No purge.
7. **Lead temperature day-zero anchor**: `lastActivityAt`; fall back to `createdAt` if no activity yet.
8. **Coverage confidence thresholds**: ≥0.95 hard-block; 0.5–0.95 review; <0.5 clear.
9. **Country code list**: 10 countries (India + 9 NRI markets).
10. **Bulk pool upload cap**: 5,000 rows per upload.
11. **Push notifications: no quiet hours.**
12. **Lead drop is manual-only.** No auto-drop on SLA breach or orphan retention.

---

## Index

| # | Jira | Ticket | Title | Priority |
|---|---|---|---|---|
| 1 | `JC-1511` | `RM-Lead creation and editing` | Create, edit and refresh leads end-to-end | Highest |
| 2 | `JC-1512` | `RM-Duplicate lead prevention` | Coverage check across client master + live leads | Highest |
| 3 | `JC-1513` | `RM-Mobile with country code` | Country-coded mobile entry on every capture form | High |
| 4 | `JC-1514` | `RM-Claim from pool` | Claim a lead from the shared pool | High |
| 5 | `JC-1515` | `RM-Lead temperature bands` | Hot / Warm / Cold visibility on every lead | High |
| 6 | `JC-1516` | `RM-Profiling wizard resume` | Resume profiling from where you left off | Medium |
| 7 | `JC-1517` | `TL-Lead ageing and SLA` | 7 / 30-day SLA cycle, server-driven | High |
| 8 | `JC-1518` | `TL-Role based access` | Every role's permissions enforced server-side | High |
| 9 | `JC-1519` | `ADMIN-Reassignment queue` | Approve, reject, cancel reassignment requests | High |
| 10 | `JC-1520` | `ADMIN-Bulk lead upload` | Upload up to 5,000 leads at once | Medium |
| 11 | `JC-1521` | `ADMIN-Orphan lead handling` | Recover leads when an RM offboards | Low |
| 12 | `JC-1532` | `IB-Checker workflow and dashboards` | IB queue, approve/reject/convert, RM-side tracking | High |
| 13 | `JC-1522` | `LEADERSHIP-Funnel dashboard` | KPIs by zone, branch, vertical with drill-down | High |
| 14 | `JC-1523` | `COMPLIANCE-Consent capture` | DPDP-compliant consent at lead creation | Highest |
| 15 | `JC-1524` | `COMPLIANCE-PII privacy and audit` | Mask PII, log every unmask, retention | High |
| 16 | `JC-1525` | `PLATFORM-Org hierarchy` | Zone → Branch → Team sync from HR | High |
| 17 | `JC-1526` | `PLATFORM-Lead history audit trail` | Per-lead activity log, retained forever | High |
| 18 | `JC-1527` | `PLATFORM-Mobile number standard` | Single phone format end-to-end + legacy backfill | High |
| 19 | `JC-1528` | `PLATFORM-Notifications` | Push and email for lead events | High |
| 20 | `JC-1529` | `PLATFORM-Crash and error reporting` | Production observability with PII guardrails | High |
| 21 | `JC-1530` | `PLATFORM-Mobile build pipeline` | Signed Android + iOS releases | High |
| 22 | `JC-1531` | `PLATFORM-Funnel analytics` | Product analytics events for the lead funnel | Medium |

**Priority roll-up**: 3 Highest · 15 High · 3 Medium · 1 Low.

---

# RM (Relationship Manager)

## RM-Lead creation and editing
- **Priority**: Highest

**User story**: As any user, I want every lead I create or edit to be saved in the real system, and I want my list views to reflect changes the moment I return — without manually pulling to refresh.

### Lead data shape

| Field | Type | Notes |
|---|---|---|
| `id` | string | Server-generated. Format `LEAD_<epoch_ms>` or UUID — server's choice. |
| `entityType` | enum | `individual`, `private_limited`, `public_limited`, `partnership`, `llp`, `huf`, `trust`, `family_office`, `others` |
| `entityTypeOther` | string \| null | Required when `entityType = others`, max 100 chars. |
| `fullName` | string | Computed: `firstName + middleName + lastName` for individual; entity name for non-individual. |
| `firstName`, `middleName`, `lastName` | string \| null | Individual leads only. |
| `companyName` | string \| null | Optional both types. |
| `groupName` | string \| null | Optional. Used for family-group de-dupe. |
| `designation` | enum \| null | Individual leads only. Values: `promoter`, `founder`, `ceo`, `family_office_head`, `others`. |
| `designationOther` | string \| null | Required when `designation = others`, max 60 chars. |
| `phone` | string \| null | E.164 canonical: `+919876543210`. See `PLATFORM-Mobile number standard`. |
| `email` | string \| null | Lowercase trimmed. |
| `keyContacts[]` | array \| empty | Non-individual leads only. Each: `{name, designation, mobile, email, isPrimary}`. Minimum 1 valid contact required when `entityType != individual`. |
| `source` | enum | RM-pickable values: `referral`, `walkIn`, `event`, `cold_call`, `social_media`, `web_inquiry`. System-only values: `bulk_upload`, `hurun`, `monetizationEvent`. |
| `stage` | enum | `lead`, `contacted`, `qualified`, `ib_pending`, `ib_approved`, `onboarded`, `dropped`. |
| `assignedRmId`, `assignedRmName` | string | Owner. `POOL` for unassigned pool leads. |
| `vertical` | enum | `EWG` or `PWG`. Inherited from creating user. |
| `consentRecords[]` | array | See `COMPLIANCE-Consent capture`. |
| `coverageVerified` | boolean | False when soft-fail saved during a coverage outage. |
| `createdAt`, `updatedAt` | ISO 8601 | Server-set. |
| `version` | integer | Increments on every update — for optimistic concurrency. |

### API endpoints

| Method | Path | Purpose |
|---|---|---|
| `POST` | `/leads` | Create. Returns the new lead with server-assigned ID + `version=1`. |
| `GET` | `/leads/{id}` | Read full lead. |
| `PUT` | `/leads/{id}` | Update. Body must include `version`; server returns 409 if it doesn't match. |
| `GET` | `/leads?assignedRmId=&stage=&vertical=&temperature=&page=&limit=` | List with filters + pagination. |

### Sample request — create lead

```
POST /leads
{
  "entityType": "individual",
  "firstName": "Aanya",
  "lastName": "Khanna",
  "phone": "+919876543210",
  "email": "aanya.khanna@example.com",
  "companyName": "Khanna Holdings",
  "designation": "founder",
  "source": "referral",
  "vertical": "PWG",
  "consentRecords": [/* see COMPLIANCE-Consent capture */]
}

201 Created
{
  "id": "LEAD_1745920000123",
  "fullName": "Aanya Khanna",
  "stage": "lead",
  "assignedRmId": "EMP1234",
  "assignedRmName": "Vikram Mehta",
  "vertical": "PWG",
  "createdAt": "2026-04-30T11:13:20.123+05:30",
  "updatedAt": "2026-04-30T11:13:20.123+05:30",
  "version": 1,
  ...
}
```

### Validation rules — Save Lead

- Name: required (full name for non-individual; first + last for individual).
- Non-individual: at least one Key Contact with valid mobile or email.
- Source: required.
- `entityType = others` → `entityTypeOther` required, max 100 chars.
- Individual + `designation = others` → `designationOther` required, max 60 chars.

### Optimistic concurrency

Every PUT must include the `version` from the GET. Server returns:
- `200 OK` + updated record (with new `version`) if `version` matches.
- `409 Conflict` + the latest version of the record if `version` is stale.

### List refresh behaviour

After any state-changing action (edit / claim / drop / IB submit / consent grant), the list views the user returns to (All Leads, My Leads, Home active count, pool view) reflect the latest state without manual pull-to-refresh. Implementation: cubit `didPopNext` re-fetch via RouteAware. No double-fetch loops on screen entry (debounce ≥ 200 ms or skip if a fetch is in flight).

### Error states

| Failure | What the user sees |
|---|---|
| Required field empty on submit | Inline red error under the field: "Required" |
| `entityType = others`, qualifier empty | Inline error: "Required when Others is selected" |
| Phone fails country rule | Inline error from `RM-Mobile with country code` ticket |
| Network error on save | Red toast: "Couldn't save lead. Check your connection and try again." Retry action. Form data preserved. |
| Server validation failure (400) | Red toast with the server-returned message; form data preserved. |
| Concurrent edit conflict (409) | Modal: "This lead was updated by [decidedByName] [time]. Reload to see the latest version?" Actions: Reload (discard local) / Keep editing (override — re-submits with new version after refetch). |
| Permission denied editing another RM's lead | Toast: "You don't have permission to edit this lead." Form is read-only. |
| Lead deleted server-side while user views it | Banner: "This lead is no longer available." with Back button. |

### Done when

1. Create / read / update / list endpoints live and used by Add Lead, lead detail, every lead list.
2. Optimistic create with rollback path and visible error toast.
3. Concurrent-edit conflict (409) surfaces the modal with both action options.
4. Lists refresh on screen return for every state-changing action; no double-fetch.
5. Validation rules above enforced both client-side (immediate inline errors) and server-side (rejected with field-level error in 400 response).

---

## RM-Duplicate lead prevention
- **Priority**: Highest · **Depends on**: `RM-Lead creation and editing`

**User story**: As an RM, when I'm entering a name / phone / email / company on Add Lead or IB Lead, I want the system to tell me — before I save — if this person is already a client of the firm or already an active lead under another RM. If the service is unreachable, I shouldn't be blocked, but the lead should be flagged for re-checking.

### Pools checked (in priority order — first hit wins)

1. **Wealth Spectrum client master** (existing MATRIX integration). Hit → `existingClient` status.
2. **MATRIX internal lead table** (open leads, any RM, any stage except `dropped`). Hit → `duplicateLead` status.

Both hard-block Save Lead.

### Match algorithm (identical for both pools)

ANY single field hit counts as a match:

| Field | Match rule |
|---|---|
| Mobile | Compare digits-only (strip `+`, spaces, dashes). Bidirectional `endsWith` so `+91 9876543210` matches a stored `9876543210` either way. |
| Email | Case-insensitive exact match, trimmed. |
| Full name | Case-insensitive — record name contains entered name (substring). |
| Company / Group | Case-insensitive substring. **PWG vertical only.** |

User vertical comes from profile. Unknown vertical (IB-side capture) → behave as EWG (no company match).

### Trigger conditions

The check fires once any of these is true: phone ≥ 10 digits (or country-specific minimum), email contains `@`, name has ≥ 3 chars, company has ≥ 3 chars. Wait 600 ms after the user stops typing.

### Confidence scoring

| Match type | Weight |
|---|---|
| Mobile exact | 1.0 |
| Email exact | 1.0 |
| Name substring | 0.7 |
| Company substring (PWG only) | 0.7 |

`confidence = max(weights of all matched fields)`.

| Confidence | Status | Save behaviour |
|---|---|---|
| ≥ 0.95 | `existingClient` or `duplicateLead` | Hard block |
| 0.5 – <0.95 | `requiresReview` | Soft block — RM may proceed with reason ≥ 20 chars |
| < 0.5 | `clear` | Save allowed |

Thresholds tunable from backend without app release.

### DND check

- Phone (digits-only) matched against the DND register (source confirmed in existing Wealth Spectrum integration).
- DND hit → `dnd` status — hard block.
- Admin override available with reason ≥ 20 chars; audited.
- RMs see no override path.

### Family panel (Wealth Spectrum hits only)

A family = set of `clientMaster` records sharing the same group identifier (case-insensitive). Returned with `existingClient`:

```
{
  "groupName": "Khanna Family Office",
  "memberCount": 4,
  "members": [
    {"clientId": "CM00018", "clientName": "Aanya Khanna", "rmId": "EMP1001", "rmName": "Vikram Mehta"},
    {"clientId": "CM00019", "clientName": "Rohan Khanna", "rmId": "EMP1002", "rmName": "Pooja Sharma"},
    ...
  ]
}
```

`duplicateLead` results never carry a family panel (family is a Wealth Spectrum concept).

### API endpoint

```
POST /coverage/check
{
  "name": "Aanya Khanna",      // optional
  "phone": "+919876543210",    // optional, canonical format
  "email": "aanya.k@example.com", // optional
  "company": "Khanna Holdings", // optional
  "vertical": "PWG"            // RM's vertical
}
```

### Sample responses

**Clear**:
```
{ "status": "clear", "confidence": 0 }
```

**Existing client (Wealth Spectrum hit, mobile match)**:
```
{
  "status": "existingClient",
  "confidence": 1.0,
  "matchedField": "mobile",
  "matchedRecord": {
    "clientId": "CM00018",
    "clientName": "Aanya Khanna",
    "rmId": "EMP1001",
    "rmName": "Vikram Mehta",
    "vertical": "PWG"
  },
  "familyMatch": { "groupName": "Khanna Family Office", "memberCount": 4, "members": [...] }
}
```

**Duplicate lead (MATRIX lead table, email match)**:
```
{
  "status": "duplicateLead",
  "confidence": 1.0,
  "matchedField": "email",
  "matchedLead": {
    "leadId": "LEAD_1745910000111",
    "fullName": "Aanya Khanna",
    "stage": "qualified",
    "assignedRmId": "EMP1003",
    "assignedRmName": "Sneha Iyer"
  }
}
```

**DND**:
```
{
  "status": "dnd",
  "matchedPhone": "+919876543210",
  "registerSource": "TRAI"
}
```

**Requires review**:
```
{
  "status": "requiresReview",
  "confidence": 0.7,
  "alternates": [
    { "source": "clientMaster", "id": "CM00021", "name": "Aanya Khan", "matchedField": "name" },
    { "source": "leadList", "id": "LEAD_1745912000333", "name": "Aanya Khanna Singh", "matchedField": "name" }
  ]
}
```

### Worked examples

**Example 1** — RM enters phone `9876543210`, no other input. Wealth Spectrum has client with phone `+91 9876543210`.
- Match: mobile, weight 1.0 → `existingClient`. Save blocked.

**Example 2** — RM enters name `John D`, vertical `EWG`, no other input. Wealth Spectrum has client `John David Smith`.
- Substring match on name, weight 0.7. Below 0.95 → `requiresReview`. Alternates listed; save allowed with reason.

**Example 3** — RM enters email `john.smith@gmail.com`, vertical `PWG`. Internal lead table has lead with same email under another RM.
- Wealth Spectrum: no match. Lead table: email exact match, weight 1.0. Pool order: Wealth Spectrum first (no hit), then lead table → `duplicateLead`. Save blocked.

**Example 4** — RM enters company `Acme Inc`, vertical `EWG`. Wealth Spectrum has client at `Acme Industries`.
- EWG vertical doesn't match on company → no hit → `clear`.

**Example 5** — RM enters phone `9999999999` which is on the DND register.
- DND match → `dnd`. Save hard-blocked with override path for Admin only.

### Soft-fail behaviour

- Coverage call returns 5xx or times out (>5s) → soft-fail banner: "Coverage couldn't be verified. You can save the lead anyway — it'll be flagged for review."
- Save proceeds with `coverageVerified: false`.
- Admin "Unverified leads" queue lists these for batch re-check.
- If re-check later finds a conflict, a yellow strip on lead detail says: "Re-check found a conflict with [client name]. Admin will review."

### Error states

| Failure | What the user sees |
|---|---|
| Coverage timeout (>5s) | Yellow banner above Save: "Coverage couldn't be verified. You can save the lead anyway — it'll be flagged for review." Save remains enabled. |
| Coverage 5xx | Same yellow banner. |
| `existingClient` (≥0.95) | Red result sheet with matched client + RM, "Already a client of [RM]". Save Lead disabled. Action: "Request reassignment". |
| `duplicateLead` (≥0.95) | Red result sheet with matched lead + RM + stage. Save Lead disabled. Actions: "Request reassignment" and "Contact RM" (deep link). |
| `requiresReview` (0.5–<0.95) | Amber sheet listing alternates. Save Lead enabled with caveat "Mark this as a new lead — provide reason ≥ 20 chars." |
| `dnd` | Red blocking dialog: "This number is on a Do Not Disturb register. Contact Compliance Admin to override." Save disabled. |
| Override reason too short | Inline error in modal: "Reason must be at least 20 characters." |
| Re-check finds late conflict on unverified lead | Lead detail yellow strip: "Re-check found a conflict with [client name]. Admin will review." |

### Done when

1. Coverage call checks both pools and produces the right status.
2. P95 ≤ 800 ms; loading shimmer beyond 300 ms.
3. `existingClient` and `duplicateLead` block save and route to reassignment.
4. Family panel renders on Wealth Spectrum hits when a family group exists.
5. DND hit hard-blocks; Admin override audited; reason min 20 chars enforced.
6. Soft-fail banner appears on outage; lead saves with `coverageVerified=false`; Admin queue lists unverified leads.

---

## RM-Mobile with country code
- **Priority**: High

**User story**: As an RM (and IB-side capturer) entering a mobile number on Add Lead, IB Lead, or any Key Contact, I want a country-code dropdown next to the digits, so foreign clients are captured correctly and Indian numbers are validated for the local rule.

### Country code rules (locked)

| Country | Dial code | Length | Must start with |
|---|---|---|---|
| 🇮🇳 India *(default)* | +91 | 10 | 6, 7, 8 or 9 |
| 🇦🇪 UAE | +971 | 9 | 5 |
| 🇸🇬 Singapore | +65 | 8 | 8 or 9 |
| 🇬🇧 United Kingdom | +44 | 10 | 7 |
| 🇺🇸 United States | +1 | 10 | (no rule) |
| 🇨🇦 Canada | +1 | 10 | (no rule) |
| 🇦🇺 Australia | +61 | 9 | 4 |
| 🇸🇦 Saudi Arabia | +966 | 9 | 5 |
| 🇭🇰 Hong Kong | +852 | 8 | 5, 6 or 9 |
| 🇨🇭 Switzerland | +41 | 9 | 7 |

### Where it appears

- Add Lead — lead's mobile field.
- IB Lead capture form — lead's mobile field.
- Key Contacts row — every contact has its own country code (different contacts on the same lead can be in different countries).

### Behaviour

- Default selection: India.
- Input accepts digits only (`FilteringTextInputFormatter.digitsOnly`).
- `LengthLimitingTextInputFormatter` caps at country max.
- Mobile is optional — empty always passes.
- Switching country trims excess digits and clears any prior coverage hit.
- Closed dropdown shows just `🇮🇳 +91`; expanded menu shows `🇮🇳 India +91`.
- Persistence: `dialCode + digits` in canonical format (`+919876543210`) per `PLATFORM-Mobile number standard`.

### Worked examples

| User input | Country selected | Stored | Displayed | Valid? |
|---|---|---|---|---|
| `9876543210` | India (+91) | `+919876543210` | `+91 98765 43210` | Yes |
| `5555555555` | India (+91) | n/a | n/a | No — must start with 6/7/8/9 |
| `12345` | India (+91) | n/a | n/a | No — only 5 digits |
| `987654321` | UAE (+971) | n/a | n/a | No — must start with 5 |
| `512345678` | UAE (+971) | `+971512345678` | `+971 51234 5678` | Yes |
| `91234567` | Singapore (+65) | `+6591234567` | `+65 91234 567` | Yes |
| empty | India (+91) | `null` | `—` | Yes (mobile is optional) |
| `+91 9876543210` (paste) | India (+91) | `+919876543210` (auto-strip prefix) | `+91 98765 43210` | Yes |
| `+1 9876543210` (paste while India selected) | India (+91) | n/a | n/a | Inline error: "Pasted country code doesn't match the selected country." |

### Validation rules

- Empty → no error (optional field).
- Length < min or > max → "Enter X digits" or "Enter X–Y digits" (depending on country range).
- Leading digit fails regex → country-specific hint (e.g. "Indian mobile must start with 6, 7, 8 or 9").

### Error states

| Failure | What the user sees |
|---|---|
| Length wrong (e.g. 9 digits for India) | Inline error: "Enter 10 digits" |
| Range mismatch (UAE 8-9 digits) | "Enter 8–9 digits" |
| Leading digit wrong | Country-specific inline hint as listed in the table |
| Paste with matching `+CC ` prefix | Auto-strip silently |
| Paste with mismatching country code | Inline: "Pasted country code doesn't match the selected country." |
| Paste with letters or special chars | Filter to digits-only on input; no error needed |

### Done when

1. Add Lead, IB Lead, and Key Contacts use the same country-code component.
2. Each Key Contact row has independent country selection.
3. All ten countries' rules enforced.
4. IB checker queue and lead lists display the formatted number consistently.

---

## RM-Claim from pool
- **Priority**: High · **Depends on**: `RM-Lead creation and editing`, `TL-Role based access`

**User story**: As an RM, when I tap "claim" on a pool lead, exactly one RM should win — even if two RMs tap at the same instant.

### Pool eligibility

An RM can claim a pool lead only if ALL of:
- RM's vertical matches the lead's vertical.
- RM's branch is in the lead's allowed-branch list (default: any branch in the lead's zone).
- RM is not under IB-gating restriction for that lead (existing IB-gating logic).

### Atomic claim semantics

The server uses a row-level conditional update:

```
UPDATE leads
SET assigned_rm_id = :rmId, assigned_rm_name = :rmName, claimed_at = NOW(), version = version + 1
WHERE id = :leadId AND assigned_rm_id = 'POOL'
RETURNING ...;
```

If 0 rows updated → 409 Conflict (someone else won). If 1 row → success.

### API endpoint

```
POST /leads/{id}/claim
Idempotency-Key: <client-generated UUID>

200 OK  (won)
{ "lead": { ... full lead with assignedRm = caller ... } }

409 Conflict  (lost the race)
{ "error": "AlreadyClaimed", "claimedBy": { "rmId": "EMP1234", "rmName": "Vikram Mehta" } }

403 Forbidden  (ineligible)
{ "error": "NotEligible", "reason": "vertical_mismatch" }
```

Idempotency: re-tap with same key → returns the original 200 response.

### Sequence — race resolution

```
Time   RM-A taps              RM-B taps
T+0ms  POST /claim/LEAD_42    POST /claim/LEAD_42
T+5ms  Server picks RM-A      ─
T+8ms  ─                      Server returns 409 to RM-B
T+10ms RM-A sees lead detail  RM-B sees "Already claimed by [RM-A]"
T+12ms All pool viewers' lists refresh — LEAD_42 disappears
```

### Post-claim side effects

1. Lead moves to RM-A's queue.
2. Removed from pool view (push refresh to all online RMs viewing the pool).
3. Activity log entry: `{eventType: "claimed_from_pool", actor: "EMP1234", leadId, timestamp}`.
4. Push notification to RM-A: "You claimed [lead name]" with deep link to lead detail.

### Error states

| Failure | What the user sees |
|---|---|
| Concurrent claim — this RM lost (409) | Snackbar: "Already claimed by [other RM name]." Pool list refreshes immediately. |
| Network error | Snackbar: "Couldn't reach the server. Tap to retry." Lead stays in the pool. |
| Permission denied (403) | Snackbar: "You're not eligible to claim this lead." (e.g. vertical mismatch). Lead stays in pool. |
| Lead already claimed by self | No-op; navigate to lead detail. |
| Pool empty when user reaches the screen | Empty state: "No leads in the pool right now." with Refresh button. |

### Done when

1. Two simultaneous claim taps produce one win and one informative loss.
2. Eligibility (vertical / branch / IB-gating) enforced server-side; client-side hides ineligible claim buttons as defence-in-depth.
3. Pool list refreshes for everyone after a claim.
4. Activity log entry written on every successful claim.
5. Idempotent — same `Idempotency-Key` returns the original response.

---

## RM-Lead temperature bands
- **Priority**: High · **Depends on**: `RM-Lead creation and editing`, `PLATFORM-Lead history audit trail`

**User story**: As an RM, TL, and Leadership viewer, I want every lead labelled Hot / Warm / Cold, so I can prioritise where to spend time.

### Bands

| Band | Days since last activity | Range |
|---|---|---|
| 🔥 Hot | 0–30 | day count `< 30` |
| 🟠 Warm | 30–90 | `30 ≤` day count `< 90` |
| 🧊 Cold | 90+ | day count `≥ 90` |

Day count = `daysBetween(now, lastActivityAt, IST)`. Calendar days, IST timezone. Boundary: exactly 30 = Warm; exactly 90 = Cold.

### Anchor — `lastActivityAt`

`lastActivityAt` updates on these events: lead created, lead edited, stage moved forward, claim from pool, consent granted, profiling step advanced, IB submission, manual notes added.

Does NOT update on: drop to pool, SLA-breach flagging, system-only state changes.

For leads with no recorded activity yet, fall back to `createdAt`.

### Computation

Server computes `temperature` and `daysSinceActivity` on every lead read. Cache 1 hour at the API layer.

### API response (within `GET /leads/{id}`)

```
{
  "id": "LEAD_1745920000123",
  "fullName": "Aanya Khanna",
  ...
  "lastActivityAt": "2026-04-25T14:00:00+05:30",
  "daysSinceActivity": 5,
  "temperature": "hot"
}
```

Temperature also returned in list endpoints.

### Worked examples

| createdAt | lastActivityAt | now (IST) | days | Band |
|---|---|---|---|---|
| 2026-04-30 | (none) | 2026-04-30 | 0 | 🔥 Hot |
| 2026-04-25 | 2026-04-25 | 2026-04-30 | 5 | 🔥 Hot |
| 2026-03-30 | 2026-04-25 | 2026-04-30 | 5 | 🔥 Hot (last activity wins) |
| 2026-04-01 | 2026-04-01 | 2026-04-30 | 29 | 🔥 Hot |
| 2026-03-31 | 2026-03-31 | 2026-04-30 | 30 | 🟠 Warm |
| 2026-02-29 | 2026-02-29 | 2026-04-30 | 60 | 🟠 Warm |
| 2026-01-30 | 2026-01-30 | 2026-04-30 | 90 | 🧊 Cold |
| 2025-10-30 | 2025-12-30 | 2026-04-30 | 121 | 🧊 Cold |

### Where it shows

- Small chip / dot in band colour on every lead list cell + lead detail header.
- Day count in tooltip (long-press on mobile).
- Filter chips (multi-select) on My Leads, All Leads, TL view, Manage Pool.
- Default sort: Hot → Warm → Cold; ties broken by most-recent `lastActivityAt`.
- Leadership Dashboard tile: per-band counts (rolled into `LEADERSHIP-Funnel dashboard`).

### Analytics

Emit `temperature_changed` event when a lead crosses a band boundary on read (per `PLATFORM-Funnel analytics`).

### Error states

| Failure | What the user sees |
|---|---|
| Compute failure (rare) | List cell shows no chip; lead detail shows "Temperature unavailable" subtle text. Logged silently. |
| Cache miss + backend slow | Show last-known temperature with subtle "as of [time]" tooltip. |

### Done when

1. Every lead read returns `temperature` + `daysSinceActivity`.
2. Boundary verified at 29 / 30 / 89 / 90 days.
3. Chip on every list cell and detail header.
4. Filter and sort work across all lead lists.
5. Band-change analytics emitted.

---

## RM-Profiling wizard resume
- **Priority**: Medium · **Depends on**: `RM-Lead creation and editing`

**User story**: As an RM, I want my profiling answers saved at every step, so I can resume if I'm interrupted and don't lose work.

### Wizard state shape

```
{
  "leadId": "LEAD_1745920000123",
  "totalSteps": 7,
  "currentStep": 4,
  "completedSteps": [1, 2, 3],
  "stepAnswers": {
    "1": { "annualIncome": "5_to_10_cr", "incomeSource": "salary" },
    "2": { "investmentExperience": "advanced", "yearsInvesting": 12 },
    "3": { "riskAppetite": "moderate", "horizon": "long_term" }
  },
  "completedAt": null,
  "completedSnapshot": null,
  "version": 4
}
```

### Behaviour

- Each step's answers save when the RM advances to the next step (`PUT /profiles/{leadId}` with the latest step data + `version`).
- On reopening a partially completed wizard, the user lands on the first unanswered step (= `currentStep`).
- The final step writes a `completedSnapshot` stamped with time and actor.
- Once a lead is closed (`stage = dropped` or `onboarded`), the profile becomes read-only; the wizard renders past answers but no edit affordance.
- Two devices editing same profile: last-write-wins via `version` check; loser sees a soft warning.

### API endpoints

```
GET  /profiles/{leadId}
PUT  /profiles/{leadId}   (body: updated step answers + version)
POST /profiles/{leadId}/complete  (writes the completedSnapshot)
```

### Error states

| Failure | What the user sees |
|---|---|
| Save fails on step advance | Red banner inside the wizard: "Couldn't save your answers. Tap to retry." Retry button. The user is NOT advanced to the next step until save succeeds. Local answers preserved. |
| Two devices editing — losing device on next save | Soft toast: "Your answers were updated from another device. Pull to refresh." |
| Lead closed or converted while editing | Wizard becomes read-only with banner: "This lead is [closed/converted]. Profile is now read-only." Save button hidden. |
| Network offline mid-flow | Banner: "You're offline. Reconnect to save." Local answers preserved across reconnects. |

### Done when

1. Step advance autosaves with `version` check.
2. Resume after force-close lands on the first unanswered step.
3. Closed / converted lead's profile is read-only.
4. Last-write-wins handled with the soft warning.
5. Every error state above renders.

---

# TL (Team Lead)

## TL-Lead ageing and SLA
- **Priority**: High · **Depends on**: `RM-Claim from pool`, `PLATFORM-Notifications`

**User story**: As a TL, I want stage transitions and SLA warnings to fire from a server-side clock, so RMs can't game the timer by editing on their device.

### Stage flow

```
lead → contacted → qualified → ib_pending → ib_approved → onboarded
   │
   └→ dropped  (manual only — see Assumption #12)
```

### SLA timeline (per business — confirm thresholds)

```
Day 0  Lead created (stage = lead)                    │
                                                       │
Day 4  ── 50% of 7-day SLA   → push to assigned RM  ─┤  7-day SLA: must reach
Day 6  ── 80% of 7-day SLA   → push to assigned RM  ─┤  stage `contacted`
Day 7  ── 100% breach        → push + flag in TL view│  by Day 7
                                                       │
Day 15 ── 50% of 30-day SLA  → push to assigned RM  ─┤
Day 24 ── 80% of 30-day SLA  → push to assigned RM  ─┤  30-day SLA: must reach
Day 30 ── 100% breach        → push + flag in TL view│  `onboarded` or be
                                                       │  manually dropped
NO AUTO-DROP ON BREACH. Lead stays with RM until manually dropped.
```

Days are JMFL business days (holiday calendar honoured). Time zone: IST.

### Server-side scheduler

- Cron tick once per business hour (configurable).
- For each open lead, compute `elapsed_business_days_since_lead_started` and `elapsed_since_active_stage`.
- Fire a notification when crossing each threshold (50% / 80% / 100%).
- Each notification fires once per threshold per lead — store last-fired threshold to avoid duplicates.

### Sample SLA event record

```
{
  "leadId": "LEAD_1745920000123",
  "slaType": "7_day_contacted",
  "threshold": "80%",
  "elapsedBusinessDays": 6,
  "thresholdBusinessDays": 7,
  "firedAt": "2026-05-06T10:00:00+05:30",
  "recipientRmId": "EMP1234"
}
```

### "On hold" handling (confirm with business)

If "on hold" status exists: SLA pauses while on hold. Resume from where it left off (not reset).

### Error states

| Failure | What the user sees |
|---|---|
| Holiday calendar service unavailable | Fall back to all-days-business mode silently; system-level alert raised; no user-facing error. |
| SLA notification delivery fails | Logged; in-app drawer still shows the warning when the user opens MATRIX. |
| Lead breached but not auto-dropped (intentional) | Lead detail shows red strip: "30-day SLA breached. Drop the lead manually or escalate to TL." |
| Scheduler tick missed (server down) | On next tick, catch-up logic computes all missed thresholds and fires backlogged notifications (deduped to most-recent threshold per lead). |

### Done when

1. Stage transitions and SLA flags driven by backend scheduler (not the device).
2. Notifications fire at 50 / 80 / 100% per `PLATFORM-Notifications`.
3. Holiday calendar respected.
4. **No auto-drop on breach** — TL view simply highlights it.
5. Each notification fires once per threshold per lead (no duplicates).

**Confirm with business**: 7 / 30-day thresholds — fixed for both verticals or different? "On hold" status — does it exist?

---

## TL-Role based access
- **Priority**: High · *(spans every role)*

**User story**: As JMFL InfoSec, every gated action must be enforced on the server, so a tampered client can't bypass RM / TL / Admin / IB controls.

### Role permission matrix

| Action | RM | TL | Admin | IB | Leadership |
|---|---|---|---|---|---|
| Add Lead | ✅ | ✅ | ✅ | — | — |
| Edit own lead | ✅ | ✅ (team) | ✅ | — | — |
| Edit another RM's lead | — | ✅ (team) | ✅ | — | — |
| Get Lead (claim from pool) | ✅ | ✅ | — | — | — |
| Manage Pool view | — | — | ✅ | — | — |
| Approve / reject reassignment | — | — | ✅ | — | — |
| Submit lead to IB | ✅ | ✅ | — | — | — |
| Approve / reject in IB checker | — | — | — | ✅ | — |
| Leadership Dashboard | — | partial | partial | — | ✅ |
| Bulk pool upload | — | — | ✅ | — | — |
| DND override / coverage override | — | — | ✅ | — | — |
| Drop lead manually | ✅ | ✅ | ✅ | — | — |

### Sample 403 response

```
HTTP 403 Forbidden
{
  "error": "Forbidden",
  "message": "You don't have permission to do this.",
  "requiredRole": "Admin",
  "yourRole": "RM",
  "endpoint": "POST /reassignment/RR_1745920000333/approve",
  "correlationId": "corr_abc123"
}
```

### Audit on 403

Every 403 logged: `{userId, endpoint, attemptedAction, timestamp, deviceId}`.

### Error states

| Failure | What the user sees |
|---|---|
| User taps a gated action they shouldn't see (defence-in-depth) | Toast: "You don't have permission to do this." Action button disables itself. |
| Server returns 403 on an action the UI thought was permitted (state drift) | Same toast; trigger profile refresh in background; if role actually changed, UI re-renders with new permissions. |
| Token expired mid-action | Existing MATRIX login flow handles redirect; user returns to the same screen and can retry. |

### Confirm with business

- TL "team" scope — only direct reports, or full hierarchy under them?
- Leadership scope — all-org, or constrained to zone for zonal heads?

### Done when

1. Every action mapped to roles per the matrix.
2. Direct API call without UI returns 403 if role lacks permission (pen-test verified).
3. Role changes propagate without app reinstall.
4. Every 403 audited.

---

# Admin / MIS

## ADMIN-Reassignment queue
- **Priority**: High · **Depends on**: `RM-Lead creation and editing`, `TL-Role based access`, `PLATFORM-Notifications`

**User story**: As an Admin, I want a clean queue of reassignment requests with proper state and concurrency handling, plus full context on every request — including the original coverage hit that triggered it.

### State machine

```
pending ─┬─→ approved   (Admin action; lead reassigns to target RM)
         ├─→ rejected   (Admin action)
         └─→ cancelled  (source RM cancels their own request, only while pending)

Once approved / rejected / cancelled → terminal. No reopening.
```

### Reassignment request data shape

```
{
  "id": "RR_1745920000333",
  "leadId": "LEAD_1745920000123",
  "matchedClientId": "CM00018",        // optional — present when raised from coverage hit
  "matchedClientName": "Aanya Khanna",
  "sourceRmId": "EMP1234",
  "sourceRmName": "Vikram Mehta",
  "targetRmId": "EMP1001",
  "targetRmName": "Pooja Sharma",
  "reason": "Coverage match — Vikram requesting reassignment of Aanya Khanna",
  "status": "pending",  // pending | approved | rejected | cancelled
  "createdAt": "2026-04-30T11:13:20.123+05:30",
  "decidedBy": null,
  "decidedAt": null,
  "version": 1
}
```

### API endpoints

| Method | Path | Purpose |
|---|---|---|
| `POST` | `/reassignment` | Source RM creates request. |
| `GET` | `/reassignment?status=pending&page=&limit=` | Admin queue listing. |
| `GET` | `/reassignment/{id}` | Detail view. |
| `POST` | `/reassignment/{id}/approve` | Admin approves. Body: `{reason, version}`. |
| `POST` | `/reassignment/{id}/reject` | Admin rejects. Body: `{reason, version}`. |
| `POST` | `/reassignment/{id}/cancel` | Source RM (or Admin) cancels. Body: `{version}`. |

### Concurrency

All decision endpoints check `version`. Two admins acting simultaneously: first wins (returns 200 with new version), second gets 409.

### Approval — atomic operations

Approving a request triggers, in one transaction:
1. `reassignmentRequest.status = approved`, `decidedBy`, `decidedAt`.
2. `lead.assignedRmId = targetRmId`, `lead.assignedRmName = targetRmName`, `lead.version++`.
3. Activity log entry on the lead: `{eventType: "reassigned", actor: adminId, before: {assignedRm: source}, after: {assignedRm: target}}`.
4. Push notification to source RM: "Your reassignment request was approved".
5. Push notification to target RM: "[Lead name] was reassigned to you".

If any step fails, the whole transaction rolls back.

### Sample request — admin approves

```
POST /reassignment/RR_1745920000333/approve
{
  "reason": "Confirmed existing client of Pooja Sharma; matched on mobile.",
  "version": 1
}

200 OK
{
  "request": { ...status: "approved", decidedBy: "EMP9001", decidedAt: "...", version: 2 },
  "lead": { ...assignedRmId: "EMP1001", version: 6 }
}

409 Conflict  (another admin already actioned)
{ "error": "AlreadyActioned", "actionedBy": "EMP9002", "actionedAt": "..." }
```

### Admin queue UI

Lists pending requests with: matched client name (if any), source + target RM, request reason verbatim, age in queue. Sortable by age. Filterable by source RM, target RM, vertical.

### Error states

| Failure | What the user sees |
|---|---|
| Two admins approve simultaneously | Loser sees: "This request was already actioned by [other admin] at [time]." Queue refreshes. |
| Approval succeeds but reassignment write fails (transaction abort) | Server rolls back; admin sees: "Couldn't complete the reassignment. Try again." Activity log records the failure. |
| Network error on action | Toast: "Couldn't reach the server. Try again." with Retry button. |
| Matched client deleted from Wealth Spectrum after request | Detail view shows: "Client no longer in master." Approve still allowed. |
| Request cancelled by source RM while admin reviewing | Admin sees: "Request was cancelled by [RM] [time]." Refresh button. |
| Source or target RM offboarded between create and decide | Banner: "Source/Target RM has offboarded. Lead is in orphan bucket — reassign from there." Cancel-only. |

### Done when

1. Create / list / detail / approve / reject / cancel endpoints live.
2. Concurrent-action conflict produces exactly one winner and one informative loss (409).
3. Approval triggers reassignment + activity log + notifications atomically.
4. Admin queue surfaces all linkage fields and full coverage context.
5. Cancellation only from `pending` and only by source RM (or Admin).

---

## ADMIN-Bulk lead upload
- **Priority**: Medium · **Depends on**: `RM-Lead creation and editing`, `TL-Role based access`

**User story**: As an Admin, I want to upload a CSV of leads into the pool, so a list (event attendees, partner referrals) doesn't have to be entered one at a time.

### CSV template (exact header — case-sensitive)

```
fullName,entityType,phone,email,companyName,source,vertical
```

### Per-row validation

| Column | Rule |
|---|---|
| `fullName` | Required, ≥ 2 chars |
| `entityType` | One of: `individual`, `private_limited`, `public_limited`, `partnership`, `llp`, `huf`, `trust`, `family_office`, `others` |
| `phone` | E.164 canonical OR validates per country rule (see `RM-Mobile with country code`). Optional. |
| `email` | Must contain `@` if present. Optional. |
| `companyName` | Optional. |
| `source` | One of RM-pickable values (see `RM-Lead creation and editing` data shape). System-only sources rejected. |
| `vertical` | `EWG` or `PWG` |

### Sample CSV (good + bad rows)

```
fullName,entityType,phone,email,companyName,source,vertical
Aanya Khanna,individual,+919876543210,aanya@example.com,Khanna Holdings,referral,PWG
Rohan Singh,individual,+9198765,rohan@example.com,,referral,PWG
Priya Patel,individual,+911234567890,priya@,Patel Trust,referral,PWG
Acme Foundation,trust,+912023456789,info@acmef.org,,event,EWG
,individual,+919811112222,vinod@example.com,,referral,PWG
Vikram Mehta,unknown_type,+919811112222,,,referral,PWG
```

Row 1: ✅ valid.
Row 2: ❌ phone too short.
Row 3: ❌ email missing domain after `@`.
Row 4: ✅ valid (non-individual).
Row 5: ❌ fullName empty.
Row 6: ❌ entityType not in enum.

### Sample error report (CSV download)

```
rowNumber,fullName,error
2,Rohan Singh,"phone: must be 10 digits starting with 6/7/8/9 (India)"
3,Priya Patel,"email: invalid format"
5,(empty),"fullName: required, at least 2 chars"
6,Vikram Mehta,"entityType: must be one of [individual, private_limited, ...]"
```

### Within-file dedupe

Dedupe key: `phone + email` together (both present). If two rows share both, the later row wins (overwrites in the upload — confirm with business).

### Caps & encoding

- Maximum **5,000 rows per upload** (locked).
- Encoding: UTF-8 only.
- Max file size: 10 MB.

### Successful row → lead

Successful rows enter the pool with `assignedRmId = "POOL"`, `source = "bulk_upload"` (system tag overrides whatever was in the CSV — confirm), `vertical` from CSV, `coverageVerified = false` (bulk uploads bypass coverage; Admin queue lists them for re-check).

### Audit batch record

```
{
  "batchId": "BATCH_1745920500111",
  "uploadedBy": "EMP9001",
  "uploadedAt": "2026-04-30T11:21:40+05:30",
  "fileName": "event_2026_04_28_attendees.csv",
  "totalRows": 4523,
  "succeeded": 4480,
  "failed": 43
}
```

### Summary email (sent to uploader on completion)

> Subject: `[MATRIX] Bulk upload complete: event_2026_04_28_attendees.csv`
>
> Hi Vinit,
> Your upload finished: **4,480 of 4,523 rows** imported into the pool.
> 43 rows failed validation — [download the error report](deeplink).
> Batch ID: BATCH_1745920500111
> Imported leads are tagged `bulk_upload` and listed in the Manage Pool screen for review.

### API endpoints

```
POST /admin/leads/bulk-upload    (multipart/form-data: file)
GET  /admin/leads/bulk-upload/{batchId}/status
GET  /admin/leads/bulk-upload/{batchId}/error-report  (returns CSV)
```

### Error states

| Failure | What the user sees |
|---|---|
| File over 5,000 rows | Red banner pre-upload: "File has [X] rows. Maximum 5,000 per upload. Split the file and try again." |
| File not UTF-8 | Red banner: "Save the file as CSV (UTF-8) and try again." |
| File missing required header columns | Red banner listing missing columns. |
| Some rows fail validation | Yellow banner: "[X] of [Y] rows imported. [Y-X] failed — download report." Download button. |
| All rows fail | Red banner: "No rows imported. Download report." |
| Upload network error mid-stream | Banner: "Upload interrupted. Retry?" Already-imported rows kept; re-attempt the rest. |
| Server error during processing | Banner: "Server couldn't process the file. Contact platform support." Audit record still captures the attempt. |

### Done when

1. CSV/XLSX template documented (sample file attached to ticket).
2. Per-row validation surfaces row-level errors.
3. Successful rows enter the pool with `bulk_upload` source tag.
4. Summary email sent to uploader.
5. Audit batch record per upload.
6. 5,000-row test passes within reasonable time (target ≤ 60 s).

---

## ADMIN-Orphan lead handling
- **Priority**: Low · **Depends on**: `ADMIN-Reassignment queue`

**User story**: As an Admin, when an RM offboards, I want their leads moved to a recoverable bucket so nothing is lost and the team can pick up.

**Per business: leads are NEVER auto-dropped. They stay until someone reassigns or manually drops them.**

### Trigger — HR offboarding signal

```
POST /webhooks/hr/offboarding   (called by HR system)
{
  "employeeId": "EMP1234",
  "name": "Vikram Mehta",
  "role": "RM",
  "effectiveDate": "2026-05-15",
  "reason": "resignation"  // resignation | termination | retirement
}
```

### Action on offboarding

1. All leads where `assignedRmId == EMP1234` are atomically updated to `assignedRmId = "ORPHAN_<TL_id>"`, retaining ownership lineage.
2. Original assignment recorded in activity log: `{eventType: "rm_offboarded_orphan", actor: "system", note: "Original RM Vikram Mehta offboarded 2026-05-15"}`.
3. Orphan event audit record:
   ```
   {
     "orphanEventId": "ORPH_1745920500222",
     "departedRmId": "EMP1234",
     "departedRmName": "Vikram Mehta",
     "tlBucketId": "EMP9501",
     "leadCount": 47,
     "createdAt": "2026-05-15T18:00:00+05:30"
   }
   ```
4. Push to TL: "47 leads moved to your orphan bucket from Vikram Mehta's offboarding."

### TL / Admin orphan bucket UI

- Listed at: `Admin → Manage Pool → Orphan bucket` (or `TL view → Orphan bucket`).
- Each row shows: lead name, original RM, last activity, days in orphan bucket, lead temperature.
- Multi-select checkboxes for bulk reassign.
- Bulk reassign action: pick target RM (must be in same vertical / branch); writes activity entries on each lead.

### Manual trigger fallback

If the HR webhook is delayed or fails, Admin has a manual "Mark RM offboarded" action: input employee ID, confirm. Same effect.

### Re-joiners

If the offboarded RM rejoins, their leads are NOT automatically restored. Admin can use Manage Pool to bulk-reassign the orphan leads back to them.

### API endpoints

```
POST /webhooks/hr/offboarding
GET  /admin/orphan-bucket?tlId=
POST /admin/orphan-bucket/reassign   (body: {leadIds: [], targetRmId})
POST /admin/orphan-bucket/manual-trigger   (body: {employeeId, effectiveDate})
```

### Error states

| Failure | What the user sees |
|---|---|
| HR webhook delayed / fails | Admin uses manual trigger. |
| Bulk reassign partially fails | Snackbar: "[X] of [Y] reassigned. [Y-X] failed — see details." Per-row error report. |
| Orphan event for an RM with no leads | No-op; audit record still written. |
| Network error during webhook | HR webhook retried per HR's retry policy; if persistent, on-call alerted. |

### Done when

1. HR signal handler implemented; orphan bucket UI for TL/Admin live.
2. Bulk reassign works with vertical / branch eligibility.
3. Manual trigger fallback available for Admin.
4. No auto-drop logic anywhere.

**Confirm with platform**: HR offboarding signal contract.

---

# IB / Wealth-IB Checker

## IB-Checker workflow and dashboards
- **Priority**: High · **Depends on**: `RM-Lead creation and editing`, `TL-Role based access`, `PLATFORM-Lead history audit trail`, `PLATFORM-Notifications`

**User story**: As an IB Checker, I need a dedicated queue to approve, reject, or convert lead submissions, with email previews before sending. As an RM who has submitted a lead to IB, I want to track its status. As the IB team head, I want a dashboard showing queue depth and throughput.

### Submission data shape (extension of LeadModel)

When a lead is submitted to IB, the following submission record is created:

```
{
  "submissionId": "IBS_1745920000444",
  "leadId": "LEAD_1745920000123",
  "submittedBy": "EMP1234",
  "submittedAt": "2026-04-30T11:30:00+05:30",
  "status": "pending",  // pending | approved | rejected | converted
  "decidedBy": null,
  "decidedAt": null,
  "decisionReason": null,
  "rejectionHistory": [],  // array of past rejections if resubmitted
  "version": 1
}
```

The lead's `stage` advances to `ib_pending` on submission.

### IB checker queue UI

Each row shows:
- Lead name (masked PII).
- Source RM (name + branch).
- Vertical (EWG / PWG).
- Age in queue (e.g. "2h 14m").
- Decision-relevant fields: phone, email, company, designation.

Filters: source RM, vertical, age (>1h, >24h).
Sort: oldest first (FIFO) — overridable.

### Real-time updates

- New submission appears within 5 seconds for all online IB checkers (consumes `PLATFORM-Notifications` push).
- Resume from background → trigger refresh.
- Push delivery failure → fall back to 30 s polling.

### Actions

| Action | Effect |
|---|---|
| **Approve** | `submission.status = approved`, `lead.stage = ib_approved`. Approval email fires (preview-before-send). Source RM notified. |
| **Reject** | `submission.status = rejected`, `lead.stage = ib_pending` stays. Rejection added to `rejectionHistory`. Email fires. Source RM notified. Lead stays in RM's pipeline. |
| **Convert** | `submission.status = converted`, `lead.stage = onboarded`. Conversion email fires. Activity log entry. |

Each action requires `reason ≥ 10 chars`.

### API endpoints

```
GET  /ib/queue?vertical=&maxAge=&page=&limit=
GET  /ib/submissions/{id}
POST /ib/submissions/{id}/approve   (body: {reason, version, emailPreviewConfirmed})
POST /ib/submissions/{id}/reject    (body: {reason, version, emailPreviewConfirmed})
POST /ib/submissions/{id}/convert   (body: {reason, version, emailPreviewConfirmed})
GET  /ib/dashboard?timeframe=&vertical=
GET  /rm/my-ib-leads?status=&page=&limit=
```

### Sample approval email

> Subject: `[MATRIX-IB] Approved: Aanya Khanna`
>
> Dear team,
>
> The following lead has been approved by IB:
>
> - **Name**: Aanya Khanna
> - **Source RM**: Vikram Mehta (Mumbai branch)
> - **Vertical**: PWG
> - **Approved by**: Sneha Iyer
> - **Approved at**: 30 Apr 2026, 11:48 IST
> - **Reason**: Documentation complete; KYC clear.
>
> [Open lead in MATRIX](deeplink)
>
> — JM Compass

PII (mobile, email, PAN) masked per `COMPLIANCE-PII privacy and audit`.

### Duplicate IB submission block

- A lead in `ib_pending` cannot be re-submitted.
- A previously rejected lead can be re-submitted only after at least one field edit. On resubmit form open, RM sees the previous rejection reason.

### RM-side "My IB Leads" view

Grouped by status: Pending, Approved, Rejected, Converted.

```
{
  "pending": [
    {"leadId": "...", "fullName": "...", "submittedAt": "...", "ageInQueue": "2h"}
  ],
  "approved": [...],
  "rejected": [
    {"leadId": "...", "fullName": "...", "rejectionReason": "Missing PAN copy", "rejectedAt": "..."}
  ],
  "converted": [...]
}
```

### IB dashboard payload

```
GET /ib/dashboard?timeframe=30d&vertical=PWG

200 OK
{
  "timeframe": "30d",
  "vertical": "PWG",
  "queueDepth": { "current": 14, "trend": [9, 12, 11, 14] },
  "approvalsCount": { "today": 3, "thisWeek": 17, "thisMonth": 64 },
  "averageTimeInQueueHours": 4.2,
  "topRejectionReasons": [
    {"reason": "Missing PAN copy", "count": 8},
    {"reason": "Address mismatch", "count": 5},
    ...
  ]
}
```

### Error states

| Failure | What the user sees |
|---|---|
| Two checkers approve same submission | Loser sees: "Already actioned by [other checker]." Queue refreshes. |
| Reason field shorter than 10 chars | Inline error: "Reason must be at least 10 characters." Action button disabled. |
| Email send fails after action | Action completes; lead detail banner: "Approval email queued for retry." |
| Email bounces (3 retries failed) | Activity log: "Email to [recipient] bounced." Lead detail flags recipient invalid. |
| Re-submit on already-pending lead | Banner: "This lead is already in the IB queue. Awaiting decision." Submit button disabled. |
| Re-submit after rejection without edits | Banner: "Edit at least one field to re-submit." Submit disabled until a field changes. |
| RM lacks IB-submit permission | Toast: "You're not authorised to submit to IB." Submit button hidden going forward. |
| IB dashboard query times out | Tile shows last-known value with "as of [time]" footer; page banner: "Some metrics may be stale. Retry." |

### Done when

1. IB checker queue lists pending submissions with all required fields and refreshes within 5 s on new submissions.
2. Approve / Reject / Convert actions work, capture reason ≥ 10 chars, fire correct email, write to activity log.
3. Two-checker conflict: one wins, one sees clean error.
4. Duplicate-submission block enforced.
5. RM-side My IB Leads grouped by status with rejection reasons visible.
6. IB dashboard renders the five KPIs with timeframe + vertical filters.

---

# Leadership

## LEADERSHIP-Funnel dashboard
- **Priority**: High · **Depends on**: `RM-Lead creation and editing`, `TL-Role based access`, `PLATFORM-Org hierarchy`

**User story**: As a Leadership viewer (Head, Zonal Head, etc.), I want the dashboard to show real lead funnel data over my chosen timeframe and org scope, and I want to tap any KPI to see the underlying leads.

### Timeframes

`today` / `7d` / `30d` / `90d` / `fy` (current Indian financial year, Apr–Mar IST) / `custom (from–to)`.

### KPIs (confirm full list with Leadership)

| KPI | Definition |
|---|---|
| Lead count by stage | Count of leads currently in each stage as of the end of the timeframe |
| Conversion rate | `count(stage=onboarded created in timeframe) / count(created in timeframe)` |
| Committed AUM | Sum of `profile.aumCommitted` on leads onboarded in the timeframe |
| Per-band counts | Count of leads currently Hot / Warm / Cold |
| New leads created | Count of leads created in the timeframe |
| Drops | Count of leads dropped in the timeframe |

### Org filters (cascading dropdowns from `PLATFORM-Org hierarchy`)

- Vertical: EWG / PWG / All
- Zone: South / West / North / East / Central etc.
- Branch (within selected zone)
- Team (within selected branch)
- RM (within selected team)

Selecting a parent narrows children's options.

### Default scope by role (confirm with Leadership)

- Heads → full org by default.
- Zonal Heads → their zone by default.
- TL → their team by default.
- RM → only themselves.

### API endpoint

```
GET /dashboard/leadership?timeframe=30d&vertical=PWG&zone=South&branch=&team=&rm=
```

### Sample response

```
{
  "timeframe": { "type": "30d", "from": "2026-04-01", "to": "2026-04-30" },
  "scope": { "vertical": "PWG", "zone": "South" },
  "kpis": {
    "leadCountByStage": {
      "lead": 142, "contacted": 88, "qualified": 41,
      "ib_pending": 12, "ib_approved": 7, "onboarded": 23, "dropped": 9
    },
    "conversionRate": 0.18,
    "committedAumCr": 412.5,
    "temperatureCounts": { "hot": 167, "warm": 103, "cold": 52 },
    "newLeadsCreated": 178,
    "drops": 9
  },
  "computedAt": "2026-04-30T11:35:12+05:30",
  "cacheExpiresAt": "2026-04-30T11:40:12+05:30"
}
```

Cache 5 minutes per `(timeframe, scope)` tuple. P95 ≤ 1.2 s for 30-day window.

### Drill-down

- Each KPI tile is tappable.
- Tap → navigate to leads list pre-filtered by KPI semantics:
  - "Onboarded leads (April 2026)" → filter `stage=onboarded`, `createdAt in 30d`.
  - "Hot leads in Mumbai" → filter `temperature=hot`, `branch=mumbai`.
- Back returns to dashboard with timeframe + scope state preserved.
- Destination list shows active filters as removable chips.

### Error states

| Failure | What the user sees |
|---|---|
| Aggregation query times out | Each affected tile shows last-known value with "as of [time]" footer; page-level banner: "Some metrics may be stale. Retry?" |
| Aggregation returns zero rows | Tile shows `0` with subtle "No leads in this slice" copy. |
| Drill-down to empty list | Empty state: "No leads match these filters. Try removing a filter." Filter chips removable. |
| Permission denies a scope | Page shows: "You don't have access to this view." Button back to your default scope. |
| Cache-only mode (offline) | Banner: "Showing cached data. Connect to refresh." |

### Done when

1. KPIs computed server-side in <1.2s for 30-day window.
2. Cascading filters work end-to-end.
3. Default scope per role matches sign-off.
4. 5-minute cache on identical queries.
5. Drill-down works on every KPI tile with empty-state copy approved by design.

---

# Compliance / Legal / DPO

## COMPLIANCE-Consent capture
- **Priority**: Highest · **Depends on**: `RM-Lead creation and editing`

**User story**: As DPO and Legal, every lead creation must have explicit consent capture per the DPDP Act 2023.

### Consent types (confirm final list with Legal)

| Type | Mandatory? | Purpose statement (sample, owned by Legal) |
|---|---|---|
| `lead_capture` | ✅ Yes | "I consent to JM Financial collecting and processing my personal data for the purpose of evaluating my eligibility as a wealth management client." |
| `marketing_communication` | Optional | "I consent to receiving marketing communications about JM Financial wealth products via email, SMS, and phone." |
| `data_sharing_jmfl_entities` | Optional | "I consent to JM Financial sharing my data with affiliated JM Group entities for cross-sell of relevant products." |

### Consent record data shape

```
{
  "id": "CON_1745920000555",
  "leadId": "LEAD_1745920000123",
  "consentType": "lead_capture",
  "decision": "granted",  // granted | declined | withdrawn
  "purposeStatement": "I consent to JM Financial collecting and processing my personal data...",
  "consentTextVersion": "v3",
  "decidedAt": "2026-04-30T11:13:18+05:30",
  "decidedByUserId": "EMP1234",
  "decidedByUserName": "Vikram Mehta",
  "deviceFingerprint": "android-pixel7-abc123",
  "withdrawnAt": null,
  "withdrawnByUserId": null,
  "withdrawnByUserName": null,
  "withdrawalReason": null
}
```

### Capture flow on Add Lead

1. Add Lead progresses through Lead Type → Name → Contact → Source.
2. Before Save, the consent step appears with one toggle row per consent type.
3. Each row shows the active purpose statement (versioned text fetched from `GET /consent/active-text`).
4. Toggle: Granted / Declined.
5. On tap Save:
   - All consent decisions written to `consentRecords[]` on the lead.
   - If mandatory consent declined → save blocked with toast.
   - If consent text version changes mid-flow (server returns updated version) → user re-prompted with new text.

### Versioning

```
GET /consent/active-text

200 OK
{
  "lead_capture": { "version": "v3", "text": "I consent to..." },
  "marketing_communication": { "version": "v2", "text": "I consent to receiving..." },
  "data_sharing_jmfl_entities": { "version": "v1", "text": "I consent to JM Financial sharing..." }
}
```

Whenever Legal updates a consent text, the version bumps. Old grants remain valid (snapshotted in the record); next captures use the new text.

### Withdrawal

From lead detail (authorised users only — confirm role):

```
POST /leads/{leadId}/consent/{consentId}/withdraw
{ "reason": "Customer requested via email on 2026-04-29" }

200 OK
{ "consent": { ...decision: "withdrawn", withdrawnAt: "...", withdrawnByUserId: "...", withdrawalReason: "..." } }
```

Original grant retained; withdrawal record added. Marketing or data-sharing actions stop immediately on withdrawal.

### Error states

| Failure | What the user sees |
|---|---|
| Mandatory consent declined | Save Lead disabled; under the toggle: "Consent for lead capture is mandatory." |
| Network failure mid-grant (consent saved but lead create fails) | Lead is NOT saved; consent record rolled back. Toast: "Couldn't save the lead. Try again — your consent answers are preserved." |
| Server returns updated consent text version while user on consent step | Modal: "Consent text was updated. Please review the latest version." Re-render with new text; user must tick again. |
| Consent text fetch fails on Add Lead open | Modal: "Couldn't load the latest consent text. Connect and retry." Save Lead disabled. |
| Withdrawal attempted by user without permission | Toast: "You don't have permission to withdraw consent." |

### Done when

1. Consent step on Add Lead with mandatory blocking.
2. Consent record carries actor, time, device, text version, snapshotted purpose statement.
3. Versioned text fetched from server.
4. Withdrawal flow on lead detail.
5. Each grant / withdrawal audited.

**Confirm with Legal**: final consent type list; who owns the text content; versioning scheme; withdrawal permission (which roles).

---

## COMPLIANCE-PII privacy and audit
- **Priority**: High · **Depends on**: `RM-Lead creation and editing`, `TL-Role based access`

**User story**: As DPO, every PII unmask must be auditable, so we can prove access controls in compliance reviews.

### PII fields

`phone`, `email`, `pan`, `dateOfBirth`.

### Masking rules

| Field | Raw | Masked |
|---|---|---|
| Phone (India) | `+919876543210` | `+91 98***43210` |
| Phone (UAE) | `+971512345678` | `+971 51***5678` |
| Email | `aanya.khanna@example.com` | `aa***@example.com` |
| PAN | `ABCDE1234F` | `ABC**1234F` |
| DOB | `1985-03-14` | `**-**-1985` |

### Unmask flow

User taps a masked field → audit entry written → field reveals.

```
POST /leads/{leadId}/pii/unmask
{ "field": "phone" }

200 OK
{ "field": "phone", "value": "+919876543210", "auditId": "AUD_..." }
```

### Audit record

```
{
  "id": "AUD_1745920000666",
  "userId": "EMP1234",
  "userName": "Vikram Mehta",
  "leadId": "LEAD_1745920000123",
  "field": "phone",
  "action": "unmask",
  "timestamp": "2026-04-30T11:42:00+05:30",
  "deviceId": "android-pixel7-abc123",
  "ipAddress": "10.0.5.7"
}
```

### Bulk export

Triggered when admin exports more than 50 records (confirm threshold).

```
POST /admin/leads/export
{
  "filter": { ... },
  "reason": "Quarterly compliance review with InfoSec — request #INF-2026-Q2-014"  // ≥ 30 chars
}
```

### Retention purge

Nightly cron: leads in `dropped` stage older than 365 days (confirm) have PII fields nulled. Lead row, activity log, and aggregates retained.

### Audit query (Admin)

```
GET /admin/audit/pii-access?userId=&dateFrom=&dateTo=&leadId=&page=&limit=

200 OK
{
  "entries": [
    { ... AUD_... },
    ...
  ],
  "total": 1247
}
```

### Error states

| Failure | What the user sees |
|---|---|
| Audit write fails before unmask | Field stays masked. Toast: "Couldn't record access. Try again." |
| User offline | Tooltip on PII tap: "Connect to view full details — access must be logged." Field stays masked. |
| Bulk export attempted without reason | Modal blocks: "Enter a reason for export (at least 30 characters)." Cancel and Export buttons. Export disabled until valid. |
| Bulk export attempted by non-Admin | Hidden in UI; if reached via API, server returns 403 → toast "You don't have permission to export." |
| Retention purge fails | Backend retries on next nightly run; alert raised; no user-facing message. |
| User accesses a purged lead | Lead detail shows: "This lead's contact details were purged per retention policy on [date]. Activity history remains." |

### Done when

1. Masking rules applied on every PII field render.
2. Tap → audit → reveal.
3. Bulk export gated behind Admin + reason ≥ 30 chars.
4. Nightly retention purge runs.
5. Audit query works with full filter set.
6. Every error state above renders.

**Confirm with Compliance**: bulk-export threshold; retention window; PII masking display format.

---

# Platform Foundation

## PLATFORM-Org hierarchy
- **Priority**: High

**User story**: As Platform / Data, I want a synced org hierarchy in our backend, so the dashboard, Manage Pool, and Get Lead can scope by Zone / Branch / Team without each consumer hitting HR.

### Source of truth

HR system (confirm: SAP HR? Workday?) is authoritative. Local edits in MATRIX never override; sync overwrites.

### Sync model

- Nightly batch sync (floor) — runs at ~02:00 IST.
- On-change webhook from HR keeps changes fresh through the day, propagation under 60 s.

### Hierarchy

1. **Zone** — South, West, North, East, Central (HR-driven values, not a fixed enum).
2. **Branch** — within a zone (Mumbai, Bengaluru, etc.). Each branch sits in exactly one zone.
3. **Team** — within a branch, headed by a TL.
4. **RM** — leaf node.

### Per-employee data shape

```
{
  "employeeId": "EMP1234",
  "name": "Vikram Mehta",
  "role": "RM",  // RM | TL | Admin | IB | Leadership
  "vertical": "PWG",  // EWG | PWG | null
  "zone": "South",
  "branchCode": "BNG_KORM",
  "branchName": "Bengaluru Koramangala",
  "teamId": "EMP9501",  // TL's employeeId for RMs
  "reportsTo": "EMP9501",
  "active": true,
  "effectiveFrom": "2024-01-15",
  "effectiveTo": null,
  "lastSyncedAt": "2026-04-30T02:00:00+05:30"
}
```

### Endpoints

```
GET /org/hierarchy?zone=&branch=&team=
GET /org/zones
GET /org/employees/{employeeId}
```

### Sample hierarchy tree

```
GET /org/hierarchy

200 OK
{
  "zones": [
    {
      "name": "South",
      "branches": [
        {
          "code": "BNG_KORM", "name": "Bengaluru Koramangala",
          "teams": [
            { "id": "EMP9501", "tlName": "Sneha Iyer",
              "rms": [ {"id": "EMP1234", "name": "Vikram Mehta", "vertical": "PWG"}, ... ] }
          ]
        },
        ...
      ]
    },
    { "name": "West", "branches": [...] },
    ...
  ]
}
```

### Sample HR sync row

```
{
  "employeeId": "EMP1234",
  "name": "Vikram Mehta",
  "role": "RM",
  "vertical": "PWG",
  "zone": "South",
  "branchCode": "BNG_KORM",
  "branchName": "Bengaluru Koramangala",
  "reportsTo": "EMP9501",
  "active": true,
  "effectiveFrom": "2024-01-15"
}
```

### Offboarding

When `active` becomes `false`, fire `ADMIN-Orphan lead handling`'s flow.

### Privacy

MATRIX clients see only: name, role, vertical, zone, branch, team, reports-to. Phone / email / PAN of employees stay server-side.

### Error states

| Failure | What the user sees |
|---|---|
| HR webhook misses a change | Nightly batch catches up. If delta > 24h, on-call alerted. Consumers keep using last-known data — no banner. |
| Employee with no zone in HR | Defaults to "Unassigned" zone; filter dropdowns include "Unassigned"; Admin alert raised. |
| Zone rename in HR | Propagates on next sync; old zone disappears from filter; lead history retains snapshot value via activity log. |
| Hierarchy tree fetch fails | Dropdown shows: "Couldn't load org filters. Retry?" Filters disabled until reload. |

### Done when

1. Nightly sync logs total / inserted / updated / removed.
2. Webhook handler updates within 60 s.
3. Hierarchy tree, zones list, employee lookup endpoints live.
4. Inactive flag triggers orphan-recovery.
5. Idempotent — re-running a batch produces no churn.

**Confirm with HR / platform**: HR system identity; webhook contract; zone-name stability; mid-day role change semantics.

---

## PLATFORM-Lead history audit trail
- **Priority**: High · **Depends on**: `RM-Lead creation and editing`

**User story**: As any user, I want a per-lead history of every state change, so I understand how a lead got here. Compliance retains this forever.

### Event types

| Event | When |
|---|---|
| `lead_created` | New lead saved |
| `lead_updated` | Field-level edit |
| `stage_changed` | Manual or system stage transition |
| `claimed_from_pool` | Pool claim succeeded |
| `dropped_to_pool` | Manual drop (per Assumption #12) |
| `ib_submitted` / `ib_approved` / `ib_rejected` / `ib_converted` | IB lifecycle |
| `reassigned` | Reassignment approved |
| `consent_granted` / `consent_withdrawn` | Consent lifecycle |
| `coverage_overridden` | Admin DND or coverage override |
| `pii_unmasked` | PII access (also feeds DPDP-2 audit) |
| `rm_offboarded_orphan` | RM offboarded; lead moved to orphan bucket |

### Event data shape

```
{
  "id": "ACT_1745920000777",
  "leadId": "LEAD_1745920000123",
  "eventType": "stage_changed",
  "actor": { "userId": "EMP1234", "userName": "Vikram Mehta", "role": "RM" },
  "timestamp": "2026-04-30T11:50:00+05:30",
  "before": { "stage": "lead" },
  "after": { "stage": "contacted" },
  "note": "First call completed; client interested."
}
```

`before` / `after` snapshot only the changed fields.

### Sample event records

**Lead created**:
```
{ "eventType": "lead_created", "actor": {...}, "before": null, "after": { /* full lead */ }, "note": null }
```

**Reassigned**:
```
{
  "eventType": "reassigned",
  "actor": { "userId": "EMP9001", "userName": "Admin User", "role": "Admin" },
  "before": { "assignedRmId": "EMP1234", "assignedRmName": "Vikram Mehta" },
  "after":  { "assignedRmId": "EMP1001", "assignedRmName": "Pooja Sharma" },
  "note": "Coverage match — Vikram requesting reassignment of Aanya Khanna"
}
```

**PII unmasked**:
```
{
  "eventType": "pii_unmasked",
  "actor": { "userId": "EMP1234", "userName": "Vikram Mehta", "role": "RM" },
  "before": null,
  "after": { "field": "phone" },
  "note": null
}
```

### API endpoints

```
GET /leads/{leadId}/activity?page=&limit=  (default 50)
GET /admin/audit?userId=&dateFrom=&dateTo=&eventType=&leadId=&page=&limit=
```

### Reliability

Every state-changing API writes its activity entry atomically with the state change (single transaction). Write failures queued and retried — never silently lost.

### Retention

Indefinite. No purge job (per Assumption #6).

### Error states

| Failure | What the user sees |
|---|---|
| Activity tab fails to load | "Couldn't load activity. Retry?" button. Other tabs still work. |
| Pagination fails on later page | Banner: "Couldn't load more events. Retry." Already-loaded events stay visible. |
| Audit query returns >1,000 results | First 1,000 returned; banner: "Showing 1,000 of [X]. Narrow the date range." |
| Event-write retry queue full (rare) | Server alert raised; user actions still succeed; cron flushes backlog later. |

### Done when

1. All event types captured.
2. Activity tab on lead detail shows newest-first paginated history.
3. Admin audit query works with full filter set.
4. No purge job exists.
5. Atomic writes verified — state changes without activity entries don't happen.

---

## PLATFORM-Mobile number standard
- **Priority**: High · **Depends on**: `RM-Mobile with country code`, `RM-Lead creation and editing`

**User story**: As Platform / Data, I want a single canonical phone format end-to-end, and the legacy records normalised, so dedupe and downstream integrations don't drift.

### Canonical format

```
+CC<DDDDDDDDDD>
```
- Country-code prefix (`+91`, `+971`, etc.).
- Digits only after the `+`.
- No spaces, no dashes, no parentheses.

Examples: `+919876543210`, `+971512345678`, `+6591234567`.

### Display format (UI render layer)

| Country | Stored | Displayed |
|---|---|---|
| India | `+919876543210` | `+91 98765 43210` |
| UAE | `+971512345678` | `+971 51234 5678` |
| Singapore | `+6591234567` | `+65 9123 4567` |
| US / Canada | `+19876543210` | `+1 (987) 654-3210` |
| UK | `+447976543210` | `+44 7976 543210` |
| Other | `+CC<digits>` | `+CC <digits>` (no internal grouping) |

### Server validation

```
PUT /leads/{id}
{ "phone": "9876543210" }   // bad

400 Bad Request
{ "errors": { "phone": "Mobile must be in E.164 format starting with +. Example: +919876543210" } }
```

### Migration script — input → canonical mapping

| Input (legacy) | Output (canonical) |
|---|---|
| `+91 9876543210` | `+919876543210` |
| `91-9876543210` | `+919876543210` |
| `0091 9876543210` | `+919876543210` |
| `9876543210` | `+919876543210` (Indian heuristic — 10 digits, starts 6/7/8/9) |
| `(987) 654-3210` | `(triage — could be US +1 9876543210 or India)` |
| `+1 9876543210` | `+19876543210` |
| `+971 51 234 5678` | `+971512345678` |
| `9123` | `(triage — too short)` |
| `abcdef` | `(triage — non-numeric)` |
| `+91 98765 43210` | `+919876543210` |
| `00919876543210` | `+919876543210` |
| `912345` | `(triage — Indian heuristic fails: 6 digits)` |
| `9876543210, 9876543211` | `(triage — multiple numbers)` |

### Migration parse rules (in order)

1. Strip spaces, dashes, parentheses.
2. If starts with `+` → keep as-is.
3. If starts with `00` → replace with `+`.
4. If 10 digits and first digit ∈ {6,7,8,9} → prepend `+91` (Indian heuristic).
5. Otherwise → flag for manual triage.

### Idempotency

Re-running on an already-canonical value is a no-op.

### Migration run log

```
{
  "runId": "PHN_MIG_1745920501000",
  "startedAt": "2026-05-01T01:00:00+05:30",
  "endedAt": "2026-05-01T01:14:32+05:30",
  "totalRecords": 124583,
  "alreadyCanonical": 87412,
  "converted": 36205,
  "triaged": 911,
  "failed": 55
}
```

### Triage queue UI (Admin)

Each triaged record shows:
- Raw value (e.g. `(987) 654-3210`).
- Best guess (e.g. `+19876543210`).
- Manual override input.
- Actions: Accept best guess / Use override / Mark as no number.

### Error states

| Failure | What the user sees |
|---|---|
| User enters non-canonical phone via legacy form | Server rejects with field-level error per the validation example. |
| Migration flags a record | Admin queue lists it with raw value, best guess, override input. |
| Display formatter receives unknown country code | Falls back to `+CC <digits>` with no internal grouping; never crashes. |

### Done when

1. All writes use canonical format.
2. UI formatter applied at every render site.
3. Coverage works on canonical format.
4. Server validation rejects non-canonical input.
5. Migration script processes every legacy record; triage queue drained by Admin.

---

## PLATFORM-Notifications
- **Priority**: High

**User story**: As any user, I want to be told about events that need my attention — pushes for app events, emails for IB outcomes — so I act quickly without polling. The IB checker queue should feel real-time.

### Push events

| Event | Recipient | Mandatory? |
|---|---|---|
| `lead_claimed` | Winning RM | Optional |
| `reassignment_requested` | Target RM | Optional |
| `reassignment_approved` / `rejected` | Source RM | Optional |
| `sla_warning_50` / `sla_warning_80` | Assigned RM | Optional |
| `sla_breach` | Assigned RM | **Mandatory** |
| `ib_submission_arrived` | All online IB checkers | Optional |
| `ib_approved` / `ib_rejected` / `ib_converted` | Source RM | **Mandatory** |
| `lead_dropped_to_pool` | Former assigned RM | Optional |

(Confirm full mandatory list with Product.)

### Sample push payload

```
{
  "to": "<device_token>",
  "data": {
    "eventType": "lead_claimed",
    "leadId": "LEAD_1745920000123",
    "leadName": "Aanya Khanna",
    "actorName": "Vikram Mehta",
    "deepLink": "matrix://leads/LEAD_1745920000123"
  },
  "notification": {
    "title": "Lead claimed",
    "body": "You claimed Aanya Khanna from the pool."
  },
  "priority": "high"
}
```

Tap → deep-link via `matrix://` scheme to the relevant screen.

### Token registration

```
POST /devices/register
{
  "deviceId": "android-pixel7-abc123",
  "fcmToken": "<token>",
  "platform": "android",
  "appVersion": "2.4.1"
}
```

Re-register on token refresh.

### Multi-device

A user logged in on multiple devices receives the push on all of them. Backend stores all active tokens per user.

### IB email channel

Events: IB submitted, IB approved, IB rejected, IB converted.
Recipients: source RM, IB team, Admin (cc).
Subject: `[MATRIX-IB] {action}: {leadName}`
Sender: `noreply-ib@jmfl.com` (confirm).

Sample body:

> Subject: `[MATRIX-IB] Approved: Aanya Khanna`
>
> Dear team,
>
> Lead **Aanya Khanna** (Source RM: Vikram Mehta, PWG, Mumbai) has been approved by IB.
>
> Approved by: Sneha Iyer at 30 Apr 2026, 11:48 IST.
> Reason: Documentation complete; KYC clear.
>
> [Open lead](matrix://leads/LEAD_1745920000123)

PII (mobile, email) masked per `COMPLIANCE-PII privacy and audit`.

### Bounce handling

```
{
  "messageId": "msg_abc123",
  "to": "old-email@jmfl.com",
  "status": "bounced",
  "bounceReason": "mailbox_does_not_exist",
  "retryCount": 3,
  "lastRetryAt": "2026-04-30T11:55:00+05:30"
}
```

Up to 3 retries; after that, activity log entry: `"Email to [recipient] bounced"`. Lead detail flags the recipient as invalid.

### IB checker realtime

Driven by the same push events. New IB submission appears in the queue within 5 seconds for any online checker. Push delivery failure → fall back to 30-second polling.

### Error states

| Failure | What the user sees |
|---|---|
| Push delivery fails (token revoked, device offline) | Notification stays in the in-app drawer; visible under bell icon when user opens MATRIX. |
| Email send fails (SMTP error) | Lead detail: "Email delivery pending — will retry." Logged. After 3 fails: "Email failed to deliver — Admin alerted." |
| Email bounces (invalid address) | Activity log: "Email to [recipient] bounced." Lead detail flags recipient as invalid; no further retry. |
| Token registration fails on login | Silent retry on next API call. If persistent, push features degrade — user still gets in-app notifications. |
| Realtime push to IB checker fails | Queue falls back to 30-second polling; queue header indicates "Polling — connection unstable." |

### Done when

1. Every event above sends a push to the right audience.
2. Deep-links work on tap.
3. Per-event opt-outs respected (except mandatory).
4. IB emails delivered with preview, bounce handling, activity-log entry.
5. IB checker queue updates within 5 s on new submissions.
6. Multi-device delivery works.

**Confirm with platform**: push provider; email service; sender domain; final mandatory event list.

---

## PLATFORM-Crash and error reporting
- **Priority**: High

**User story**: As Platform / SRE, I want crashes and network errors reported with context, so I can diagnose without asking the user — without any client PII leaking into logs.

### What gets reported

- **Crashes**: stack trace + breadcrumbs (last 50 user actions) + non-PII context.
- **Network errors**: endpoint, status code, correlation ID linking to backend logs.
- **App start anomalies**: cold start failures, OOM, background termination spikes.

### PII redaction filter

Strip these field names from any log payload (case-insensitive):
`phone`, `email`, `name`, `firstName`, `lastName`, `fullName`, `pan`, `dob`, `dateOfBirth`, `address`, `aadhaar`.

### Sampling

- 100% of errors reported.
- 10% of info-level traces sampled.
- Confirm with platform — log retention budget.

### Sample crash report (PII-redacted)

```
{
  "type": "crash",
  "timestamp": "2026-04-30T12:00:00+05:30",
  "platform": "android",
  "appVersion": "2.4.1",
  "deviceModel": "Pixel 7",
  "osVersion": "Android 15",
  "crashType": "NullPointerException",
  "message": "Attempt to invoke virtual method on null object",
  "stack": [...],
  "breadcrumbs": [
    { "category": "navigation", "from": "/home", "to": "/lead-detail/<redacted>" },
    { "category": "tap", "widget": "EditButton" },
    { "category": "api", "endpoint": "PUT /leads/<id>", "status": 500 },
    ...
  ],
  "user": { "employeeId": "EMP1234", "role": "RM", "vertical": "PWG" },
  "correlationId": "corr_abc123"
}
```

### Network error sample

```
{
  "type": "network_error",
  "timestamp": "...",
  "endpoint": "POST /coverage/check",
  "status": 504,
  "durationMs": 8123,
  "correlationId": "corr_abc124",
  "user": { "employeeId": "EMP1234", "role": "RM" }
}
```

### Error states

| Failure | What the user sees |
|---|---|
| App crash | Restart with friendly screen: "Something went wrong. The team has been notified." [Restart] button. Crash already reported. |
| Network error from any API call | Caller-specific UX (toast/banner) per consuming ticket. Underlying error tagged with endpoint + correlation ID and reported. |
| Logging tool unreachable | Errors buffered locally; flushed on next reachable call. App keeps running. |
| PII redaction logic bug catches a payload that contains PII | Defence in depth: drop the payload entirely; backend alert raised. |

### Done when

1. Crash reporting integrated for Android + iOS.
2. Network errors auto-tag with correlation ID.
3. PII redaction tested with representative payloads (including known PII names + variant casings).
4. Backend and client logs join via correlation ID.

**Confirm with platform**: crash reporting tool.

---

## PLATFORM-Mobile build pipeline
- **Priority**: High · **Depends on**: `PLATFORM-Crash and error reporting`

**User story**: As Tech Lead, I need a CI/CD pipeline producing signed mobile builds, so the app can ship.

### Triggers

- **PR**: build + tests + lint. No artefact upload.
- **Tag push (`v*.*.*`)**: build signed Android (AAB) + iOS (IPA), upload symbols, distribute to internal testers, generate release notes.

### Pipeline steps (PR)

```
1. Checkout
2. flutter pub get
3. flutter analyze
4. flutter test --coverage
5. Coverage gate check (≥ 60% on repos + cubits)
6. Build Android debug + iOS debug (smoke compile)
7. Surface results to PR reviewer
```

### Pipeline steps (release)

```
1. Checkout (tag)
2. Decrypt signing keys from CI vault
3. flutter pub get
4. flutter test
5. flutter build appbundle --release  (Android)
6. flutter build ipa --release         (iOS)
7. Upload Android symbols to crash tool
8. Upload iOS dSYMs to crash tool
9. Upload AAB to Play Console internal track
10. Upload IPA to App Store Connect TestFlight
11. Distribute to Firebase App Distribution / App Center for internal testers
12. Generate release notes from PR titles since last tag
```

### Sample release notes

```
v2.4.1 (2026-04-30)

- RM-Lead temperature bands: Hot/Warm/Cold chip on every lead
- RM-Mobile with country code: country dropdown on IB Lead and Key Contacts
- ADMIN-Reassignment queue: server-side concurrency
- PLATFORM-Notifications: push integration
- Bug fixes: list refresh after lead claim, profiling resume on warm boot
```

### Signing

Keys live in CI secrets vault (e.g. GitLab CI Variables or HashiCorp Vault). Never in repo. Rotation policy per platform team.

### Error states (developer-facing)

| Failure | What devs see |
|---|---|
| Signing key expired or rotated | CI fails: "Signing key invalid — coordinate with platform to rotate." Release blocked. |
| Symbol upload to crash tool fails | Build still succeeds; CI yellow warning; on-call alerted. |
| Distribution channel unreachable | Build succeeds; distribution step retries 3x then fails: "Couldn't push to internal testers — see logs." |
| Tests fail on PR | PR build fails with failing test names; PR can't merge. |
| Coverage gate breached | PR build fails with: "Coverage dropped to X% (gate is 60%)." |

### Done when

1. PR CI runs build + tests + lint + coverage gate.
2. Tag release produces signed AAB + IPA.
3. Symbols uploaded.
4. Internal testers can download.
5. Release notes auto-generated.
6. Secrets via vault, never in repo.

**Confirm with platform**: distribution channels (Firebase App Distribution? App Center?); reuse `compass_v2_mobile` pipeline or fork.

---

## PLATFORM-Funnel analytics
- **Priority**: Medium

**User story**: As Product, I want a consistent funnel instrumentation, so I can measure activation, conversion, and drop-off.

### Events

| Event | Payload (event-specific fields) |
|---|---|
| `lead_created` | `vertical`, `role`, `source`, `entityType` |
| `coverage_check` | `result` (status), `responseTimeMs`, `vertical` |
| `coverage_blocked` | `status` (existingClient / duplicateLead / dnd), `vertical` |
| `lead_claimed` | `vertical`, `sourceLeadAgeDays` |
| `lead_converted` | `vertical`, `daysToConvert` |
| `ib_submitted` | `vertical` |
| `reassignment_requested` | `reasonCategory` (coverage_match / other) |
| `pii_unmasked` | `field` (phone / email / pan / dob) |
| `temperature_changed` | `from` (band), `to` (band) |

### Common payload (every event)

```
{
  "event": "lead_created",
  "timestamp": "2026-04-30T11:13:20.123+05:30",
  "userId_hash": "sha256:abc123...",  // salted SHA-256 of employee ID
  "sessionId": "sess_xyz",
  "appVersion": "2.4.1",
  "vertical": "PWG",
  "role": "RM",
  "properties": {
    "source": "referral",
    "entityType": "individual"
  }
}
```

### Sample event payloads

**`lead_created`**:
```
{ "event": "lead_created", "userId_hash": "sha256:abc...", "vertical": "PWG", "role": "RM",
  "properties": { "source": "referral", "entityType": "individual" } }
```

**`coverage_blocked`**:
```
{ "event": "coverage_blocked", "userId_hash": "sha256:abc...", "vertical": "PWG", "role": "RM",
  "properties": { "status": "existingClient" } }
```

**`temperature_changed`**:
```
{ "event": "temperature_changed", "userId_hash": "sha256:abc...", "vertical": "PWG", "role": "RM",
  "properties": { "from": "warm", "to": "cold", "leadId_hash": "sha256:..." } }
```

### PII rules

- Never include `phone`, `email`, `name`, `pan`, `dob`, raw employee ID.
- `userId_hash` uses salted SHA-256.
- `leadId_hash` (if needed) similarly hashed.

### Buffering

Events buffered in a small local queue (max 1,000 events). Flush on next reachable network call. If buffer overflows during long offline periods, oldest dropped first; counter on next flush reports the count.

### Error states

| Failure | What happens |
|---|---|
| Analytics provider unreachable | Events buffered; flushed on reconnect. No user-facing error. |
| Event payload contains PII (logic bug) | Defence in depth: drop the event entirely; backend alert raised. |
| Buffer overflow during long offline period | Oldest events dropped first; counter on next flush tells the team how many were lost. |

### Done when

1. Every event firing with correct payload.
2. PII never appears in events (verified with redaction tests).
3. Analytics dashboard set up for Product team.
4. Buffer-and-flush behaviour verified offline.

**Confirm with product**: analytics provider; user-ID hashing scheme.

---

# Recommended push order

1. **Foundation**: `PLATFORM-Org hierarchy`, `RM-Lead creation and editing`, `PLATFORM-Lead history audit trail`, `PLATFORM-Crash and error reporting`, `PLATFORM-Mobile build pipeline`.
2. **RM core**: `RM-Duplicate lead prevention`, `RM-Mobile with country code`, `PLATFORM-Mobile number standard`, `COMPLIANCE-Consent capture`.
3. **Remaining RM + TL**: `RM-Profiling wizard resume`, `RM-Claim from pool`, `TL-Lead ageing and SLA`, `RM-Lead temperature bands`, `TL-Role based access`.
4. **Admin / IB / Leadership**: `ADMIN-Reassignment queue`, `ADMIN-Bulk lead upload`, `ADMIN-Orphan lead handling`, `PLATFORM-Notifications`, `IB-Checker workflow and dashboards`, `LEADERSHIP-Funnel dashboard`.
5. **Hardening**: `COMPLIANCE-PII privacy and audit`, `PLATFORM-Funnel analytics`.

---

# Open questions still to resolve

**For Vinit (small Product calls)**:
- Mandatory push events list (final).
- PII unmask reason minimum character count (proposed: 30).
- Leadership Dashboard cache TTL (proposed: 5 min).
- Default Leadership scope per role.

**For Business heads (EWG + PWG)**:
- Canonical lead stage list.
- 7-day / 30-day SLA values — fixed for both verticals or different?
- "On hold" status — does it exist?
- Canonical KPI list for Leadership Dashboard.
- AUM source — profiling wizard or Wealth Spectrum?
- Bulk upload template columns final confirmation.

**For Compliance / Legal / DPO**:
- Final consent type list and who owns the consent text content.
- Consent text versioning scheme.
- Withdrawal permission — which roles?
- Retention window for dropped leads (365 days proposed).
- PII masking format final confirmation.
- Bulk export threshold.
- DND fail mode — fail-closed or fail-open?
- PII redaction filter field list.

**For HR / Platform**:
- Confirm existing MATRIX login already exposes zone + team in user profile.
- HR system of record (SAP HR? Workday?).
- HR → MATRIX integration pattern.
- Zone names stable today, or messy and need a curation layer?
- Mid-day role change handling.
- Offboarding webhook contract.

**For Wealth Spectrum / Data team**:
- Family identifier in existing integration — group name string or `family_id`?
- AUM data location.
- Coverage trigger thresholds (3-char minimum on name/company etc).
- DND list source surfaced via existing integration, or separate?

**For Tech / Platform**:
- Push provider, email provider, crash reporting tool, analytics provider.
- API base URL conventions, versioning, error envelope.
- Optimistic concurrency mechanism (version int? ETag? `updatedAt`?).
- Holiday calendar source.

**For Design / UX**:
- Temperature band colours.
- Coverage soft-fail banner copy.
- Consent step UX (one screen vs per-consent confirmation).
- KPI tile visual treatment.

**Cross-cutting structural confirmations**:
- Full LeadSource enum values.
- Verticals: only EWG and PWG?
- What happens to a dropped lead — visible forever, hidden after N days, hard-purged?
- Does an RM operate in one branch or multiple?
- Can a lead have co-RMs?
- When does a "lead" become a "client" in Wealth Spectrum?

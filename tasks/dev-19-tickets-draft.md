# Wealth CRM — Lead & Prospect (Sprint 1 dev tickets)

> **Status**: Draft for Vinit's review before pushing to Jira project `JC`.
> **Date**: 2026-05-04 · **Owner**: Vinit Mehta
> **Epic**: `Wealth CRM - Lead & Prospect` (will be created fresh; existing 22 tickets to be deleted before push).
> **Scope**: 19 sprint-ready tickets, RM-only slice, with assignees + story points as provided by the dev team.
> **Total points**: 74

---

## Locked assumptions (apply to every ticket)

These are decided. Don't repeat per ticket.

1. **MATRIX login is already live in production.** Each ticket assumes the logged-in user profile carries: employee ID, name, role, vertical (EWG / PWG), zone, branch, team, email.
2. **Mobile-only target.** No web build.
3. **Wealth Spectrum integration is already in production.** Coverage tickets reuse the existing API-token-based integration.
4. **Dedupe rule matrix** *(signed off)*:
   - PWG: Full Name + Email + Mobile + Company / Group.
   - EWG / IB-side capture: Full Name + Email + Mobile.
   - Pool checked: Wealth Spectrum client master AND MATRIX internal lead table.
5. **Designation values**: Promoter, Founder, CEO, Family Office Head, Others (free text, max 60 chars).
6. **Activity logs are retained indefinitely.**
7. **Lead temperature anchor**: `lastActivityAt`, fall back to `createdAt`. Hot 0–30, Warm 30–90, Cold 90+ days.
8. **Coverage confidence thresholds**: ≥0.95 hard-block; 0.5–0.95 review; <0.5 clear.
9. **Country code list**: India (default) + UAE / Singapore / UK / US / Canada / Australia / Saudi Arabia / Hong Kong / Switzerland.
10. **Bulk pool upload cap**: 5,000 rows.
11. **Push notifications: no quiet hours.**
12. **Lead drop is manual-only.** No auto-drop on SLA breach or orphan retention.

## What every ticket includes (definition of done)

1. Tested — unit + widget tests as appropriate, coverage ≥ 60% on repos / cubits.
2. Logged — state-changing actions write activity entries.
3. Observed — errors and crashes report with PII redacted.
4. Role-gated — endpoints sit behind the right role check.
5. PII-safe — phone / email / PAN / DOB never leave masked unless role + audit allow.
6. Error UX — every failure mode listed has a defined user-visible state.

## Reference paths in the code hand-over

| Concern | Code reference |
|---|---|
| Domain models | `lib/core/models/` |
| Repository interfaces | `lib/core/repositories/` |
| Reference impls (in-memory) | `lib/core/services/mock/` |
| Add Lead form + country code | `lib/features/create_lead/presentation/pages/create_lead_screen.dart` |
| Key Contacts field | `lib/core/widgets/key_contacts_field.dart` |
| Lead detail screen | `lib/features/lead_detail/presentation/pages/lead_detail_screen.dart` |
| Action sheets (Call / WA / Meet / Picker) | `lib/features/lead_detail/presentation/widgets/` |
| Activity log sheet | `lib/features/activity/presentation/widgets/activity_quick_log_sheet.dart` |
| Coverage match algorithm | `lib/core/services/mock/mock_coverage_repository.dart` |

---

## Index

| # | Title | Type | Points | Assignee |
|---|---|---|---|---|
| 1 | Matrix Wealth CRM FE:RM New Lead | Story | 5 | Omkar |
| 2 | Matrix Wealth CRM BE:RM New Lead (Dedup check) | Story | 5 | Forum |
| 3 | Matrix Wealth CRM FE:RM Lead Request | Story | 3 | Gopinath |
| 4 | Matrix Wealth CRM BE:RM Lead Request | Story | 2 | Vishwas |
| 5 | Matrix Wealth CRM FE:RM all Leads with filter & search | Story | 5 | Gopinath |
| 6 | Matrix Wealth CRM BE:RM all Leads with filter & search | Story | 5 | Vishwas |
| 7 | Matrix Wealth CRM FE:RM Lead Details | Story | 5 | Omkar |
| 8 | Matrix Wealth CRM BE:RM Lead Details | Story | 5 | Vaibhav |
| 9 | Matrix Wealth CRM FE:RM Convert to IB Leads | Story | 2 | Gopinath |
| 10 | Matrix Wealth CRM BE:RM Convert to IB Leads | Story | 2 | Vaibhav |
| 11 | Matrix Wealth CRM FE:RM Drop Lead | Story | 2 | Omkar |
| 12 | Matrix Wealth CRM BE:RM Drop Lead | Story | 2 | Vishwas |
| 13 | Matrix Wealth CRM FE:RM Dashboard | Story | 5 | Gopinath |
| 14 | Matrix Wealth CRM BE:RM Dashboard | Story | 3 | Vaibhav |
| 15 | Matrix Wealth CRM FE:RM Lead Log Capture | Story | 5 | Arsh |
| 16 | Matrix Wealth CRM BE:RM Lead Log Capture | Story | 3 | Forum |
| 17 | Matrix Wealth CRM FE:RM Lead Activity Request - Call,WhatsApp,Meeting, Notes | Story | 5 | Arsh |
| 18 | Matrix Wealth CRM BE:RM Lead Activity Request - Call,WhatsApp,Meeting, Notes | Story | 3 | Forum |
| 19 | Matrix Wealth CRM BE:RM New Lead Country Master, Lead Type, Designation | Story | 2 | Vishwas |

---

# 1. Matrix Wealth CRM FE:RM New Lead
- **Points**: 5 · **Assignee**: Omkar · **Depends on**: #2 (BE), #19 (master data)

**User story**: As an RM, I want to create a new lead by capturing the prospect's identity, contact, source and consent, so the firm has a clean record to work from.

### Behaviour

The form is a single screen captured top-to-bottom:

1. **Lead type** — single dropdown of 9 values: Individual, Private Limited, Public Limited, Partnership, LLP, HUF, Trust, Family Office, Others. When `Others` is picked, a free-text "Specify lead type" field appears (max 100 chars, required).
2. **Name** — for Individual: First / Middle / Last (First + Last required). For non-Individual: a single Entity Name field (required).
3. **Designation** *(Individual only)* — dropdown: Promoter / Founder / CEO / Family Office Head / Others. When `Others`, a free-text qualifier appears (max 60 chars, required).
4. **Company name** *(both types, optional)* — free text. Used by coverage / family-group de-dupe (PWG only).
5. **Contact** — Mobile (with country code, see below) and Email. Both optional, but the form must accept at least one of the two on save (BE rule). Validate format on each.
6. **Mobile country code** — dropdown of 10 countries (India default). Locked rules:

| Country | Dial | Length | Must start with |
|---|---|---|---|
| 🇮🇳 India *(default)* | +91 | 10 | 6, 7, 8, 9 |
| 🇦🇪 UAE | +971 | 9 | 5 |
| 🇸🇬 Singapore | +65 | 8 | 8, 9 |
| 🇬🇧 UK | +44 | 10 | 7 |
| 🇺🇸 US / 🇨🇦 Canada | +1 | 10 | (no rule) |
| 🇦🇺 Australia | +61 | 9 | 4 |
| 🇸🇦 Saudi Arabia | +966 | 9 | 5 |
| 🇭🇰 Hong Kong | +852 | 8 | 5, 6, 9 |
| 🇨🇭 Switzerland | +41 | 9 | 7 |

  Stored as canonical E.164 `+CC<digits>` (no spaces). Display formatted with spacing.

7. **Key contact person** *(non-Individual only)* — repeating field. Each row: Name, Designation (dropdown), Mobile (with country code, same rules), Email, Primary toggle. At least one row required for non-Individual leads, with Mobile or Email present.
8. **Source** — chip selector. RM-pickable values: Referral, Walk-in, Event, Cold Call, Social Media, Web Inquiry. (Other system-only sources like `bulk_upload`, `hurun`, `monetization_event` are not selectable here.)
9. **Consent** *(DPDP)* — three toggles, each with a versioned purpose statement fetched from the server:
   - `lead_capture` — **mandatory**. If declined, save is blocked.
   - `marketing_communication` — optional.
   - `data_sharing_jmfl_entities` — optional.
10. **Save Lead** button at the bottom. Disabled until all required fields are valid. Tap → calls BE coverage check (#2). On clear → saves the lead and navigates to lead detail. On hit → shows the de-dupe sheet.

### De-dupe result sheet (on save when BE returns a hit)

Plain-language headline, then matched record card, then two action buttons:

| BE returns | Headline | Buttons |
|---|---|---|
| `existingClient` | "This person is already a client of the firm — managed by [RM]." | Request reassignment / Cancel |
| `duplicateLead` | "[RM] is already working this lead." | Request reassignment / Cancel |
| `requiresReview` | "We found N similar records — could be the same person." | Request reassignment / Cancel |
| `dnd` | "This number is on the Do Not Disturb register." | Cancel only (with note about Compliance) |

`Request reassignment` calls the reassignment-create endpoint (#4) and pops back. `Cancel` closes the sheet, RM stays on the form.

### Soft-fail (BE coverage outage)

If BE returns 5xx or times out (>5s), show a yellow banner above Save: *"Coverage couldn't be verified. You can save the lead anyway — it'll be flagged for review."* Save proceeds, lead is saved with `coverageVerified = false`.

### Validation table

| Field | Rule | Error wording |
|---|---|---|
| Lead type | Required | "Required" |
| Lead type qualifier (Others) | Required, max 100 | "Required when Others is selected" |
| First name (Individual) | Required | "Required" |
| Last name (Individual) | Required | "Required" |
| Entity name (non-Individual) | Required | "Required" |
| Designation qualifier (Others) | Required, max 60 | "Required when Others is selected" |
| Mobile (when present) | Length + leading digit per country | Country-specific hint, e.g. "Indian mobile must start with 6, 7, 8 or 9" |
| Email (when present) | Must contain `@` | "Enter a valid email" |
| Source | Required | Save button stays disabled with no inline error (chip selector is visible) |
| Mandatory consent | Granted | Save blocked, toggle row shows "Consent is mandatory" |
| Key Contacts (non-Ind.) | At least 1 with valid mobile or email | "Add at least one key contact with mobile or email" |

### Error states

| Failure | UX |
|---|---|
| Required field empty on submit | Inline red error under the field |
| Network error on save | Red toast: "Couldn't save lead. Try again." Form data preserved. |
| Server validation 400 | Red toast with server message; form data preserved |
| Coverage timeout / 5xx | Soft-fail banner; save proceeds with `coverageVerified = false` |
| `existingClient` / `duplicateLead` / `requiresReview` / `dnd` | Result sheet (above) |
| Override reason on requiresReview is too short | Inline error in modal: "Reason must be at least 20 characters" |

### Done when

1. Form renders all sections per the order above with required-field validation.
2. Country code dropdown enforces all 10 countries' rules.
3. Key Contacts field works for non-Individual types with at least one row required.
4. Consent step blocks save if mandatory consent declined.
5. Save Lead triggers BE coverage check (#2); clear → save proceeds; hit → de-dupe sheet renders correctly.
6. Soft-fail banner appears on BE outage; lead saves with `coverageVerified = false`.
7. Reassignment request creates correctly via #4.
8. Phone stored canonically (E.164 with `+`).

### Code reference

- `lib/features/create_lead/presentation/pages/create_lead_screen.dart` — full form reference (current implementation matches this spec).
- `lib/core/widgets/key_contacts_field.dart` — Key Contacts field shape.
- `lib/features/coverage/presentation/widgets/coverage_result_sheet.dart` — de-dupe sheet.

---

# 2. Matrix Wealth CRM BE:RM New Lead (Dedup check)
- **Points**: 5 · **Assignee**: Forum · **Depends on**: #19 (master data)

**User story**: As the RM-side backend, I provide lead persistence and a coverage / de-dupe service so the FE can save a lead only when it's not already a client or another RM's active lead.

### Endpoints

```
POST /leads
GET  /leads/{id}
PUT  /leads/{id}        (used by Lead Details edit, #8)
POST /coverage/check
```

### Lead data shape

Field set the FE will send on POST and the BE must persist:

| Field | Type | Required | Notes |
|---|---|---|---|
| `entityType` | enum (9 values) | yes | individual / private_limited / public_limited / partnership / llp / huf / trust / family_office / others |
| `entityTypeOther` | string \| null | when `entityType=others` | max 100 |
| `firstName, middleName, lastName` | string \| null | first+last when individual | |
| `entityName` | string \| null | when non-individual | |
| `companyName` | string \| null | optional both | |
| `groupName` | string \| null | optional, used for family de-dupe | |
| `designation` | enum \| null | individual only | promoter / founder / ceo / family_office_head / others |
| `designationOther` | string \| null | when `designation=others` | max 60 |
| `phone` | string \| null | E.164 canonical (`+919876543210`) | server-side regex enforced |
| `email` | string \| null | trimmed, lowercased on store | |
| `keyContacts[]` | array | min 1 valid for non-individual | each: `{name, designation, mobile, email, isPrimary}` |
| `source` | enum | yes | RM-pickable values only (reject system-only values) |
| `consentRecords[]` | array | mandatory `lead_capture` granted | each: `{type, decision, purposeStatement, textVersion, decidedAt, decidedByUserId, decidedByUserName, deviceFingerprint}` |
| `vertical` | enum | yes | EWG / PWG, derived from caller's profile |
| `assignedRmId, assignedRmName` | string | yes | derived from caller |
| `stage` | enum | yes (default `lead`) | lead / contacted / qualified / ib_pending / ib_approved / onboarded / dropped |
| `coverageVerified` | bool | default true | false when soft-fail saved during outage |
| `createdAt, updatedAt` | ISO 8601 | server-set | |
| `version` | int | server-set, increments on update | |

`POST /leads` returns `201` with the persisted record + `id` (server-assigned, e.g. `LEAD_<epoch_ms>` or UUID).

### Coverage check

```
POST /coverage/check
{
  "name": string | null,
  "phone": string | null,        // canonical E.164
  "email": string | null,
  "company": string | null,
  "vertical": "EWG" | "PWG"      // from caller's profile
}
```

Algorithm — match against **TWO** pools, in this order, first hit wins:

1. **Wealth Spectrum client master** (existing integration) → `existingClient`.
2. **MATRIX internal lead table** (open leads, any RM, any stage except `dropped`) → `duplicateLead`.

Match rules per field (identical for both pools):

| Field | Rule | Weight |
|---|---|---|
| Mobile | digits-only, bidirectional `endsWith` (whitespace stripped) | 1.0 |
| Email | lowercase exact, trimmed | 1.0 |
| Full name | lowercase substring (record contains entered) | 0.7 |
| Company / group | lowercase substring | **PWG only** | 0.7 |

`confidence = max(weights of matched fields)`.

Status thresholds (configurable, defaults locked):
- `≥ 0.95` → hard hit (`existingClient` or `duplicateLead`)
- `0.5 ≤ x < 0.95` → `requiresReview` with alternates
- `< 0.5` → `clear`

### DND check

Phone (digits-only) matched against the DND register *(source — TRAI scrub vs JMFL internal — confirm with Compliance)*. Hit returns `status: "dnd"`. RMs can't override; Admin override path is out of scope for this ticket.

### Family-group lookup

On `existingClient` hits, return the family group (set of `clientMaster` records sharing the same group identifier). Format:

```
"familyMatch": {
  "groupName": "Khanna Family Office",
  "memberCount": 4,
  "members": [
    { "clientId": "...", "clientName": "...", "rmId": "...", "rmName": "..." },
    ...
  ]
}
```

`duplicateLead` results never carry a family panel.

### Sample responses

**Clear**:
```
{ "status": "clear", "confidence": 0 }
```

**Existing client**:
```
{
  "status": "existingClient",
  "confidence": 1.0,
  "matchedField": "mobile",
  "matchedRecord": { "clientId": "CM00018", "clientName": "Aanya Khanna", "rmId": "...", "rmName": "Vikram Mehta" },
  "familyMatch": { ... }
}
```

**Duplicate lead**:
```
{
  "status": "duplicateLead",
  "confidence": 1.0,
  "matchedField": "email",
  "matchedLead": { "leadId": "...", "fullName": "...", "stage": "qualified", "assignedRmId": "...", "assignedRmName": "..." }
}
```

### Validation rules (server-side)

- Phone must match canonical E.164 if present (`^\+[1-9]\d{6,14}$` plus country-specific length / leading-digit rule).
- Email must contain `@` if present.
- Mandatory consent (`lead_capture`) must be granted; otherwise reject with field-level error.
- `entityType=others` requires `entityTypeOther`.
- Non-Individual requires at least one valid Key Contact.
- Source must be one of the RM-pickable values (reject system-only).
- Reject non-canonical phone with 400 + clear error: *"Mobile must include the country code (e.g. +919876543210)."*

### Error states

| Failure | Response |
|---|---|
| Validation failure | 400 with `{ "errors": { "<field>": "<message>" } }` |
| Concurrent edit (PUT) — version mismatch | 409 + latest record |
| Coverage source down | 503; FE handles soft-fail |
| Permission denied | 403 |

### Done when

1. POST / GET / PUT `/leads` live with full field set + canonical phone validation.
2. POST `/coverage/check` returns the right status per the algorithm.
3. P95 ≤ 800 ms on coverage check.
4. Family-group lookup populated on Wealth Spectrum hits.
5. DND register integrated.
6. Activity log entry written on `lead_created` (uses #16's endpoint).
7. Concurrent-edit (409) handled correctly on PUT.

### Code reference

- `lib/core/services/mock/mock_coverage_repository.dart` — algorithm reference (production reuses existing Wealth Spectrum integration).
- `lib/core/repositories/lead_repository.dart` — interface contract.
- `lib/core/services/mock/mock_lead_repository.dart` — reference behavior.

---

# 3. Matrix Wealth CRM FE:RM Lead Request
- **Points**: 3 · **Assignee**: Gopinath · **Depends on**: #4 (BE)

**User story**: As an RM, I want to request that a specific lead be assigned to me (e.g. from the shared pool, or to claim a lead another RM no longer works), so the Admin can act on it.

### Behaviour

Lead Request screen is reachable from a top-level "Get Lead" / "Request a Lead" entry point (RM home). Two flows:

1. **From the shared pool** — list of unassigned pool leads. RM taps a lead → tap "Request" → on success, lead moves into the RM's queue. Concurrent-claim handling: if another RM wins the race, RM sees "Already claimed by [other RM]" and the pool list refreshes.
2. **Reassignment request** (initiated from a coverage hit on Add Lead — see #1) — the actual sheet lives in #1; this ticket only handles the listing of pending requests in "My Lead Requests" (RM-side visibility into requests they raised).

### Pool eligibility (UI hides ineligible leads)

- Same vertical as the RM.
- RM's branch is permitted.
- IB-gating logic respected (RM under IB-gate cannot claim leads above the gate).

### "My Lead Requests" tab

Lists requests the RM has raised, grouped by status: Pending / Approved / Rejected / Cancelled. Each row shows: matched client name (if any), target RM name, age, reason. Pending requests can be cancelled by the source RM (and the RM only).

### Error states

| Failure | UX |
|---|---|
| Concurrent claim — RM lost | Snackbar: "Already claimed by [other RM]." Pool list refreshes. |
| Network error | Toast: "Couldn't reach the server. Tap to retry." |
| Permission denied (vertical/branch/IB-gate) | Toast: "You're not eligible to claim this lead." |
| Pool empty | Empty state: "No leads in the pool right now." with Refresh button |
| Cancelling a request | Confirmation modal: "Cancel this reassignment request?" |

### Done when

1. Pool list renders with eligibility filter applied client-side.
2. Tap-to-request fires the BE claim endpoint (#4); idempotency-key header used to safely retry.
3. Race-loss handled with "Already claimed" message.
4. "My Lead Requests" tab renders the RM's raised requests, grouped by status, with cancel action on Pending.
5. All error states above implemented.

### Code reference

- `lib/features/get_lead/` — pool view + claim UX.
- `lib/core/repositories/lead_request_repository.dart` — interface.

---

# 4. Matrix Wealth CRM BE:RM Lead Request
- **Points**: 2 · **Assignee**: Vishwas · **Depends on**: #2 (lead persistence)

**User story**: As the BE, I provide atomic pool-claim and reassignment-request endpoints with proper concurrency handling.

### Endpoints

```
GET   /leads/pool                        // pool list with eligibility filter
POST  /leads/{id}/claim                  // atomic claim
GET   /reassignment?requesterId=&status= // RM's own raised requests
POST  /reassignment                      // create a request (called from coverage hit)
POST  /reassignment/{id}/cancel          // source RM cancels a pending request
```

### Atomic claim semantics

```
UPDATE leads
SET    assigned_rm_id = :rmId, assigned_rm_name = :rmName, claimed_at = NOW(), version = version + 1
WHERE  id = :leadId AND assigned_rm_id = 'POOL'
RETURNING ...;
```

If 0 rows updated → `409 Conflict` with `{ "claimedBy": { rmId, rmName } }`. If 1 row → `200 OK` with the full lead.

Idempotency: client-supplied `Idempotency-Key` header. Re-call with same key returns the original 200.

### Reassignment request data shape

```
{
  "id": "RR_<epoch_ms>",
  "leadId": string | null,         // null when raised against a Wealth Spectrum client (not a MATRIX lead)
  "matchedClientId": string | null,
  "matchedClientName": string | null,
  "sourceRmId": string,
  "sourceRmName": string,
  "targetRmId": string,
  "targetRmName": string,
  "reason": string,                // free text + auto-prefix "Coverage match — ..."
  "status": "pending" | "approved" | "rejected" | "cancelled",
  "createdAt": ISO 8601,
  "decidedBy": string | null,
  "decidedAt": ISO 8601 | null,
  "version": int
}
```

State machine (cancellation is the only RM-side transition; approve / reject are Admin and out of scope here):

```
pending -> cancelled  (source RM, only while pending)
```

### Validation

- Reassignment request: `reason` ≥ 20 chars. Source RM must be the caller. Target RM derived from matched record.
- Cancel: only allowed when `status = pending` and caller is `sourceRmId`.

### Error states

| Failure | Response |
|---|---|
| Race-loss on claim | 409 + claimedBy info |
| Network / server error | 5xx with retry guidance |
| Permission denied (e.g. RM tries to cancel another RM's request) | 403 |
| Already actioned (Admin approved/rejected before cancel) | 409 + current status |

### Done when

1. Pool list endpoint applies eligibility (vertical / branch / IB-gating).
2. Atomic claim with idempotency works under concurrent calls (verified via integration test).
3. Reassignment create + cancel endpoints live.
4. RM-side query (raised by me) returns correct grouping.
5. Activity log entries written on claim and reassignment-cancel.

### Code reference

- `lib/core/repositories/lead_request_repository.dart` — interface contract.
- `lib/core/repositories/reassignment_repository.dart` — interface contract.

---

# 5. Matrix Wealth CRM FE:RM all Leads with filter & search
- **Points**: 5 · **Assignee**: Gopinath · **Depends on**: #6 (BE)

**User story**: As an RM, I want a single screen showing all my leads with search, filter, and sort, so I can quickly find what I need.

### Behaviour

- **Tab strip** at top: "My Leads" / "All Leads" *(per vertical scope; confirm with Product)*. Default "My Leads".
- **Search bar** — searches name / phone / email / company on the visible tab. Debounced 300 ms.
- **Filter chips** — Stage, Vertical, Source, Temperature (Hot / Warm / Cold). Multi-select within a category. Active filters shown as removable chips above the list.
- **Sort options** — default "Hot first → Warm → Cold, then by most recent activity"; alt: by created date / by name.
- **Lead row card** shows:
  - Lead name + entity type icon
  - Company name (if present)
  - Stage badge (lead / contacted / qualified / ib_pending / ib_approved / onboarded / dropped)
  - Temperature chip (🔥 Hot / 🟠 Warm / 🧊 Cold) with day count tooltip on long-press
  - Next-action chip (if set) with due date
  - Last activity time ("2 days ago")
- **Tap row** → Lead Details (#7).
- **Pagination** — infinite scroll, 50 per page.

### Empty / failure states

| State | UX |
|---|---|
| No leads at all | Friendly empty state with "Create your first lead" CTA → New Lead (#1) |
| Filter narrows to zero | "No leads match these filters. Try removing a filter." with chips removable in place |
| Network error | Banner: "Couldn't load leads. Tap to retry." |
| Pagination fails on later page | Banner: "Couldn't load more. Retry." Already-loaded list stays |

### Done when

1. Search + filter + sort work end-to-end with the BE endpoint (#6).
2. Pagination loads 50 at a time without flicker.
3. Temperature chips render correctly per the band rules.
4. Default sort is Hot → Warm → Cold then by activity.
5. Tap-row navigates to Lead Details with state preserved (back returns to same scroll + filters).
6. All empty / failure states implemented.

### Code reference

- `lib/features/leads_dashboard/` — list view + filter chips reference.

---

# 6. Matrix Wealth CRM BE:RM all Leads with filter & search
- **Points**: 5 · **Assignee**: Vishwas · **Depends on**: #2 (lead persistence)

**User story**: As the BE, I provide the lead list endpoint with server-side search, filter, and sort, plus computed temperature.

### Endpoint

```
GET /leads
  ?assignedRmId=
  &stage=                    // multi-value
  &vertical=
  &source=                   // multi-value
  &temperature=              // multi-value (hot|warm|cold)
  &search=                   // matches name / phone / email / company
  &sort=                     // default `temperature_then_activity`
  &page=                     // default 0
  &limit=                    // default 50, max 100
```

Returns:

```
{
  "items": [
    {
      "id": "...", "fullName": "...", "stage": "...", "vertical": "...",
      "companyName": "...", "phone": "...", "email": "...",
      "lastActivityAt": ISO, "daysSinceActivity": int, "temperature": "hot|warm|cold",
      "nextAction": { "type": "...", "dueAt": ISO } | null,
      ...
    }
  ],
  "total": int,
  "page": int,
  "limit": int
}
```

### Temperature compute

| Band | Days since `lastActivityAt` (fall back to `createdAt`) |
|---|---|
| 🔥 Hot | < 30 |
| 🟠 Warm | 30 – < 90 |
| 🧊 Cold | ≥ 90 |

Boundary at exactly 30 = Warm; exactly 90 = Cold. Calendar days, IST. Recompute on read (1-hour cache).

### Sort default

`temperature_then_activity` — Hot first, then Warm, then Cold. Within band, most-recent `lastActivityAt` first.

### Performance

- P95 ≤ 600 ms for a list of 1,000 leads.
- Index on `(assigned_rm_id, stage, last_activity_at)`.

### Error states

| Failure | Response |
|---|---|
| Bad query params | 400 with field-level error |
| RM scope violation (caller asks for another RM's leads without TL/Admin role) | 403 |

### Done when

1. List endpoint returns paginated results with all filters working.
2. Temperature computed correctly with cache.
3. Search hits the right fields.
4. Sort default works.
5. P95 verified.

### Code reference

- `lib/core/repositories/lead_repository.dart` — interface.

---

# 7. Matrix Wealth CRM FE:RM Lead Details
- **Points**: 5 · **Assignee**: Omkar · **Depends on**: #8 (BE)

**User story**: As an RM, I want a single screen showing everything I need to know about a lead and easy access to all the actions I can take.

### Layout (top to bottom)

1. **Hero header** — navy gradient with lead identity:
   - Lead name (full)
   - Vertical badge (EWG / PWG) + stage badge
   - Temperature chip with day count
   - Phone / email / company sub-line (PII masked by default — see masking rules)
2. **Next-action callout** — if a next action is set, render a banner: "Next: Callback in 3 days" with "Clear" affordance.
3. **Quick action grid** — 4 tiles: Call (green), WhatsApp (WhatsApp green, disabled when no phone), Meet (navy), Note (amber). Behaviour wired in #17.
4. **IB convert CTA** — prominent button below the action grid: "Convert to IB Lead" → #9. If already converted, show "Converted to IB" info card with link.
5. **Activity timeline** — vertical timeline of activities (calls / meetings / WhatsApp / notes / system events). Newest first. Each entry: icon, type, actor, time, outcome chip, notes preview.
6. **Details block** — collapsible card with full lead data: type, designation, key contacts, company, source, consent status, dates.
7. **Bottom bar** — single primary action depending on stage (e.g. "Start profiling" / "Submit to IB" / "Drop lead").

### PII masking *(per Assumption — DPDP)*

| Field | Masked default | Unmask flow |
|---|---|---|
| Phone | `+91 98***43210` | Tap → audit-log entry → reveal |
| Email | `aa***@example.com` | Tap → audit-log entry → reveal |
| PAN | `ABC**1234F` | Same |
| DOB | `**-**-1985` | Same |

Offline: tap shows tooltip *"Connect to view full details — access must be logged."* Field stays masked.

### Edit lead

A pencil icon in the hero header opens an Edit sheet. RM can update mutable fields (name, designation, contact, source, company, key contacts). Save calls PUT `/leads/{id}` (#8). Concurrent-edit conflict (409) shows modal: *"This lead was updated by [name] [time]. Reload?"*

### Drop lead

The Drop CTA (in the overflow menu or bottom bar based on stage) opens the drop sheet (#11).

### Error states

| Failure | UX |
|---|---|
| Lead not found / deleted | Banner: "This lead is no longer available." + Back button |
| Network error on load | "Couldn't load. Retry?" |
| Unmask permission denied | Field stays masked; toast "You don't have permission" |
| Edit conflict (409) | Modal as above |
| Activity tab loading fails | "Couldn't load activity. Retry." Other tabs still work |

### Done when

1. All 7 layout sections render correctly.
2. PII masking + audit-log on unmask works.
3. Edit lead via pencil works with concurrent-edit handling.
4. Drop lead reachable via overflow menu / bottom bar.
5. Activity timeline displays all activity types with their respective icons + outcome chips.
6. Quick action grid wired to #17 sheets.
7. IB convert CTA visible per stage rules.

### Code reference

- `lib/features/lead_detail/presentation/pages/lead_detail_screen.dart` — full implementation reference.
- `lib/core/utils/pii_display.dart` — masking utility.

---

# 8. Matrix Wealth CRM BE:RM Lead Details
- **Points**: 5 · **Assignee**: Vaibhav · **Depends on**: #2 (lead persistence)

**User story**: As the BE, I provide the lead-detail GET, the activity-feed sub-endpoint, and the lead-update endpoint.

### Endpoints

```
GET /leads/{id}                 // full lead + computed temperature, masked-by-default flags
GET /leads/{id}/activities      // newest-first paginated timeline
PUT /leads/{id}                 // update mutable fields
POST /leads/{id}/pii/unmask     // unmask a single PII field, audit-logged
```

### GET /leads/{id} response

Full lead shape from #2, plus:
```
"lastActivityAt": ISO,
"daysSinceActivity": int,
"temperature": "hot|warm|cold",
"nextAction": { "type": "...", "dueAt": ISO } | null,
"piiMasked": {
  "phone": "+91 98***43210",
  "email": "aa***@example.com",
  ...
}
```

PII fields returned masked by default. Unmasked values fetched via `POST /leads/{id}/pii/unmask` which writes an audit entry then returns the raw value.

### Audit on unmask

```
{
  "userId", "userName", "leadId", "field", "action": "unmask",
  "timestamp", "deviceId", "ipAddress"
}
```

### PUT /leads/{id} update rules

- Body must include `version`.
- 409 Conflict on version mismatch (returns latest).
- Activity log entry written on every successful update with before/after of changed fields (uses #16).
- Phone validation: must be canonical E.164 if present.

### Activities endpoint

```
GET /leads/{id}/activities?page=&limit=    // default limit 50
```

Returns activity items per the model in #16.

### Error states

| Failure | Response |
|---|---|
| Lead not found | 404 |
| Permission denied (RM viewing another RM's lead) | 403 |
| 409 on PUT version mismatch | latest record returned |
| Bad PII unmask field | 400 |

### Done when

1. GET / PUT / activity-list endpoints live.
2. PII unmask writes audit entry atomically with reveal.
3. Version-based optimistic concurrency on PUT.
4. P95 ≤ 400 ms on GET.

### Code reference

- `lib/core/repositories/lead_repository.dart` — interface.
- `lib/core/repositories/audit_repository.dart` — audit interface.

---

# 9. Matrix Wealth CRM FE:RM Convert to IB Leads
- **Points**: 2 · **Assignee**: Gopinath · **Depends on**: #10 (BE)

**User story**: As an RM, when a wealth lead surfaces an IB opportunity, I want to convert it to an IB lead so the IB team can take over.

### Behaviour

CTA on Lead Details (#7) → opens "Convert to IB" sheet:
- Pre-fills lead identity (name, company, vertical).
- Captures IB-specific fields: opportunity type, deal size band, urgency, summary notes.
- Submit → calls POST `/leads/{id}/ib-convert` (#10).
- On success: lead's stage moves to `ib_pending`, sheet closes, snackbar "Submitted to IB" with link to "My IB Leads" view.

### Duplicate-IB block

If the lead is already in `ib_pending` (a previous submission still awaiting decision), Submit is blocked with banner: *"This lead is already in the IB queue. Awaiting decision."*

If a previous submission was rejected, the form pre-fills the previous data; a yellow strip at the top shows the previous rejection reason verbatim. RM must edit at least one field before re-submitting.

### Error states

| Failure | UX |
|---|---|
| Already in IB queue | Banner + Submit disabled |
| Re-submit without edit after rejection | "Edit at least one field to re-submit" |
| Insufficient role | Toast: "You're not authorised to submit to IB" |
| Network error | Toast with Retry |

### Done when

1. Convert sheet renders with all IB-specific fields.
2. Submit calls #10 endpoint with idempotency key.
3. Duplicate-IB block enforced.
4. Re-submit-after-rejection flow works with prefill + reason banner + edit gate.
5. Lead stage on detail screen reflects `ib_pending` after submit.

### Code reference

- `lib/features/lead_detail/presentation/widgets/convert_to_ib_sheet.dart` — sheet reference.

---

# 10. Matrix Wealth CRM BE:RM Convert to IB Leads
- **Points**: 2 · **Assignee**: Vaibhav · **Depends on**: #2

**User story**: As the BE, I expose the IB submit endpoint with duplicate-IB block and proper state transition on the underlying lead.

### Endpoint

```
POST /leads/{id}/ib-convert
{
  "opportunityType": "...", "dealSizeBand": "...",
  "urgency": "...", "summaryNotes": "..."
}
```

### Behaviour

1. Verify lead is not already in `ib_pending`. If it is → 409 with `{ "error": "AlreadyInIbQueue", "submissionId": "..." }`.
2. If a previous submission for this lead exists in `rejected` status, allow re-submit only if at least one field on the lead has changed since the rejection (compare `lead.updatedAt` to rejection timestamp).
3. Create an IB submission record:
   ```
   { "submissionId", "leadId", "submittedBy", "submittedAt", "status": "pending",
     "decidedBy", "decidedAt", "decisionReason", "rejectionHistory": [], ... }
   ```
4. Update lead `stage = ib_pending`, increment `version`.
5. Write activity log entry `ib_submitted`.
6. Notify IB checker queue (push) — see future Notifications ticket.

Atomic — all four steps in one transaction.

### Error states

| Failure | Response |
|---|---|
| Already pending | 409 |
| Re-submit without edit | 409 + clear message |
| Permission denied | 403 |

### Done when

1. Endpoint live with all four atomic side-effects.
2. Duplicate-IB block returns 409.
3. Re-submit-after-rejection enforces the edit gate.

### Code reference

- `lib/core/repositories/ib_lead_repository.dart` — interface.
- `lib/core/utils/duplicate_ib_check.dart` — block logic reference.

---

# 11. Matrix Wealth CRM FE:RM Drop Lead
- **Points**: 2 · **Assignee**: Omkar · **Depends on**: #12 (BE)

**User story**: As an RM, I want to manually drop a lead I no longer want to pursue, capturing the reason for audit.

### Behaviour

Drop is reachable from Lead Details overflow menu / bottom bar.

Drop sheet:
- Reason picker (chips): Not interested, Not eligible, Bad contact, Already a client elsewhere, Wrong vertical, Other (free text).
- Optional notes field (max 500 chars).
- Optional "Reopen on" date picker (for parking — RM can choose to re-engage later).
- Confirm button → calls POST `/leads/{id}/drop` (#12).

**Lead drop is manual-only** *(per Assumption #12)*. There is no auto-drop on SLA breach or orphan retention — the lead stays with the RM until explicitly dropped here.

### Error states

| Failure | UX |
|---|---|
| Reason missing | Confirm disabled |
| "Other" with empty notes | Inline error: "Add a brief reason" |
| Network error | Toast with Retry |
| Already dropped (race) | Toast: "Lead is already dropped" |

### Done when

1. Drop sheet renders all reason options.
2. Optional reopen-date works (parking).
3. Confirm calls BE endpoint and pops to lead list on success.
4. Dropped lead shows on detail screen with stage `dropped` + reason in activity log.

### Code reference

- `lib/features/stage/presentation/widgets/drop_lead_sheet.dart` — sheet reference.

---

# 12. Matrix Wealth CRM BE:RM Drop Lead
- **Points**: 2 · **Assignee**: Vishwas · **Depends on**: #2

**User story**: As the BE, I expose the drop endpoint, transitioning the lead to `dropped` and writing the audit trail.

### Endpoint

```
POST /leads/{id}/drop
{
  "reason": "...",
  "notes": "...",
  "reopenAt": ISO | null
}
```

Atomic — one transaction:
1. Update lead `stage = dropped`, `droppedReason`, `droppedNotes`, `reopenAt`, `version++`.
2. Write activity log entry `dropped_to_pool` (or `dropped` — confirm naming with #16).

No auto-drop logic anywhere on the BE *(per Assumption #12)*.

### Validation

- `reason` required.
- If `reason = "Other"`, `notes` required (≥ 10 chars).
- Caller must own the lead OR be TL / Admin.

### Error states

| Failure | Response |
|---|---|
| Validation | 400 |
| Permission denied | 403 |
| Already dropped | 409 |

### Done when

1. Endpoint live with atomic state transition + activity log.
2. Permission check enforced.
3. Dropped leads filtered out of default list (#6) unless `stage=dropped` filter applied.

---

# 13. Matrix Wealth CRM FE:RM Dashboard
- **Points**: 5 · **Assignee**: Gopinath · **Depends on**: #14 (BE)

**User story**: As an RM, I want a home dashboard showing my active workload, upcoming actions, and KPIs at a glance.

### Layout

1. **Hero greeting** — "Good morning, [RM name]" + date.
2. **KPI tiles** (top row, 3 across):
   - Active leads (count)
   - Hot leads (🔥 count)
   - Pending actions today (callbacks / meetings due)
3. **Next actions list** — leads with a next-action due today / overdue. Tap row → Lead Details.
4. **Pipeline by stage** — horizontal bar showing count per stage (lead / contacted / qualified / ib_pending / ib_approved / onboarded). Tap a bar → All Leads (#5) filtered to that stage.
5. **Temperature breakdown** — donut: Hot / Warm / Cold counts. Tap a slice → All Leads filtered to that band.
6. **Recent activity** — last 5 activities across the RM's leads.

Pull-to-refresh re-queries #14.

### Error / empty states

| State | UX |
|---|---|
| No active leads | "No active leads right now" with CTA to New Lead (#1) |
| Network error | Banner: "Couldn't load dashboard. Tap to retry." |
| Stale (cached) data | Subtle "as of [time]" footer |

### Done when

1. All sections render with live data from #14.
2. KPI tiles tappable → drill into the right list / filter.
3. Pipeline bar + temperature donut both tappable.
4. Pull-to-refresh works.
5. Stale-data footer appears when serving cached.

### Code reference

- `lib/features/dashboard_leadership/` — dashboard layout patterns *(but this is RM-personal scope, not org-wide)*.

---

# 14. Matrix Wealth CRM BE:RM Dashboard
- **Points**: 3 · **Assignee**: Vaibhav · **Depends on**: #2

**User story**: As the BE, I aggregate the RM's personal dashboard data in a single endpoint so the FE can render in one fetch.

### Endpoint

```
GET /dashboard/rm/me
```

Returns:

```
{
  "rmName": "...",
  "kpis": {
    "activeLeads": int,
    "hotLeads": int,
    "pendingActionsToday": int   // next-action due today + overdue
  },
  "nextActions": [
    { "leadId", "leadName", "actionType", "dueAt", "isOverdue" }
  ],
  "pipelineByStage": {
    "lead": int, "contacted": int, "qualified": int,
    "ib_pending": int, "ib_approved": int, "onboarded": int
  },
  "temperatureBreakdown": { "hot": int, "warm": int, "cold": int },
  "recentActivity": [
    { "leadId", "leadName", "activityType", "actor", "timestamp", "outcome" }
  ],
  "computedAt": ISO,
  "cacheExpiresAt": ISO
}
```

### Performance

- P95 ≤ 800 ms.
- 5-minute cache per RM.

### Done when

1. Endpoint returns all sections.
2. Counts match what the leads list (#6) would return for the same scope.
3. Cache TTL = 5 min.

---

# 15. Matrix Wealth CRM FE:RM Lead Log Capture
- **Points**: 5 · **Assignee**: Arsh · **Depends on**: #16 (BE)

**User story**: As an RM, I want a focused sheet to log notes / outcomes against a call, meeting, WhatsApp, or note interaction.

### Behaviour

The activity log sheet is the destination of:
- Call → "Log a past call" path (from #17 Call chooser)
- Meet → "Log a past meeting" path (from #17 Meeting picker — handles state transition on scheduled meetings)
- Note → opens directly preselected to Note
- (Activity type cannot be switched inside the sheet — the entry CTA is the type. This is intentional UX from product review to avoid confusion.)

### Layout

```
[icon] [Lead name] / [activity type description]      ← context header

[for call/meeting]
Outcome chips: [Connected] [No answer] [Interested] [Follow-up needed] [Not interested]
Duration (minutes): [____]

[for meeting only]
How was it conducted?
[ In-person ] [ Video call (default) ]
Meeting link / Location: [_____________]   ← swaps based on toggle

Notes: [_______________________________]    ← multiline, max 500

Set a follow-up (optional)
[Callback] [Meeting] [Send Proposal] [Send Docs] [Wait for Client] [None]
[When: date+time picker]                    ← shown only when a non-None type is picked

[Log <Type>]                                ← primary button at the very end
```

### Save behaviour

- Calls #16's create or update endpoint depending on whether we're logging against an existing scheduled meeting (state transition: `followUp → completed`) or creating a fresh entry (call / WhatsApp / note / walk-in meeting).
- Persists the next-action chip via PUT on the lead's `nextAction`.
- For meetings: prepends a one-line `Video call · <link>` or `In-person · <location>` to the notes so the timeline shows mode at a glance.
- After meeting save: prompts "Did any IB opportunity come up?" → optional deep-link into IB convert flow (#9).
- If the picked next-action is `Meeting`: chains into the meeting create flow (`MeetingCreateSheet` with the next-action date pre-filled) so the RM can capture title / mode / link in the same go.

### Error states

| Failure | UX |
|---|---|
| Required field missing (none here — all optional except by type) | n/a |
| Network error on save | Red toast with Retry; form data preserved |
| 409 on update (state already changed) | Toast: "This meeting was already logged" |

### Done when

1. Sheet renders with the right blocks per activity type.
2. Mode toggle visible only for meeting type; field swaps Link ↔ Location.
3. Notes prepending logic for meetings produces clean timeline display.
4. Next-action chip persists via lead PUT.
5. Meeting-as-next-action chains into MeetingCreateSheet (`hideNextAction: true`, `prefilledWhen: nextActionDate`).
6. IB-opportunity prompt fires after meeting save.

### Code reference

- `lib/features/activity/presentation/widgets/activity_quick_log_sheet.dart` — implementation reference.

---

# 16. Matrix Wealth CRM BE:RM Lead Log Capture
- **Points**: 3 · **Assignee**: Forum · **Depends on**: #2

**User story**: As the BE, I provide the activity-log endpoints for create and state-transition update.

### Endpoints

```
POST /leads/{id}/activities          // create a new activity entry
PUT  /activities/{id}                // update an existing entry (state transitions)
GET  /leads/{id}/activities          // already covered in #8 BE
```

### Activity data shape

```
{
  "id": "<lead>_ACT_<epoch_ms>",
  "leadId": "...",
  "type": "call|meeting|note|whatsApp|email|task|system",
  "dateTime": ISO,
  "durationMinutes": int | null,
  "notes": string | null,
  "outcome": "connected|no_answer|voicemail|interested|follow_up|not_interested|completed|cancelled" | null,
  "loggedById": "...",
  "loggedByName": "...",
  "isSystemGenerated": bool,
  "createdAt": ISO
}
```

### State transitions on PUT

The PUT endpoint is used specifically to flip a scheduled meeting (`outcome = follow_up`, future `dateTime`) to either:
- `completed` — when RM logs the meeting as held. Notes get appended (caller sends combined notes).
- `cancelled` — when RM cancels a scheduled meeting via the picker.

PUT must NOT change `id`, `leadId`, `type`, `loggedById`, `loggedByName`, `createdAt`, `isSystemGenerated`. Allowed fields: `dateTime`, `durationMinutes`, `notes`, `outcome`.

### Reliability

Every state-changing API in MATRIX writes an activity entry atomically. If the activity-log write fails, the parent transaction must roll back. This applies to lead create / update / drop / IB submit / claim / consent grant / reassignment-cancel / etc.

### Retention

Indefinite *(per Assumption #6)*. No purge job.

### Error states

| Failure | Response |
|---|---|
| Activity not found on PUT | 404 |
| Permission denied | 403 |
| Validation failure | 400 |

### Done when

1. POST + PUT endpoints live with the field-update rules.
2. PUT correctly handles `follow_up → completed` and `follow_up → cancelled` transitions.
3. Atomic write with parent transactions verified via integration test.
4. No purge / retention logic on activity log.

### Code reference

- `lib/core/repositories/activity_repository.dart` — interface (includes the new `updateActivity` method).
- `lib/core/services/mock/mock_activity_repository.dart` — reference impl.

---

# 17. Matrix Wealth CRM FE:RM Lead Activity Request - Call,WhatsApp,Meeting, Notes
- **Points**: 5 · **Assignee**: Arsh · **Depends on**: #15, #18

**User story**: As an RM, when I tap Call / WhatsApp / Meet / Note on lead detail, I want focused, smart flows for each — not a generic logger.

### Behaviour per tile

#### 📞 Call → 2-button chooser

| Button | What happens |
|---|---|
| **Call now** | Launches device dialer via `tel:<phone>`. On return, auto-opens the log sheet (#15) preselected to Call. Disabled when no phone is on file. |
| **Log a past call** | Opens log sheet directly. |

#### 💬 WhatsApp → opens composer directly (no chooser)

The composer:
- **Template chips** — Intro / Follow-up after call / Share proposal / Custom. Picking a template fills the message body with substitutions: `{firstName}`, `{rmName}`, `{firmName}`.
- **Editable message field** (max 1024 chars).
- **Attachments section** *(only for Share proposal and Custom templates)* — multi-select from a document library (master data via #18). Selected files render as removable chips. A subtitle clarifies *"Tip: After WhatsApp opens, tap the 📎 icon there to add these files"* — because `wa.me?text=` is text-only on Day 1.
- **Set a follow-up (optional)** — chip row + date picker.
- **Info banner**: "Opens WhatsApp with this message pre-filled. Tap Send inside WhatsApp to deliver."
- **Send via WhatsApp** button at the very end. Tap → launches `wa.me/<digits>?text=<encoded>`. On return, auto-logs the activity with: full message body in notes, prefixed with `[<template_key>]`, attachments listed on a separate `Attached: ...` line.

WhatsApp tile is disabled when the lead has no phone on file. There is no "Log a past WhatsApp" path — for messages sent outside the app, the Note tile is the right home.

#### 📅 Meet → 2-button chooser, state-aware

| Button | What happens |
|---|---|
| **Schedule a new meeting** | Opens the meeting create form: title (req), when, duration, mode (In-person / Online), link or location, notes, set-a-follow-up (optional). Save → logs activity of type `meeting`. Future date → outcome `follow_up` ("Scheduled"). Past date → `completed` ("Logged"). |
| **Log a past meeting** | Opens the **meeting picker**. |

The meeting picker lists scheduled meetings on this lead (those with `outcome = follow_up`). Sorted past-due first, then upcoming. Three sub-paths:

1. **Pick a scheduled meeting row** → Opens log sheet (#15) with header `"Logging: <title> (<date·time>)"`. On save → BE PUT (#16) flips the existing record's outcome to `completed` and appends held-meeting notes. **No duplicate record created.**
2. **Tap × on a scheduled meeting row** → Confirmation sheet → BE PUT flips the record to `cancelled`. No log entry created.
3. **"It wasn't a scheduled meeting"** footer → Opens log sheet (#15) with type `meeting`, creates a fresh activity record (walk-in / ad-hoc).

#### 📝 Note → opens log sheet directly preselected to Note

No chooser, no extra fields beyond notes + next-action.

### Set a follow-up (optional) — Meeting chaining

Across all four action sheets, when the RM picks `Meeting` as the follow-up next-action and provides a date, the system chains into the meeting create flow (`MeetingCreateSheet` with `prefilledWhen: nextActionDate, hideNextAction: true`) immediately after the parent action saves. RM fills title / mode / link → BE creates the future meeting activity. Both records persist (today's action + tomorrow's scheduled meeting).

### Disabled states

| Tile | Condition |
|---|---|
| WhatsApp | Lead has no phone on file → tile is greyed-out, tap is no-op |
| Call | Always enabled (chooser handles "Call now" disabled state) |
| Meet | Always enabled |
| Note | Always enabled |

### Error states (per sheet)

| Sheet | Failure | UX |
|---|---|---|
| Call chooser | Dialer launch fails | Toast: "Couldn't open the dialer." |
| WhatsApp composer | Template fetch fails | Toast: "Couldn't load templates" + retry; manual message still works |
| WhatsApp composer | Attachment list fetch fails | Toast; section shows "Couldn't load files" |
| Meeting picker | Picker fails to load | "Couldn't load scheduled meetings. Retry." |
| Meeting picker | Cancel confirm | "Cancel meeting?" sheet — Confirm / Keep it |
| All | Network error on save | Standard retry toast; data preserved |

### Done when

1. Call chooser implemented with both buttons + dialer launch + auto-log on return.
2. WhatsApp composer renders templates + attachments + auto-log on send + meeting chain on follow-up.
3. Meeting chooser → Schedule new (full create form) and Log past (picker).
4. Picker handles scheduled-meeting log + cancel + walk-in fallback correctly.
5. State transitions on BE (PUT) verified — no duplicate meeting records.
6. Note tile opens log sheet directly.
7. Cancellation confirmation sheet implemented.
8. Mode toggle on Meeting log path (In-person / Video call) wired correctly with link/location swap.

### Code reference

- `lib/features/lead_detail/presentation/widgets/call_action_chooser_sheet.dart`
- `lib/features/lead_detail/presentation/widgets/whatsapp_composer_sheet.dart`
- `lib/features/lead_detail/presentation/widgets/meeting_action_chooser_sheet.dart`
- `lib/features/lead_detail/presentation/widgets/meeting_create_sheet.dart`
- `lib/features/lead_detail/presentation/widgets/meeting_picker_sheet.dart`
- `lib/features/lead_detail/presentation/pages/lead_detail_screen.dart` — handlers `_onCallTap`, `_onWhatsappTap`, `_onMeetTap`, `_onLogPastMeeting`, `_logAgainstScheduledMeeting`, `_chainFollowUpMeeting`.

---

# 18. Matrix Wealth CRM BE:RM Lead Activity Request - Call,WhatsApp,Meeting, Notes
- **Points**: 3 · **Assignee**: Forum · **Depends on**: #16

**User story**: As the BE, I expose the master-data and metadata storage that the action sheets need.

### Endpoints

```
GET  /master/whatsapp-templates
GET  /master/proposal-library             // documents available for WhatsApp attachments
POST /leads/{id}/activities/whatsapp       // (or use generic create from #16) — store template_key + attachment refs
PUT  /activities/{id}                      // already in #16 — for meeting state transitions
```

### WhatsApp template master-data shape

```
[
  { "key": "intro",          "label": "Intro",                "body": "Hi {firstName}, ..." },
  { "key": "followup_call",  "label": "Follow-up after call", "body": "Hi {firstName}, ..." },
  { "key": "proposal",       "label": "Share proposal",       "body": "..." },
  { "key": "custom",         "label": "Custom",               "body": "" }
]
```

Variables: `{firstName}`, `{rmName}`, `{firmName}`. Substitution is FE-side at compose time (server stores the rendered body).

### Proposal library shape

```
[
  { "id": "doc_1", "name": "JM Wealth Brochure 2026.pdf", "sizeBytes": 2400000, "url": "..." },
  { "id": "doc_2", "name": "PMS Strategy Note.pdf",       "sizeBytes": 1100000, "url": "..." },
  ...
]
```

### Activity persistence

All four tile actions go through #16's POST `/leads/{id}/activities`. WhatsApp activities additionally store:
```
{ ..., "metadata": { "templateKey": "proposal", "attachmentNames": ["..."] } }
```

Meeting activities store mode + link/location in `metadata` *(or as a structured prefix in the notes — confirm with FE team for consistency with what gets rendered)*.

### Done when

1. Template + proposal-library master endpoints live and cacheable.
2. Activity create/update endpoints accept the structured metadata.
3. Audit-trail entries written.

---

# 19. Matrix Wealth CRM BE:RM New Lead Country Master, Lead Type, Designation
- **Points**: 2 · **Assignee**: Vishwas

**User story**: As the BE, I expose the master-data endpoints for the dropdown values used by Add Lead and Key Contacts.

### Endpoints

```
GET /master/country-codes
GET /master/lead-types
GET /master/designations
```

### Country codes

```
[
  { "iso": "IN", "dialCode": "+91", "name": "India",        "minDigits": 10, "maxDigits": 10, "leadingDigits": "^[6-9]", "leadingHint": "Indian mobile must start with 6, 7, 8 or 9" },
  { "iso": "AE", "dialCode": "+971", "name": "UAE",         "minDigits": 9,  "maxDigits": 9,  "leadingDigits": "^5", "leadingHint": "UAE mobile must start with 5" },
  { "iso": "SG", "dialCode": "+65", "name": "Singapore",    "minDigits": 8,  "maxDigits": 8,  "leadingDigits": "^[89]" },
  { "iso": "GB", "dialCode": "+44", "name": "United Kingdom","minDigits": 10, "maxDigits": 10, "leadingDigits": "^7" },
  { "iso": "US", "dialCode": "+1",  "name": "United States","minDigits": 10, "maxDigits": 10 },
  { "iso": "CA", "dialCode": "+1",  "name": "Canada",       "minDigits": 10, "maxDigits": 10 },
  { "iso": "AU", "dialCode": "+61", "name": "Australia",    "minDigits": 9,  "maxDigits": 9,  "leadingDigits": "^4" },
  { "iso": "SA", "dialCode": "+966","name": "Saudi Arabia", "minDigits": 9,  "maxDigits": 9,  "leadingDigits": "^5" },
  { "iso": "HK", "dialCode": "+852","name": "Hong Kong",    "minDigits": 8,  "maxDigits": 8,  "leadingDigits": "^[569]" },
  { "iso": "CH", "dialCode": "+41", "name": "Switzerland",  "minDigits": 9,  "maxDigits": 9,  "leadingDigits": "^7" }
]
```

India is the default selection on the FE. Order in the response is the display order.

### Lead types

```
[
  { "key": "individual",        "label": "Individual" },
  { "key": "private_limited",   "label": "Private Limited" },
  { "key": "public_limited",    "label": "Public Limited" },
  { "key": "partnership",       "label": "Partnership" },
  { "key": "llp",               "label": "LLP" },
  { "key": "huf",               "label": "HUF" },
  { "key": "trust",              "label": "Trust" },
  { "key": "family_office",     "label": "Family Office" },
  { "key": "others",             "label": "Others", "requiresQualifier": true, "qualifierMaxLength": 100 }
]
```

### Designations *(Individual leads only)*

```
[
  { "key": "promoter",            "label": "Promoter" },
  { "key": "founder",             "label": "Founder" },
  { "key": "ceo",                 "label": "CEO" },
  { "key": "family_office_head",  "label": "Family Office Head" },
  { "key": "others",              "label": "Others", "requiresQualifier": true, "qualifierMaxLength": 60 }
]
```

### Caching

All three endpoints are cacheable (long TTL — 1 day or via ETag) since these are master data that change infrequently.

### Done when

1. All three endpoints live with the locked values.
2. Cacheable headers set (ETag or `Cache-Control: max-age=86400`).
3. FE uses these to populate dropdowns instead of hardcoded enums.

---

# Push process

Once Vinit approves the descriptions:

1. **Delete the existing 22 tickets** in epic `JC-1510` via `DELETE /rest/api/3/issue/{key}` (one call per ticket).
2. **Delete the existing epic** `JC-1510` (or rename / reuse — confirm).
3. **Create a fresh epic** with the same title `Wealth CRM - Lead & Prospect`.
4. **Lookup the 6 assignees by name** via Jira user search (Forum, Gopinath, Vishwas, Vaibhav, Omkar, Arsh). Need their account IDs to set on `assignee`.
5. **Create the 19 stories** with full descriptions, story points, assignee, parent epic, labels (`lead-prospects`, `sprint-1`, plus `be` / `fe`).
6. **Return the mapping** (new ticket IDs).

Before push, confirm:

- **Assignee identification** — do these names match Jira display names exactly? If yes, search-by-name works. If they're different, please share the email addresses or current Jira account IDs.
- **Sprint label** — should I tag all 19 with `sprint-1` (or whatever your sprint convention is)?
- **Reuse `JC-1510` epic?** Or fresh epic ID? Reusing keeps the same epic key, which is cleaner.

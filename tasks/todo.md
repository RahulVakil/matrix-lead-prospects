# JM Matrix — IB & Wealth Lead Management Enhancement

Base version: `140c2ca` on `main` (+ uncommitted local changes from resubmit + filter fixes)

---

## Prerequisite Answers (Section 0)

### 1. Where are roles defined and gated?
- **Enum**: `lib/core/enums/user_role.dart` — values: rm, teamLead, compliance, admin, management, ib
- **Gating helpers** on the enum: `canCreateLead`, `canEditLead`, `canApproveIB`, `canBulkAssign`, `isIB`, etc. (lines 14–23)
- **Not centralized** — role checks are inline in UI files (e.g., `user.role == UserRole.admin`)
- **Action**: Create `lib/core/utils/role_gates.dart` with `canUpdateIBStatus(role)`, `canViewPool(role)`, etc.

### 2. Where is mock data?
- **Users**: `lib/core/services/mock/mock_data_generators.dart` L61–86 (5 RMs, 1 TL, 1 Admin, 1 IB = **8 total, need 10+ RMs**)
- **Leads**: `lib/core/services/mock/mock_lead_repository.dart` L30 (150 leads generated)
- **Pool leads**: `mock_data_generators.dart` `generatePoolLeads()` L246–280 (currently 50 per last change)
- **IB leads**: `lib/core/services/mock/mock_ib_lead_repository.dart` L14–230 (9 IB leads)

### 3. Listing pages
- IB Leads: `lib/features/ib_lead/presentation/pages/my_ib_leads_screen.dart`
- All Leads: `lib/features/lead_inbox/presentation/pages/lead_inbox_screen.dart`
- Clients: `lib/features/clients/presentation/pages/client_list_screen.dart`
- Manage Pool: `lib/features/admin/presentation/pages/manage_pool_screen.dart`

### 4. Notification/toast infra
- `showCompassSnack` at `lib/core/widgets/compass_snackbar.dart:7`
- `NotificationModel` at `lib/core/models/notification_model.dart:21` (has deepLink, isRead)
- `NotificationService` at `lib/core/services/notification_service.dart` — fire-and-forget mock; no persistent queue
- **Action**: Create `lib/core/services/mock_notification_queue.dart` for email queue + in-app queue

### 5. Timeline/history components
- **_RemarkThreadCard** (IB detail L674) — admin/RM back-and-forth with doc attachments
- **_ProgressCard** (IB detail L760) — 30-day cycle status timeline with dot indicators
- **TimelineEntryModel** at `lib/core/models/timeline_entry_model.dart` — view-model for merged timeline
- **Can reuse**: _ProgressCard pattern for the new IBStatus timeline. Will extract to a shared `StatusTimeline` widget.

### 6. Additional findings
- **LeadSubType**: `lib/core/enums/lead_entity_type.dart:11` — already has `other` value. Just need to add "Others" label + free-text field.
- **KeyContactModel**: `lib/core/models/key_contact_model.dart` — only `name` + `designation`. Need to add `mobile` + `email` fields.
- **Declaration default**: `ib_lead_form_state.dart:57` — currently `false`. Change to `true` for RM-5.
- **Duplicate IB check**: Not implemented. `ibLeadIds` is a list allowing multiple. Need to gate.
- **Pool claim**: Claimed leads DO appear in `getLeads()` immediately (inserted at index 0).

---

## Phase 1 — Foundation

- [ ] 1.1 Expand mock users: add 5+ more RMs (total 10), 2nd TL, 2nd Admin, 2nd IB
- [ ] 1.2 Create `lib/core/utils/role_gates.dart` — canUpdateIBStatus, canViewPool, canAllocateLeads, isReadOnlyForStatus
- [ ] 1.3 Create `lib/core/services/mock_notification_queue.dart` — in-app + email mock queue
- [ ] 1.4 Add duplicate IB lead check utility — one active IB per client (status ≠ Closed Won / Closed Lost)
- [ ] 1.5 Seed 12 demo scenarios (A–L per Section 9)

## Phase 2 — RM Quick Wins

- [ ] 2.1 RM-2: Remove AUM from sort dropdown on All Leads
- [ ] 2.2 RM-5: Pre-tick declaration checkbox (default = true)
- [ ] 2.3 RM-3: "Others" in Entity Sub Type — free-text reveal when selected

## Phase 3 — RM Major Flows

- [ ] 3.1 RM-4: Key Contact fields (Name, Designation, Mobile, Email) × 2 contacts on IB capture
- [ ] 3.2 RM-1: Send Back modal — show last remark, mandatory Resolution (≥20 chars), up to 3 doc uploads
- [ ] 3.3 RM-6: Claimed leads → appear in All Leads with "Newly Claimed" badge (24h)
- [ ] 3.4 RM-7: Duplicate IB block — disable Convert to IB if active IB exists

## Phase 4 — Team Lead

- [ ] 4.1 TL-2: "My Lead" badge on leads created by TL + "Show only my leads" filter chip

## Phase 5 — Admin/MIS

- [ ] 5.1 Admin-2: Return to Pool — full modal (reason dropdown + notes + activity log)
- [ ] 5.2 Admin-3: Lead Requests tab (table + Allocate modal with bulk/1-by-1 modes)
- [ ] 5.3 Admin-4: Mapped Leads tab (table + filters + Return to Pool action)
- [ ] 5.4 Admin-5: TODO comment only (skip build)

## Phase 6 — IB

- [ ] 6.1 IB-1: Hide IB Approval module for IB role (nav, quick actions, route guard)

## Phase 7 — Status Tracking (biggest block)

- [ ] 7.1 Extend IbLeadModel with ibStatus, ibStatusHistory, reminderFlags
- [ ] 7.2 Status Update form (dropdown + notes) — visible to RM/TL/IB, read-only Admin
- [ ] 7.3 Status History Timeline — extract to shared widget, newest first
- [ ] 7.4 Reminder/escalation utility — 7-day flag, 9-day escalation + "+1 day" debug button
- [ ] 7.5 Lead routing — Sonia notification, SPOC assignment dropdown, RM+IB notifications on approval
- [ ] 7.6 Role-based access matrix enforcement

## Verification

- [ ] Walk through scenarios A–L manually
- [ ] Login as each role, verify visibility/permissions
- [ ] flutter analyze = 0 errors
- [ ] Build + serve on localhost
- [ ] Update tasks/lessons.md with gotchas

---

*Generated from Claude Code build prompt. Each phase commits separately.*

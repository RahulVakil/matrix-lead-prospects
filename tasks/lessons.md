# Lessons Learned

Track corrections and patterns here so they aren't repeated.

---

## 2026-04-16 — Session 1

### localhost serving
- `flutter run -d chrome` is flaky on Windows (Chrome debug-service websocket fails intermittently). Use `flutter build web --release` + `npx serve build/web -l 8080` for reliable local testing.
- Python on Windows PATH may be the Microsoft Store stub — `npx serve` is the safe fallback.

### IB Lead statuses
- User doesn't want a "Sent For Review" status — creation auto-routes to Admin/MIS. Keep it to 4 user-facing statuses: Lead Created / Sent Back / Approved / Dropped or Closed.
- "Save Draft" CTA on IB capture was removed — every create is an auto-submit to Admin/MIS.

### Prospect Discovery
- User rejected the Prospect Discovery / Excel export feature mid-build ("horrible"). Always get explicit approval on localhost BEFORE committing large new features. Reset to known-good commit immediately when told to discard.

### Alignment
- Floating chips (temperature/status) on list cards should be in a single right-aligned Column, not inline with the title text — prevents drift from varying title lengths.

### DPDP masking
- Apply `PiiDisplay.nameFor()` on list surfaces (Lead Inbox, Get Lead claims, Manage Pool Dropped). Client list left unmasked (implied consent post-onboarding).
- Confidential IB leads: mask company name + contacts from non-creator viewers until lead is assigned.

---

## 2026-04-28 — Session 2

### AskUserQuestion answer fidelity
- **Rule:** When the user picks one option in `AskUserQuestion`, do NOT silently apply behaviors from the rejected options. The discriminator between options is meaningful — the option not picked was actively rejected.
- **Specific incident:** I asked "Add Declined to IbProgressStatus only (terminal, separate from Dropped)" vs "Same as above + treat Declined as a final state that locks further updates". User picked option 1 (no lock). I implemented option 2 anyway, adding `!isProgressTerminal` to `canLogProgress`. Result: Mandate Won and Mandate Lost ended up locking the Update Status button — a regression the user had to flag in the next session.
- **Going forward:** If an option contains added behavior beyond the baseline and the user picks the baseline, treat the added behavior as forbidden until explicitly asked for.

### "Terminal" ≠ "locked"
- A terminal status in an enum means no further automatic state transitions. It does NOT imply the user is locked out of adding documentation, notes, or further updates to the underlying record.
- Before tying a write-lock to enum values (`if (status.isTerminal) hideButton`), confirm intent. Default to permissive: a status name signals position in a workflow, not a permission boundary.

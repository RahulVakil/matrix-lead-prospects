# IB Lead Capture (Riverpod)

This feature is the **only** part of the codebase that uses
[`flutter_riverpod`](https://pub.dev/packages/flutter_riverpod). The rest of
the app uses `flutter_bloc` Cubits.

## Why the boundary

The IB Lead form has a large flat shape (15+ fields, multi-select chips, a
dynamic key-contacts list, computed validation that depends on multiple
fields). Riverpod's `StateNotifier` + `select` gives this kind of fan-out
form ergonomics that would otherwise require a lot of `BlocSelector` plumbing.

The boundary is strict — Riverpod imports may only appear inside
`lib/features/ib_lead/`. Everywhere else continues to use Cubit + GetIt.

## Files
- `notifier/ib_lead_form_state.dart` — immutable state with `copyWith`
- `notifier/ib_lead_form_notifier.dart` — `StateNotifier<IbLeadFormState>`
- `notifier/providers.dart` — provider declarations
- `presentation/pages/ib_lead_capture_screen.dart` — the form UI
- `presentation/pages/ib_checker_queue_screen.dart` — Branch Head queue
- `presentation/pages/ib_lead_detail_screen.dart` — read-only detail
- `presentation/widgets/send_back_sheet.dart` — return-with-remarks sheet

The Riverpod `ProviderScope` is mounted at the top of `main.dart` so other
features keep working as before.

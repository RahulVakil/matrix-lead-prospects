import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/injection.dart';
import '../../../core/repositories/coverage_repository.dart';
import '../../../core/repositories/ib_lead_repository.dart';
import '../../../core/services/notification_service.dart';
import 'ib_lead_form_notifier.dart';
import 'ib_lead_form_state.dart';

/// Family-keyed provider so each open form has its own notifier seeded with
/// any pre-fill values passed in via the [IbLeadFormSeed] key.
class IbLeadFormSeed {
  final String createdById;
  final String createdByName;
  final String? clientName;
  final String? clientCode;
  final String? companyName;
  final String? notes;

  const IbLeadFormSeed({
    required this.createdById,
    required this.createdByName,
    this.clientName,
    this.clientCode,
    this.companyName,
    this.notes,
  });

  @override
  bool operator ==(Object other) =>
      other is IbLeadFormSeed &&
      other.createdById == createdById &&
      other.clientName == clientName &&
      other.clientCode == clientCode &&
      other.companyName == companyName &&
      other.notes == notes;

  @override
  int get hashCode =>
      Object.hash(createdById, clientName, clientCode, companyName, notes);
}

final ibLeadFormProvider = StateNotifierProvider.autoDispose
    .family<IbLeadFormNotifier, IbLeadFormState, IbLeadFormSeed>((ref, seed) {
  return IbLeadFormNotifier(
    repository: getIt<IbLeadRepository>(),
    notifications: getIt<NotificationService>(),
    coverage: getIt<CoverageRepository>(),
    createdById: seed.createdById,
    createdByName: seed.createdByName,
    initialClientName: seed.clientName,
    initialClientCode: seed.clientCode,
    initialCompanyName: seed.companyName,
    initialNotes: seed.notes,
  );
});

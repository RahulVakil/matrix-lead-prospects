import 'package:get_it/get_it.dart';
import '../repositories/activity_repository.dart';
import '../repositories/client_repository.dart';
import '../repositories/coverage_repository.dart';
import '../repositories/ib_lead_repository.dart';
import '../repositories/lead_repository.dart';
import '../repositories/notification_repository.dart';
import '../services/in_app_notification_service.dart';
import '../services/mock/mock_activity_repository.dart';
import '../services/mock/mock_client_repository.dart';
import '../services/mock/mock_coverage_repository.dart';
import '../services/mock/mock_ib_lead_repository.dart';
import '../services/mock/mock_lead_repository.dart';
import '../services/mock/mock_notification_repository.dart';
import '../services/notification_service.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  // Repositories — swap to API implementations when backend is ready
  getIt.registerLazySingleton<LeadRepository>(() => MockLeadRepository());
  getIt.registerLazySingleton<ActivityRepository>(() => MockActivityRepository());
  getIt.registerLazySingleton<CoverageRepository>(() => MockCoverageRepository());
  getIt.registerLazySingleton<ClientRepository>(() => MockClientRepository());
  getIt.registerLazySingleton<IbLeadRepository>(() => MockIbLeadRepository());
  getIt.registerLazySingleton<NotificationRepository>(() => MockNotificationRepository());

  // Notification service — FCM-shaped interface, in-app implementation today.
  getIt.registerLazySingleton<NotificationService>(
    () => InAppNotificationService(getIt<NotificationRepository>()),
  );
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/permissions/app_permissions.dart';
import '../../core/storage/token_storage.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/company/data/organization_repository.dart';
import '../../features/dashboard/data/dashboard_repository.dart';
import '../../features/finance/data/finance_repository.dart';
import '../../features/fleet/data/fleet_repository.dart';
import '../../features/jobs/data/job_repository.dart';
import '../../features/notifications/data/notification_repository.dart';
import '../../features/quotations/data/quotation_repository.dart';
import '../../features/shipments/data/shipment_repository.dart';
import '../../features/trips/data/trip_repository.dart';
import '../models/user.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final unauthorizedTickProvider = StateProvider<int>((ref) => 0);

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    tokenStorage: ref.watch(tokenStorageProvider),
    onUnauthorized: () {
      ref.read(unauthorizedTickProvider.notifier).state++;
    },
  );
});

final authRepositoryProvider = Provider((ref) => AuthRepository(ref.watch(apiClientProvider)));
final dashboardRepositoryProvider = Provider((ref) => DashboardRepository(ref.watch(apiClientProvider)));
final shipmentRepositoryProvider = Provider((ref) => ShipmentRepository(ref.watch(apiClientProvider)));
final quotationRepositoryProvider = Provider((ref) => QuotationRepository(ref.watch(apiClientProvider)));
final jobRepositoryProvider = Provider((ref) => JobRepository(ref.watch(apiClientProvider)));
final tripRepositoryProvider = Provider((ref) => TripRepository(ref.watch(apiClientProvider)));
final fleetRepositoryProvider = Provider((ref) => FleetRepository(ref.watch(apiClientProvider)));
final financeRepositoryProvider = Provider((ref) => FinanceRepository(ref.watch(apiClientProvider)));
final organizationRepositoryProvider = Provider((ref) => OrganizationRepository(ref.watch(apiClientProvider)));
final notificationRepositoryProvider = Provider((ref) => NotificationRepository(ref.watch(apiClientProvider)));

class SessionState {
  const SessionState({
    required this.ready,
    this.token,
    this.user,
  });

  final bool ready;
  final String? token;
  final AppUser? user;

  bool get isAuthenticated => token != null && token!.isNotEmpty && user != null;
  bool get isPendingReview => user?.organization?.isPending ?? false;
  PermissionSet get permissions => user?.permissionSet ?? const PermissionSet([]);
}

class SessionNotifier extends Notifier<SessionState> {
  @override
  SessionState build() {
    ref.listen<int>(unauthorizedTickProvider, (previous, next) {
      if (next > (previous ?? 0)) {
        state = const SessionState(ready: true);
      }
    });
    Future.microtask(restore);
    return const SessionState(ready: false);
  }

  Future<void> restore() async {
    final storage = ref.read(tokenStorageProvider);
    final token = await storage.read();
    if (token == null || token.isEmpty) {
      state = const SessionState(ready: true);
      return;
    }
    try {
      final user = await ref.read(authRepositoryProvider).me();
      state = SessionState(ready: true, token: token, user: user);
    } catch (_) {
      await storage.clear();
      state = const SessionState(ready: true);
    }
  }

  Future<void> apply(AuthSession session) async {
    await ref.read(tokenStorageProvider).write(session.token);
    state = SessionState(ready: true, token: session.token, user: session.user);
  }

  void updateUser(AppUser user) {
    state = SessionState(ready: true, token: state.token, user: user);
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    await ref.read(tokenStorageProvider).clear();
    state = const SessionState(ready: true);
  }
}

final sessionProvider = NotifierProvider<SessionNotifier, SessionState>(SessionNotifier.new);

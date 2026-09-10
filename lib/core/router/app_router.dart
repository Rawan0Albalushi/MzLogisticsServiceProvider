import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/company/presentation/company_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/dispatch/presentation/dispatch_screen.dart';
import '../../features/documents/presentation/documents_screen.dart';
import '../../features/drivers/presentation/drivers_screen.dart';
import '../../features/equipment/presentation/equipment_screen.dart';
import '../../features/finance/presentation/finance_screen.dart';
import '../../features/fleet/presentation/fleet_screen.dart';
import '../../features/jobs/presentation/job_detail_screen.dart';
import '../../features/jobs/presentation/jobs_screen.dart';
import '../../features/more/presentation/more_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/quotations/presentation/quotation_detail_screen.dart';
import '../../features/quotations/presentation/quotations_screen.dart';
import '../../features/shipments/presentation/shipment_detail_screen.dart';
import '../../features/shipments/presentation/shipments_screen.dart';
import '../../features/shipments/presentation/submit_quotation_screen.dart';
import '../../features/trips/presentation/trip_detail_screen.dart';
import '../../features/trips/presentation/trips_screen.dart';
import '../../features/trucks/presentation/truck_form_screen.dart';
import '../../features/trucks/presentation/trucks_screen.dart';
import '../../features/users/presentation/users_screen.dart';
import '../../shared/providers/session_provider.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/async_body.dart';
import 'page_transitions.dart';

class _AuthenticatedShell extends ConsumerWidget {
  const _AuthenticatedShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ready = ref.watch(sessionProvider).ready;
    if (!ready) {
      return const Scaffold(body: LoadingState());
    }
    return AppShell(child: child);
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(sessionProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  GoRoute fadeRoute(
    String path,
    Widget Function(BuildContext context, GoRouterState state) screen,
  ) {
    return GoRoute(
      path: path,
      pageBuilder: (context, state) => subtleFadePage(
        key: state.pageKey,
        child: screen(context, state),
      ),
    );
  }

  return GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: refresh,
    redirect: (context, state) {
      final session = ref.read(sessionProvider);
      final loggingIn = state.matchedLocation == '/login' || state.matchedLocation == '/register';
      if (!session.ready) {
        return null;
      }
      if (!session.isAuthenticated && !loggingIn) {
        return '/login';
      }
      if (session.isAuthenticated && loggingIn) {
        return '/dashboard';
      }
      return null;
    },
    routes: [
      fadeRoute('/login', (context, state) => const LoginScreen()),
      fadeRoute('/register', (context, state) => const RegisterScreen()),
      ShellRoute(
        builder: (context, state, child) => _AuthenticatedShell(child: child),
        routes: [
          fadeRoute('/dashboard', (context, state) => const DashboardScreen()),
          fadeRoute('/shipments', (context, state) => const ShipmentsScreen()),
          fadeRoute(
            '/shipments/:id',
            (context, state) => ShipmentDetailScreen(id: int.parse(state.pathParameters['id']!)),
          ),
          fadeRoute(
            '/shipments/:id/quote',
            (context, state) => SubmitQuotationScreen(shipmentId: int.parse(state.pathParameters['id']!)),
          ),
          fadeRoute('/quotations', (context, state) => const QuotationsScreen()),
          fadeRoute(
            '/quotations/:id',
            (context, state) => QuotationDetailScreen(id: int.parse(state.pathParameters['id']!)),
          ),
          fadeRoute('/jobs', (context, state) => const JobsScreen()),
          fadeRoute(
            '/jobs/:id',
            (context, state) => JobDetailScreen(id: int.parse(state.pathParameters['id']!)),
          ),
          fadeRoute('/trips', (context, state) => const TripsScreen()),
          fadeRoute(
            '/trips/:id',
            (context, state) => TripDetailScreen(id: int.parse(state.pathParameters['id']!)),
          ),
          fadeRoute('/dispatch', (context, state) => const DispatchScreen()),
          fadeRoute('/fleet', (context, state) => const FleetScreen()),
          fadeRoute('/trucks', (context, state) => const TrucksScreen()),
          fadeRoute('/trucks/new', (context, state) => const TruckFormScreen()),
          fadeRoute(
            '/trucks/:id/edit',
            (context, state) => TruckFormScreen(truckId: int.parse(state.pathParameters['id']!)),
          ),
          fadeRoute('/equipment', (context, state) => const EquipmentScreen()),
          fadeRoute('/drivers', (context, state) => const DriversScreen()),
          fadeRoute('/documents', (context, state) => const DocumentsScreen()),
          fadeRoute('/finance', (context, state) => const FinanceScreen()),
          fadeRoute('/notifications', (context, state) => const NotificationsScreen()),
          fadeRoute('/company', (context, state) => const CompanyScreen()),
          fadeRoute('/users', (context, state) => const UsersScreen()),
          fadeRoute('/profile', (context, state) => const ProfileScreen()),
          fadeRoute('/more', (context, state) => const MoreScreen()),
        ],
      ),
    ],
  );
});

class AppPermissions {
  const AppPermissions._();

  static const dashboardView = 'dashboard.view';
  static const fleetView = 'fleet.view';
  static const fleetManage = 'fleet.manage';
  static const driversView = 'drivers.view';
  static const driversManage = 'drivers.manage';
  static const shipmentsView = 'shipments.view';
  static const quotationsView = 'quotations.view';
  static const quotationsCreate = 'quotations.create';
  static const quotationsManage = 'quotations.manage';
  static const jobsView = 'jobs.view';
  static const tripsView = 'trips.view';
  static const tripsAssign = 'trips.assign';
  static const tripsUpdate = 'trips.update';
  static const paymentsView = 'payments.view';
  static const invoicesView = 'invoices.view';
  static const settlementsView = 'settlements.view';
  static const usersManage = 'users.manage';
  static const companyManage = 'company.manage';
  static const trackingView = 'tracking.view';
  static const podView = 'pod.view';

  static const List<String> roleCatalog = [
    'users.roleProviderAdmin',
    'users.roleOperations',
    'users.roleDispatcher',
    'users.roleFleetManager',
    'users.roleFinance',
    'users.roleQuotation',
    'users.roleViewer',
  ];
}

class PermissionSet {
  const PermissionSet(this.values);

  final List<String> values;

  bool can(String permission) => values.contains(permission);

  bool any(List<String> permissions) => permissions.any(can);
}

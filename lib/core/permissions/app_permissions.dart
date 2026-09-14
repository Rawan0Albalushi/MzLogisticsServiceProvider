class PermissionGroup {
  const PermissionGroup({
    required this.id,
    required this.keys,
  });

  final String id;
  final List<String> keys;
}

class ProviderRoleGuide {
  const ProviderRoleGuide({
    required this.id,
    required this.backendName,
    required this.labelKey,
    required this.permissions,
  });

  final String id;
  final String backendName;
  final String labelKey;
  final List<String> permissions;

  String get nameKey => 'users.roleName.$id';

  bool grants(String permission) => permissions.contains(permission);

  int grantedIn(PermissionGroup group) => group.keys.where(grants).length;

  bool matches(Iterable<String> roles) {
    return roles.any((role) {
      final value = role.trim().toLowerCase();
      return value == backendName.toLowerCase() || value == id.toLowerCase();
    });
  }
}

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
  static const settlementsRequest = 'settlements.request';
  static const walletsView = 'wallets.view';
  static const usersManage = 'users.manage';
  static const rolesManage = 'roles.manage';
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

  static const List<PermissionGroup> groups = [
    PermissionGroup(id: 'overview', keys: [dashboardView]),
    PermissionGroup(
      id: 'operations',
      keys: [
        shipmentsView,
        quotationsView,
        quotationsCreate,
        quotationsManage,
        jobsView,
        tripsView,
        tripsAssign,
        tripsUpdate,
        trackingView,
        podView,
      ],
    ),
    PermissionGroup(
      id: 'fleet',
      keys: [fleetView, fleetManage, driversView, driversManage],
    ),
    PermissionGroup(
      id: 'finance',
      keys: [paymentsView, invoicesView, settlementsView, settlementsRequest, walletsView],
    ),
    PermissionGroup(
      id: 'workspace',
      keys: [usersManage, rolesManage, companyManage],
    ),
  ];

  static const List<ProviderRoleGuide> roleGuides = [
    ProviderRoleGuide(
      id: 'providerAdmin',
      backendName: 'Provider Admin',
      labelKey: 'users.roleProviderAdmin',
      permissions: [
        dashboardView,
        companyManage,
        usersManage,
        rolesManage,
        fleetView,
        fleetManage,
        driversView,
        driversManage,
        shipmentsView,
        quotationsView,
        quotationsCreate,
        quotationsManage,
        jobsView,
        tripsView,
        tripsAssign,
        tripsUpdate,
        trackingView,
        podView,
        paymentsView,
        invoicesView,
        settlementsView,
        settlementsRequest,
        walletsView,
      ],
    ),
    ProviderRoleGuide(
      id: 'operations',
      backendName: 'Operations',
      labelKey: 'users.roleOperations',
      permissions: [
        dashboardView,
        jobsView,
        tripsView,
        tripsAssign,
        tripsUpdate,
        fleetView,
        driversView,
        trackingView,
        podView,
      ],
    ),
    ProviderRoleGuide(
      id: 'dispatcher',
      backendName: 'Dispatcher',
      labelKey: 'users.roleDispatcher',
      permissions: [dashboardView, tripsView, tripsAssign, fleetView, driversView, jobsView],
    ),
    ProviderRoleGuide(
      id: 'fleetManager',
      backendName: 'Fleet Manager',
      labelKey: 'users.roleFleetManager',
      permissions: [dashboardView, fleetView, fleetManage, driversView],
    ),
    ProviderRoleGuide(
      id: 'finance',
      backendName: 'Finance',
      labelKey: 'users.roleFinance',
      permissions: [dashboardView, paymentsView, invoicesView, settlementsView, settlementsRequest, walletsView],
    ),
    ProviderRoleGuide(
      id: 'quotation',
      backendName: 'Quotation / Sales',
      labelKey: 'users.roleQuotation',
      permissions: [dashboardView, shipmentsView, quotationsView, quotationsCreate, quotationsManage],
    ),
    ProviderRoleGuide(
      id: 'viewer',
      backendName: 'Viewer',
      labelKey: 'users.roleViewer',
      permissions: [dashboardView, shipmentsView, quotationsView, jobsView, tripsView],
    ),
  ];

  static const List<String> catalogKeys = [
    dashboardView,
    shipmentsView,
    quotationsView,
    quotationsCreate,
    quotationsManage,
    jobsView,
    tripsView,
    tripsAssign,
    tripsUpdate,
    trackingView,
    podView,
    fleetView,
    fleetManage,
    driversView,
    driversManage,
    paymentsView,
    invoicesView,
    settlementsView,
    settlementsRequest,
    walletsView,
    usersManage,
    rolesManage,
    companyManage,
  ];

  static String permissionLabelKey(String permission) {
    return 'users.perm_${permission.replaceAll('.', '_')}';
  }

  static String groupLabelKey(String groupId) => 'users.group_$groupId';
}

class PermissionSet {
  const PermissionSet(this.values);

  final List<String> values;

  bool can(String permission) => values.contains(permission);

  bool any(List<String> permissions) => permissions.any(can);
}

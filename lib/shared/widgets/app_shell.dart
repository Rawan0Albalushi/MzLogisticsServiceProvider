import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/permissions/app_permissions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/breakpoints.dart';
import '../providers/session_provider.dart';
import 'confirm_dialog.dart';

class NavDestination {
  const NavDestination({
    required this.path,
    required this.labelKey,
    required this.icon,
    this.permission,
    this.anyPermissions,
  });

  final String path;
  final String labelKey;
  final IconData icon;
  final String? permission;
  final List<String>? anyPermissions;
}

const sidebarDestinations = <NavDestination>[
  NavDestination(path: '/dashboard', labelKey: 'nav.dashboard', icon: Icons.space_dashboard_outlined, permission: AppPermissions.dashboardView),
  NavDestination(path: '/shipments', labelKey: 'nav.shipments', icon: Icons.local_shipping_outlined, permission: AppPermissions.shipmentsView),
  NavDestination(path: '/quotations', labelKey: 'nav.quotations', icon: Icons.request_quote_outlined, permission: AppPermissions.quotationsView),
  NavDestination(path: '/jobs', labelKey: 'nav.jobs', icon: Icons.work_outline, permission: AppPermissions.jobsView),
  NavDestination(path: '/trips', labelKey: 'nav.trips', icon: Icons.route_outlined, permission: AppPermissions.tripsView),
  NavDestination(path: '/dispatch', labelKey: 'nav.dispatch', icon: Icons.assignment_ind_outlined, permission: AppPermissions.tripsAssign),
  NavDestination(path: '/fleet', labelKey: 'nav.fleet', icon: Icons.agriculture_outlined, permission: AppPermissions.fleetView),
  NavDestination(path: '/trucks', labelKey: 'nav.trucks', icon: Icons.fire_truck_outlined, permission: AppPermissions.fleetView),
  NavDestination(path: '/equipment', labelKey: 'nav.equipment', icon: Icons.handyman_outlined, permission: AppPermissions.fleetView),
  NavDestination(path: '/drivers', labelKey: 'nav.drivers', icon: Icons.badge_outlined, permission: AppPermissions.driversView),
  NavDestination(path: '/documents', labelKey: 'nav.documents', icon: Icons.folder_outlined, permission: AppPermissions.fleetView),
  NavDestination(
    path: '/finance',
    labelKey: 'nav.finance',
    icon: Icons.account_balance_outlined,
    anyPermissions: [AppPermissions.paymentsView, AppPermissions.invoicesView, AppPermissions.settlementsView],
  ),
  NavDestination(path: '/notifications', labelKey: 'nav.notifications', icon: Icons.notifications_outlined),
  NavDestination(path: '/company', labelKey: 'nav.company', icon: Icons.apartment_outlined, permission: AppPermissions.companyManage),
  NavDestination(path: '/users', labelKey: 'nav.users', icon: Icons.groups_outlined, permission: AppPermissions.usersManage),
  NavDestination(path: '/profile', labelKey: 'nav.profile', icon: Icons.person_outline),
];

List<NavDestination> visibleDestinations(PermissionSet permissions) {
  return sidebarDestinations.where((item) {
    if (item.permission != null && !permissions.can(item.permission!)) {
      return false;
    }
    if (item.anyPermissions != null && !permissions.any(item.anyPermissions!)) {
      return false;
    }
    return true;
  }).toList();
}

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final items = visibleDestinations(session.permissions);
    final location = GoRouterState.of(context).uri.path;
    final desktop = Breakpoints.isDesktop(context);

    if (desktop) {
      return Scaffold(
        body: Row(
          children: [
            _Sidebar(items: items, location: location),
            Expanded(
              child: Column(
                children: [
                  _TopBar(location: location),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final maxW = Breakpoints.contentMaxWidth(context);
                        final width = constraints.maxWidth < maxW ? constraints.maxWidth : maxW;
                        return Align(
                          alignment: Alignment.topCenter,
                          child: SizedBox(
                            width: width,
                            height: constraints.maxHeight,
                            child: child,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final mobileTabs = _mobileTabs(items);
    final currentIndex = _mobileIndex(mobileTabs, location);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr(_titleKey(location))),
        actions: [
          IconButton(
            tooltip: context.tr('nav.notifications'),
            onPressed: () => context.go('/notifications'),
            icon: const Icon(Icons.notifications_outlined),
          ),
          IconButton(
            tooltip: context.tr('nav.language'),
            onPressed: () => ref.read(localeControllerProvider.notifier).toggle(),
            icon: const Icon(Icons.language),
          ),
        ],
      ),
      drawer: Drawer(child: _Sidebar(items: items, location: location, inDrawer: true)),
      body: child,
      bottomNavigationBar: mobileTabs.length < 2
          ? null
          : NavigationBar(
              selectedIndex: currentIndex < 0 ? 0 : currentIndex,
              onDestinationSelected: (index) {
                if (index == mobileTabs.length - 1 && mobileTabs.last.path == '/more') {
                  context.go('/more');
                  return;
                }
                context.go(mobileTabs[index].path);
              },
              destinations: [
                for (final item in mobileTabs)
                  NavigationDestination(
                    icon: Icon(item.icon),
                    label: context.tr(item.labelKey),
                  ),
              ],
            ),
    );
  }

  List<NavDestination> _mobileTabs(List<NavDestination> items) {
    final preferred = ['/dashboard', '/shipments', '/jobs', '/fleet'];
    final tabs = <NavDestination>[];
    for (final path in preferred) {
      final match = items.where((item) => item.path == path);
      if (match.isNotEmpty) {
        tabs.add(match.first);
      }
    }
    tabs.add(const NavDestination(path: '/more', labelKey: 'nav.more', icon: Icons.more_horiz));
    return tabs;
  }

  int _mobileIndex(List<NavDestination> tabs, String location) {
    if (location == '/more' ||
        location == '/profile' ||
        location == '/company' ||
        location == '/users' ||
        location == '/finance' ||
        location == '/notifications' ||
        location == '/quotations' ||
        location == '/trips' ||
        location == '/dispatch' ||
        location == '/trucks' ||
        location == '/equipment' ||
        location == '/drivers' ||
        location == '/documents') {
      return tabs.length - 1;
    }
    final index = tabs.indexWhere((item) => location == item.path || location.startsWith('${item.path}/'));
    return index;
  }

  String _titleKey(String location) {
    if (location.startsWith('/shipments')) return 'nav.shipments';
    if (location.startsWith('/quotations')) return 'nav.quotations';
    if (location.startsWith('/jobs')) return 'nav.jobs';
    if (location.startsWith('/trips')) return 'nav.trips';
    if (location.startsWith('/dispatch')) return 'nav.dispatch';
    if (location.startsWith('/trucks')) return 'nav.trucks';
    if (location.startsWith('/equipment')) return 'nav.equipment';
    if (location.startsWith('/drivers')) return 'nav.drivers';
    if (location.startsWith('/documents')) return 'nav.documents';
    if (location.startsWith('/finance')) return 'nav.finance';
    if (location.startsWith('/notifications')) return 'nav.notifications';
    if (location.startsWith('/company')) return 'nav.company';
    if (location.startsWith('/users')) return 'nav.users';
    if (location.startsWith('/profile')) return 'nav.profile';
    if (location.startsWith('/more')) return 'nav.more';
    if (location.startsWith('/fleet')) return 'nav.fleet';
    return 'nav.dashboard';
  }
}

class _TopBar extends ConsumerWidget {
  const _TopBar({required this.location});

  final String location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider).user;
    return Container(
      height: 64,
      padding: EdgeInsets.symmetric(horizontal: Breakpoints.isLarge(context) ? 32 : 24),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Text(
            context.tr(_desktopTitle(location)),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () => ref.read(localeControllerProvider.notifier).toggle(),
            icon: const Icon(Icons.language, size: 18),
            label: Text(context.tr('nav.language')),
          ),
          IconButton(
            tooltip: context.tr('nav.notifications'),
            onPressed: () => context.go('/notifications'),
            icon: const Icon(Icons.notifications_outlined),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => context.go('/profile'),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(user?.name ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  user?.organization?.name ?? user?.primaryRole ?? '',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _desktopTitle(String location) {
    if (location.startsWith('/shipments')) return 'nav.shipments';
    if (location.startsWith('/quotations')) return 'nav.quotations';
    if (location.startsWith('/jobs')) return 'nav.jobs';
    if (location.startsWith('/trips')) return 'nav.trips';
    if (location.startsWith('/dispatch')) return 'nav.dispatch';
    if (location.startsWith('/trucks')) return 'nav.trucks';
    if (location.startsWith('/equipment')) return 'nav.equipment';
    if (location.startsWith('/drivers')) return 'nav.drivers';
    if (location.startsWith('/documents')) return 'nav.documents';
    if (location.startsWith('/finance')) return 'nav.finance';
    if (location.startsWith('/notifications')) return 'nav.notifications';
    if (location.startsWith('/company')) return 'nav.company';
    if (location.startsWith('/users')) return 'nav.users';
    if (location.startsWith('/profile')) return 'nav.profile';
    if (location.startsWith('/fleet')) return 'nav.fleet';
    return 'nav.dashboard';
  }
}

class _Sidebar extends ConsumerWidget {
  const _Sidebar({
    required this.items,
    required this.location,
    this.inDrawer = false,
  });

  final List<NavDestination> items;
  final String location;
  final bool inDrawer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider).user;
    return Material(
      color: AppColors.sidebar,
      child: SafeArea(
        child: SizedBox(
          width: inDrawer ? null : Breakpoints.sidebarWidth(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('app.name'),
                      style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr('app.tagline'),
                      style: const TextStyle(color: Color(0xFFB7C4CC), fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  children: [
                    for (final item in items)
                      _SideItem(
                        item: item,
                        selected: location == item.path || location.startsWith('${item.path}/'),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextButton.icon(
                  onPressed: () async {
                    final confirmed = await showConfirmDialog(
                      context,
                      message: context.tr('common.logoutConfirm'),
                      confirmLabel: context.tr('nav.logout'),
                    );
                    if (confirmed && context.mounted) {
                      await ref.read(sessionProvider.notifier).logout();
                    }
                  },
                  icon: const Icon(Icons.logout, color: Color(0xFFD7DEE3)),
                  label: Text(
                    context.tr('nav.logout'),
                    style: const TextStyle(color: Color(0xFFD7DEE3)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Text(
                  user?.organization?.name ?? '',
                  style: const TextStyle(color: Color(0xFF8EA0AA), fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SideItem extends StatelessWidget {
  const _SideItem({required this.item, required this.selected});

  final NavDestination item;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: () {
          context.go(item.path);
          if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
            Navigator.of(context).pop();
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.sidebarHover : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: selected
                ? const Border(left: BorderSide(color: AppColors.amber, width: 3))
                : null,
          ),
          child: Row(
            children: [
              Icon(item.icon, size: 18, color: selected ? AppColors.amber : const Color(0xFFD7DEE3)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.tr(item.labelKey),
                  style: TextStyle(
                    color: selected ? AppColors.white : const Color(0xFFD7DEE3),
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

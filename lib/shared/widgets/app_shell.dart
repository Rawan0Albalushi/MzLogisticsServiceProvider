import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/permissions/app_permissions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/page_visuals.dart';
import '../../core/utils/breakpoints.dart';
import '../providers/session_provider.dart';
import 'confirm_dialog.dart';
import 'icon_well.dart';

enum NavSection { operations, fleet, finance, account }

class NavDestination {
  const NavDestination({
    required this.path,
    required this.labelKey,
    required this.icon,
    required this.selectedIcon,
    this.section = NavSection.operations,
    this.permission,
    this.anyPermissions,
  });

  final String path;
  final String labelKey;
  final IconData icon;
  final IconData selectedIcon;
  final NavSection section;
  final String? permission;
  final List<String>? anyPermissions;
}

const sidebarDestinations = <NavDestination>[
  NavDestination(
    path: '/dashboard',
    labelKey: 'nav.dashboard',
    icon: Icons.space_dashboard_outlined,
    selectedIcon: Icons.space_dashboard_rounded,
    permission: AppPermissions.dashboardView,
  ),
  NavDestination(
    path: '/shipments',
    labelKey: 'nav.shipments',
    icon: Icons.local_shipping_outlined,
    selectedIcon: Icons.local_shipping_rounded,
    permission: AppPermissions.shipmentsView,
  ),
  NavDestination(
    path: '/quotations',
    labelKey: 'nav.quotations',
    icon: Icons.request_quote_outlined,
    selectedIcon: Icons.request_quote_rounded,
    permission: AppPermissions.quotationsView,
  ),
  NavDestination(
    path: '/jobs',
    labelKey: 'nav.jobs',
    icon: Icons.work_outline_rounded,
    selectedIcon: Icons.work_rounded,
    permission: AppPermissions.jobsView,
  ),
  NavDestination(
    path: '/trips',
    labelKey: 'nav.trips',
    icon: Icons.route_outlined,
    selectedIcon: Icons.route_rounded,
    permission: AppPermissions.tripsView,
  ),
  NavDestination(
    path: '/dispatch',
    labelKey: 'nav.dispatch',
    icon: Icons.assignment_ind_outlined,
    selectedIcon: Icons.assignment_ind_rounded,
    permission: AppPermissions.tripsAssign,
  ),
  NavDestination(
    path: '/fleet',
    labelKey: 'nav.fleet',
    icon: Icons.agriculture_outlined,
    selectedIcon: Icons.agriculture_rounded,
    section: NavSection.fleet,
    permission: AppPermissions.fleetView,
  ),
  NavDestination(
    path: '/trucks',
    labelKey: 'nav.trucks',
    icon: Icons.fire_truck_outlined,
    selectedIcon: Icons.fire_truck,
    section: NavSection.fleet,
    permission: AppPermissions.fleetView,
  ),
  NavDestination(
    path: '/truck-types',
    labelKey: 'nav.truckTypes',
    icon: Icons.category_outlined,
    selectedIcon: Icons.category_rounded,
    section: NavSection.fleet,
    permission: AppPermissions.fleetManage,
  ),
  NavDestination(
    path: '/equipment',
    labelKey: 'nav.equipment',
    icon: Icons.handyman_outlined,
    selectedIcon: Icons.handyman_rounded,
    section: NavSection.fleet,
    permission: AppPermissions.fleetView,
  ),
  NavDestination(
    path: '/drivers',
    labelKey: 'nav.drivers',
    icon: Icons.badge_outlined,
    selectedIcon: Icons.badge_rounded,
    section: NavSection.fleet,
    permission: AppPermissions.driversView,
  ),
  NavDestination(
    path: '/documents',
    labelKey: 'nav.documents',
    icon: Icons.folder_outlined,
    selectedIcon: Icons.folder_rounded,
    section: NavSection.fleet,
    permission: AppPermissions.fleetView,
  ),
  NavDestination(
    path: '/finance',
    labelKey: 'nav.finance',
    icon: Icons.account_balance_outlined,
    selectedIcon: Icons.account_balance_rounded,
    section: NavSection.finance,
    anyPermissions: [
      AppPermissions.paymentsView,
      AppPermissions.invoicesView,
      AppPermissions.settlementsView,
      AppPermissions.walletsView,
    ],
  ),
  NavDestination(
    path: '/notifications',
    labelKey: 'nav.notifications',
    icon: Icons.notifications_outlined,
    selectedIcon: Icons.notifications_rounded,
    section: NavSection.account,
  ),
  NavDestination(
    path: '/company',
    labelKey: 'nav.company',
    icon: Icons.apartment_outlined,
    selectedIcon: Icons.apartment_rounded,
    section: NavSection.account,
    permission: AppPermissions.companyManage,
  ),
  NavDestination(
    path: '/users',
    labelKey: 'nav.users',
    icon: Icons.groups_outlined,
    selectedIcon: Icons.groups_rounded,
    section: NavSection.account,
    permission: AppPermissions.usersManage,
  ),
  NavDestination(
    path: '/profile',
    labelKey: 'nav.profile',
    icon: Icons.person_outline_rounded,
    selectedIcon: Icons.person_rounded,
    section: NavSection.account,
  ),
];

List<NavDestination> visibleDestinations(SessionState session) {
  return sidebarDestinations.where((item) {
    if (session.isAccountRestricted) {
      if (!session.allowsRestrictedPath(item.path)) {
        return false;
      }
      if (item.path == '/dashboard' || item.path == '/profile') {
        return true;
      }
    }
    if (item.permission != null && !session.permissions.can(item.permission!)) {
      return false;
    }
    if (item.anyPermissions != null && !session.permissions.any(item.anyPermissions!)) {
      return false;
    }
    return true;
  }).toList();
}

String navSectionLabel(NavSection section) {
  return switch (section) {
    NavSection.operations => 'nav.operations',
    NavSection.fleet => 'nav.fleet',
    NavSection.finance => 'nav.finance',
    NavSection.account => 'nav.account',
  };
}

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  static const double _minUsableSize = 48;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final items = visibleDestinations(session);
    final location = GoRouterState.of(context).uri.path;
    final size = MediaQuery.sizeOf(context);
    if (size.width < _minUsableSize || size.height < _minUsableSize) {
      return const ColoredBox(color: AppColors.surface);
    }
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
                    child: ColoredBox(
                      color: AppColors.surface,
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
    final showAppBar = size.width >= 160;
    final showAppBarActions = size.width >= 280;

    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              titleSpacing: 8,
              title: Row(
                children: [
                  Icon(
                    PageVisuals.of(location).icon,
                    size: 20,
                    color: AppColors.teal800,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.tr(_titleKey(location)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              actions: [
                if (showAppBarActions) ...[
                  if (!session.isAccountRestricted)
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
              ],
            )
          : null,
      drawer: Drawer(child: _Sidebar(items: items, location: location, inDrawer: true)),
      body: ColoredBox(color: AppColors.surface, child: child),
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
                    selectedIcon: Icon(item.selectedIcon),
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
    tabs.add(
      const NavDestination(
        path: '/more',
        labelKey: 'nav.more',
        icon: Icons.apps_outlined,
        selectedIcon: Icons.apps_rounded,
        section: NavSection.account,
      ),
    );
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
        location == '/truck-types' ||
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
    if (location.startsWith('/truck-types')) return 'nav.truckTypes';
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
    final initials = _initials(user?.name ?? '');
    return Container(
      height: 64,
      padding: EdgeInsets.symmetric(horizontal: Breakpoints.isLarge(context) ? 32 : 20),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          IconWell(
            icon: PageVisuals.of(location).icon,
            tone: PageVisuals.of(location).tone,
            size: IconWellSize.sm,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.tr(_desktopTitle(location)),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, height: 1.3),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerEnd,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton.icon(
                      onPressed: () => ref.read(localeControllerProvider.notifier).toggle(),
                      icon: const Icon(Icons.language, size: 18),
                      label: Text(context.tr('nav.language')),
                    ),
                    if (!ref.watch(sessionProvider).isAccountRestricted)
                      IconButton(
                        tooltip: context.tr('nav.notifications'),
                        onPressed: () => context.go('/notifications'),
                        icon: const Icon(Icons.notifications_outlined),
                      ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => context.go('/profile'),
                      borderRadius: BorderRadius.circular(24),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.tealSoft,
                            child: Text(
                              initials,
                              style: const TextStyle(
                                color: AppColors.teal800,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 180),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.name ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.w600, height: 1.3),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                Text(
                                  user?.organization?.name ?? user?.primaryRole ?? '',
                                  style: const TextStyle(color: AppColors.muted, fontSize: 12, height: 1.3),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return 'MZ';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
  }

  String _desktopTitle(String location) {
    if (location.startsWith('/shipments')) return 'nav.shipments';
    if (location.startsWith('/quotations')) return 'nav.quotations';
    if (location.startsWith('/jobs')) return 'nav.jobs';
    if (location.startsWith('/trips')) return 'nav.trips';
    if (location.startsWith('/dispatch')) return 'nav.dispatch';
    if (location.startsWith('/truck-types')) return 'nav.truckTypes';
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
    final sections = NavSection.values
        .map((section) => (section: section, items: items.where((item) => item.section == section).toList()))
        .where((group) => group.items.isNotEmpty)
        .toList();

    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.sidebarGradient),
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          child: SizedBox(
            width: inDrawer ? null : Breakpoints.sidebarWidth(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                  child: Row(
                    children: [
                      const BrandMark(),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          context.tr('app.tagline'),
                          style: const TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            height: 1.25,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0x14FFFFFF)),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(10, 12, 10, 16),
                    children: [
                      for (final group in sections) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
                          child: Text(
                            context.tr(navSectionLabel(group.section)).toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.onSidebarMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        for (final item in group.items)
                          _SideItem(
                            item: item,
                            selected: location == item.path || location.startsWith('${item.path}/'),
                          ),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0x14FFFFFF)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
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
                    icon: const Icon(Icons.logout, color: AppColors.onSidebarMuted),
                    label: Text(
                      context.tr('nav.logout'),
                      style: const TextStyle(color: AppColors.onSidebarMuted),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(
                    user?.organization?.name ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.onSidebarMuted, fontSize: 12),
                  ),
                ),
              ],
            ),
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
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0x22FFFFFF) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: selected
                ? const BorderDirectional(start: BorderSide(color: AppColors.coral, width: 3))
                : null,
          ),
          child: Row(
            children: [
              Icon(
                selected ? item.selectedIcon : item.icon,
                size: 18,
                color: selected ? AppColors.coral : AppColors.onSidebarMuted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.tr(item.labelKey),
                  style: TextStyle(
                    color: selected ? AppColors.white : AppColors.onSidebarMuted,
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

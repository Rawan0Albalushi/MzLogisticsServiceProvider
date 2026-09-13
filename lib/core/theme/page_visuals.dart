import 'package:flutter/material.dart';

import 'app_colors.dart';

enum IconTone { teal, coral, info, success, warning, danger, muted }

class PageVisual {
  const PageVisual({
    required this.icon,
    required this.selectedIcon,
    required this.tone,
  });

  final IconData icon;
  final IconData selectedIcon;
  final IconTone tone;
}

class PageVisuals {
  const PageVisuals._();

  static const dashboard = PageVisual(
    icon: Icons.space_dashboard_outlined,
    selectedIcon: Icons.space_dashboard_rounded,
    tone: IconTone.coral,
  );
  static const shipments = PageVisual(
    icon: Icons.local_shipping_outlined,
    selectedIcon: Icons.local_shipping_rounded,
    tone: IconTone.teal,
  );
  static const quotations = PageVisual(
    icon: Icons.request_quote_outlined,
    selectedIcon: Icons.request_quote_rounded,
    tone: IconTone.info,
  );
  static const jobs = PageVisual(
    icon: Icons.work_outline_rounded,
    selectedIcon: Icons.work_rounded,
    tone: IconTone.warning,
  );
  static const trips = PageVisual(
    icon: Icons.route_outlined,
    selectedIcon: Icons.route_rounded,
    tone: IconTone.success,
  );
  static const dispatch = PageVisual(
    icon: Icons.assignment_ind_outlined,
    selectedIcon: Icons.assignment_ind_rounded,
    tone: IconTone.warning,
  );
  static const fleet = PageVisual(
    icon: Icons.agriculture_outlined,
    selectedIcon: Icons.agriculture_rounded,
    tone: IconTone.coral,
  );
  static const trucks = PageVisual(
    icon: Icons.fire_truck_outlined,
    selectedIcon: Icons.fire_truck,
    tone: IconTone.teal,
  );
  static const truckTypes = PageVisual(
    icon: Icons.category_outlined,
    selectedIcon: Icons.category_rounded,
    tone: IconTone.muted,
  );
  static const equipment = PageVisual(
    icon: Icons.handyman_outlined,
    selectedIcon: Icons.handyman_rounded,
    tone: IconTone.info,
  );
  static const drivers = PageVisual(
    icon: Icons.badge_outlined,
    selectedIcon: Icons.badge_rounded,
    tone: IconTone.success,
  );
  static const documents = PageVisual(
    icon: Icons.folder_outlined,
    selectedIcon: Icons.folder_rounded,
    tone: IconTone.muted,
  );
  static const finance = PageVisual(
    icon: Icons.account_balance_outlined,
    selectedIcon: Icons.account_balance_rounded,
    tone: IconTone.success,
  );
  static const notifications = PageVisual(
    icon: Icons.notifications_outlined,
    selectedIcon: Icons.notifications_rounded,
    tone: IconTone.coral,
  );
  static const company = PageVisual(
    icon: Icons.apartment_outlined,
    selectedIcon: Icons.apartment_rounded,
    tone: IconTone.teal,
  );
  static const users = PageVisual(
    icon: Icons.groups_outlined,
    selectedIcon: Icons.groups_rounded,
    tone: IconTone.info,
  );
  static const profile = PageVisual(
    icon: Icons.person_outline_rounded,
    selectedIcon: Icons.person_rounded,
    tone: IconTone.muted,
  );
  static const more = PageVisual(
    icon: Icons.apps_outlined,
    selectedIcon: Icons.apps_rounded,
    tone: IconTone.teal,
  );

  static const _routes = <({String prefix, PageVisual visual})>[
    (prefix: '/truck-types', visual: truckTypes),
    (prefix: '/shipments', visual: shipments),
    (prefix: '/quotations', visual: quotations),
    (prefix: '/jobs', visual: jobs),
    (prefix: '/trips', visual: trips),
    (prefix: '/dispatch', visual: dispatch),
    (prefix: '/trucks', visual: trucks),
    (prefix: '/equipment', visual: equipment),
    (prefix: '/drivers', visual: drivers),
    (prefix: '/documents', visual: documents),
    (prefix: '/finance', visual: finance),
    (prefix: '/notifications', visual: notifications),
    (prefix: '/company', visual: company),
    (prefix: '/users', visual: users),
    (prefix: '/profile', visual: profile),
    (prefix: '/fleet', visual: fleet),
    (prefix: '/more', visual: more),
    (prefix: '/dashboard', visual: dashboard),
  ];

  static PageVisual of(String path) {
    for (final route in _routes) {
      if (path == route.prefix || path.startsWith('${route.prefix}/')) {
        return route.visual;
      }
    }
    return dashboard;
  }
}

extension IconToneColors on IconTone {
  Color get foreground {
    return switch (this) {
      IconTone.teal => AppColors.teal800,
      IconTone.coral => AppColors.coralDeep,
      IconTone.info => AppColors.info,
      IconTone.success => AppColors.success,
      IconTone.warning => AppColors.warning,
      IconTone.danger => AppColors.danger,
      IconTone.muted => AppColors.muted,
    };
  }

  Color get background {
    return switch (this) {
      IconTone.teal => AppColors.tealSoft,
      IconTone.coral => AppColors.coralSoft,
      IconTone.info => AppColors.infoSoft,
      IconTone.success => AppColors.successSoft,
      IconTone.warning => AppColors.warningSoft,
      IconTone.danger => AppColors.dangerSoft,
      IconTone.muted => AppColors.chipBg,
    };
  }
}

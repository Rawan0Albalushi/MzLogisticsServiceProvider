import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/permissions/app_permissions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/page_visuals.dart';
import '../../../core/utils/breakpoints.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/providers/session_provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_page.dart';
import '../../../shared/widgets/async_body.dart';
import '../../../shared/widgets/icon_well.dart';
import '../../../shared/widgets/info_grid.dart';
import '../../../shared/widgets/metric_card.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/status_badge.dart';

final fleetTrucksProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(fleetRepositoryProvider).trucks(page: 1);
});

final fleetDriversProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(fleetRepositoryProvider).drivers(page: 1);
});

final fleetEquipmentProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(fleetRepositoryProvider).equipment(page: 1);
});

class FleetScreen extends ConsumerWidget {
  const FleetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    if (!session.permissions.can(AppPermissions.fleetView)) {
      return const NoPermissionState();
    }
    final trucks = ref.watch(fleetTrucksProvider);
    final drivers = ref.watch(fleetDriversProvider);
    final equipment = ref.watch(fleetEquipmentProvider);
    final canDrivers = session.permissions.can(AppPermissions.driversView);
    final locale = Localizations.localeOf(context).languageCode;
    final available = trucks.asData?.value.items.where((truck) => truck.isAvailable).length;

    return AppPage(
      child: ListView(
        children: [
          PageHeader(title: context.tr('fleet.title'), subtitle: context.tr('fleet.subtitle')),
          const SizedBox(height: 12),
          _FleetNote(text: context.tr('fleet.belongsToCompany')),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = Breakpoints.metricColumns(constraints.maxWidth);
              final gap = 12.0;
              final itemWidth = (constraints.maxWidth - (gap * (columns - 1))) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: MetricCard(
                      label: context.tr('fleet.trucksSummary'),
                      value: trucks.asData?.value.total.toString() ?? '—',
                      icon: Icons.fire_truck_outlined,
                      tone: IconTone.teal,
                      hint: available == null ? null : '${context.tr('fleet.availableNow')}: $available',
                      onTap: () => context.go('/trucks'),
                    ),
                  ),
                  if (canDrivers)
                    SizedBox(
                      width: itemWidth,
                      child: MetricCard(
                        label: context.tr('fleet.driversSummary'),
                        value: drivers.asData?.value.total.toString() ?? '—',
                        icon: Icons.badge_outlined,
                        tone: IconTone.success,
                        onTap: () => context.go('/drivers'),
                      ),
                    ),
                  SizedBox(
                    width: itemWidth,
                    child: MetricCard(
                      label: context.tr('fleet.equipmentSummary'),
                      value: equipment.asData?.value.total.toString() ?? '—',
                      icon: Icons.handyman_outlined,
                      tone: IconTone.info,
                      onTap: () => context.go('/equipment'),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          Text(
            context.tr('fleet.shortcuts'),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 720 ? 3 : constraints.maxWidth >= 420 ? 2 : 1;
              final gap = 10.0;
              final width = (constraints.maxWidth - (gap * (columns - 1))) / columns;
              final links = <_Shortcut>[
                _Shortcut('/trucks', 'nav.trucks', Icons.fire_truck_outlined, IconTone.teal),
                if (canDrivers) _Shortcut('/drivers', 'nav.drivers', Icons.badge_outlined, IconTone.success),
                _Shortcut('/equipment', 'nav.equipment', Icons.handyman_outlined, IconTone.info),
                if (session.permissions.can(AppPermissions.fleetManage))
                  _Shortcut('/truck-types', 'nav.truckTypes', Icons.category_outlined, IconTone.muted),
                _Shortcut('/documents', 'nav.documents', Icons.folder_outlined, IconTone.warning),
              ];
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final link in links)
                    SizedBox(
                      width: width,
                      child: _ShortcutCard(
                        label: context.tr(link.labelKey),
                        icon: link.icon,
                        tone: link.tone,
                        onTap: () => context.go(link.path),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          ResponsiveSplit(
            breakpoint: 900,
            primary: SectionCard(
              title: context.tr('fleet.recentTrucks'),
              icon: Icons.fire_truck_outlined,
              tone: IconTone.teal,
              child: Column(
                children: [
                  AsyncBody(
                    value: trucks,
                    onRetry: () => ref.invalidate(fleetTrucksProvider),
                    isEmpty: (data) => data.isEmpty,
                    empty: EmptyState(message: context.tr('trucks.empty'), icon: Icons.fire_truck_outlined),
                    builder: (data) {
                      return Column(
                        children: [
                          for (final truck in data.items.take(5))
                            _FleetRow(
                              icon: Icons.fire_truck_outlined,
                              tone: IconTone.teal,
                              title: truck.plateNumber ?? '—',
                              subtitle: [
                                context.l10n.truckType(truck.type, label: truck.typeLabel),
                                if (truck.capacityTons != null)
                                  '${Formatters.number(truck.capacityTons, locale: locale)} ${context.tr('common.tons')}',
                                if (truck.assignedDriver?.name != null) truck.assignedDriver!.name!,
                              ].join(' · '),
                              status: truck.status,
                              onTap: () => context.go('/trucks'),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: AppButton(
                      label: context.tr('common.seeAll'),
                      outlined: true,
                      icon: Icons.arrow_outward_rounded,
                      onPressed: () => context.go('/trucks'),
                    ),
                  ),
                ],
              ),
            ),
            secondary: canDrivers
                ? SectionCard(
                    title: context.tr('fleet.recentDrivers'),
                    icon: Icons.badge_outlined,
                    tone: IconTone.success,
                    child: Column(
                      children: [
                        AsyncBody(
                          value: drivers,
                          onRetry: () => ref.invalidate(fleetDriversProvider),
                          isEmpty: (data) => data.isEmpty,
                          empty: EmptyState(message: context.tr('drivers.empty'), icon: Icons.badge_outlined),
                          builder: (data) {
                            return Column(
                              children: [
                                for (final driver in data.items.take(5))
                                  _FleetRow(
                                    icon: Icons.badge_outlined,
                                    tone: IconTone.success,
                                    title: driver.name ?? '—',
                                    subtitle: [
                                      if (driver.phone != null && driver.phone!.isNotEmpty) driver.phone!,
                                      if (driver.driverProfile?.licenseNumber != null)
                                        driver.driverProfile!.licenseNumber!,
                                    ].join(' · '),
                                    status: driver.driverProfile?.status,
                                    onTap: () => context.go('/drivers'),
                                  ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: AppButton(
                            label: context.tr('common.seeAll'),
                            outlined: true,
                            icon: Icons.arrow_outward_rounded,
                            onPressed: () => context.go('/drivers'),
                          ),
                        ),
                      ],
                    ),
                  )
                : SectionCard(
                    title: context.tr('fleet.recentEquipment'),
                    icon: Icons.handyman_outlined,
                    tone: IconTone.info,
                    child: _EquipmentSnapshot(equipment: equipment, onRetry: () => ref.invalidate(fleetEquipmentProvider)),
                  ),
          ),
          if (canDrivers) ...[
            const SizedBox(height: 12),
            SectionCard(
              title: context.tr('fleet.recentEquipment'),
              icon: Icons.handyman_outlined,
              tone: IconTone.info,
              child: _EquipmentSnapshot(equipment: equipment, onRetry: () => ref.invalidate(fleetEquipmentProvider)),
            ),
          ],
        ],
      ),
    );
  }
}

class _Shortcut {
  const _Shortcut(this.path, this.labelKey, this.icon, this.tone);

  final String path;
  final String labelKey;
  final IconData icon;
  final IconTone tone;
}

class _FleetNote extends StatelessWidget {
  const _FleetNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.tealSoft,
        borderRadius: BorderRadius.circular(AppColors.radius),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const IconWell(icon: Icons.info_outline, tone: IconTone.teal, size: IconWellSize.sm),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(height: 1.45))),
        ],
      ),
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  const _ShortcutCard({
    required this.label,
    required this.icon,
    required this.tone,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconTone tone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              IconWell(icon: icon, tone: tone, size: IconWellSize.sm),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, height: 1.35)),
              ),
              Icon(
                Directionality.of(context) == TextDirection.rtl ? Icons.chevron_left : Icons.chevron_right,
                color: AppColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FleetRow extends StatelessWidget {
  const _FleetRow({
    required this.icon,
    required this.tone,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.status,
  });

  final IconData icon;
  final IconTone tone;
  final String title;
  final String subtitle;
  final String? status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              IconWell(icon: icon, tone: tone, size: IconWellSize.sm),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (subtitle.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                    ],
                  ],
                ),
              ),
              if (status != null) StatusBadge(status: status),
            ],
          ),
        ),
      ),
    );
  }
}

class _EquipmentSnapshot extends ConsumerWidget {
  const _EquipmentSnapshot({required this.equipment, required this.onRetry});

  final AsyncValue equipment;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        AsyncBody(
          value: equipment,
          onRetry: onRetry,
          isEmpty: (data) => data.isEmpty,
          empty: EmptyState(message: context.tr('equipment.empty'), icon: Icons.handyman_outlined),
          builder: (data) {
            return Column(
              children: [
                for (final item in data.items.take(5))
                  _FleetRow(
                    icon: Icons.handyman_outlined,
                    tone: IconTone.info,
                    title: item.name ?? '—',
                    subtitle: [item.type, if (item.quantity != null) '${item.quantity}'].whereType<String>().join(' · '),
                    status: item.status,
                    onTap: () => context.go('/equipment'),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: AppButton(
            label: context.tr('common.seeAll'),
            outlined: true,
            icon: Icons.arrow_outward_rounded,
            onPressed: () => context.go('/equipment'),
          ),
        ),
      ],
    );
  }
}

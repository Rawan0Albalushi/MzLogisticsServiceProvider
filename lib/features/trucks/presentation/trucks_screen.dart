import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/permissions/app_permissions.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/truck.dart';
import '../../../shared/providers/session_provider.dart';
import '../../documents/presentation/required_documents_section.dart';
import '../../fleet/presentation/fleet_screen.dart';
import '../../fleet/presentation/import_fleet_sheet.dart';
import '../../../core/theme/page_visuals.dart';
import '../../../shared/widgets/app_page.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/entity_card.dart';
import '../../../shared/widgets/async_body.dart';
import '../../../shared/widgets/filter_bar.dart';
import '../../../shared/widgets/info_grid.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/record_actions.dart';
import '../../../shared/widgets/record_details_dialog.dart';
import '../../../shared/widgets/responsive_data_view.dart';
import '../../../shared/widgets/status_badge.dart';

final truckStatusProvider = StateProvider<String?>((ref) => null);
final truckSearchProvider = StateProvider<String>((ref) => '');
final truckPageProvider = StateProvider<int>((ref) => 1);

final trucksProvider = FutureProvider.autoDispose((ref) {
  return ref
      .watch(fleetRepositoryProvider)
      .trucks(
        page: ref.watch(truckPageProvider),
        status: ref.watch(truckStatusProvider),
        search: ref.watch(truckSearchProvider),
      );
});

class TrucksScreen extends ConsumerWidget {
  const TrucksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    if (!session.permissions.can(AppPermissions.fleetView)) {
      return const NoPermissionState();
    }
    final locale = Localizations.localeOf(context).languageCode;
    final canManage = session.permissions.can(AppPermissions.fleetManage);
    return AppPage(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            title: context.tr('trucks.title'),
            subtitle: context.tr('app.companyFleetNote'),
            actions: [
              if (canManage) ...[
                AppButton(
                  label: context.tr('trucks.import'),
                  outlined: true,
                  icon: Icons.table_view_outlined,
                  onPressed: () => showFleetImportSheet(
                    context,
                    ref,
                    FleetImportRequest(
                      namespace: 'trucks',
                      templateFilename: 'trucks-import-template.xlsx',
                      downloadTemplate: () => ref
                          .read(fleetRepositoryProvider)
                          .downloadTruckImportTemplate(),
                      importFile: ({required bytes, required filename}) => ref
                          .read(fleetRepositoryProvider)
                          .importTrucks(bytes: bytes, filename: filename),
                      onImported: (ref) {
                        ref.invalidate(trucksProvider);
                        ref.invalidate(fleetTrucksProvider);
                      },
                    ),
                  ),
                ),
                AppButton(
                  label: context.tr('trucks.add'),
                  icon: Icons.add,
                  onPressed: () => context.go('/trucks/new'),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          FilterBar(
            children: [
              FilterSearchField(
                hint: context.tr('common.searchReference'),
                onChanged: (value) {
                  ref.read(truckSearchProvider.notifier).state = value;
                  ref.read(truckPageProvider.notifier).state = 1;
                },
              ),
              FilterSelect(
                options: AppConfig.truckStatuses,
                value: ref.watch(truckStatusProvider),
                onChanged: (value) {
                  ref.read(truckStatusProvider.notifier).state = value;
                  ref.read(truckPageProvider.notifier).state = 1;
                },
                labelOf: context.l10n.status,
              ),
            ],
          ),
          AsyncBody(
            value: ref.watch(trucksProvider),
            onRetry: () => ref.invalidate(trucksProvider),
            isEmpty: (data) => data.isEmpty,
            empty: EmptyState(message: context.tr('trucks.empty')),
            builder: (data) {
              return ResponsiveDataView<Truck>(
                items: data.items,
                onRowTap: (item) => _showTruckDetails(
                  context,
                  item,
                  locale: locale,
                  onEdit: canManage
                      ? () => context.go('/trucks/${item.id}/edit')
                      : null,
                ),
                columns: [
                  DataColumnSpec(context.tr('trucks.plate')),
                  DataColumnSpec(context.tr('common.type')),
                  DataColumnSpec(context.tr('trucks.make')),
                  DataColumnSpec(context.tr('trucks.model')),
                  DataColumnSpec(context.tr('trucks.year')),
                  DataColumnSpec(context.tr('common.capacity')),
                  DataColumnSpec(context.tr('trucks.volume')),
                  DataColumnSpec(context.tr('trucks.assignedDriver')),
                  DataColumnSpec(context.tr('trucks.insurance')),
                  DataColumnSpec(context.tr('common.status')),
                  DataColumnSpec(context.tr('common.actions')),
                ],
                rowCells: (item) => [
                  Text(item.plateNumber ?? ''),
                  Text(
                    context.l10n.truckType(item.type, label: item.typeLabel),
                  ),
                  Text(item.make ?? '—'),
                  Text(item.model ?? '—'),
                  Text(item.year?.toString() ?? '—'),
                  Text(
                    '${Formatters.number(item.capacityTons, locale: locale)} ${context.tr('common.tons')}',
                  ),
                  Text(
                    item.volumeCbm == null
                        ? '—'
                        : '${Formatters.number(item.volumeCbm, locale: locale)} ${context.tr('common.cbm')}',
                  ),
                  Text(item.assignedDriver?.name ?? '—'),
                  Text(
                    Formatters.date(item.insuranceExpiresAt, locale: locale),
                  ),
                  StatusBadge(status: item.status),
                  RecordActions(
                    onView: () => _showTruckDetails(
                      context,
                      item,
                      locale: locale,
                      onEdit: canManage
                          ? () => context.go('/trucks/${item.id}/edit')
                          : null,
                    ),
                    onEdit: canManage
                        ? () => context.go('/trucks/${item.id}/edit')
                        : null,
                  ),
                ],
                cardBuilder: (item) => EntityCard(
                  title: item.plateNumber ?? '',
                  icon: Icons.fire_truck_outlined,
                  tone: IconTone.teal,
                  trailing: StatusBadge(status: item.status),
                  meta: [
                    context.l10n.truckType(item.type, label: item.typeLabel),
                    [item.make, item.model]
                        .where((value) => value != null && value.isNotEmpty)
                        .join(' '),
                    '${Formatters.number(item.capacityTons, locale: locale)} ${context.tr('common.tons')}',
                    if (item.volumeCbm != null)
                      '${Formatters.number(item.volumeCbm, locale: locale)} ${context.tr('common.cbm')}',
                    item.assignedDriver?.name ?? '',
                  ],
                  onTap: () => _showTruckDetails(
                    context,
                    item,
                    locale: locale,
                    onEdit: canManage
                        ? () => context.go('/trucks/${item.id}/edit')
                        : null,
                  ),
                  footer: RecordActions(
                    onView: () => _showTruckDetails(
                      context,
                      item,
                      locale: locale,
                      onEdit: canManage
                          ? () => context.go('/trucks/${item.id}/edit')
                          : null,
                    ),
                    onEdit: canManage
                        ? () => context.go('/trucks/${item.id}/edit')
                        : null,
                  ),
                ),
                pagination: TablePagination(
                  currentPage: data.currentPage,
                  lastPage: data.lastPage,
                  total: data.total,
                  onPage: (page) =>
                      ref.read(truckPageProvider.notifier).state = page,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

void _showTruckDetails(
  BuildContext context,
  Truck truck, {
  required String locale,
  VoidCallback? onEdit,
}) {
  String text(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '—';
    }
    return value;
  }

  String measure(num? value, String unit) {
    if (value == null) {
      return '—';
    }
    return '${Formatters.number(value, locale: locale)} $unit';
  }

  final equipment = truck.equipment
      .map((item) {
        final name = item.name ?? '';
        if (name.isEmpty) {
          return '';
        }
        if (item.quantity == null) {
          return name;
        }
        return '$name · ${item.quantity}';
      })
      .where((line) => line.isNotEmpty)
      .join('\n');

  showRecordDetails(
    context,
    title: context.tr('trucks.details'),
    onEdit: onEdit,
    fields: [
      InfoField(
        label: context.tr('trucks.plate'),
        value: text(truck.plateNumber),
      ),
      InfoField(
        label: context.tr('common.type'),
        value: context.l10n.truckType(truck.type, label: truck.typeLabel),
      ),
      InfoField(
        label: context.tr('common.status'),
        value: context.l10n.status(truck.status),
      ),
      InfoField(label: context.tr('trucks.make'), value: text(truck.make)),
      InfoField(label: context.tr('trucks.model'), value: text(truck.model)),
      InfoField(
        label: context.tr('trucks.year'),
        value: truck.year?.toString() ?? '—',
      ),
      InfoField(
        label: context.tr('trucks.capacityTons'),
        value: measure(truck.capacityTons, context.tr('common.tons')),
      ),
      InfoField(
        label: context.tr('trucks.volume'),
        value: measure(truck.volumeCbm, context.tr('common.cbm')),
      ),
      InfoField(
        label: context.tr('trucks.length'),
        value: truck.cargoLengthM == null
            ? '—'
            : Formatters.number(truck.cargoLengthM, locale: locale),
      ),
      InfoField(
        label: context.tr('trucks.width'),
        value: truck.cargoWidthM == null
            ? '—'
            : Formatters.number(truck.cargoWidthM, locale: locale),
      ),
      InfoField(
        label: context.tr('trucks.height'),
        value: truck.cargoHeightM == null
            ? '—'
            : Formatters.number(truck.cargoHeightM, locale: locale),
      ),
      InfoField(
        label: context.tr('trucks.axles'),
        value: truck.axleCount?.toString() ?? '—',
      ),
      InfoField(
        label: context.tr('trucks.assignedDriver'),
        value: text(truck.assignedDriver?.name),
      ),
      InfoField(
        label: context.tr('trucks.insurance'),
        value: Formatters.date(truck.insuranceExpiresAt, locale: locale),
      ),
      InfoField(
        label: context.tr('trucks.equipmentSection'),
        value: equipment.isEmpty
            ? context.tr('trucks.equipmentEmpty')
            : equipment,
        wide: true,
      ),
    ],
    extra: RequiredDocumentsSection(
      types: const ['insurance', 'vehicle_registration'],
      documents: truck.documents,
    ),
  );
}

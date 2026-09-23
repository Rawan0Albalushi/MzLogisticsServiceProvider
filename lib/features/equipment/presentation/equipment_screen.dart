import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/paginated.dart';
import '../../../core/config/app_config.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/permissions/app_permissions.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/models/equipment.dart';
import '../../../shared/models/truck.dart';
import '../../../shared/providers/session_provider.dart';
import '../../../core/theme/page_visuals.dart';
import '../../../shared/widgets/app_page.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/entity_card.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/async_body.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/filter_bar.dart';
import '../../../shared/widgets/info_grid.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/record_actions.dart';
import '../../../shared/widgets/record_details_dialog.dart';
import '../../../shared/widgets/responsive_data_view.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../fleet/presentation/fleet_screen.dart';
import '../../fleet/presentation/import_fleet_sheet.dart';
import '../../trucks/presentation/trucks_screen.dart';

final equipmentPageProvider = StateProvider<int>((ref) => 1);
final equipmentSearchProvider = StateProvider<String>((ref) => '');
final equipmentStatusProvider = StateProvider<String?>((ref) => null);
final equipmentPlacementProvider = StateProvider<String?>((ref) => null);
final equipmentListProvider = FutureProvider.autoDispose((ref) {
  return ref
      .watch(fleetRepositoryProvider)
      .equipment(
        page: ref.watch(equipmentPageProvider),
        search: ref.watch(equipmentSearchProvider),
        status: ref.watch(equipmentStatusProvider),
        placement: ref.watch(equipmentPlacementProvider),
      );
});

class EquipmentScreen extends ConsumerWidget {
  const EquipmentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    if (!session.permissions.can(AppPermissions.fleetView)) {
      return const NoPermissionState();
    }
    final canManage = session.permissions.can(AppPermissions.fleetManage);
    return AppPage(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            title: context.tr('equipment.title'),
            actions: [
              if (canManage) ...[
                AppButton(
                  label: context.tr('equipment.import'),
                  outlined: true,
                  icon: Icons.table_view_outlined,
                  onPressed: () => showFleetImportSheet(
                    context,
                    ref,
                    FleetImportRequest(
                      namespace: 'equipment',
                      templateFilename: 'equipment-import-template.xlsx',
                      downloadTemplate: () => ref
                          .read(fleetRepositoryProvider)
                          .downloadEquipmentImportTemplate(),
                      importFile: ({required bytes, required filename}) => ref
                          .read(fleetRepositoryProvider)
                          .importEquipment(bytes: bytes, filename: filename),
                      onImported: (ref) {
                        ref.invalidate(equipmentListProvider);
                        ref.invalidate(fleetEquipmentProvider);
                        ref.invalidate(trucksProvider);
                      },
                    ),
                  ),
                ),
                AppButton(
                  label: context.tr('equipment.add'),
                  icon: Icons.add,
                  onPressed: () => _openForm(context, ref),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          FilterBar(
            children: [
              FilterSearchField(
                onChanged: (value) {
                  ref.read(equipmentSearchProvider.notifier).state = value;
                  ref.read(equipmentPageProvider.notifier).state = 1;
                },
              ),
              FilterSelect(
                options: AppConfig.equipmentStatuses,
                value: ref.watch(equipmentStatusProvider),
                onChanged: (value) {
                  ref.read(equipmentStatusProvider.notifier).state = value;
                  ref.read(equipmentPageProvider.notifier).state = 1;
                },
                labelOf: context.l10n.status,
              ),
              FilterSelect(
                options: const ['company', 'truck'],
                value: ref.watch(equipmentPlacementProvider),
                allLabel: context.tr('equipment.placementAll'),
                onChanged: (value) {
                  ref.read(equipmentPlacementProvider.notifier).state = value;
                  ref.read(equipmentPageProvider.notifier).state = 1;
                },
                labelOf: (value) => context.tr(
                  value == 'company'
                      ? 'equipment.placementCompany'
                      : 'equipment.placementTruck',
                ),
              ),
            ],
          ),
          AsyncBody(
            value: ref.watch(equipmentListProvider),
            onRetry: () => ref.invalidate(equipmentListProvider),
            isEmpty: (data) => data.isEmpty,
            empty: EmptyState(message: context.tr('equipment.empty')),
            builder: (data) {
              return ResponsiveDataView<EquipmentItem>(
                items: data.items,
                onRowTap: (item) => _showEquipmentDetails(
                  context,
                  item,
                  onEdit: canManage
                      ? () => _openForm(context, ref, item)
                      : null,
                ),
                columns: [
                  DataColumnSpec(context.tr('equipment.name')),
                  DataColumnSpec(context.tr('common.type')),
                  DataColumnSpec(context.tr('equipment.quantity')),
                  DataColumnSpec(context.tr('equipment.assignment')),
                  DataColumnSpec(context.tr('common.status')),
                  DataColumnSpec(context.tr('common.actions')),
                ],
                rowCells: (item) => [
                  Text(item.name ?? ''),
                  Text(item.type ?? '—'),
                  Text('${item.quantity ?? 0}'),
                  Text(_assignmentLabel(context, item)),
                  StatusBadge(status: item.status),
                  RecordActions(
                    onView: () => _showEquipmentDetails(
                      context,
                      item,
                      onEdit: canManage
                          ? () => _openForm(context, ref, item)
                          : null,
                    ),
                    onEdit: canManage
                        ? () => _openForm(context, ref, item)
                        : null,
                  ),
                ],
                cardBuilder: (item) => EntityCard(
                  title: item.name ?? '',
                  icon: Icons.handyman_outlined,
                  tone: IconTone.info,
                  trailing: StatusBadge(status: item.status),
                  subtitle: item.type,
                  meta: [
                    '${item.quantity ?? 0}',
                    _assignmentLabel(context, item),
                  ],
                  onTap: () => _showEquipmentDetails(
                    context,
                    item,
                    onEdit: canManage
                        ? () => _openForm(context, ref, item)
                        : null,
                  ),
                  footer: RecordActions(
                    onView: () => _showEquipmentDetails(
                      context,
                      item,
                      onEdit: canManage
                          ? () => _openForm(context, ref, item)
                          : null,
                    ),
                    onEdit: canManage
                        ? () => _openForm(context, ref, item)
                        : null,
                  ),
                ),
                pagination: TablePagination(
                  currentPage: data.currentPage,
                  lastPage: data.lastPage,
                  total: data.total,
                  onPage: (page) =>
                      ref.read(equipmentPageProvider.notifier).state = page,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, [
    EquipmentItem? existing,
  ]) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final type = TextEditingController(text: existing?.type ?? '');
    final quantity = TextEditingController(text: '${existing?.quantity ?? 1}');
    var status = existing?.status ?? 'available';
    var truckValue = existing?.truckId?.toString() ?? '';
    final formKey = GlobalKey<FormState>();
    final trucksFuture = ref.read(fleetRepositoryProvider).trucks(perPage: 100);
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            context.tr(existing == null ? 'equipment.add' : 'equipment.edit'),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppTextField(
                      label: context.tr('equipment.name'),
                      controller: name,
                      required: true,
                      validator: (value) => AppValidators.required(
                        value,
                        context.tr('validation.required'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: context.tr('common.type'),
                      controller: type,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: context.tr('equipment.quantity'),
                      controller: quantity,
                      required: true,
                      keyboardType: TextInputType.number,
                      validator: (value) => AppValidators.positiveInt(
                        value,
                        context.tr('validation.positive'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    StatefulBuilder(
                      builder: (context, setState) {
                        return Column(
                          children: [
                            AppDropdown<String>(
                              label: context.tr('common.status'),
                              value: status,
                              items: [
                                for (final item in AppConfig.equipmentStatuses)
                                  DropdownMenuItem(
                                    value: item,
                                    child: Text(context.l10n.status(item)),
                                  ),
                              ],
                              onChanged: (value) =>
                                  setState(() => status = value ?? status),
                            ),
                            const SizedBox(height: 12),
                            FutureBuilder<Paginated<Truck>>(
                              future: trucksFuture,
                              builder: (context, snapshot) {
                                final trucks = [
                                  ...snapshot.data?.items ?? const <Truck>[],
                                ];
                                final selectedId = int.tryParse(truckValue);
                                if (selectedId != null &&
                                    !trucks.any(
                                      (truck) => truck.id == selectedId,
                                    )) {
                                  trucks.insert(
                                    0,
                                    Truck(
                                      id: selectedId,
                                      plateNumber: existing?.truckPlate,
                                    ),
                                  );
                                }
                                return AppDropdown<String>(
                                  label: context.tr('equipment.assignment'),
                                  value: truckValue,
                                  items: [
                                    DropdownMenuItem(
                                      value: '',
                                      child: Text(
                                        context.tr('equipment.companyPool'),
                                      ),
                                    ),
                                    for (final truck in trucks)
                                      DropdownMenuItem(
                                        value: '${truck.id}',
                                        child: Text(
                                          truck.plateNumber ?? '${truck.id}',
                                        ),
                                      ),
                                  ],
                                  onChanged: (value) =>
                                      setState(() => truckValue = value ?? ''),
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            Text(
                              context.tr('equipment.assignmentHint'),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.tr('common.cancel')),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) {
                  return;
                }
                final payload = {
                  'name': name.text.trim(),
                  'type': type.text.trim(),
                  'quantity': int.parse(quantity.text),
                  'status': status,
                  'truck_id': truckValue.isEmpty ? null : int.parse(truckValue),
                };
                try {
                  final repository = ref.read(fleetRepositoryProvider);
                  if (existing == null) {
                    await repository.createEquipment(payload);
                  } else {
                    await repository.updateEquipment(existing.id, payload);
                  }
                  ref.invalidate(equipmentListProvider);
                  ref.invalidate(fleetEquipmentProvider);
                  ref.invalidate(trucksProvider);
                  if (context.mounted) {
                    Navigator.pop(context);
                    showAppSnack(
                      context,
                      context.tr(
                        existing == null
                            ? 'equipment.saved'
                            : 'equipment.updated',
                      ),
                    );
                  }
                } on ApiException catch (error) {
                  if (context.mounted) {
                    showAppSnack(context, error.message);
                  }
                }
              },
              child: Text(context.tr('common.save')),
            ),
          ],
        );
      },
    );
    name.dispose();
    type.dispose();
    quantity.dispose();
  }
}

void _showEquipmentDetails(
  BuildContext context,
  EquipmentItem item, {
  VoidCallback? onEdit,
}) {
  String text(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '—';
    }
    return value;
  }

  showRecordDetails(
    context,
    title: context.tr('equipment.details'),
    onEdit: onEdit,
    fields: [
      InfoField(label: context.tr('equipment.name'), value: text(item.name)),
      InfoField(label: context.tr('common.type'), value: text(item.type)),
      InfoField(
        label: context.tr('equipment.quantity'),
        value: '${item.quantity ?? 0}',
      ),
      InfoField(
        label: context.tr('common.status'),
        value: context.l10n.status(item.status),
      ),
      InfoField(
        label: context.tr('equipment.assignment'),
        value: _assignmentLabel(context, item),
        wide: true,
      ),
    ],
  );
}

String _assignmentLabel(BuildContext context, EquipmentItem item) {
  final plate = item.truckPlate;
  if (item.truckId == null) {
    return context.tr('equipment.companyPool');
  }
  if (plate == null || plate.isEmpty) {
    return context.tr('equipment.placementTruck');
  }
  return context.tr('equipment.attachedTo', {'plate': plate});
}

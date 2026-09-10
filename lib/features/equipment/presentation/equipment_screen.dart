import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/config/app_config.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/permissions/app_permissions.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/models/equipment.dart';
import '../../../shared/providers/session_provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/async_body.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/responsive_data_view.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../fleet/presentation/fleet_screen.dart';

final equipmentPageProvider = StateProvider<int>((ref) => 1);
final equipmentListProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(fleetRepositoryProvider).equipment(page: ref.watch(equipmentPageProvider));
});

class EquipmentScreen extends ConsumerWidget {
  const EquipmentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    if (!session.permissions.can(AppPermissions.fleetView)) {
      return const NoPermissionState();
    }
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          PageHeader(
            title: context.tr('equipment.title'),
            actions: [
              if (session.permissions.can(AppPermissions.fleetManage))
                AppButton(
                  label: context.tr('equipment.add'),
                  icon: Icons.add,
                  onPressed: () => _openForm(context, ref),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: AsyncBody(
              value: ref.watch(equipmentListProvider),
              onRetry: () => ref.invalidate(equipmentListProvider),
              isEmpty: (data) => data.isEmpty,
              empty: EmptyState(message: context.tr('equipment.empty')),
              builder: (data) {
                return ListView(
                  children: [
                    ResponsiveDataView<EquipmentItem>(
                      items: data.items,
                      columns: [
                        DataColumnSpec(context.tr('equipment.name')),
                        DataColumnSpec(context.tr('common.type')),
                        DataColumnSpec(context.tr('equipment.quantity')),
                        DataColumnSpec(context.tr('common.status')),
                      ],
                      rowCells: (item) => [
                        Text(item.name ?? ''),
                        Text(item.type ?? '—'),
                        Text('${item.quantity ?? 0}'),
                        StatusBadge(status: item.status),
                      ],
                      cardBuilder: (item) => Card(
                        child: ListTile(
                          title: Text(item.name ?? ''),
                          subtitle: Text('${item.type ?? ''} · ${item.quantity ?? 0}'),
                          trailing: StatusBadge(status: item.status),
                        ),
                      ),
                    ),
                    PaginationBar(
                      currentPage: data.currentPage,
                      lastPage: data.lastPage,
                      onPage: (page) => ref.read(equipmentPageProvider.notifier).state = page,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openForm(BuildContext context, WidgetRef ref) async {
    final name = TextEditingController();
    final type = TextEditingController();
    final quantity = TextEditingController(text: '1');
    var status = 'available';
    final formKey = GlobalKey<FormState>();
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(context.tr('equipment.add')),
          content: Form(
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
                    validator: (value) => AppValidators.required(value, context.tr('validation.required')),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(label: context.tr('common.type'), controller: type),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: context.tr('equipment.quantity'),
                    controller: quantity,
                    required: true,
                    keyboardType: TextInputType.number,
                    validator: (value) => AppValidators.positiveInt(value, context.tr('validation.positive')),
                  ),
                  const SizedBox(height: 12),
                  StatefulBuilder(
                    builder: (context, setState) {
                      return AppDropdown<String>(
                        label: context.tr('common.status'),
                        value: status,
                        items: [
                          for (final item in AppConfig.equipmentStatuses)
                            DropdownMenuItem(value: item, child: Text(context.l10n.status(item))),
                        ],
                        onChanged: (value) => setState(() => status = value ?? status),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(context.tr('common.cancel'))),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) {
                  return;
                }
                try {
                  await ref.read(fleetRepositoryProvider).createEquipment({
                    'name': name.text.trim(),
                    'type': type.text.trim(),
                    'quantity': int.parse(quantity.text),
                    'status': status,
                  });
                  ref.invalidate(equipmentListProvider);
                  ref.invalidate(fleetEquipmentProvider);
                  if (context.mounted) {
                    Navigator.pop(context);
                    showAppSnack(context, context.tr('equipment.saved'));
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

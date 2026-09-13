import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/permissions/app_permissions.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/models/truck_type.dart';
import '../../../shared/providers/session_provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/async_body.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/filter_bar.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/responsive_data_view.dart';
import '../../../shared/widgets/status_badge.dart';
import 'truck_type_providers.dart';

final truckTypeSearchProvider = StateProvider<String>((ref) => '');
final truckTypeStatusProvider = StateProvider<String?>((ref) => null);
final truckTypeSourceProvider = StateProvider<String?>((ref) => null);

class TruckTypesScreen extends ConsumerWidget {
  const TruckTypesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    if (!session.permissions.can(AppPermissions.fleetManage)) {
      return const NoPermissionState();
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          PageHeader(
            title: context.tr('truckTypes.title'),
            subtitle: context.tr('truckTypes.subtitle'),
            actions: [
              AppButton(
                label: context.tr('truckTypes.add'),
                icon: Icons.add,
                onPressed: () => _openForm(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilterBar(
            children: [
              FilterSearchField(
                onChanged: (value) => ref.read(truckTypeSearchProvider.notifier).state = value,
              ),
              FilterSelect(
                options: const ['active', 'inactive'],
                value: ref.watch(truckTypeStatusProvider),
                onChanged: (value) => ref.read(truckTypeStatusProvider.notifier).state = value,
                labelOf: context.l10n.status,
              ),
              FilterSelect(
                options: const ['platform', 'company'],
                value: ref.watch(truckTypeSourceProvider),
                onChanged: (value) => ref.read(truckTypeSourceProvider.notifier).state = value,
                labelOf: (value) =>
                    value == 'platform' ? context.tr('truckTypes.platform') : context.tr('truckTypes.company'),
                allLabel: context.tr('common.allSources'),
              ),
            ],
          ),
          Expanded(
            child: AsyncBody(
              value: ref.watch(managedTruckTypesProvider),
              onRetry: () => ref.invalidate(managedTruckTypesProvider),
              isEmpty: (data) => data.isEmpty,
              empty: EmptyState(message: context.tr('truckTypes.empty')),
              builder: (data) {
                final search = ref.watch(truckTypeSearchProvider).trim().toLowerCase();
                final status = ref.watch(truckTypeStatusProvider);
                final source = ref.watch(truckTypeSourceProvider);
                final items = data.where((item) {
                  if (search.isNotEmpty) {
                    final haystack = '${item.name} ${item.nameAr} ${item.code}'.toLowerCase();
                    if (!haystack.contains(search)) {
                      return false;
                    }
                  }
                  if (status == 'active' && !item.isActive) {
                    return false;
                  }
                  if (status == 'inactive' && item.isActive) {
                    return false;
                  }
                  if (source == 'platform' && !item.isPlatform) {
                    return false;
                  }
                  if (source == 'company' && item.isPlatform) {
                    return false;
                  }
                  return true;
                }).toList();
                if (items.isEmpty) {
                  return EmptyState(message: context.tr('truckTypes.empty'));
                }
                return ResponsiveDataView<TruckTypeOption>(
                  items: items,
                  columns: [
                    DataColumnSpec(context.tr('common.name')),
                    DataColumnSpec(context.tr('truckTypes.code')),
                    DataColumnSpec(context.tr('truckTypes.source')),
                    DataColumnSpec(context.tr('common.status')),
                    DataColumnSpec(context.tr('common.actions')),
                  ],
                  rowCells: (item) {
                    final arabic = context.l10n.isRtl;
                    return [
                      Text(item.displayName(arabic)),
                      Text(item.code),
                      Text(item.isPlatform ? context.tr('truckTypes.platform') : context.tr('truckTypes.company')),
                      StatusBadge(status: item.isActive ? 'active' : 'inactive'),
                      item.canManage
                          ? Wrap(
                              spacing: 4,
                              children: [
                                TextButton(
                                  onPressed: () => _openForm(context, ref, item: item),
                                  child: Text(context.tr('common.edit')),
                                ),
                                TextButton(
                                  onPressed: () => _toggle(context, ref, item),
                                  child: Text(item.isActive ? context.tr('truckTypes.disable') : context.tr('truckTypes.enable')),
                                ),
                                if (!item.isSystem)
                                  TextButton(
                                    onPressed: () => _delete(context, ref, item),
                                    child: Text(context.tr('truckTypes.delete')),
                                  ),
                              ],
                            )
                          : Text(context.tr('truckTypes.readOnly')),
                    ];
                  },
                  cardBuilder: (item) {
                    final arabic = context.l10n.isRtl;
                    return Card(
                      child: ListTile(
                        title: Text(item.displayName(arabic)),
                        subtitle: Text(
                          '${item.code} · ${item.isPlatform ? context.tr('truckTypes.platform') : context.tr('truckTypes.company')}',
                        ),
                        trailing: StatusBadge(status: item.isActive ? 'active' : 'inactive'),
                        onTap: item.canManage ? () => _openForm(context, ref, item: item) : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggle(BuildContext context, WidgetRef ref, TruckTypeOption item) async {
    if (item.id == null) {
      return;
    }
    try {
      await ref.read(truckTypeRepositoryProvider).update(item.id!, {'is_active': !item.isActive});
      _refresh(ref);
      if (context.mounted) {
        showAppSnack(context, context.tr('truckTypes.saved'));
      }
    } on ApiException catch (error) {
      if (context.mounted) {
        showAppSnack(context, error.message);
      }
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, TruckTypeOption item) async {
    if (item.id == null) {
      return;
    }
    final confirmed = await showConfirmDialog(
      context,
      message: context.tr('truckTypes.deleteBody'),
      confirmLabel: context.tr('truckTypes.delete'),
    );
    if (!confirmed) {
      return;
    }
    try {
      await ref.read(truckTypeRepositoryProvider).delete(item.id!);
      _refresh(ref);
      if (context.mounted) {
        showAppSnack(context, context.tr('truckTypes.deleted'));
      }
    } on ApiException catch (error) {
      if (context.mounted) {
        showAppSnack(context, error.message);
      }
    }
  }

  Future<void> _openForm(BuildContext context, WidgetRef ref, {TruckTypeOption? item}) async {
    final code = TextEditingController(text: item?.code ?? '');
    final name = TextEditingController(text: item?.name ?? '');
    final nameAr = TextEditingController(text: item?.nameAr ?? '');
    var isActive = item?.isActive ?? true;
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(item == null ? context.tr('truckTypes.add') : context.tr('truckTypes.edit')),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: 420,
              child: StatefulBuilder(
                builder: (context, setState) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppTextField(
                        label: context.tr('truckTypes.code'),
                        controller: code,
                        required: true,
                        enabled: item == null,
                        validator: (value) => AppValidators.required(value, context.tr('validation.required')),
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: context.tr('truckTypes.nameEn'),
                        controller: name,
                        required: true,
                        validator: (value) => AppValidators.required(value, context.tr('validation.required')),
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: context.tr('truckTypes.nameAr'),
                        controller: nameAr,
                        required: true,
                        validator: (value) => AppValidators.required(value, context.tr('validation.required')),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(context.tr('truckTypes.active')),
                        value: isActive,
                        onChanged: (value) => setState(() => isActive = value),
                      ),
                    ],
                  );
                },
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
                  final payload = {
                    'name': name.text.trim(),
                    'name_ar': nameAr.text.trim(),
                    'is_active': isActive,
                    if (item == null) 'code': code.text.trim(),
                  };
                  if (item == null) {
                    await ref.read(truckTypeRepositoryProvider).create(payload);
                  } else if (item.id != null) {
                    await ref.read(truckTypeRepositoryProvider).update(item.id!, payload);
                  }
                  _refresh(ref);
                  if (context.mounted) {
                    Navigator.pop(context);
                    showAppSnack(context, context.tr('truckTypes.saved'));
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
    code.dispose();
    name.dispose();
    nameAr.dispose();
  }

  void _refresh(WidgetRef ref) {
    ref.invalidate(managedTruckTypesProvider);
    ref.invalidate(catalogTruckTypesProvider);
  }
}

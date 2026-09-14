import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/permissions/app_permissions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/models/access_role.dart';
import '../../../shared/providers/session_provider.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/confirm_dialog.dart';

Future<AccessRole?> showCreateRoleDialog(
  BuildContext context,
  WidgetRef ref, {
  required List<String> permissions,
}) async {
  final name = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final selected = <String>{AppPermissions.dashboardView};
  final groups = _visibleGroups(permissions);

  final created = await showDialog<AccessRole>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(context.tr('users.createRole')),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 520,
            child: StatefulBuilder(
              builder: (context, setState) {
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        context.tr('users.createRoleHint'),
                        style: const TextStyle(color: AppColors.muted, height: 1.45),
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        label: context.tr('users.roleNameLabel'),
                        controller: name,
                        required: true,
                        validator: (value) => AppValidators.required(value, context.tr('validation.required')),
                      ),
                      const SizedBox(height: 16),
                      for (final group in groups) ...[
                        _CreatePermissionGroup(
                          group: group,
                          selected: selected,
                          onToggle: (permission) {
                            setState(() {
                              if (selected.contains(permission)) {
                                selected.remove(permission);
                              } else {
                                selected.add(permission);
                              }
                            });
                          },
                          onToggleGroup: () {
                            setState(() {
                              final allOn = group.keys.every(selected.contains);
                              if (allOn) {
                                selected.removeAll(group.keys);
                              } else {
                                selected.addAll(group.keys);
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(context.tr('common.cancel'))),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate() || selected.isEmpty) {
                if (selected.isEmpty && context.mounted) {
                  showAppSnack(context, context.tr('users.permissionsRequired'));
                }
                return;
              }
              try {
                final role = await ref.read(roleRepositoryProvider).create(
                      name: name.text.trim(),
                      permissions: selected.toList(),
                    );
                if (context.mounted) {
                  Navigator.pop(context, role);
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
  return created;
}

List<PermissionGroup> _visibleGroups(List<String> permissions) {
  final allowed = permissions.toSet();
  final source = allowed.isEmpty ? AppPermissions.groups : AppPermissions.groups;
  return source
      .map(
        (group) => PermissionGroup(
          id: group.id,
          keys: allowed.isEmpty ? group.keys : group.keys.where(allowed.contains).toList(),
        ),
      )
      .where((group) => group.keys.isNotEmpty)
      .toList();
}

class _CreatePermissionGroup extends StatelessWidget {
  const _CreatePermissionGroup({
    required this.group,
    required this.selected,
    required this.onToggle,
    required this.onToggleGroup,
  });

  final PermissionGroup group;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final VoidCallback onToggleGroup;

  @override
  Widget build(BuildContext context) {
    final allOn = group.keys.every(selected.contains);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggleGroup,
            child: Row(
              children: [
                Icon(
                  allOn ? Icons.check_box_rounded : Icons.indeterminate_check_box_outlined,
                  size: 18,
                  color: allOn ? AppColors.teal800 : AppColors.muted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.tr(AppPermissions.groupLabelKey(group.id)),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          for (final permission in group.keys)
            CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              value: selected.contains(permission),
              onChanged: (_) => onToggle(permission),
              title: Text(
                context.tr(AppPermissions.permissionLabelKey(permission)),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }
}

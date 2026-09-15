import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/permissions/app_permissions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/page_visuals.dart';
import '../../../core/utils/breakpoints.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/access_role.dart';
import '../../../shared/models/user.dart';
import '../../../shared/providers/session_provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_page.dart';
import '../../../shared/widgets/async_body.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/entity_card.dart';
import '../../../shared/widgets/filter_bar.dart';
import '../../../shared/widgets/icon_well.dart';
import '../../../shared/widgets/info_grid.dart';
import '../../../shared/widgets/metric_card.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../company/presentation/company_screen.dart';
import 'create_role_dialog.dart';
import 'role_providers.dart';

final companyUserSearchProvider = StateProvider<String>((ref) => '');

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  String? _selectedRoleName;
  List<String> _checked = const [];
  var _saving = false;

  AccessRole? _selectedRole(AccessCatalog catalog) {
    if (catalog.roles.isEmpty) {
      return null;
    }
    return catalog.roles.cast<AccessRole?>().firstWhere(
          (role) => role!.name == _selectedRoleName,
          orElse: () => catalog.roles.first,
        );
  }

  void _selectRole(AccessRole role) {
    setState(() {
      _selectedRoleName = role.name;
      _checked = List<String>.from(role.permissions);
    });
  }

  List<PermissionGroup> _groups(AccessCatalog catalog) {
    final allowed = catalog.permissions.toSet();
    return AppPermissions.visibleGroups()
        .map(
          (group) => PermissionGroup(
            id: group.id,
            keys: allowed.isEmpty ? group.keys : group.keys.where(allowed.contains).toList(),
          ),
        )
        .where((group) => group.keys.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    if (!session.permissions.can(AppPermissions.usersManage) && !session.permissions.can(AppPermissions.rolesManage)) {
      return const NoPermissionState();
    }

    final user = session.user;
    final orgId = user?.organizationId;
    final org = orgId == null ? null : ref.watch(organizationProvider(orgId));
    final catalog = ref.watch(accessCatalogProvider);
    final canCreate = session.permissions.can(AppPermissions.rolesManage);

    return AppPage(
      child: AsyncBody(
        value: catalog,
        onRetry: () => ref.invalidate(accessCatalogProvider),
        builder: (data) {
          final roster = org?.asData?.value.users ?? const <AppUser>[];
          final locale = Localizations.localeOf(context).languageCode;
          final selected = _selectedRole(data);
          if (selected != null && _selectedRoleName != selected.name) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _selectRole(selected);
              }
            });
          } else if (selected != null && _checked.isEmpty && selected.permissions.isNotEmpty && _selectedRoleName == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                final match = _matchingRole(data.roles, user?.roles ?? const []);
                _selectRole(match ?? selected);
              }
            });
          }

          final yourRole = _matchingRole(data.roles, user?.roles ?? const []);
          final yourPermissions = AppPermissions.visibleKeys(user?.permissions ?? const <String>[])
              .where((permission) => data.permissions.contains(permission) || AppPermissions.catalogKeys.contains(permission))
              .toList();

          return ListView(
            children: [
              PageHeader(
                title: context.tr('users.title'),
                subtitle: context.tr('users.subtitle'),
                actions: [
                  if (canCreate)
                    AppButton(
                      label: context.tr('users.createRole'),
                      icon: Icons.add,
                      onPressed: () => _createRole(data.permissions),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              _Metrics(
                roles: data.roles.length,
                users: org?.asData?.value.users.length,
                access: yourPermissions.length,
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: context.tr('users.currentUser'),
                icon: Icons.person_outline_rounded,
                tone: IconTone.info,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DetailHero(
                      title: user?.name?.trim().isNotEmpty == true ? user!.name! : '—',
                      subtitle: user?.email,
                      icon: Icons.verified_user_outlined,
                      tone: IconTone.teal,
                      chips: [
                        if (yourRole != null)
                          DetailChip(label: _roleTitle(context, yourRole), icon: Icons.workspace_premium_outlined),
                        DetailChip(
                          label: _userTypeLabel(context, user?.userType),
                          icon: Icons.badge_outlined,
                        ),
                        DetailChip(
                          label: context.l10n.status(user?.isActive == false ? 'inactive' : 'active'),
                          icon: user?.isActive == false ? Icons.pause_circle_outline : Icons.check_circle_outline,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    InfoGrid(
                      fields: [
                        InfoField(
                          label: context.tr('users.roles'),
                          value: (user?.roles.isNotEmpty ?? false)
                              ? user!.roles.map((role) => _roleTitleForName(context, data.roles, role)).join(' · ')
                              : '—',
                          icon: Icons.shield_outlined,
                          tone: IconTone.teal,
                        ),
                        InfoField(
                          label: context.tr('users.kpiAccess'),
                          value: '${yourPermissions.length}',
                          icon: Icons.key_outlined,
                          tone: IconTone.coral,
                        ),
                        InfoField(
                          label: context.tr('users.lastLogin'),
                          value: Formatters.dateTime(user?.lastLoginAt, locale: locale),
                          icon: Icons.schedule_outlined,
                        ),
                      ],
                    ),
                    if (yourPermissions.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(
                        context.tr('users.yourAccess'),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final permission in yourPermissions)
                            DetailChip(
                              label: context.tr(AppPermissions.permissionLabelKey(permission)),
                              icon: Icons.check_rounded,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final roleList = _RoleList(
                    roles: data.roles,
                    selected: selected,
                    sessionRoles: user?.roles ?? const [],
                    users: roster,
                    onSelect: _selectRole,
                  );
                  final matrix = selected == null
                      ? const SizedBox.shrink()
                      : _PermissionMatrix(
                          role: selected,
                          groups: _groups(data),
                          checked: _checked,
                          saving: _saving,
                          onToggle: (permission) {
                            setState(() {
                              _checked = _checked.contains(permission)
                                  ? _checked.where((item) => item != permission).toList()
                                  : [..._checked, permission];
                            });
                          },
                          onToggleGroup: (keys) {
                            setState(() {
                              final allOn = keys.every(_checked.contains);
                              _checked = allOn
                                  ? _checked.where((item) => !keys.contains(item)).toList()
                                  : [...{..._checked, ...keys}];
                            });
                          },
                          onSave: () => _saveRole(selected),
                          onDelete: selected.canDelete ? () => _deleteRole(selected) : null,
                        );

                  if (constraints.maxWidth < 960) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        roleList,
                        const SizedBox(height: 12),
                        matrix,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 300, child: roleList),
                      const SizedBox(width: 12),
                      Expanded(child: matrix),
                    ],
                  );
                },
              ),
              if (orgId != null) ...[
                const SizedBox(height: 16),
                AsyncBody(
                  value: org!,
                  onRetry: () => ref.invalidate(organizationProvider(orgId)),
                  builder: (organization) => _UserRoster(users: organization.users, roles: data.roles),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _createRole(List<String> permissions) async {
    final created = await showCreateRoleDialog(context, ref, permissions: permissions);
    if (created == null || !mounted) {
      return;
    }
    ref.invalidate(accessCatalogProvider);
    _selectRole(created);
    showAppSnack(context, context.tr('users.roleCreated'));
  }

  Future<void> _saveRole(AccessRole role) async {
    if (_checked.isEmpty) {
      showAppSnack(context, context.tr('users.permissionsRequired'));
      return;
    }
    setState(() => _saving = true);
    try {
      final updated = await ref.read(roleRepositoryProvider).update(role: role.name, permissions: _checked);
      ref.invalidate(accessCatalogProvider);
      await ref.read(sessionProvider.notifier).refreshUser();
      if (mounted) {
        _selectRole(updated);
        showAppSnack(context, context.tr('users.roleSaved'));
      }
    } on ApiException catch (error) {
      if (mounted) {
        showAppSnack(context, error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _deleteRole(AccessRole role) async {
    final confirmed = await showConfirmDialog(
      context,
      message: context.tr('users.deleteRoleBody'),
      confirmLabel: context.tr('users.deleteRole'),
    );
    if (!confirmed) {
      return;
    }
    try {
      await ref.read(roleRepositoryProvider).delete(role.name);
      setState(() => _selectedRoleName = null);
      ref.invalidate(accessCatalogProvider);
      if (mounted) {
        showAppSnack(context, context.tr('users.roleDeleted'));
      }
    } on ApiException catch (error) {
      if (mounted) {
        showAppSnack(context, error.message);
      }
    }
  }
}

class _Metrics extends StatelessWidget {
  const _Metrics({
    required this.roles,
    required this.users,
    required this.access,
  });

  final int roles;
  final int? users;
  final int access;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = Breakpoints.metricColumns(constraints.maxWidth).clamp(1, 3);
        final gap = 12.0;
        final width = (constraints.maxWidth - (gap * (columns - 1))) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            SizedBox(
              width: width,
              child: MetricCard(
                label: context.tr('users.kpiRoles'),
                value: '$roles',
                icon: Icons.shield_outlined,
                tone: IconTone.teal,
              ),
            ),
            SizedBox(
              width: width,
              child: MetricCard(
                label: context.tr('users.kpiUsers'),
                value: users?.toString() ?? '—',
                icon: Icons.groups_outlined,
                tone: IconTone.info,
              ),
            ),
            SizedBox(
              width: width,
              child: MetricCard(
                label: context.tr('users.kpiAccess'),
                value: '$access',
                icon: Icons.key_outlined,
                tone: IconTone.coral,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RoleList extends StatelessWidget {
  const _RoleList({
    required this.roles,
    required this.selected,
    required this.sessionRoles,
    required this.users,
    required this.onSelect,
  });

  final List<AccessRole> roles;
  final AccessRole? selected;
  final List<String> sessionRoles;
  final List<AppUser> users;
  final ValueChanged<AccessRole> onSelect;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: context.tr('users.list'),
      icon: Icons.shield_outlined,
      child: Column(
        children: [
          for (final role in roles)
            _RoleTile(
              role: role,
              selected: role.name == selected?.name,
              yours: role.matches(sessionRoles),
              userCount: users.where((user) => role.matches(user.roles)).length,
              onTap: () => onSelect(role),
            ),
        ],
      ),
    );
  }
}

class _RoleTile extends StatelessWidget {
  const _RoleTile({
    required this.role,
    required this.selected,
    required this.yours,
    required this.userCount,
    required this.onTap,
  });

  final AccessRole role;
  final bool selected;
  final bool yours;
  final int userCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final visual = _roleVisual(role);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? AppColors.tealSoft : AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: selected ? AppColors.teal : AppColors.border),
            ),
            child: Row(
              children: [
                IconWell(icon: visual.icon, tone: visual.tone, size: IconWellSize.sm),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _roleTitle(context, role),
                        style: const TextStyle(fontWeight: FontWeight.w700, height: 1.35),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.tr('users.usersCount', {'count': '$userCount'}),
                        style: const TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (yours)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.coralSoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      context.tr('users.yourRole'),
                      style: const TextStyle(
                        color: AppColors.coralDeep,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
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

class _PermissionMatrix extends StatelessWidget {
  const _PermissionMatrix({
    required this.role,
    required this.groups,
    required this.checked,
    required this.saving,
    required this.onToggle,
    required this.onToggleGroup,
    required this.onSave,
    this.onDelete,
  });

  final AccessRole role;
  final List<PermissionGroup> groups;
  final List<String> checked;
  final bool saving;
  final ValueChanged<String> onToggle;
  final ValueChanged<List<String>> onToggleGroup;
  final VoidCallback onSave;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final description = role.guide == null ? context.tr('users.customRoleHint') : context.tr(role.guide!.labelKey);
    return SectionCard(
      title: _roleTitle(context, role),
      icon: Icons.tune_outlined,
      tone: IconTone.coral,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(description, style: const TextStyle(color: AppColors.muted, height: 1.45)),
          const SizedBox(height: 8),
          Text(
            role.canManage ? context.tr('users.editHint') : context.tr('users.catalogHint'),
            style: const TextStyle(color: AppColors.muted, height: 1.45),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: role.isSystem ? AppColors.coralSoft : AppColors.tealSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  role.isSystem ? context.tr('users.systemRole') : context.tr('users.customRole'),
                  style: TextStyle(
                    color: role.isSystem ? AppColors.coralDeep : AppColors.teal800,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              if (role.canManage)
                AppButton(
                  label: context.tr('common.save'),
                  loading: saving,
                  onPressed: onSave,
                ),
              if (onDelete != null)
                AppButton(
                  label: context.tr('users.deleteRole'),
                  outlined: true,
                  onPressed: onDelete,
                ),
            ],
          ),
          const SizedBox(height: 16),
          for (final group in groups) ...[
            _PermissionGroupCard(
              group: group,
              checked: checked,
              canEdit: role.canManage,
              onToggle: onToggle,
              onToggleGroup: onToggleGroup,
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _PermissionGroupCard extends StatelessWidget {
  const _PermissionGroupCard({
    required this.group,
    required this.checked,
    required this.canEdit,
    required this.onToggle,
    required this.onToggleGroup,
  });

  final PermissionGroup group;
  final List<String> checked;
  final bool canEdit;
  final ValueChanged<String> onToggle;
  final ValueChanged<List<String>> onToggleGroup;

  @override
  Widget build(BuildContext context) {
    final granted = group.keys.where(checked.contains).length;
    final allGranted = granted == group.keys.length;
    final visual = _groupVisual(group.id);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: canEdit ? () => onToggleGroup(group.keys) : null,
            child: Row(
              children: [
                IconWell(icon: visual.icon, tone: visual.tone, size: IconWellSize.sm),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.tr(AppPermissions.groupLabelKey(group.id)),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Icon(
                  allGranted ? Icons.check_box_rounded : Icons.indeterminate_check_box_outlined,
                  size: 18,
                  color: allGranted ? AppColors.teal800 : AppColors.muted,
                ),
                const SizedBox(width: 6),
                Text(
                  context.tr('users.grantedCount', {
                    'granted': '$granted',
                    'total': '${group.keys.length}',
                  }),
                  style: const TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 640 ? 2 : 1;
              final width = columns == 1 ? constraints.maxWidth : (constraints.maxWidth - 10) / 2;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final permission in group.keys)
                    SizedBox(
                      width: width,
                      child: _PermissionTile(
                        label: context.tr(AppPermissions.permissionLabelKey(permission)),
                        granted: checked.contains(permission),
                        canEdit: canEdit,
                        onTap: () => onToggle(permission),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({
    required this.label,
    required this.granted,
    required this.canEdit,
    required this.onTap,
  });

  final String label;
  final bool granted;
  final bool canEdit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: granted ? AppColors.tealSoft : AppColors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: canEdit ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: granted ? AppColors.teal.withValues(alpha: 0.45) : AppColors.border),
          ),
          child: Row(
            children: [
              Icon(
                granted ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                size: 18,
                color: granted ? AppColors.teal800 : AppColors.muted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    height: 1.35,
                    color: granted ? AppColors.ink : AppColors.muted,
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

class _UserRoster extends ConsumerWidget {
  const _UserRoster({required this.users, required this.roles});

  final List<AppUser> users;
  final List<AccessRole> roles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final search = ref.watch(companyUserSearchProvider).trim().toLowerCase();
    final locale = Localizations.localeOf(context).languageCode;
    final filtered = users.where((user) {
      if (search.isEmpty) {
        return true;
      }
      return '${user.name ?? ''} ${user.email ?? ''} ${user.userType ?? ''} ${user.roles.join(' ')}'
          .toLowerCase()
          .contains(search);
    }).toList();

    return SectionCard(
      title: context.tr('users.roster'),
      icon: Icons.groups_outlined,
      tone: IconTone.info,
      child: Column(
        children: [
          FilterBar(
            children: [
              FilterSearchField(
                hint: context.tr('common.search'),
                onChanged: (value) => ref.read(companyUserSearchProvider.notifier).state = value,
              ),
            ],
          ),
          if (filtered.isEmpty)
            EmptyState(message: context.tr('users.empty'), icon: Icons.groups_outlined)
          else
            for (final user in filtered)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: EntityCard(
                  title: user.name?.trim().isNotEmpty == true ? user.name! : (user.email ?? '—'),
                  subtitle: user.email,
                  icon: Icons.person_outline_rounded,
                  tone: user.isActive ? IconTone.teal : IconTone.muted,
                  meta: [
                    [
                      _userTypeLabel(context, user.userType),
                      if (user.roles.isNotEmpty)
                        user.roles.map((role) => _roleTitleForName(context, roles, role)).join(' · '),
                    ].join(' · '),
                    '${context.tr('users.lastLogin')}: ${Formatters.dateTime(user.lastLoginAt, locale: locale)}',
                  ],
                  trailing: StatusBadge(status: user.isActive ? 'active' : 'inactive'),
                ),
              ),
        ],
      ),
    );
  }
}

({IconData icon, IconTone tone}) _roleVisual(AccessRole role) {
  return switch (role.guide?.id) {
    'providerAdmin' => (icon: Icons.admin_panel_settings_outlined, tone: IconTone.teal),
    'operations' => (icon: Icons.work_outline_rounded, tone: IconTone.warning),
    'dispatcher' => (icon: Icons.assignment_ind_outlined, tone: IconTone.coral),
    'fleetManager' => (icon: Icons.fire_truck_outlined, tone: IconTone.teal),
    'finance' => (icon: Icons.account_balance_outlined, tone: IconTone.success),
    'quotation' => (icon: Icons.request_quote_outlined, tone: IconTone.info),
    _ => (icon: Icons.shield_outlined, tone: role.isSystem ? IconTone.muted : IconTone.teal),
  };
}

({IconData icon, IconTone tone}) _groupVisual(String id) {
  return switch (id) {
    'overview' => (icon: Icons.space_dashboard_outlined, tone: IconTone.coral),
    'operations' => (icon: Icons.route_outlined, tone: IconTone.warning),
    'fleet' => (icon: Icons.agriculture_outlined, tone: IconTone.teal),
    'finance' => (icon: Icons.payments_outlined, tone: IconTone.success),
    _ => (icon: Icons.manage_accounts_outlined, tone: IconTone.info),
  };
}

AccessRole? _matchingRole(List<AccessRole> roles, Iterable<String> assigned) {
  for (final role in roles) {
    if (role.matches(assigned)) {
      return role;
    }
  }
  return null;
}

String _roleTitle(BuildContext context, AccessRole role) {
  final guide = role.guide;
  if (guide != null) {
    return context.tr(guide.nameKey);
  }
  return role.displayName;
}

String _roleTitleForName(BuildContext context, List<AccessRole> roles, String name) {
  final match = roles.cast<AccessRole?>().firstWhere(
        (role) => role!.name == name,
        orElse: () => null,
      );
  if (match != null) {
    return _roleTitle(context, match);
  }
  return name;
}

String _userTypeLabel(BuildContext context, String? type) {
  if (type == null || type.isEmpty) {
    return '—';
  }
  final key = 'users.userType.$type';
  final mapped = context.tr(key);
  return mapped == key ? type : mapped;
}

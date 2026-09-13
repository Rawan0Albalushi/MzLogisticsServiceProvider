import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/permissions/app_permissions.dart';
import '../../../shared/providers/session_provider.dart';
import '../../../shared/widgets/async_body.dart';
import '../../../shared/widgets/filter_bar.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/section_card.dart';
import '../../company/presentation/company_screen.dart';

final companyUserSearchProvider = StateProvider<String>((ref) => '');

class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    if (!session.permissions.can(AppPermissions.usersManage)) {
      return const NoPermissionState();
    }
    final orgId = session.user?.organizationId;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ListView(
        children: [
          PageHeader(title: context.tr('users.title'), subtitle: context.tr('users.subtitle')),
          const SizedBox(height: 16),
          SectionCard(
            title: context.tr('users.currentUser'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InfoRow(label: context.tr('auth.name'), value: session.user?.name ?? '—'),
                InfoRow(label: context.tr('auth.email'), value: session.user?.email ?? '—'),
                InfoRow(label: context.tr('users.roles'), value: session.user?.roles.join(', ') ?? '—'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final permission in session.user?.permissions ?? const <String>[])
                      Chip(label: Text(permission)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: context.tr('users.roles'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final key in AppPermissions.roleCatalog)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(context.tr(key)),
                  ),
              ],
            ),
          ),
          if (orgId != null) ...[
            const SizedBox(height: 12),
            AsyncBody(
              value: ref.watch(organizationProvider(orgId)),
              onRetry: () => ref.invalidate(organizationProvider(orgId)),
              builder: (org) {
                final search = ref.watch(companyUserSearchProvider).trim().toLowerCase();
                final users = org.users.where((user) {
                  if (search.isEmpty) {
                    return true;
                  }
                  return '${user.name ?? ''} ${user.email ?? ''} ${user.userType ?? ''}'.toLowerCase().contains(search);
                }).toList();
                if (users.isEmpty) {
                  return EmptyState(message: context.tr('users.empty'));
                }
                return SectionCard(
                  title: context.tr('nav.users'),
                  child: Column(
                    children: [
                      FilterBar(
                        children: [
                          FilterSearchField(
                            onChanged: (value) => ref.read(companyUserSearchProvider.notifier).state = value,
                          ),
                        ],
                      ),
                      for (final user in users)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(user.name ?? ''),
                          subtitle: Text('${user.email ?? ''} · ${user.userType ?? ''}'),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

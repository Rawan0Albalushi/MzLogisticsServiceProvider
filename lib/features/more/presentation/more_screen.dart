import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../shared/providers/session_provider.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/page_header.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = visibleDestinations(ref.watch(sessionProvider).permissions)
        .where((item) => item.path != '/dashboard')
        .toList();
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ListView(
        children: [
          PageHeader(title: context.tr('nav.more')),
          const SizedBox(height: 12),
          for (final item in items)
            Card(
              child: ListTile(
                leading: Icon(item.icon),
                title: Text(context.tr(item.labelKey)),
                onTap: () => context.go(item.path),
              ),
            ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout),
              title: Text(context.tr('nav.logout')),
              onTap: () async {
                final ok = await showConfirmDialog(
                  context,
                  message: context.tr('common.logoutConfirm'),
                  confirmLabel: context.tr('nav.logout'),
                );
                if (ok && context.mounted) {
                  await ref.read(sessionProvider.notifier).logout();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

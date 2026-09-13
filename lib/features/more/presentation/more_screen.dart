import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/page_visuals.dart';
import '../../../shared/providers/session_provider.dart';
import '../../../shared/widgets/app_page.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/icon_well.dart';
import '../../../shared/widgets/page_header.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = visibleDestinations(ref.watch(sessionProvider))
        .where((item) => item.path != '/dashboard')
        .toList();
    final sections = NavSection.values
        .map((section) => (section: section, items: items.where((item) => item.section == section).toList()))
        .where((group) => group.items.isNotEmpty)
        .toList();

    return AppPage(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 640 ? 2 : 1;
          final gap = 10.0;
          final itemWidth = columns == 1
              ? constraints.maxWidth
              : (constraints.maxWidth - gap) / 2;

          return ListView(
            children: [
              PageHeader(
                title: context.tr('nav.more'),
                subtitle: context.tr('app.tagline'),
                icon: Icons.apps_outlined,
                tone: IconTone.teal,
              ),
              const SizedBox(height: 8),
              for (final group in sections) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
                  child: Text(
                    context.tr(navSectionLabel(group.section)),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final item in group.items)
                      SizedBox(
                        width: itemWidth,
                        child: _MoreTile(
                          icon: item.icon,
                          tone: PageVisuals.of(item.path).tone,
                          label: context.tr(item.labelKey),
                          onTap: () => context.go(item.path),
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              _MoreTile(
                icon: Icons.logout,
                tone: IconTone.danger,
                label: context.tr('nav.logout'),
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
            ],
          );
        },
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({
    required this.icon,
    required this.tone,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final IconTone tone;
  final String label;
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
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600, height: 1.35),
                ),
              ),
              Icon(
                Directionality.of(context) == TextDirection.rtl
                    ? Icons.chevron_left
                    : Icons.chevron_right,
                color: AppColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

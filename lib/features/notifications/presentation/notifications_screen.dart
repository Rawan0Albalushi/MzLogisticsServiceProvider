import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/providers/session_provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/async_body.dart';
import '../../../shared/widgets/filter_bar.dart';
import '../../../shared/widgets/page_header.dart';

final notificationStatusProvider = StateProvider<String?>((ref) => null);
final notificationsProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(notificationRepositoryProvider).list(status: ref.watch(notificationStatusProvider));
});

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = Localizations.localeOf(context).languageCode;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          PageHeader(
            title: context.tr('notifications.title'),
            actions: [
              AppButton(
                label: context.tr('common.markAllRead'),
                outlined: true,
                onPressed: () async {
                  await ref.read(notificationRepositoryProvider).markAllRead();
                  ref.invalidate(notificationsProvider);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilterBar(
            children: [
              FilterSelect(
                options: const ['unread', 'read'],
                value: ref.watch(notificationStatusProvider),
                onChanged: (value) => ref.read(notificationStatusProvider.notifier).state = value,
                labelOf: (value) => context.tr('notifications.$value'),
              ),
            ],
          ),
          Expanded(
            child: AsyncBody(
              value: ref.watch(notificationsProvider),
              onRetry: () => ref.invalidate(notificationsProvider),
              isEmpty: (data) => data.isEmpty,
              empty: EmptyState(message: context.tr('notifications.empty'), icon: Icons.notifications_outlined),
              builder: (data) {
                return ListView(
                  children: [
                    for (final item in data.items)
                      Card(
                        child: ListTile(
                          title: Text(item.title ?? context.tr('notifications.title')),
                          subtitle: Text(
                            '${item.body ?? ''}\n${Formatters.dateTime(item.createdAt, locale: locale)}',
                          ),
                          isThreeLine: true,
                          leading: Icon(
                            item.isUnread ? Icons.circle : Icons.circle_outlined,
                            size: 12,
                            color: item.isUnread ? AppColors.amber : AppColors.muted,
                          ),
                          onTap: item.isUnread
                              ? () async {
                                  await ref.read(notificationRepositoryProvider).markRead(item.id);
                                  ref.invalidate(notificationsProvider);
                                }
                              : null,
                        ),
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
}

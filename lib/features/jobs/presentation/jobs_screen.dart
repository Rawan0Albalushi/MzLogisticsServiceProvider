import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/permissions/app_permissions.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/job.dart';
import '../../../shared/providers/session_provider.dart';
import '../../../shared/widgets/async_body.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/responsive_data_view.dart';
import '../../../shared/widgets/status_badge.dart';

final jobStatusProvider = StateProvider<String?>((ref) => null);
final jobPageProvider = StateProvider<int>((ref) => 1);

final jobsProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(jobRepositoryProvider).list(
        page: ref.watch(jobPageProvider),
        status: ref.watch(jobStatusProvider),
      );
});

class JobsScreen extends ConsumerWidget {
  const JobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(sessionProvider).permissions.can(AppPermissions.jobsView)) {
      return const NoPermissionState();
    }
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          PageHeader(title: context.tr('jobs.title'), subtitle: context.tr('jobs.subtitle')),
          const SizedBox(height: 12),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilterChips(
              options: const ['pending_dispatch', 'in_progress', 'completed', 'cancelled'],
              selected: ref.watch(jobStatusProvider),
              onSelected: (value) {
                ref.read(jobStatusProvider.notifier).state = value;
                ref.read(jobPageProvider.notifier).state = 1;
              },
              labelOf: context.l10n.status,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: AsyncBody(
              value: ref.watch(jobsProvider),
              onRetry: () => ref.invalidate(jobsProvider),
              isEmpty: (data) => data.isEmpty,
              empty: EmptyState(message: context.tr('jobs.empty'), icon: Icons.work_outline),
              builder: (data) {
                return ListView(
                  children: [
                    ResponsiveDataView<TransportJob>(
                      items: data.items,
                      columns: [
                        DataColumnSpec(context.tr('common.reference')),
                        DataColumnSpec(context.tr('common.customer')),
                        DataColumnSpec(context.tr('jobs.progress')),
                        DataColumnSpec(context.tr('nav.trips')),
                        DataColumnSpec(context.tr('common.status')),
                      ],
                      onRowTap: (item) => context.go('/jobs/${item.id}'),
                      rowCells: (item) => [
                        Text(item.reference ?? ''),
                        Text(item.customer?.name ?? ''),
                        Text(Formatters.percent(item.progressPercent)),
                        Text('${item.trips.length}'),
                        StatusBadge(status: item.status),
                      ],
                      cardBuilder: (item) => Card(
                        child: ListTile(
                          title: Text(item.reference ?? ''),
                          subtitle: Text(
                            '${item.customer?.name ?? ''} · ${item.trips.length} ${context.tr('common.trips')} · ${Formatters.percent(item.progressPercent)}',
                          ),
                          trailing: StatusBadge(status: item.status),
                          onTap: () => context.go('/jobs/${item.id}'),
                        ),
                      ),
                    ),
                    PaginationBar(
                      currentPage: data.currentPage,
                      lastPage: data.lastPage,
                      onPage: (page) => ref.read(jobPageProvider.notifier).state = page,
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

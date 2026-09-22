import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/permissions/app_permissions.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/job.dart';
import '../../../shared/providers/session_provider.dart';
import '../../../core/theme/page_visuals.dart';
import '../../../shared/widgets/app_page.dart';
import '../../../shared/widgets/async_body.dart';
import '../../../shared/widgets/entity_card.dart';
import '../../../shared/widgets/filter_bar.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/responsive_data_view.dart';
import '../../../shared/widgets/status_badge.dart';

final jobStatusProvider = StateProvider<String?>((ref) => null);
final jobSearchProvider = StateProvider<String>((ref) => '');
final jobDateFromProvider = StateProvider<String?>((ref) => null);
final jobDateToProvider = StateProvider<String?>((ref) => null);
final jobPageProvider = StateProvider<int>((ref) => 1);

final jobsProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(jobRepositoryProvider).list(
        page: ref.watch(jobPageProvider),
        status: ref.watch(jobStatusProvider),
        search: ref.watch(jobSearchProvider),
        dateFrom: ref.watch(jobDateFromProvider),
        dateTo: ref.watch(jobDateToProvider),
      );
});

final jobDetailProvider = FutureProvider.autoDispose.family((ref, int id) {
  return ref.watch(jobRepositoryProvider).show(id);
});

class JobsScreen extends ConsumerWidget {
  const JobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(sessionProvider).permissions.can(AppPermissions.jobsView)) {
      return const NoPermissionState();
    }
    final locale = Localizations.localeOf(context).languageCode;
    return AppPage(
      child: Column(
        children: [
          PageHeader(title: context.tr('jobs.title'), subtitle: context.tr('jobs.subtitle')),
          const SizedBox(height: 12),
          FilterBar(
            children: [
              FilterSearchField(
                hint: context.tr('common.searchReference'),
                onChanged: (value) {
                  ref.read(jobSearchProvider.notifier).state = value;
                  ref.read(jobPageProvider.notifier).state = 1;
                },
              ),
              FilterSelect(
                options: const ['pending_dispatch', 'in_progress', 'completed', 'cancelled'],
                value: ref.watch(jobStatusProvider),
                onChanged: (value) {
                  ref.read(jobStatusProvider.notifier).state = value;
                  ref.read(jobPageProvider.notifier).state = 1;
                },
                labelOf: context.l10n.status,
              ),
              FilterDateRange(
                from: ref.watch(jobDateFromProvider),
                to: ref.watch(jobDateToProvider),
                onChanged: (from, to) {
                  ref.read(jobDateFromProvider.notifier).state = from;
                  ref.read(jobDateToProvider.notifier).state = to;
                  ref.read(jobPageProvider.notifier).state = 1;
                },
              ),
            ],
          ),
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
                        DataColumnSpec(context.tr('nav.shipments')),
                        DataColumnSpec(context.tr('quotations.totalPrice')),
                        DataColumnSpec(context.tr('jobs.totalQuantity')),
                        DataColumnSpec(context.tr('jobs.delivered')),
                        DataColumnSpec(context.tr('jobs.progress')),
                        DataColumnSpec(context.tr('nav.trips')),
                        DataColumnSpec(context.tr('common.status')),
                      ],
                      onRowTap: (item) => context.go('/jobs/${item.id}'),
                      rowCells: (item) => [
                        Text(item.reference ?? ''),
                        Text(item.customer?.name ?? ''),
                        Text(item.shipment?.reference ?? '—'),
                        Text(Formatters.money(item.totalPrice, currency: item.currency, locale: locale)),
                        Text(Formatters.number(item.totalQuantity, locale: locale)),
                        Text(Formatters.number(item.deliveredQuantity, locale: locale)),
                        Text(Formatters.percent(item.progressPercent)),
                        Text('${item.trips.length}'),
                        StatusBadge(status: item.status),
                      ],
                      cardBuilder: (item) => EntityCard(
                        title: item.reference ?? '',
                        icon: Icons.work_outline_rounded,
                        tone: IconTone.warning,
                        trailing: StatusBadge(status: item.status),
                        subtitle: item.customer?.name,
                        meta: [
                          item.shipment?.reference ?? '',
                          Formatters.money(item.totalPrice, currency: item.currency, locale: locale),
                          '${item.trips.length} ${context.tr('common.trips')} · ${Formatters.percent(item.progressPercent)}',
                        ],
                        onTap: () => context.go('/jobs/${item.id}'),
                      ),
                      pagination: TablePagination(
                        currentPage: data.currentPage,
                        lastPage: data.lastPage,
                        total: data.total,
                        onPage: (page) => ref.read(jobPageProvider.notifier).state = page,
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

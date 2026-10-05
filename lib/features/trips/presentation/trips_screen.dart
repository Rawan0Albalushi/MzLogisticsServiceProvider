import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/permissions/app_permissions.dart';
import '../../../core/utils/directional_text.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/job.dart';
import '../../../shared/models/trip.dart';
import '../../../shared/providers/session_provider.dart';
import '../../../core/theme/page_visuals.dart';
import '../../../shared/widgets/app_page.dart';
import '../../../shared/widgets/async_body.dart';
import '../../../shared/widgets/entity_card.dart';
import '../../../shared/widgets/filter_bar.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/responsive_data_view.dart';
import '../../../shared/widgets/status_badge.dart';

final tripStatusProvider = StateProvider<String?>((ref) => null);
final tripSearchProvider = StateProvider<String>((ref) => '');
final tripCityProvider = StateProvider<String>((ref) => '');
final tripJobIdProvider = StateProvider<int?>((ref) => null);
final tripJobLabelProvider = StateProvider<String?>((ref) => null);
final tripJobSearchProvider = StateProvider<String>((ref) => '');
final tripDateFromProvider = StateProvider<String?>((ref) => null);
final tripDateToProvider = StateProvider<String?>((ref) => null);
final tripPageProvider = StateProvider<int>((ref) => 1);

final tripJobOptionsProvider = FutureProvider.autoDispose((ref) async {
  if (!ref.watch(sessionProvider).permissions.can(AppPermissions.jobsView)) {
    return const <TransportJob>[];
  }
  final page = await ref.watch(jobRepositoryProvider).list(
        page: 1,
        perPage: 30,
        search: ref.watch(tripJobSearchProvider),
      );
  return page.items;
});

final tripsProvider = FutureProvider.autoDispose((ref) {
  return ref
      .watch(tripRepositoryProvider)
      .list(
        page: ref.watch(tripPageProvider),
        status: ref.watch(tripStatusProvider),
        search: ref.watch(tripSearchProvider),
        city: ref.watch(tripCityProvider),
        jobId: ref.watch(tripJobIdProvider),
        dateFrom: ref.watch(tripDateFromProvider),
        dateTo: ref.watch(tripDateToProvider),
      );
});

final unassignedTripsProvider = FutureProvider.autoDispose((ref) {
  return ref
      .watch(tripRepositoryProvider)
      .list(status: 'unassigned', page: 1, perPage: 50);
});

final tripDetailProvider = FutureProvider.autoDispose.family((ref, int id) {
  return ref.watch(tripRepositoryProvider).show(id);
});

class TripsScreen extends ConsumerWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(sessionProvider).permissions.can(AppPermissions.tripsView)) {
      return const NoPermissionState();
    }
    final locale = Localizations.localeOf(context).languageCode;
    final canFilterByJob = ref.watch(sessionProvider).permissions.can(AppPermissions.jobsView);
    final jobOptions = ref.watch(tripJobOptionsProvider);
    final selectedJobId = ref.watch(tripJobIdProvider);
    final selectedJobLabel = ref.watch(tripJobLabelProvider);
    return AppPage(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            title: context.tr('trips.title'),
            subtitle: context.tr('trips.subtitle'),
          ),
          const SizedBox(height: 12),
          FilterBar(
            children: [
              FilterSearchField(
                hint: context.tr('common.searchReference'),
                onChanged: (value) {
                  ref.read(tripSearchProvider.notifier).state = value;
                  ref.read(tripPageProvider.notifier).state = 1;
                },
              ),
              FilterSearchField(
                hint: context.tr('common.cityPlaceholder'),
                onChanged: (value) {
                  ref.read(tripCityProvider.notifier).state = value;
                  ref.read(tripPageProvider.notifier).state = 1;
                },
              ),
              if (canFilterByJob)
                FilterLookup(
                  value: selectedJobId?.toString(),
                  selectedLabel: selectedJobLabel,
                  loading: jobOptions.isLoading,
                  emptyLabel: jobOptions.hasError
                      ? context.tr('common.error')
                      : context.tr('common.noResults'),
                  options: [
                    for (final job in jobOptions.value ?? const <TransportJob>[])
                      FilterOption(
                        value: '${job.id}',
                        label: job.reference ?? '',
                      ),
                  ],
                  onQuery: (value) {
                    ref.read(tripJobSearchProvider.notifier).state = value;
                  },
                  onChanged: (option) {
                    ref.read(tripJobIdProvider.notifier).state =
                        option == null ? null : int.tryParse(option.value);
                    ref.read(tripJobLabelProvider.notifier).state = option?.label;
                    ref.read(tripPageProvider.notifier).state = 1;
                  },
                ),
              FilterSelect(
                options: AppConfig.tripStatuses,
                value: ref.watch(tripStatusProvider),
                onChanged: (value) {
                  ref.read(tripStatusProvider.notifier).state = value;
                  ref.read(tripPageProvider.notifier).state = 1;
                },
                labelOf: context.l10n.status,
              ),
              FilterDateRange(
                from: ref.watch(tripDateFromProvider),
                to: ref.watch(tripDateToProvider),
                onChanged: (from, to) {
                  ref.read(tripDateFromProvider.notifier).state = from;
                  ref.read(tripDateToProvider.notifier).state = to;
                  ref.read(tripPageProvider.notifier).state = 1;
                },
              ),
            ],
          ),
          AsyncBody(
            value: ref.watch(tripsProvider),
            onRetry: () => ref.invalidate(tripsProvider),
            isEmpty: (data) => data.isEmpty,
            empty: EmptyState(
              message: context.tr('trips.empty'),
              icon: Icons.route_outlined,
            ),
            builder: (data) {
              return ResponsiveDataView<Trip>(
                items: data.items,
                columns: [
                  DataColumnSpec(context.tr('common.reference')),
                  DataColumnSpec(context.tr('common.job')),
                  DataColumnSpec(context.tr('trips.sequence')),
                  DataColumnSpec(context.tr('shipments.route')),
                  DataColumnSpec(context.tr('common.truck')),
                  DataColumnSpec(context.tr('common.driver')),
                  DataColumnSpec(context.tr('trips.planned')),
                  DataColumnSpec(context.tr('jobs.delivered')),
                  DataColumnSpec(context.tr('trips.scheduledDeparture')),
                  DataColumnSpec(context.tr('trips.eta')),
                  DataColumnSpec(context.tr('common.status')),
                ],
                onRowTap: (item) => context.go('/trips/${item.id}'),
                rowCells: (item) => [
                  Text(item.reference ?? ''),
                  Text(item.job?.reference ?? ''),
                  Text('${item.sequence ?? ''}'),
                  Text(
                    directionalRouteOf(context, item.pickupCity, item.deliveryCity),
                  ),
                  Text(item.truck?.plateNumber ?? '—'),
                  Text(item.driver?.name ?? '—'),
                  Text(Formatters.number(item.plannedQuantity, locale: locale)),
                  Text(
                    Formatters.number(item.deliveredQuantity, locale: locale),
                  ),
                  Text(Formatters.dateTime(item.scheduledDepartureAt, locale: locale)),
                  Text(Formatters.dateTime(item.etaAt, locale: locale)),
                  StatusBadge(status: item.status),
                ],
                cardBuilder: (item) => EntityCard(
                  title: item.reference ?? '',
                  icon: Icons.route_outlined,
                  tone: IconTone.success,
                  trailing: StatusBadge(status: item.status),
                  subtitle: item.job?.reference,
                  meta: [
                    if (item.scheduledDepartureAt != null)
                      Formatters.dateTime(item.scheduledDepartureAt, locale: locale),
                    directionalRouteOf(context, item.pickupCity, item.deliveryCity),
                    [item.truck?.plateNumber, item.driver?.name]
                        .where(
                          (value) =>
                              value != null &&
                              value.toString().trim().isNotEmpty,
                        )
                        .join(' · '),
                  ],
                  onTap: () => context.go('/trips/${item.id}'),
                ),
                pagination: TablePagination(
                  currentPage: data.currentPage,
                  lastPage: data.lastPage,
                  total: data.total,
                  onPage: (page) =>
                      ref.read(tripPageProvider.notifier).state = page,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

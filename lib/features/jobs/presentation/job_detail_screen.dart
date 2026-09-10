import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/providers/session_provider.dart';
import '../../../shared/widgets/async_body.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/status_badge.dart';

final jobDetailProvider = FutureProvider.autoDispose.family((ref, int id) {
  return ref.watch(jobRepositoryProvider).show(id);
});

class JobDetailScreen extends ConsumerWidget {
  const JobDetailScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = Localizations.localeOf(context).languageCode;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: AsyncBody(
        value: ref.watch(jobDetailProvider(id)),
        onRetry: () => ref.invalidate(jobDetailProvider(id)),
        builder: (job) {
          return ListView(
            children: [
              PageHeader(
                title: job.reference ?? context.tr('jobs.detailTitle'),
                subtitle: context.tr('jobs.notATrip'),
                actions: [StatusBadge(status: job.status)],
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: ((job.progressPercent ?? 0) / 100).clamp(0, 1),
                minHeight: 8,
                borderRadius: BorderRadius.circular(8),
                color: AppColors.amber,
                backgroundColor: AppColors.chipBg,
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: context.tr('jobs.detailTitle'),
                child: Column(
                  children: [
                    InfoRow(label: context.tr('common.customer'), value: job.customer?.name ?? '—'),
                    InfoRow(label: context.tr('jobs.progress'), value: Formatters.percent(job.progressPercent)),
                    InfoRow(label: context.tr('jobs.totalQuantity'), value: Formatters.number(job.totalQuantity, locale: locale)),
                    InfoRow(label: context.tr('jobs.delivered'), value: Formatters.number(job.deliveredQuantity, locale: locale)),
                    InfoRow(label: context.tr('quotations.totalPrice'), value: Formatters.money(job.totalPrice, currency: job.currency, locale: locale)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SectionCard(
                title: context.tr('jobs.tripsInJob'),
                child: job.trips.isEmpty
                    ? Text(context.tr('trips.empty'))
                    : Column(
                        children: [
                          for (final trip in job.trips)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text('${context.tr('trips.sequence')} ${trip.sequence ?? ''} · ${trip.reference ?? ''}'),
                              subtitle: Text('${trip.pickupCity ?? ''} → ${trip.deliveryCity ?? ''}'),
                              trailing: StatusBadge(status: trip.status),
                              onTap: () => context.go('/trips/${trip.id}'),
                            ),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

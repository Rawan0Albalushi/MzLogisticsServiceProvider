import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/permissions/app_permissions.dart';
import '../../../shared/providers/session_provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/async_body.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../dispatch/presentation/assign_sheet.dart';
import 'jobs_screen.dart';

class JobDetailScreen extends ConsumerWidget {
  const JobDetailScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
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
                actions: [
                  StatusBadge(status: job.status),
                  if (session.permissions.can(AppPermissions.tripsAssign) && job.unassignedTrips.isNotEmpty)
                    AppButton(
                      label: context.tr('jobs.assignFleet'),
                      amber: true,
                      onPressed: () => showAssignSheet(context, ref, job: job),
                    ),
                ],
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
                    if (job.quotation != null) ...[
                      InfoRow(
                        label: context.tr('quotations.truckCount'),
                        value: '${job.quotation!.dispatchTruckCount}',
                      ),
                      InfoRow(
                        label: context.tr('quotations.truckType'),
                        value: context.l10n.truckType(job.quotation!.truckType),
                      ),
                    ],
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

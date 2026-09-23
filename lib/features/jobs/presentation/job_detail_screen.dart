import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/permissions/app_permissions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/page_visuals.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/providers/session_provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_page.dart';
import '../../../shared/widgets/async_body.dart';
import '../../../shared/widgets/entity_card.dart';
import '../../../shared/widgets/info_grid.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../dispatch/presentation/assign_sheet.dart';
import '../../shipments/presentation/widgets/shipment_request_summary.dart';
import 'jobs_screen.dart';

class JobDetailScreen extends ConsumerWidget {
  const JobDetailScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final locale = Localizations.localeOf(context).languageCode;
    return AppPage(
      child: AsyncBody(
        value: ref.watch(jobDetailProvider(id)),
        onRetry: () => ref.invalidate(jobDetailProvider(id)),
        builder: (job) {
          final progress = ((job.progressPercent ?? 0) / 100).clamp(0.0, 1.0);
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DetailBackLink(label: context.tr('jobs.backToList'), path: '/jobs'),
              const SizedBox(height: 4),
              PageHeader(
                title: job.reference ?? context.tr('jobs.detailTitle'),
                subtitle: context.tr('jobs.notATrip'),
                actions: [
                  StatusBadge(status: job.status),
                  if (session.permissions.can(AppPermissions.tripsAssign) && job.unassignedTrips.isNotEmpty)
                    AppButton(
                      label: context.tr('jobs.assignFleet'),
                      amber: true,
                      icon: Icons.assignment_ind_outlined,
                      onPressed: () => showAssignSheet(context, ref, job: job),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              ResponsiveSplit(
                primary: SectionCard(
                  title: context.tr('jobs.detailTitle'),
                  icon: Icons.work_outline_rounded,
                  tone: IconTone.warning,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DetailHero(
                        title: job.reference ?? context.tr('jobs.detailTitle'),
                        subtitle: Formatters.percent(job.progressPercent),
                        icon: Icons.work_outline_rounded,
                        tone: IconTone.warning,
                        chips: [
                          StatusBadge(status: job.status),
                          if (job.customer?.name != null)
                            DetailChip(label: job.customer!.name!, icon: Icons.apartment_outlined),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 10,
                          color: AppColors.teal,
                          backgroundColor: AppColors.chipBg,
                        ),
                      ),
                      const SizedBox(height: 16),
                      InfoGrid(
                        fields: [
                          InfoField(
                            label: context.tr('common.customer'),
                            value: job.customer?.name ?? '—',
                            icon: Icons.apartment_outlined,
                            tone: IconTone.info,
                          ),
                          InfoField(
                            label: context.tr('jobs.progress'),
                            value: Formatters.percent(job.progressPercent),
                            icon: Icons.trending_up_rounded,
                            tone: IconTone.teal,
                          ),
                          InfoField(
                            label: context.tr('jobs.totalQuantity'),
                            value: Formatters.number(job.totalQuantity, locale: locale),
                            icon: Icons.inventory_2_outlined,
                          ),
                          InfoField(
                            label: context.tr('jobs.delivered'),
                            value: Formatters.number(job.deliveredQuantity, locale: locale),
                            icon: Icons.done_all_rounded,
                            tone: IconTone.success,
                          ),
                          InfoField(
                            label: context.tr('quotations.totalPrice'),
                            value: Formatters.money(job.totalPrice, currency: job.currency, locale: locale),
                            icon: Icons.payments_outlined,
                            tone: IconTone.success,
                          ),
                          if (job.shipment != null)
                            InfoField(
                              label: context.tr('shipments.paymentTerms'),
                              value: paymentTermsLabel(context, job.shipment!),
                              icon: Icons.account_balance_wallet_outlined,
                              tone: IconTone.info,
                              wide: true,
                            ),
                          if (job.quotation != null)
                            InfoField(
                              label: context.tr('quotations.truckCount'),
                              value: '${job.quotation!.dispatchTruckCount}',
                              icon: Icons.fire_truck_outlined,
                              tone: IconTone.teal,
                            ),
                          if (job.quotation != null)
                            InfoField(
                              label: context.tr('quotations.truckType'),
                              value: context.l10n.truckType(job.quotation!.truckType, label: job.quotation!.truckTypeLabel),
                              icon: Icons.category_outlined,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                secondary: SectionCard(
                  title: context.tr('jobs.tripsInJob'),
                  icon: Icons.route_outlined,
                  tone: IconTone.success,
                  child: job.trips.isEmpty
                      ? Text(context.tr('trips.empty'), style: const TextStyle(color: AppColors.muted))
                      : Column(
                          children: [
                            for (var i = 0; i < job.trips.length; i++) ...[
                              if (i > 0) const SizedBox(height: 10),
                              EntityCard(
                                title: job.trips[i].reference ?? '${context.tr('trips.sequence')} ${job.trips[i].sequence ?? ''}',
                                icon: Icons.route_outlined,
                                tone: IconTone.success,
                                trailing: StatusBadge(status: job.trips[i].status),
                                subtitle: '${context.tr('trips.sequence')} ${job.trips[i].sequence ?? ''}',
                                meta: [
                                  '${job.trips[i].pickupCity ?? ''} → ${job.trips[i].deliveryCity ?? ''}',
                                ],
                                onTap: () => context.go('/trips/${job.trips[i].id}'),
                              ),
                            ],
                          ],
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

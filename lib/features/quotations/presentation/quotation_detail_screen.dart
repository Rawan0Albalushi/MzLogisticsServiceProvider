import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/permissions/app_permissions.dart';
import '../../../core/theme/page_visuals.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/providers/session_provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_page.dart';
import '../../../shared/widgets/async_body.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/info_grid.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/status_badge.dart';
import 'quotations_screen.dart';
import 'widgets/quotation_billing_preview.dart';

final quotationDetailProvider = FutureProvider.autoDispose.family((ref, int id) {
  return ref.watch(quotationRepositoryProvider).show(id);
});

class QuotationDetailScreen extends ConsumerWidget {
  const QuotationDetailScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = Localizations.localeOf(context).languageCode;
    final canManage = ref.watch(sessionProvider).permissions.can(AppPermissions.quotationsManage);
    return AppPage(
      child: AsyncBody(
        value: ref.watch(quotationDetailProvider(id)),
        onRetry: () => ref.invalidate(quotationDetailProvider(id)),
        builder: (item) {
          final shipment = item.shipment;
          final routeLabel = [
            if (shipment?.pickupCity?.isNotEmpty == true) shipment!.pickupCity,
            if (shipment?.deliveryCity?.isNotEmpty == true) shipment!.deliveryCity,
          ].join(' → ');

          return ListView(
            children: [
              DetailBackLink(label: context.tr('quotations.backToList'), path: '/quotations'),
              const SizedBox(height: 4),
              PageHeader(
                title: item.reference ?? context.tr('quotations.detailTitle'),
                subtitle: context.tr('quotations.detailTitle'),
                actions: [
                  StatusBadge(status: item.status),
                  if (canManage && item.canWithdraw)
                    AppButton(
                      label: context.tr('common.withdraw'),
                      outlined: true,
                      icon: Icons.undo_rounded,
                      onPressed: () async {
                        final ok = await showConfirmDialog(context, message: context.tr('quotations.withdrawConfirm'));
                        if (!ok) {
                          return;
                        }
                        try {
                          await ref.read(quotationRepositoryProvider).withdraw(id);
                          ref.invalidate(quotationDetailProvider(id));
                          ref.invalidate(quotationsProvider);
                        } on ApiException catch (error) {
                          if (context.mounted) {
                            showAppSnack(context, error.message);
                          }
                        }
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),
              ResponsiveSplit(
                primary: SectionCard(
                  title: context.tr('quotations.offerSection'),
                  icon: Icons.request_quote_outlined,
                  tone: IconTone.info,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DetailHero(
                        title: item.reference ?? context.tr('quotations.detailTitle'),
                        subtitle: Formatters.money(item.totalPrice, currency: item.currency, locale: locale),
                        icon: Icons.request_quote_outlined,
                        tone: IconTone.info,
                        chips: [
                          StatusBadge(status: item.status),
                          if (shipment != null)
                            DetailChip(
                              label: shipment.reference ?? context.tr('nav.shipments'),
                              icon: Icons.local_shipping_outlined,
                              onTap: () => context.go('/shipments/${shipment.id}'),
                            ),
                          if (routeLabel.isNotEmpty)
                            DetailChip(label: routeLabel, icon: Icons.route_outlined),
                        ],
                      ),
                      const SizedBox(height: 16),
                      InfoGrid(
                        fields: [
                          InfoField(
                            label: context.tr('quotations.totalPrice'),
                            value: Formatters.money(item.totalPrice, currency: item.currency, locale: locale),
                            icon: Icons.payments_outlined,
                            tone: IconTone.success,
                          ),
                          InfoField(
                            label: context.tr('quotations.additionalCosts'),
                            value: Formatters.money(item.additionalCosts, currency: item.currency, locale: locale),
                            icon: Icons.receipt_long_outlined,
                            tone: IconTone.warning,
                          ),
                          if (shipment != null)
                            InfoField(
                              label: context.tr('nav.shipments'),
                              value: shipment.reference ?? '—',
                              icon: Icons.local_shipping_outlined,
                              tone: IconTone.teal,
                              onTap: () => context.go('/shipments/${shipment.id}'),
                            ),
                        ],
                      ),
                      if (shipment != null) ...[
                        const SizedBox(height: 16),
                        QuotationBillingPreview(
                          shipment: shipment,
                          totalPrice: item.totalPrice ?? 0,
                          tripCount: item.plannedTripRecords,
                          currency: item.currency,
                        ),
                      ],
                    ],
                  ),
                ),
                secondary: Column(
                  children: [
                    SectionCard(
                      title: context.tr('quotations.executionSection'),
                      icon: Icons.agriculture_outlined,
                      tone: IconTone.teal,
                      child: InfoGrid(
                        fields: [
                          InfoField(
                            label: context.tr('quotations.truckCount'),
                            value: '${item.truckCount ?? 0}',
                            icon: Icons.fire_truck_outlined,
                            tone: IconTone.teal,
                          ),
                          InfoField(
                            label: context.tr('quotations.truckType'),
                            value: context.l10n.truckType(item.truckType, label: item.truckTypeLabel),
                            icon: Icons.category_outlined,
                          ),
                          InfoField(
                            label: context.tr('quotations.truckCapacity'),
                            value: Formatters.number(item.truckCapacityTons, locale: locale),
                            icon: Icons.scale_outlined,
                            tone: IconTone.info,
                          ),
                          InfoField(
                            label: context.tr('quotations.tripCount'),
                            value: '${item.tripCount ?? 0}',
                            icon: Icons.route_outlined,
                            tone: IconTone.success,
                          ),
                          InfoField(
                            label: context.tr('quotations.quantityPerTrip'),
                            value: Formatters.number(item.quantityPerTrip, locale: locale),
                            icon: Icons.inventory_2_outlined,
                          ),
                          InfoField(
                            label: context.tr('quotations.durationDays'),
                            value: '${item.durationDays ?? 0}',
                            icon: Icons.schedule_outlined,
                            tone: IconTone.warning,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SectionCard(
                      title: context.tr('quotations.validitySection'),
                      icon: Icons.event_outlined,
                      tone: IconTone.warning,
                      child: InfoGrid(
                        fields: [
                          InfoField(
                            label: context.tr('quotations.validUntil'),
                            value: Formatters.date(item.validUntil, locale: locale),
                            icon: Icons.event_available_outlined,
                            tone: IconTone.warning,
                          ),
                        ],
                      ),
                    ),
                    if (item.conditions != null && item.conditions!.trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      SectionCard(
                        title: context.tr('quotations.conditions'),
                        icon: Icons.notes_outlined,
                        tone: IconTone.muted,
                        child: Text(item.conditions!, style: const TextStyle(height: 1.5)),
                      ),
                    ],
                  ],
                ),
              ),
              if (shipment != null) ...[
                const SizedBox(height: 12),
                SectionCard(
                  title: context.tr('quotations.shipmentSection'),
                  icon: Icons.local_shipping_outlined,
                  tone: IconTone.teal,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      InfoGrid(
                        fields: [
                          InfoField(
                            label: context.tr('common.reference'),
                            value: shipment.reference ?? '—',
                            icon: Icons.tag_outlined,
                            onTap: () => context.go('/shipments/${shipment.id}'),
                          ),
                          InfoField(
                            label: context.tr('common.customer'),
                            value: shipment.customer?.name ?? '—',
                            icon: Icons.apartment_outlined,
                            tone: IconTone.info,
                          ),
                          InfoField(
                            label: context.tr('shipments.cargo'),
                            value: shipment.cargoType ?? '—',
                            icon: Icons.inventory_2_outlined,
                          ),
                          InfoField(
                            label: context.tr('common.requiredDate'),
                            value: Formatters.date(shipment.requiredDate, locale: locale),
                            icon: Icons.event_outlined,
                            tone: IconTone.warning,
                          ),
                          if (routeLabel.isNotEmpty)
                            InfoField(
                              label: context.tr('shipments.route'),
                              value: routeLabel,
                              icon: Icons.route_outlined,
                              tone: IconTone.success,
                              wide: true,
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: AppButton(
                          label: shipment.reference ?? context.tr('nav.shipments'),
                          outlined: true,
                          icon: Icons.open_in_new,
                          onPressed: () => context.go('/shipments/${shipment.id}'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

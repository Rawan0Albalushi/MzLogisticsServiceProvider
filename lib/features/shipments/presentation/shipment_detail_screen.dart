import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/permissions/app_permissions.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/providers/session_provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/async_body.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/status_badge.dart';

final shipmentDetailProvider = FutureProvider.autoDispose.family((ref, int id) {
  return ref.watch(shipmentRepositoryProvider).show(id);
});

class ShipmentDetailScreen extends ConsumerWidget {
  const ShipmentDetailScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final locale = Localizations.localeOf(context).languageCode;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: AsyncBody(
        value: ref.watch(shipmentDetailProvider(id)),
        onRetry: () => ref.invalidate(shipmentDetailProvider(id)),
        builder: (item) {
          final canQuote = session.permissions.can(AppPermissions.quotationsCreate) &&
              !item.quotedBy(session.user?.organizationId) &&
              !session.isPendingReview;
          return ListView(
            children: [
              PageHeader(
                title: item.reference ?? context.tr('shipments.detailTitle'),
                subtitle: item.customer?.name,
                actions: [
                  if (canQuote)
                    AppButton(
                      label: context.tr('shipments.quote'),
                      amber: true,
                      onPressed: () => context.go('/shipments/$id/quote'),
                    ),
                ],
              ),
              if (session.isPendingReview) ...[
                const SizedBox(height: 12),
                const PendingReviewBanner(),
              ],
              const SizedBox(height: 16),
              SectionCard(
                title: context.tr('shipments.detailTitle'),
                child: Column(
                  children: [
                    InfoRow(label: context.tr('common.status'), value: context.l10n.status(item.status)),
                    InfoRow(label: context.tr('shipments.cargo'), value: item.cargoType ?? '—'),
                    InfoRow(label: context.tr('shipments.weight'), value: '${Formatters.number(item.weightTons, locale: locale)} ${context.tr('common.tons')}'),
                    InfoRow(label: context.tr('common.quantity'), value: '${Formatters.number(item.quantity, locale: locale)} ${item.quantityUnit ?? ''}'),
                    InfoRow(label: context.tr('shipments.pickup'), value: '${item.pickupCity ?? ''} · ${item.pickupAddress ?? ''}'),
                    InfoRow(label: context.tr('shipments.delivery'), value: '${item.deliveryCity ?? ''} · ${item.deliveryAddress ?? ''}'),
                    InfoRow(label: context.tr('common.requiredDate'), value: Formatters.date(item.requiredDate, locale: locale)),
                    if (item.notes != null) InfoRow(label: context.tr('common.notes'), value: item.notes!),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SectionCard(
                title: context.tr('shipments.quotesOnRequest'),
                child: item.quotations.isEmpty
                    ? Text(context.tr('quotations.empty'))
                    : Column(
                        children: [
                          for (final quote in item.quotations)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(quote.reference ?? ''),
                              subtitle: Text(Formatters.money(quote.totalPrice, currency: quote.currency, locale: locale)),
                              trailing: StatusBadge(status: quote.status),
                              onTap: quote.provider?.id == session.user?.organizationId
                                  ? () => context.go('/quotations/${quote.id}')
                                  : null,
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

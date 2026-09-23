import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/permissions/app_permissions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/quotation.dart';
import '../../../shared/providers/session_provider.dart';
import '../../../shared/widgets/app_page.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/async_body.dart';
import '../../../core/theme/page_visuals.dart';
import '../../../shared/widgets/icon_well.dart';
import '../../../shared/widgets/info_grid.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/status_badge.dart';
import 'widgets/shipment_request_summary.dart';

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
    return AppPage(
      child: AsyncBody(
        value: ref.watch(shipmentDetailProvider(id)),
        onRetry: () => ref.invalidate(shipmentDetailProvider(id)),
        builder: (item) {
          final alreadyQuoted = item.quotedBy(session.user?.organizationId);
          final canQuote = session.canOperate &&
              session.permissions.can(AppPermissions.quotationsCreate) &&
              !alreadyQuoted;
          final customerName = item.customer?.name?.trim();
          final cargoType = item.cargoType?.trim();
          final subtitleParts = <String>[
            if (customerName != null && customerName.isNotEmpty) customerName,
            if (cargoType != null && cargoType.isNotEmpty) cargoType,
          ];

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DetailBackLink(label: context.tr('shipments.backToList'), path: '/shipments'),
              const SizedBox(height: 4),
              PageHeader(
                title: item.reference ?? context.tr('shipments.detailTitle'),
                subtitle: subtitleParts.isEmpty ? null : subtitleParts.join(' · '),
                actions: [
                  StatusBadge(status: item.status),
                  if (canQuote)
                    AppButton(
                      label: context.tr('shipments.quote'),
                      amber: true,
                      icon: Icons.request_quote_outlined,
                      onPressed: () => context.push('/shipments/$id/quote'),
                    ),
                ],
              ),
              if (session.isAccountRestricted) ...[
                const SizedBox(height: 12),
                const PendingReviewBanner(),
              ],
              if (alreadyQuoted) ...[
                const SizedBox(height: 12),
                const _QuotedBanner(),
              ],
              const SizedBox(height: 16),
              ShipmentRequestSummary(shipment: item),
              const SizedBox(height: 12),
              _QuotationsCard(
                quotations: item.quotations,
                locale: locale,
                organizationId: session.user?.organizationId,
                canQuote: canQuote,
                onQuote: () => context.push('/shipments/$id/quote'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _QuotedBanner extends StatelessWidget {
  const _QuotedBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.successSoft,
        borderRadius: BorderRadius.circular(AppColors.radius),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const IconWell(icon: Icons.check_circle_outline, tone: IconTone.success, size: IconWellSize.sm),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.tr('shipments.alreadyQuoted'),
              style: const TextStyle(height: 1.45, color: AppColors.success),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuotationsCard extends StatelessWidget {
  const _QuotationsCard({
    required this.quotations,
    required this.locale,
    required this.organizationId,
    required this.canQuote,
    required this.onQuote,
  });

  final List<Quotation> quotations;
  final String locale;
  final int? organizationId;
  final bool canQuote;
  final VoidCallback onQuote;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: context.tr('shipments.quotesOnRequest'),
      icon: Icons.request_quote_outlined,
      tone: IconTone.info,
      child: quotations.isEmpty
          ? _QuotationsEmpty(canQuote: canQuote, onQuote: onQuote)
          : Column(
              children: [
                for (var i = 0; i < quotations.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  _QuotationTile(
                    quote: quotations[i],
                    locale: locale,
                    ownQuote: quotations[i].provider?.id == organizationId,
                  ),
                ],
              ],
            ),
    );
  }
}

class _QuotationsEmpty extends StatelessWidget {
  const _QuotationsEmpty({required this.canQuote, required this.onQuote});

  final bool canQuote;
  final VoidCallback onQuote;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          const IconWell(icon: Icons.request_quote_outlined, tone: IconTone.info),
          const SizedBox(height: 10),
          Text(
            context.tr('shipments.noQuotations'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.muted, height: 1.45),
          ),
          if (canQuote) ...[
            const SizedBox(height: 14),
            AppButton(
              label: context.tr('shipments.quote'),
              amber: true,
              icon: Icons.request_quote_outlined,
              onPressed: onQuote,
            ),
          ],
        ],
      ),
    );
  }
}

class _QuotationTile extends StatelessWidget {
  const _QuotationTile({
    required this.quote,
    required this.locale,
    required this.ownQuote,
  });

  final Quotation quote;
  final String locale;
  final bool ownQuote;

  @override
  Widget build(BuildContext context) {
    final plan = [
      if (quote.truckCount != null) '${quote.truckCount} ${context.tr('common.trucks')}',
      if (quote.tripCount != null) '${quote.tripCount} ${context.tr('common.trips')}',
      if (quote.truckType != null || quote.truckTypeLabel != null)
        context.l10n.truckType(quote.truckType, label: quote.truckTypeLabel),
    ].join(' · ');

    return InkWell(
      onTap: ownQuote ? () => context.go('/quotations/${quote.id}') : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconWell(
              icon: Icons.request_quote_outlined,
              tone: ownQuote ? IconTone.info : IconTone.muted,
              size: IconWellSize.sm,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quote.reference ?? context.tr('quotations.detailTitle'),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Formatters.money(quote.totalPrice, currency: quote.currency, locale: locale),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    textDirection: TextDirection.ltr,
                  ),
                  if (plan.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(plan, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.muted)),
                  ],
                  if (ownQuote) ...[
                    const SizedBox(height: 6),
                    Text(
                      context.tr('shipments.openQuote'),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.navy),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            StatusBadge(status: quote.status),
          ],
        ),
      ),
    );
  }
}

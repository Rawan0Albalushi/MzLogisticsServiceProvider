import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/models/shipment.dart';
import '../../domain/billing_split.dart';

class QuotationBillingPreview extends StatelessWidget {
  const QuotationBillingPreview({
    super.key,
    required this.shipment,
    required this.totalPrice,
    required this.tripCount,
    this.currency,
  });

  final Shipment shipment;
  final double totalPrice;
  final int tripCount;
  final String? currency;

  bool get _prepaid =>
      shipment.paymentPrepaid || shipment.paymentBillingTrigger == 'on_award';

  bool get _perTrip => !_prepaid && shipment.paymentBillingUnit == 'trip';

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final trips = tripCount < 1 ? 1 : tripCount;
    final amount = Formatters.money(totalPrice, currency: currency, locale: locale);
    final days = shipment.paymentDueDays ?? 0;
    final lines = <String>[];

    if (_prepaid) {
      lines.add(context.tr('quotations.billingPrepaid'));
    } else if (_perTrip) {
      lines.add(context.tr('quotations.billingPerTrip', {'count': '$trips'}));
      lines.add(
        days <= 0
            ? context.tr('quotations.billingPerTripDue')
            : context.tr('quotations.billingPerTripNet', {'days': '$days'}),
      );
      if (totalPrice > 0) {
        final slices = BillingSplit.splitEqually(totalPrice, trips);
        final shown = slices.length > 4 ? slices.take(3).toList() : slices;
        for (var index = 0; index < shown.length; index++) {
          lines.add(
            context.tr('quotations.billingTripAmount', {
              'n': '${index + 1}',
              'amount': Formatters.money(shown[index], currency: currency, locale: locale),
            }),
          );
        }
        if (slices.length > shown.length) {
          lines.add(
            context.tr('quotations.billingTripRest', {
              'amount': Formatters.money(slices.last, currency: currency, locale: locale),
            }),
          );
        }
      }
    } else if (totalPrice <= 0) {
      lines.add(context.tr('quotations.billingFullJob'));
      lines.add(
        days <= 0
            ? context.tr('quotations.billingFullJobDueHint')
            : context.tr('quotations.billingFullJobNetHint', {'days': '$days'}),
      );
    } else {
      lines.add(
        days <= 0
            ? context.tr('quotations.billingFullJobDue', {'amount': amount})
            : context.tr('quotations.billingFullJobNet', {'amount': amount, 'days': '$days'}),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.infoSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('quotations.billingPreviewTitle'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.info,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
          ),
          const SizedBox(height: 6),
          for (var index = 0; index < lines.length; index++) ...[
            if (index > 0) const SizedBox(height: 4),
            Text(
              lines[index],
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.info,
                    fontWeight: index == 0 ? FontWeight.w600 : FontWeight.w500,
                    height: 1.4,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

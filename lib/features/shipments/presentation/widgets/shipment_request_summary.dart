import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/models/shipment.dart';
import '../../../../shared/utils/quantity_units.dart';
import '../../../../shared/widgets/location_preview.dart';
import '../../../../core/theme/page_visuals.dart';
import '../../../../shared/widgets/section_card.dart';

class ShipmentRequestSummary extends StatelessWidget {
  const ShipmentRequestSummary({
    super.key,
    required this.shipment,
    this.showRoute = true,
  });

  final Shipment shipment;
  final bool showRoute;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final description = shipment.cargoDescription?.trim();
    final notes = shipment.notes?.trim();
    final metrics = <_SummaryMetric>[
      _SummaryMetric(context.tr('common.type'), shipment.cargoType ?? '—'),
      _SummaryMetric(
        context.tr('shipments.weight'),
        '${Formatters.number(shipment.weightTons, locale: locale)} ${context.tr('common.tons')}',
      ),
      if (!QuantityUnits.isTons(shipment.quantityUnit))
        _SummaryMetric(
          context.tr('common.quantity'),
          '${Formatters.number(shipment.quantity, locale: locale)} ${QuantityUnits.label(context, shipment.quantityUnit)}',
        ),
      if (shipment.volumeCbm != null)
        _SummaryMetric(
          context.tr('shipments.volume'),
          '${Formatters.number(shipment.volumeCbm, locale: locale)} ${context.tr('common.cbm')}',
        ),
    ];
    final schedule = <_SummaryMetric>[
      _SummaryMetric(context.tr('common.customer'), shipment.customer?.name ?? '—'),
      _SummaryMetric(
        context.tr('common.requiredDate'),
        Formatters.date(shipment.requiredDate, locale: locale),
      ),
      if (shipment.publishedAt != null)
        _SummaryMetric(
          context.tr('shipments.publishedAt'),
          Formatters.dateTime(shipment.publishedAt, locale: locale),
        ),
    ];
    final payment = _paymentMetrics(context, shipment);

    return SectionCard(
      title: context.tr('shipments.requestSummary'),
      icon: Icons.inventory_2_outlined,
      tone: IconTone.teal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SummaryBlock(
            title: context.tr('shipments.cargo'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _MetricGrid(metrics: metrics),
                if (description != null && description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _NarrativeField(
                    label: context.tr('shipments.cargoDescription'),
                    value: description,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          _SummaryBlock(
            title: context.tr('shipments.schedule'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _MetricGrid(metrics: schedule),
                if (notes != null && notes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _NarrativeField(label: context.tr('common.notes'), value: notes),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          _SummaryBlock(
            title: context.tr('shipments.paymentTerms'),
            child: _MetricGrid(metrics: payment),
          ),
          if (showRoute) ...[
            const SizedBox(height: 18),
            _SummaryBlock(
              title: context.tr('shipments.route'),
              showDivider: false,
              child: _RouteStops(shipment: shipment),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryBlock extends StatelessWidget {
  const _SummaryBlock({
    required this.title,
    required this.child,
    this.showDivider = true,
  });

  final String title;
  final Widget child;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 10),
        child,
        if (showDivider) ...[
          const SizedBox(height: 18),
          const Divider(height: 1, color: AppColors.border),
        ],
      ],
    );
  }
}

class _SummaryMetric {
  const _SummaryMetric(this.label, this.value);

  final String label;
  final String value;
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics});

  final List<_SummaryMetric> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 680
            ? metrics.length.clamp(1, 4)
            : constraints.maxWidth >= 420
                ? 2
                : 1;
        final rows = <List<_SummaryMetric>>[];
        for (var i = 0; i < metrics.length; i += columns) {
          final end = i + columns > metrics.length ? metrics.length : i + columns;
          rows.add(metrics.sublist(i, end));
        }

        return DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) ...[
                if (rowIndex > 0) const Divider(height: 1, color: AppColors.border),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var cellIndex = 0; cellIndex < columns; cellIndex++) ...[
                        if (cellIndex > 0)
                          const VerticalDivider(width: 1, thickness: 1, color: AppColors.border),
                        Expanded(
                          child: cellIndex < rows[rowIndex].length
                              ? _MetricCell(metric: rows[rowIndex][cellIndex])
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _MetricCell extends StatelessWidget {
  const _MetricCell({required this.metric});

  final _SummaryMetric metric;

  bool _isMostlyLtr(String value) {
    return RegExp(r'^[\x00-\x7F\-_/.:#→\s]+$').hasMatch(value.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            metric.label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 6),
          Text(
            metric.value,
            style: Theme.of(context).textTheme.titleSmall,
            textDirection: _isMostlyLtr(metric.value) ? TextDirection.ltr : null,
          ),
        ],
      ),
    );
  }
}

class _NarrativeField extends StatelessWidget {
  const _NarrativeField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.muted),
        ),
        const SizedBox(height: 6),
        Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.45)),
      ],
    );
  }
}

class _RouteStops extends StatelessWidget {
  const _RouteStops({required this.shipment});

  final Shipment shipment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 640;
        final pickup = _StopPanel(
          title: context.tr('shipments.pickup'),
          icon: Icons.trip_origin,
          address: shipment.pickupAddress,
          city: shipment.pickupCity,
          lat: shipment.pickupLat,
          lng: shipment.pickupLng,
          accent: AppColors.navy,
        );
        final delivery = _StopPanel(
          title: context.tr('shipments.delivery'),
          icon: Icons.flag_outlined,
          address: shipment.deliveryAddress,
          city: shipment.deliveryCity,
          lat: shipment.deliveryLat,
          lng: shipment.deliveryLng,
          accent: AppColors.amber,
        );

        if (stacked) {
          return Column(
            children: [
              pickup,
              const _RouteConnector(vertical: true),
              delivery,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: pickup),
            const _RouteConnector(vertical: false),
            Expanded(child: delivery),
          ],
        );
      },
    );
  }
}

class _StopPanel extends StatelessWidget {
  const _StopPanel({
    required this.title,
    required this.icon,
    required this.accent,
    this.address,
    this.city,
    this.lat,
    this.lng,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final String? address;
  final String? city;
  final double? lat;
  final double? lng;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: accent),
              const SizedBox(width: 8),
              Text(title, style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
          LocationPreview(
            title: '',
            address: address,
            city: city,
            lat: lat,
            lng: lng,
          ),
        ],
      ),
    );
  }
}

class _RouteConnector extends StatelessWidget {
  const _RouteConnector({required this.vertical});

  final bool vertical;

  @override
  Widget build(BuildContext context) {
    if (vertical) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            SizedBox(height: 4),
            Icon(Icons.south, size: 16, color: AppColors.muted),
            SizedBox(height: 4),
          ],
        ),
      );
    }

    return const Padding(
      padding: EdgeInsets.fromLTRB(10, 28, 10, 0),
      child: Icon(Icons.arrow_forward, size: 18, color: AppColors.muted),
    );
  }
}

List<_SummaryMetric> _paymentMetrics(BuildContext context, Shipment shipment) {
  final prepaid = shipment.paymentPrepaid || shipment.paymentBillingTrigger == 'on_award';
  return [
    _SummaryMetric(
      context.tr('shipments.paymentTrigger'),
      prepaid ? context.tr('shipments.payOnAward') : context.tr('shipments.payOnDeliveryTrigger'),
    ),
    if (!prepaid) ...[
      _SummaryMetric(
        context.tr('shipments.paymentUnit'),
        shipment.paymentBillingUnit == 'trip'
            ? context.tr('shipments.unitTrip')
            : context.tr('shipments.unitJob'),
      ),
      _SummaryMetric(
        context.tr('shipments.paymentDue'),
        (shipment.paymentDueDays ?? 0) <= 0
            ? context.tr('shipments.dueImmediate')
            : context.tr('shipments.payNetDays', {'days': '${shipment.paymentDueDays}'}),
      ),
    ],
  ];
}

String paymentTermsLabel(BuildContext context, Shipment shipment) {
  if (shipment.paymentPrepaid || shipment.paymentBillingTrigger == 'on_award') {
    return context.tr('shipments.payOnAward');
  }
  final days = shipment.paymentDueDays ?? 0;
  final perTrip = shipment.paymentBillingUnit == 'trip';
  if (perTrip && days <= 0) {
    return context.tr('shipments.payPerTrip');
  }
  if (perTrip) {
    return context.tr('shipments.payPerTripNet', {'days': '$days'});
  }
  if (days <= 0) {
    return context.tr('shipments.payOnDelivery');
  }
  return context.tr('shipments.payNetDays', {'days': '$days'});
}

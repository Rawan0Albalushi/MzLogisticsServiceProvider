import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/models/quotation.dart';
import '../../../shared/models/shipment.dart';
import '../../../shared/models/truck.dart';
import '../../../shared/providers/session_provider.dart';
import '../../../shared/utils/quantity_units.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/async_body.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/section_card.dart';
import '../../quotations/presentation/quotations_screen.dart';
import '../../truck_types/presentation/truck_type_providers.dart';
import '../domain/quote_transport_planner.dart';
import 'shipment_detail_screen.dart';
import 'widgets/shipment_request_summary.dart';

final quoteFleetTrucksProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(fleetRepositoryProvider).trucks(page: 1, perPage: 100);
});

class SubmitQuotationScreen extends ConsumerStatefulWidget {
  const SubmitQuotationScreen({super.key, required this.shipmentId});

  final int shipmentId;

  @override
  ConsumerState<SubmitQuotationScreen> createState() => _SubmitQuotationScreenState();
}

class _SubmitQuotationScreenState extends ConsumerState<SubmitQuotationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _price = TextEditingController();
  final _truckCount = TextEditingController(text: '1');
  final _capacity = TextEditingController();
  final _tripCount = TextEditingController(text: '1');
  final _qtyPerTrip = TextEditingController();
  final _duration = TextEditingController(text: '1');
  final _extra = TextEditingController();
  final _conditions = TextEditingController();
  String? _truckType;
  var _loading = false;
  var _qtyTouched = false;
  var _capacityTouched = false;
  var _trucksTouched = false;
  var _tripsTouched = false;
  var _durationTouched = false;
  String? _appliedPlanKey;
  Shipment? _shipment;

  void _setControllerText(TextEditingController controller, String value) {
    if (controller.text == value) {
      return;
    }
    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  int _neededTripCount(Shipment? shipment) {
    final quantity = shipment?.quantity ?? 0;
    final perTrip = _qtyPerTripValue > 0 ? _qtyPerTripValue : quantity;
    if (quantity <= 0 || perTrip <= 0) {
      return _plannedTrucks;
    }
    return math.max(_plannedTrucks, (quantity / perTrip).ceil());
  }

  void _syncTripsToPlan() {
    final trucks = _plannedTrucks;
    final trips = int.tryParse(_tripCount.text.trim()) ?? 0;
    final needed = _neededTripCount(_shipment);
    if (trucks > trips || trips > math.max(needed, trucks) * 2) {
      _setControllerText(_tripCount, '$trucks');
    }
  }

  int get _plannedTrucks {
    final trucks = int.tryParse(_truckCount.text.trim()) ?? 1;
    return trucks < 1 ? 1 : trucks;
  }

  int get _plannedTrips {
    final trips = int.tryParse(_tripCount.text.trim()) ?? 1;
    return _plannedTrucks > trips ? _plannedTrucks : trips;
  }

  double get _qtyPerTripValue => double.tryParse(_qtyPerTrip.text.trim()) ?? 0;

  double get _capacityValue => double.tryParse(_capacity.text.trim()) ?? 0;

  @override
  void dispose() {
    _price.dispose();
    _truckCount.dispose();
    _capacity.dispose();
    _tripCount.dispose();
    _qtyPerTrip.dispose();
    _duration.dispose();
    _extra.dispose();
    _conditions.dispose();
    super.dispose();
  }

  String _formatInput(num value) {
    if (value <= 0) {
      return '';
    }
    final rounded = (value * 100).round() / 100;
    if (rounded == rounded.roundToDouble()) {
      return '${rounded.round()}';
    }
    return rounded.toStringAsFixed(2);
  }

  List<double> _fleetCapacities(List<Truck> trucks) {
    return trucks
        .where((item) => item.type == _truckType && !item.isUnavailable)
        .map((item) => item.capacityTons ?? 0)
        .where((capacity) => capacity > 0)
        .toList();
  }

  String _planSourceKey(Shipment shipment, List<Truck> trucks) {
    return '${shipment.id}|${_truckType ?? ''}|${_fleetCapacities(trucks).join(',')}';
  }

  QuoteTransportSuggestion? _suggestionOf(Shipment shipment, List<Truck> trucks) {
    return QuoteTransportPlanner.suggest(
      quantity: shipment.quantity ?? 0,
      weightTons: shipment.weightTons ?? 0,
      quantityUnit: shipment.quantityUnit,
      fleetCapacities: _fleetCapacities(trucks),
      manualCapacityTons: _capacityTouched ? _capacityValue : null,
    );
  }

  void _writeSuggestion(QuoteTransportSuggestion suggestion, {required bool force}) {
    if (force || !_capacityTouched) {
      _setControllerText(_capacity, _formatInput(suggestion.capacityTons));
    }
    if (force || !_trucksTouched) {
      _setControllerText(_truckCount, '${suggestion.truckCount}');
    }
    if (force || !_tripsTouched) {
      _setControllerText(_tripCount, '${suggestion.tripCount}');
    }
    if (force || !_qtyTouched) {
      _setControllerText(_qtyPerTrip, _formatInput(suggestion.quantityPerTrip));
    }
    if (force || !_durationTouched) {
      _setControllerText(_duration, '${suggestion.durationDays}');
    }
  }

  void _scheduleAutoPlan(Shipment shipment, List<Truck> trucks) {
    if (_truckType == null || _truckType!.isEmpty) {
      return;
    }
    final key = _planSourceKey(shipment, trucks);
    if (key == _appliedPlanKey) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _applyAutoPlan(shipment, trucks);
    });
  }

  void _applyAutoPlan(Shipment shipment, List<Truck> trucks) {
    final key = _planSourceKey(shipment, trucks);
    if (key == _appliedPlanKey) {
      return;
    }
    _appliedPlanKey = key;
    final suggestion = _suggestionOf(shipment, trucks);
    if (suggestion == null) {
      setState(() {});
      return;
    }
    _writeSuggestion(suggestion, force: false);
    setState(() {});
  }

  void _applySuggestionNow(Shipment shipment, List<Truck> trucks) {
    final suggestion = _suggestionOf(shipment, trucks);
    if (suggestion == null) {
      return;
    }
    _trucksTouched = false;
    _tripsTouched = false;
    _qtyTouched = false;
    _capacityTouched = false;
    _durationTouched = false;
    _writeSuggestion(suggestion, force: true);
    setState(() {});
  }

  void _splitQuantityAcrossTrips() {
    if (_qtyTouched) {
      return;
    }
    final quantity = _shipment?.quantity ?? 0;
    final trips = _plannedTrips;
    if (quantity <= 0 || trips <= 0) {
      return;
    }
    _setControllerText(_qtyPerTrip, _formatInput(QuoteTransportPlanner.splitQuantity(quantity, trips)));
  }

  void _onPlanChanged({bool fromTrucks = false, bool fromTrips = false}) {
    if (fromTrucks) {
      _trucksTouched = true;
      if (!_tripsTouched) {
        final shipment = _shipment;
        final capacity = _capacityValue;
        final loads = shipment == null || capacity <= 0
            ? _plannedTrucks
            : QuoteTransportPlanner.loadsNeeded(
                quantity: shipment.quantity ?? 0,
                weightTons: shipment.weightTons ?? 0,
                quantityUnit: shipment.quantityUnit,
                capacityTons: capacity,
              );
        _setControllerText(_tripCount, '${math.max(_plannedTrucks, loads)}');
      } else {
        _syncTripsToPlan();
      }
    }
    if (fromTrips) {
      _tripsTouched = true;
      _syncTripsToPlan();
    }
    _splitQuantityAcrossTrips();
    setState(() {});
  }

  double _loadWeightPerTrip(Shipment shipment) {
    final quantity = shipment.quantity ?? 0;
    final weight = shipment.weightTons ?? 0;
    if (quantity > 0 && _qtyPerTripValue > 0) {
      return weight * (_qtyPerTripValue / quantity);
    }
    return _plannedTrips == 0 ? 0 : weight / _plannedTrips;
  }

  _QuotePlan _planOf(Shipment shipment, List<Truck> trucks, QuoteTransportSuggestion? suggestion) {
    final trips = _plannedTrips;
    final requiredQty = shipment.quantity ?? 0;
    final plannedQty = _qtyPerTripValue * trips;
    final weightPerTrip = _loadWeightPerTrip(shipment);
    final ofType = trucks.where((item) => item.type == _truckType && !item.isUnavailable).toList();
    final maxCapacity = ofType.fold<double>(0, (max, item) {
      final capacity = item.capacityTons ?? 0;
      return capacity > max ? capacity : max;
    });
    return _QuotePlan(
      requiredQuantity: requiredQty,
      plannedQuantity: plannedQty,
      weightPerTrip: weightPerTrip,
      capacity: _capacityValue,
      truckCount: _plannedTrucks,
      tripCount: trips,
      fleetCount: ofType.length,
      fleetMaxCapacity: maxCapacity,
      neededTrips: _neededTripCount(shipment),
      unit: shipment.quantityUnit,
      suggestion: suggestion,
    );
  }

  void _openRequest() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/shipments/${widget.shipmentId}');
  }

  Future<void> _submit(_QuotePlan plan) async {
    if (!ref.read(sessionProvider).canOperate) {
      return;
    }
    if (!_formKey.currentState!.validate() || _loading) {
      return;
    }
    final truckType = _truckType;
    if (truckType == null || truckType.isEmpty) {
      return;
    }
    if (!plan.covers || plan.overshoot) {
      showAppSnack(context, context.tr('quotations.submitBlocked'));
      return;
    }
    if (!plan.capacityOk) {
      showAppSnack(context, context.tr('quotations.submitBlockedCapacity'));
      return;
    }
    _syncTripsToPlan();
    setState(() => _loading = true);
    try {
      await ref.read(quotationRepositoryProvider).submit(
            widget.shipmentId,
            QuotationDraft(
              totalPrice: double.parse(_price.text),
              truckCount: int.parse(_truckCount.text),
              truckType: truckType,
              truckCapacityTons: double.parse(_capacity.text),
              tripCount: int.parse(_tripCount.text),
              quantityPerTrip: double.parse(_qtyPerTrip.text),
              durationDays: int.parse(_duration.text),
              additionalCosts: double.tryParse(_extra.text),
              conditions: _conditions.text.trim(),
            ),
          );
      ref.invalidate(quotationsProvider);
      ref.invalidate(shipmentDetailProvider(widget.shipmentId));
      if (mounted) {
        showAppSnack(context, context.tr('quotations.submitted'));
        context.go('/quotations');
      }
    } on ApiException catch (error) {
      if (mounted) {
        showAppSnack(context, error.message == 'network' ? context.tr('common.networkError') : error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(sessionProvider).canOperate) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: PendingReviewBanner(),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(20),
      child: AsyncBody(
        value: ref.watch(shipmentDetailProvider(widget.shipmentId)),
        onRetry: () => ref.invalidate(shipmentDetailProvider(widget.shipmentId)),
        builder: (shipment) {
          _shipment = shipment;
          final trucks = ref.watch(quoteFleetTrucksProvider).maybeWhen(
                data: (page) => page.items,
                orElse: () => const <Truck>[],
              );
          _scheduleAutoPlan(shipment, trucks);
          final suggestion = _suggestionOf(shipment, trucks);
          final plan = _planOf(shipment, trucks, suggestion);
          final summary = ShipmentRequestSummary(shipment: shipment);
          final form = _quoteForm(shipment, plan, trucks);
          final subtitleParts = [
            shipment.reference,
            shipment.customer?.name,
          ].whereType<String>().where((part) => part.trim().isNotEmpty);
          return ListView(
            children: [
              PageHeader(
                title: context.tr('quotations.submitTitle'),
                subtitle: subtitleParts.join(' · '),
                actions: [
                  AppButton(
                    label: context.tr('quotations.backToRequest'),
                    outlined: true,
                    icon: Icons.arrow_back,
                    onPressed: _openRequest,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                context.tr('quotations.submitSubtitle'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.muted,
                      height: 1.45,
                    ),
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  final twoCol = constraints.maxWidth >= 920;
                  if (!twoCol) {
                    return Column(
                      children: [
                        summary,
                        const SizedBox(height: 16),
                        form,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: summary),
                      const SizedBox(width: 20),
                      Expanded(flex: 7, child: form),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _quoteForm(Shipment shipment, _QuotePlan plan, List<Truck> trucks) {
    final unit = QuantityUnits.label(context, shipment.quantityUnit);
    return Form(
      key: _formKey,
      child: Column(
        children: [
          SectionCard(
            title: context.tr('quotations.planSection'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _typeDropdown(context),
                const SizedBox(height: 8),
                _FleetHint(
                  plan: plan,
                  locale: Localizations.localeOf(context).languageCode,
                  onApply: plan.suggestion == null ? null : () => _applySuggestionNow(shipment, trucks),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: context.tr('quotations.truckCapacity'),
                  controller: _capacity,
                  required: true,
                  showRequiredHint: false,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) => AppValidators.positiveNumber(value, context.tr('validation.positive')),
                  onChanged: (_) {
                    _capacityTouched = true;
                    setState(() {});
                  },
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: context.tr('quotations.truckCount'),
                  controller: _truckCount,
                  required: true,
                  showRequiredHint: false,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(2),
                  ],
                  validator: (value) => AppValidators.positiveInt(value, context.tr('validation.positive')),
                  onChanged: (_) => _onPlanChanged(fromTrucks: true),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('quotations.truckCountHint'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                        height: 1.45,
                      ),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: context.tr('quotations.tripCount'),
                  controller: _tripCount,
                  required: true,
                  showRequiredHint: false,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(2),
                  ],
                  validator: (value) => AppValidators.positiveInt(value, context.tr('validation.positive')),
                  onChanged: (_) => _onPlanChanged(fromTrips: true),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: '${context.tr('quotations.quantityPerTrip')} ($unit)',
                  controller: _qtyPerTrip,
                  required: true,
                  showRequiredHint: false,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) => AppValidators.positiveNumber(value, context.tr('validation.positive')),
                  onChanged: (_) {
                    _qtyTouched = true;
                    setState(() {});
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('quotations.qtyPerTripHint'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                        height: 1.45,
                      ),
                ),
                const SizedBox(height: 16),
                _PlanStatus(plan: plan),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: context.tr('quotations.priceSection'),
            child: Column(
              children: [
                AppTextField(
                  label: context.tr('quotations.totalPrice'),
                  controller: _price,
                  required: true,
                  showRequiredHint: false,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) => AppValidators.positiveNumber(value, context.tr('validation.positive')),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: context.tr('quotations.additionalCosts'),
                  controller: _extra,
                  showRequiredHint: false,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: context.tr('quotations.durationDays'),
                  controller: _duration,
                  required: true,
                  showRequiredHint: false,
                  keyboardType: TextInputType.number,
                  validator: (value) => AppValidators.positiveInt(value, context.tr('validation.positive')),
                  onChanged: (_) {
                    _durationTouched = true;
                  },
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: context.tr('quotations.conditions'),
                  controller: _conditions,
                  maxLines: 4,
                  showRequiredHint: false,
                ),
                const SizedBox(height: 20),
                AppButton(
                  label: context.tr('common.submit'),
                  onPressed: _loading ? null : () => _submit(plan),
                  loading: _loading,
                  expanded: true,
                  amber: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeDropdown(BuildContext context) {
    final catalog = ref.watch(catalogTruckTypesProvider);
    return catalog.when(
      loading: () => const LinearProgressIndicator(),
      error: (_, _) => Text(context.tr('common.error')),
      data: (types) {
        final value = types.any((item) => item.code == _truckType) ? _truckType : types.firstOrNull?.code;
        if (value != null && value != _truckType) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _selectTruckType(value);
            }
          });
        }
        return AppDropdown<String>(
          label: context.tr('quotations.truckType'),
          value: value,
          required: true,
          items: [
            for (final type in types)
              DropdownMenuItem(value: type.code, child: Text(type.displayName(context.l10n.isRtl))),
          ],
          onChanged: (selected) => _selectTruckType(selected ?? _truckType),
        );
      },
    );
  }

  void _selectTruckType(String? type) {
    if (type == null || type == _truckType) {
      return;
    }
    setState(() {
      _truckType = type;
      _appliedPlanKey = null;
      _trucksTouched = false;
      _tripsTouched = false;
      _qtyTouched = false;
      _capacityTouched = false;
      _durationTouched = false;
    });
  }
}

class _QuotePlan {
  const _QuotePlan({
    required this.requiredQuantity,
    required this.plannedQuantity,
    required this.weightPerTrip,
    required this.capacity,
    required this.truckCount,
    required this.tripCount,
    required this.fleetCount,
    required this.fleetMaxCapacity,
    required this.neededTrips,
    this.unit,
    this.suggestion,
  });

  final double requiredQuantity;
  final double plannedQuantity;
  final double weightPerTrip;
  final double capacity;
  final int truckCount;
  final int tripCount;
  final int fleetCount;
  final double fleetMaxCapacity;
  final int neededTrips;
  final String? unit;
  final QuoteTransportSuggestion? suggestion;

  bool get covers => plannedQuantity + 0.0001 >= requiredQuantity && requiredQuantity > 0;

  bool get overshoot {
    if (requiredQuantity <= 0 || plannedQuantity <= requiredQuantity + 0.0001) {
      return false;
    }
    final qtyPerTrip = tripCount <= 0 ? plannedQuantity : plannedQuantity / tripCount;
    final extra = plannedQuantity - requiredQuantity;
    return extra + 0.0001 >= qtyPerTrip * 0.5 && plannedQuantity > requiredQuantity * 1.05;
  }

  bool get capacityOk => weightPerTrip <= 0 || capacity + 0.0001 >= weightPerTrip;

  bool get fleetOk => fleetCount == 0 || truckCount <= fleetCount;

  bool get followsSuggestion {
    final suggested = suggestion;
    if (suggested == null) {
      return true;
    }
    return suggested.matches(
      truckCount: truckCount,
      tripCount: tripCount,
      capacityTons: capacity,
      quantityPerTrip: tripCount <= 0 ? plannedQuantity : plannedQuantity / tripCount,
    );
  }

  _PlanTone get tone {
    if (!covers || overshoot) {
      return _PlanTone.danger;
    }
    if (!capacityOk || !fleetOk) {
      return _PlanTone.warning;
    }
    return _PlanTone.ok;
  }
}

enum _PlanTone { ok, warning, danger }

class _FleetHint extends StatelessWidget {
  const _FleetHint({required this.plan, required this.locale, this.onApply});

  final _QuotePlan plan;
  final String locale;
  final VoidCallback? onApply;

  @override
  Widget build(BuildContext context) {
    final suggestion = plan.suggestion;
    final unit = QuantityUnits.label(context, plan.unit);
    final hint = plan.fleetCount == 0
        ? context.tr('quotations.fleetHintNone')
        : context.tr('quotations.fleetHint', {
            'count': '${plan.fleetCount}',
            'capacity': Formatters.number(plan.fleetMaxCapacity, locale: locale),
          });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hint,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.muted, height: 1.45),
        ),
        if (suggestion != null) ...[
          const SizedBox(height: 8),
          Text(
            context.tr('quotations.planSuggestion', {
              'trucks': '${suggestion.truckCount}',
              'trips': '${suggestion.tripCount}',
              'qty': Formatters.number(suggestion.quantityPerTrip, locale: locale),
              'unit': unit,
              'capacity': Formatters.number(suggestion.capacityTons, locale: locale),
            }),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                ),
          ),
          if (onApply != null && !plan.followsSuggestion) ...[
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: AppButton(
                label: context.tr('quotations.applySuggestion'),
                outlined: true,
                onPressed: onApply,
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _PlanStatus extends StatelessWidget {
  const _PlanStatus({required this.plan});

  final _QuotePlan plan;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final unit = QuantityUnits.label(context, plan.unit);
    final tone = plan.tone;
    final colors = switch (tone) {
      _PlanTone.ok => (const Color(0x142F6B4F), AppColors.success),
      _PlanTone.warning => (const Color(0x1AC9892C), AppColors.warning),
      _PlanTone.danger => (const Color(0x1A8B2E2E), AppColors.danger),
    };
    final lines = <String>[
      context.tr('quotations.planSummary', {
        'trucks': '${plan.truckCount}',
        'trips': '${plan.tripCount}',
        'quantity': Formatters.number(plan.plannedQuantity, locale: locale),
        'unit': unit,
      }),
      if (!plan.covers)
        context.tr('quotations.coverageShort', {
          'planned': Formatters.number(plan.plannedQuantity, locale: locale),
          'required': Formatters.number(plan.requiredQuantity, locale: locale),
          'unit': unit,
        })
      else if (plan.overshoot)
        context.tr('quotations.overshootShort', {
          'planned': Formatters.number(plan.plannedQuantity, locale: locale),
          'required': Formatters.number(plan.requiredQuantity, locale: locale),
          'unit': unit,
        })
      else
        context.tr('quotations.coverageOk'),
      if (plan.suggestion != null && !plan.followsSuggestion)
        context.tr('quotations.planSuggestionHint', {
          'trucks': '${plan.suggestion!.truckCount}',
          'trips': '${plan.suggestion!.tripCount}',
        }),
      if (plan.tripCount > plan.neededTrips)
        context.tr('quotations.tripsHint', {'count': '${plan.neededTrips}'}),
      plan.capacityOk
          ? context.tr('quotations.capacityOk', {
              'weight': Formatters.number(plan.weightPerTrip, locale: locale),
            })
          : context.tr('quotations.capacityShort', {
              'capacity': Formatters.number(plan.capacity, locale: locale),
              'weight': Formatters.number(plan.weightPerTrip, locale: locale),
            }),
      if (!plan.fleetOk)
        context.tr('quotations.fleetShort', {
          'needed': '${plan.truckCount}',
          'available': '${plan.fleetCount}',
        }),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.$2.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < lines.length; i++) ...[
            if (i > 0) const SizedBox(height: 6),
            Text(
              lines[i],
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.$2,
                    fontWeight: i == 0 ? FontWeight.w600 : FontWeight.w500,
                    height: 1.35,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

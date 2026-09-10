import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/config/app_config.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/models/quotation.dart';
import '../../../shared/providers/session_provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/async_body.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/section_card.dart';
import '../../quotations/presentation/quotations_screen.dart';
import 'shipment_detail_screen.dart';

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
  String _truckType = AppConfig.truckTypes.first;
  var _loading = false;

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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _loading) {
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(quotationRepositoryProvider).submit(
            widget.shipmentId,
            QuotationDraft(
              totalPrice: double.parse(_price.text),
              truckCount: int.parse(_truckCount.text),
              truckType: _truckType,
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
    return Padding(
      padding: const EdgeInsets.all(20),
      child: AsyncBody(
        value: ref.watch(shipmentDetailProvider(widget.shipmentId)),
        onRetry: () => ref.invalidate(shipmentDetailProvider(widget.shipmentId)),
        builder: (shipment) {
          return ListView(
            children: [
              PageHeader(
                title: context.tr('quotations.submitTitle'),
                subtitle: '${context.tr('quotations.submitSubtitle')} · ${shipment.reference ?? ''}',
              ),
              const SizedBox(height: 16),
              SectionCard(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      AppTextField(
                        label: context.tr('quotations.totalPrice'),
                        controller: _price,
                        required: true,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) => AppValidators.positiveNumber(value, context.tr('validation.positive')),
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: context.tr('quotations.truckCount'),
                        controller: _truckCount,
                        required: true,
                        keyboardType: TextInputType.number,
                        validator: (value) => AppValidators.positiveInt(value, context.tr('validation.positive')),
                      ),
                      const SizedBox(height: 12),
                      AppDropdown<String>(
                        label: context.tr('quotations.truckType'),
                        value: _truckType,
                        required: true,
                        items: [
                          for (final type in AppConfig.truckTypes)
                            DropdownMenuItem(value: type, child: Text(context.l10n.truckType(type))),
                        ],
                        onChanged: (value) => setState(() => _truckType = value ?? _truckType),
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: context.tr('quotations.truckCapacity'),
                        controller: _capacity,
                        required: true,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) => AppValidators.positiveNumber(value, context.tr('validation.positive')),
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: context.tr('quotations.tripCount'),
                        controller: _tripCount,
                        required: true,
                        keyboardType: TextInputType.number,
                        validator: (value) => AppValidators.positiveInt(value, context.tr('validation.positive')),
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: context.tr('quotations.quantityPerTrip'),
                        controller: _qtyPerTrip,
                        required: true,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) => AppValidators.positiveNumber(value, context.tr('validation.positive')),
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: context.tr('quotations.durationDays'),
                        controller: _duration,
                        required: true,
                        keyboardType: TextInputType.number,
                        validator: (value) => AppValidators.positiveInt(value, context.tr('validation.positive')),
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: context.tr('quotations.additionalCosts'),
                        controller: _extra,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: context.tr('quotations.conditions'),
                        controller: _conditions,
                        maxLines: 4,
                      ),
                      const SizedBox(height: 20),
                      AppButton(
                        label: context.tr('common.submit'),
                        onPressed: _submit,
                        loading: _loading,
                        expanded: true,
                        amber: true,
                      ),
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

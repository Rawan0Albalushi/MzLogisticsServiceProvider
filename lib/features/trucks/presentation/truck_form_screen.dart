import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/config/app_config.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/models/truck.dart';
import '../../../shared/providers/session_provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/async_body.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/section_card.dart';
import '../../fleet/presentation/fleet_screen.dart';
import 'trucks_screen.dart';

class TruckFormScreen extends ConsumerStatefulWidget {
  const TruckFormScreen({super.key, this.truckId});

  final int? truckId;

  @override
  ConsumerState<TruckFormScreen> createState() => _TruckFormScreenState();
}

class _TruckFormScreenState extends ConsumerState<TruckFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _plate = TextEditingController();
  final _capacity = TextEditingController();
  final _year = TextEditingController();
  final _make = TextEditingController();
  final _model = TextEditingController();
  final _insurance = TextEditingController();
  String _type = AppConfig.truckTypes.first;
  String _status = 'available';
  var _loading = false;
  var _hydrated = false;

  @override
  void dispose() {
    _plate.dispose();
    _capacity.dispose();
    _year.dispose();
    _make.dispose();
    _model.dispose();
    _insurance.dispose();
    super.dispose();
  }

  void _hydrate(Truck truck) {
    if (_hydrated) {
      return;
    }
    _hydrated = true;
    _plate.text = truck.plateNumber ?? '';
    _capacity.text = truck.capacityTons?.toString() ?? '';
    _year.text = truck.year?.toString() ?? '';
    _make.text = truck.make ?? '';
    _model.text = truck.model ?? '';
    _insurance.text = truck.insuranceExpiresAt ?? '';
    _type = truck.type ?? _type;
    _status = truck.status ?? _status;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _loading) {
      return;
    }
    setState(() => _loading = true);
    final payload = {
      'plate_number': _plate.text.trim(),
      'type': _type,
      'capacity_tons': double.parse(_capacity.text),
      'status': _status,
      if (_year.text.isNotEmpty) 'year': int.tryParse(_year.text),
      if (_make.text.isNotEmpty) 'make': _make.text.trim(),
      if (_model.text.isNotEmpty) 'model': _model.text.trim(),
      if (_insurance.text.isNotEmpty) 'insurance_expires_at': _insurance.text.trim(),
    };
    try {
      if (widget.truckId == null) {
        await ref.read(fleetRepositoryProvider).createTruck(payload);
      } else {
        await ref.read(fleetRepositoryProvider).updateTruck(widget.truckId!, payload);
      }
      ref.invalidate(trucksProvider);
      ref.invalidate(fleetTrucksProvider);
      if (mounted) {
        showAppSnack(context, context.tr('trucks.saved'));
        context.go('/trucks');
      }
    } on ApiException catch (error) {
      if (mounted) {
        showAppSnack(context, error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.truckId != null;
    final form = _form(context);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: editing
          ? AsyncBody(
              value: ref.watch(trucksProvider),
              onRetry: () => ref.invalidate(trucksProvider),
              builder: (page) {
                final truck = page.items.where((item) => item.id == widget.truckId).firstOrNull;
                if (truck != null) {
                  _hydrate(truck);
                }
                return form;
              },
            )
          : form,
    );
  }

  Widget _form(BuildContext context) {
    return ListView(
      children: [
        PageHeader(
          title: widget.truckId == null ? context.tr('trucks.add') : context.tr('trucks.edit'),
        ),
        const SizedBox(height: 16),
        SectionCard(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                AppTextField(
                  label: context.tr('trucks.plate'),
                  controller: _plate,
                  required: true,
                  validator: (value) => AppValidators.required(value, context.tr('validation.required')),
                ),
                const SizedBox(height: 12),
                AppDropdown<String>(
                  label: context.tr('quotations.truckType'),
                  value: _type,
                  required: true,
                  items: [
                    for (final type in AppConfig.truckTypes)
                      DropdownMenuItem(value: type, child: Text(context.l10n.truckType(type))),
                  ],
                  onChanged: (value) => setState(() => _type = value ?? _type),
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
                AppDropdown<String>(
                  label: context.tr('common.status'),
                  value: _status,
                  items: [
                    for (final status in AppConfig.truckStatuses)
                      DropdownMenuItem(value: status, child: Text(context.l10n.status(status))),
                  ],
                  onChanged: (value) => setState(() => _status = value ?? _status),
                ),
                const SizedBox(height: 12),
                AppTextField(label: context.tr('trucks.year'), controller: _year, keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                AppTextField(label: context.tr('trucks.make'), controller: _make),
                const SizedBox(height: 12),
                AppTextField(label: context.tr('trucks.model'), controller: _model),
                const SizedBox(height: 12),
                AppTextField(label: context.tr('trucks.insurance'), controller: _insurance, hint: 'YYYY-MM-DD'),
                const SizedBox(height: 20),
                AppButton(label: context.tr('common.save'), onPressed: _save, loading: _loading, expanded: true),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

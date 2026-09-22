import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/config/app_config.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/page_visuals.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/models/truck.dart';
import '../../../shared/models/truck_type.dart';
import '../../../shared/providers/session_provider.dart';
import '../../../shared/widgets/app_page.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/async_body.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/section_card.dart';
import '../../fleet/presentation/fleet_screen.dart';
import '../../truck_types/presentation/truck_type_providers.dart';
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
  final _volume = TextEditingController();
  final _length = TextEditingController();
  final _width = TextEditingController();
  final _height = TextEditingController();
  final _axles = TextEditingController();
  final _year = TextEditingController();
  final _make = TextEditingController();
  final _model = TextEditingController();
  final _insurance = TextEditingController();
  String? _type;
  String _status = 'available';
  var _loading = false;
  var _hydrated = false;

  @override
  void dispose() {
    _plate.dispose();
    _capacity.dispose();
    _volume.dispose();
    _length.dispose();
    _width.dispose();
    _height.dispose();
    _axles.dispose();
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
    _capacity.text = _formatNumber(truck.capacityTons);
    _volume.text = _formatNumber(truck.volumeCbm);
    _length.text = _formatNumber(truck.cargoLengthM);
    _width.text = _formatNumber(truck.cargoWidthM);
    _height.text = _formatNumber(truck.cargoHeightM);
    _axles.text = truck.axleCount?.toString() ?? '';
    _year.text = truck.year?.toString() ?? '';
    _make.text = truck.make ?? '';
    _model.text = truck.model ?? '';
    _insurance.text = truck.insuranceExpiresAt ?? '';
    _type = truck.type ?? _type;
    _status = truck.status ?? _status;
  }

  String _formatNumber(num? value) {
    if (value == null) {
      return '';
    }
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }
    return value.toString();
  }

  double? _optionalDouble(TextEditingController controller) {
    final text = controller.text.trim();
    if (text.isEmpty) {
      return null;
    }
    return double.tryParse(text);
  }

  int? _optionalInt(TextEditingController controller) {
    final text = controller.text.trim();
    if (text.isEmpty) {
      return null;
    }
    return int.tryParse(text);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _loading) {
      return;
    }
    final type = _type;
    if (type == null || type.isEmpty) {
      return;
    }
    setState(() => _loading = true);
    final payload = {
      'plate_number': _plate.text.trim(),
      'type': type,
      'capacity_tons': double.parse(_capacity.text),
      'volume_cbm': _optionalDouble(_volume),
      'cargo_length_m': _optionalDouble(_length),
      'cargo_width_m': _optionalDouble(_width),
      'cargo_height_m': _optionalDouble(_height),
      'axle_count': _optionalInt(_axles),
      'status': _status,
      if (_year.text.isNotEmpty) 'year': int.tryParse(_year.text),
      if (_make.text.isNotEmpty) 'make': _make.text.trim(),
      if (_model.text.isNotEmpty) 'model': _model.text.trim(),
      if (_insurance.text.isNotEmpty)
        'insurance_expires_at': _insurance.text.trim(),
    };
    try {
      if (widget.truckId == null) {
        await ref.read(fleetRepositoryProvider).createTruck(payload);
      } else {
        await ref
            .read(fleetRepositoryProvider)
            .updateTruck(widget.truckId!, payload);
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
    return AppPage(
      child: editing
          ? AsyncBody(
              value: ref.watch(trucksProvider),
              onRetry: () => ref.invalidate(trucksProvider),
              builder: (page) {
                final truck = page.items
                    .where((item) => item.id == widget.truckId)
                    .firstOrNull;
                if (truck != null) {
                  _hydrate(truck);
                }
                return _form(context, truck);
              },
            )
          : _form(context, null),
    );
  }

  Widget _form(BuildContext context, Truck? truck) {
    return Form(
      key: _formKey,
      child: ListView(
        children: [
          PageHeader(
            title: widget.truckId == null
                ? context.tr('trucks.add')
                : context.tr('trucks.edit'),
            subtitle: context.tr('trucks.formSubtitle'),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: context.tr('trucks.identitySection'),
            icon: Icons.badge_outlined,
            child: Column(
              children: [
                AppTextField(
                  label: context.tr('trucks.plate'),
                  controller: _plate,
                  required: true,
                  validator: (value) => AppValidators.required(
                    value,
                    context.tr('validation.required'),
                  ),
                ),
                const SizedBox(height: 12),
                _typeDropdown(context),
                const SizedBox(height: 12),
                AppDropdown<String>(
                  label: context.tr('common.status'),
                  value: _status,
                  items: [
                    for (final status in AppConfig.truckStatuses)
                      DropdownMenuItem(
                        value: status,
                        child: Text(context.l10n.status(status)),
                      ),
                  ],
                  onChanged: (value) =>
                      setState(() => _status = value ?? _status),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: context.tr('trucks.year'),
                  controller: _year,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: context.tr('trucks.make'),
                  controller: _make,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: context.tr('trucks.model'),
                  controller: _model,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: context.tr('trucks.insurance'),
                  controller: _insurance,
                  hint: 'YYYY-MM-DD',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: context.tr('trucks.loadSection'),
            icon: Icons.inventory_2_outlined,
            tone: IconTone.info,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.tr('trucks.loadHint'),
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(height: 1.4),
                ),
                const SizedBox(height: 16),
                _responsivePair(
                  AppTextField(
                    label: context.tr('trucks.capacityTons'),
                    controller: _capacity,
                    required: true,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) => AppValidators.positiveNumber(
                      value,
                      context.tr('validation.positive'),
                    ),
                  ),
                  AppTextField(
                    label: context.tr('trucks.volume'),
                    controller: _volume,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) => AppValidators.optionalPositiveNumber(
                      value,
                      context.tr('validation.positive'),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _dimensionFields(context),
                const SizedBox(height: 12),
                AppTextField(
                  label: context.tr('trucks.axles'),
                  controller: _axles,
                  keyboardType: TextInputType.number,
                  validator: (value) => AppValidators.optionalPositiveInt(
                    value,
                    context.tr('validation.positive'),
                  ),
                ),
                if (truck == null) ...[
                  const SizedBox(height: 12),
                  Text(
                    context.tr('trucks.equipmentAfterSave'),
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(height: 1.4),
                  ),
                ],
                const SizedBox(height: 20),
                AppButton(
                  label: context.tr('common.save'),
                  onPressed: _save,
                  loading: _loading,
                  expanded: true,
                ),
              ],
            ),
          ),
          if (truck != null) ...[
            const SizedBox(height: 16),
            SectionCard(
              title: context.tr('trucks.equipmentSection'),
              icon: Icons.handyman_outlined,
              tone: IconTone.info,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    context.tr('trucks.equipmentHint'),
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  if (truck.equipment.isEmpty)
                    Text(context.tr('trucks.equipmentEmpty'))
                  else
                    for (final item in truck.equipment)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          [
                            item.name ?? '',
                            if (item.quantity != null) '${item.quantity}',
                          ].where((part) => part.isNotEmpty).join(' · '),
                        ),
                      ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: AppButton(
                      label: context.tr('trucks.manageEquipment'),
                      outlined: true,
                      icon: Icons.handyman_outlined,
                      onPressed: () => context.go('/equipment'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _dimensionFields(BuildContext context) {
    return _responsiveTriple(
      AppTextField(
        label: context.tr('trucks.length'),
        controller: _length,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: (value) => AppValidators.optionalPositiveNumber(
          value,
          context.tr('validation.positive'),
        ),
      ),
      AppTextField(
        label: context.tr('trucks.width'),
        controller: _width,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: (value) => AppValidators.optionalPositiveNumber(
          value,
          context.tr('validation.positive'),
        ),
      ),
      AppTextField(
        label: context.tr('trucks.height'),
        controller: _height,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: (value) => AppValidators.optionalPositiveNumber(
          value,
          context.tr('validation.positive'),
        ),
      ),
    );
  }

  Widget _responsivePair(Widget first, Widget second) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 560) {
          return Column(children: [first, const SizedBox(height: 12), second]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: first),
            const SizedBox(width: 12),
            Expanded(child: second),
          ],
        );
      },
    );
  }

  Widget _responsiveTriple(Widget first, Widget second, Widget third) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 640) {
          return Column(
            children: [
              first,
              const SizedBox(height: 12),
              second,
              const SizedBox(height: 12),
              third,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: first),
            const SizedBox(width: 12),
            Expanded(child: second),
            const SizedBox(width: 12),
            Expanded(child: third),
          ],
        );
      },
    );
  }

  Widget _typeDropdown(BuildContext context) {
    final catalog = ref.watch(catalogTruckTypesProvider);
    return catalog.when(
      loading: () => const LinearProgressIndicator(),
      error: (_, _) => Text(context.tr('common.error')),
      data: (types) {
        final options = [...types];
        if (_type != null &&
            _type!.isNotEmpty &&
            !options.any((item) => item.code == _type)) {
          options.insert(0, TruckTypeOption.fallback(_type!));
        }
        final value = options.any((item) => item.code == _type)
            ? _type
            : options.firstOrNull?.code;
        if (value != null && value != _type) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _type = value);
            }
          });
        }
        return AppDropdown<String>(
          label: context.tr('quotations.truckType'),
          value: value,
          required: true,
          items: [
            for (final type in options)
              DropdownMenuItem(
                value: type.code,
                child: Text(type.displayName(context.l10n.isRtl)),
              ),
          ],
          onChanged: (selected) => setState(() => _type = selected ?? _type),
        );
      },
    );
  }
}

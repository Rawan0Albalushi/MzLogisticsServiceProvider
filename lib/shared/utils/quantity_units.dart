import 'package:flutter/widgets.dart';

import '../../core/l10n/app_localizations.dart';

class QuantityUnits {
  static const tons = 'tons';
  static const pallets = 'pallets';
  static const units = 'units';

  static String normalize(String? raw) {
    switch ((raw ?? '').toLowerCase().trim()) {
      case 'pallet':
      case 'pallets':
        return pallets;
      case 'unit':
      case 'units':
        return units;
      default:
        return tons;
    }
  }

  static bool isTons(String? raw) {
    final key = (raw ?? '').toLowerCase().trim();
    return key.isEmpty || key == 'ton' || key == 'tons';
  }

  static String label(BuildContext context, String? raw) {
    return switch (normalize(raw)) {
      pallets => context.tr('shipments.unitPallets'),
      units => context.tr('shipments.unitUnits'),
      _ => context.tr('shipments.unitTons'),
    };
  }
}

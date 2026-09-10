import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String message,
  String? confirmLabel,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.tr('common.cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel ?? context.tr('common.confirm')),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

void showAppSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

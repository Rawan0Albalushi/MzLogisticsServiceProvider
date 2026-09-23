import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import 'info_grid.dart';

Future<void> showRecordDetails(
  BuildContext context, {
  required String title,
  required List<InfoField> fields,
  VoidCallback? onEdit,
  Widget? extra,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InfoGrid(fields: fields),
                if (extra != null) ...[
                  const SizedBox(height: 16),
                  extra,
                ],
              ],
            ),
          ),
        ),
        actions: [
          if (onEdit != null)
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                WidgetsBinding.instance.addPostFrameCallback((_) => onEdit());
              },
              child: Text(dialogContext.tr('common.edit')),
            ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(dialogContext.tr('common.close')),
          ),
        ],
      );
    },
  );
}

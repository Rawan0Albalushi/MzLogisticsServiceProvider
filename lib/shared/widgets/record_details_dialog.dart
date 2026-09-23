import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import 'info_grid.dart';

Future<void> showRecordDetails(
  BuildContext context, {
  required String title,
  required List<InfoField> fields,
  VoidCallback? onEdit,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(child: InfoGrid(fields: fields)),
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

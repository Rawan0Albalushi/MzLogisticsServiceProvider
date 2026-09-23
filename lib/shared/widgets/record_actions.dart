import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';

class RecordActions extends StatelessWidget {
  const RecordActions({super.key, required this.onView, this.onEdit});

  final VoidCallback onView;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        RecordIconButton(
          tooltip: context.tr('common.view'),
          icon: Icons.visibility_outlined,
          onPressed: onView,
        ),
        if (onEdit != null)
          RecordIconButton(
            tooltip: context.tr('common.edit'),
            icon: Icons.edit_outlined,
            onPressed: onEdit!,
          ),
      ],
    );
  }
}

class RecordIconButton extends StatelessWidget {
  const RecordIconButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        foregroundColor: AppColors.ink,
        minimumSize: const Size(40, 40),
        padding: const EdgeInsets.all(8),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: Icon(icon, size: 20),
    );
  }
}

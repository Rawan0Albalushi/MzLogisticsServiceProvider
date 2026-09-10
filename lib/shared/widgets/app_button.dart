import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.expanded = false,
    this.amber = false,
    this.outlined = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool expanded;
  final bool amber;
  final bool outlined;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: 8),
              ],
              Flexible(child: Text(label)),
            ],
          );

    final button = outlined
        ? OutlinedButton(
            onPressed: loading ? null : onPressed,
            child: child,
          )
        : FilledButton(
            onPressed: loading ? null : onPressed,
            style: amber
                ? FilledButton.styleFrom(
                    backgroundColor: AppColors.amber,
                    foregroundColor: AppColors.white,
                  )
                : null,
            child: child,
          );

    if (!expanded) {
      return button;
    }
    return SizedBox(width: double.infinity, child: button);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exception.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';

class AsyncBody<T> extends StatelessWidget {
  const AsyncBody({
    super.key,
    required this.value,
    required this.builder,
    this.onRetry,
    this.empty,
    this.isEmpty,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final VoidCallback? onRetry;
  final Widget? empty;
  final bool Function(T data)? isEmpty;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: (data) {
        if (isEmpty?.call(data) ?? false) {
          return empty ?? EmptyState(message: context.tr('common.empty'));
        }
        return builder(data);
      },
      loading: () => const LoadingState(),
      error: (error, _) => ErrorState(
        message: _message(context, error),
        onRetry: onRetry,
      ),
    );
  }

  String _message(BuildContext context, Object error) {
    if (error is ApiException) {
      if (error.message == 'network') {
        return context.tr('common.networkError');
      }
      if (error.isForbidden) {
        return context.tr('common.noPermission');
      }
      if (error.message != 'error') {
        return error.message;
      }
    }
    return context.tr('common.error');
  }
}

class LoadingState extends StatelessWidget {
  const LoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
          const SizedBox(height: 12),
          Text(context.tr('common.loading'), style: const TextStyle(color: AppColors.muted)),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.message, this.icon = Icons.inbox_outlined});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.tealSoft,
                borderRadius: BorderRadius.circular(AppColors.radius),
              ),
              child: Icon(icon, size: 26, color: AppColors.teal800),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 36, color: AppColors.danger),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(onPressed: onRetry, child: Text(context.tr('common.retry'))),
            ],
          ],
        ),
      ),
    );
  }
}

class NoPermissionState extends StatelessWidget {
  const NoPermissionState({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      message: context.tr('common.noPermission'),
      icon: Icons.lock_outline,
    );
  }
}

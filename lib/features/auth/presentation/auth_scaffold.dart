import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/l10n/locale_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/icon_well.dart';

class AuthScaffold extends ConsumerWidget {
  const AuthScaffold({
    super.key,
    required this.child,
    this.footer,
    this.contentMaxWidth = 440,
  });

  final Widget child;
  final Widget? footer;
  final double contentMaxWidth;

  static const double _splitBreakpoint = 960;
  static const double _minUsableSize = 32;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < _minUsableSize || constraints.maxHeight < _minUsableSize) {
            return const ColoredBox(color: AppColors.surface);
          }

          final showBrand = constraints.maxWidth >= _splitBreakpoint;
          final showCompactHeader = !showBrand && constraints.maxHeight >= 120;

          if (showBrand) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(width: _brandWidth(constraints.maxWidth), child: const _BrandPanel()),
                Expanded(
                  child: _AuthFormPane(
                    maxWidth: contentMaxWidth,
                    footer: footer,
                    child: child,
                  ),
                ),
              ],
            );
          }

          return ColoredBox(
            color: AppColors.surface,
            child: SafeArea(
              child: Column(
                children: [
                  if (showCompactHeader)
                    _CompactAuthHeader(
                      onToggleLocale: () => ref.read(localeControllerProvider.notifier).toggle(),
                    ),
                  Expanded(
                    child: _AuthFormPane(
                      maxWidth: contentMaxWidth,
                      footer: footer,
                      child: child,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static double _brandWidth(double width) {
    if (width >= 1440) return (width * 0.34).clamp(400.0, 500.0);
    if (width >= 1100) return (width * 0.32).clamp(340.0, 420.0);
    return (width * 0.30).clamp(280.0, 340.0);
  }
}

class _CompactAuthHeader extends StatelessWidget {
  const _CompactAuthHeader({required this.onToggleLocale});

  final VoidCallback onToggleLocale;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
        child: Row(
          children: [
            const BrandMark(size: 32),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                context.tr('app.name'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            TextButton.icon(
              onPressed: onToggleLocale,
              icon: const Icon(Icons.language, size: 18),
              label: Text(context.tr('nav.language')),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthFormPane extends StatelessWidget {
  const _AuthFormPane({
    required this.child,
    required this.maxWidth,
    this.footer,
  });

  final Widget child;
  final Widget? footer;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < AuthScaffold._minUsableSize ||
            constraints.maxHeight < AuthScaffold._minUsableSize) {
          return const ColoredBox(color: AppColors.surface);
        }

        final compact = constraints.maxWidth < 600;
        final horizontal = compact ? 16.0 : 32.0;
        final vertical = compact ? 16.0 : 28.0;
        final cardPadding = compact ? 20.0 : 28.0;

        return ColoredBox(
          color: AppColors.surface,
          child: SingleChildScrollView(
            primary: true,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(horizontal, vertical, horizontal, vertical),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: (constraints.maxHeight - vertical * 2).clamp(0.0, constraints.maxHeight).toDouble(),
                maxWidth: constraints.maxWidth,
              ),
              child: Align(
                alignment: Alignment.center,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(AppColors.radius),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(cardPadding),
                      child: footer == null
                          ? child
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                child,
                                const SizedBox(height: 24),
                                const Divider(height: 1),
                                const SizedBox(height: 20),
                                footer!,
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BrandPanel extends ConsumerWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wide = MediaQuery.sizeOf(context).width >= 1100;

    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.sidebarGradient),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < AuthScaffold._minUsableSize ||
              constraints.maxHeight < AuthScaffold._minUsableSize) {
            return const SizedBox.expand();
          }

          final padding = (wide ? 44.0 : 28.0).clamp(16.0, constraints.maxWidth / 2);

          return SafeArea(
            child: SingleChildScrollView(
              primary: false,
              padding: EdgeInsets.symmetric(horizontal: padding, vertical: 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - 56).clamp(0.0, constraints.maxHeight).toDouble(),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: OutlinedButton.icon(
                        onPressed: () => ref.read(localeControllerProvider.notifier).toggle(),
                        icon: const Icon(Icons.language, size: 16, color: AppColors.white),
                        label: Text(
                          context.tr('nav.language'),
                          style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w500),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0x55FFFFFF)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          minimumSize: const Size(0, 36),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    const BrandMark(size: 48),
                    const SizedBox(height: 20),
                    Text(
                      context.tr('app.name'),
                      style: (wide
                              ? Theme.of(context).textTheme.headlineMedium
                              : Theme.of(context).textTheme.titleLarge)
                          ?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: 40,
                      height: 3,
                      decoration: BoxDecoration(
                        color: AppColors.coral,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.tr('app.tagline'),
                      style: const TextStyle(color: AppColors.onSidebarMuted, fontSize: 16, height: 1.45),
                    ),
                    const SizedBox(height: 36),
                    _BrandPoint(icon: Icons.apartment_outlined, text: context.tr('auth.brandPointWorkspace')),
                    const SizedBox(height: 16),
                    _BrandPoint(icon: Icons.fact_check_outlined, text: context.tr('auth.brandPointReview')),
                    const SizedBox(height: 16),
                    _BrandPoint(icon: Icons.local_shipping_outlined, text: context.tr('app.companyFleetNote')),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BrandPoint extends StatelessWidget {
  const _BrandPoint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.coral),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: AppColors.onSidebarMuted, height: 1.5, fontSize: 13.5),
          ),
        ),
      ],
    );
  }
}

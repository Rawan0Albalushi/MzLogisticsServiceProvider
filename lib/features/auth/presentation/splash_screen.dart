import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/icon_well.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final compact = MediaQuery.sizeOf(context).width < 360;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.tealDeep,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.tealDeep,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 24,
                      ),
                      child: _SplashMark(
                        compact: compact,
                        reduceMotion: reduceMotion,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SplashMark extends StatelessWidget {
  const _SplashMark({required this.compact, required this.reduceMotion});

  final bool compact;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final nameStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(
      color: AppColors.white,
      fontWeight: FontWeight.w700,
      height: 1.2,
    );
    final taglineStyle = Theme.of(context).textTheme.bodyMedium
        ?.copyWith(color: AppColors.onSidebarMuted, height: 1.4);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        BrandMark(size: compact ? 56 : 64),
        const SizedBox(height: 18),
        Text(
          context.tr('app.name'),
          textAlign: TextAlign.center,
          style: nameStyle,
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: Text(
            context.tr('app.tagline'),
            textAlign: TextAlign.center,
            style: taglineStyle,
          ),
        ),
        const SizedBox(height: 22),
        Container(
          width: 36,
          height: 3,
          decoration: BoxDecoration(
            color: AppColors.coral,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        const SizedBox(height: 28),
        if (reduceMotion)
          Text(
            context.tr('splash.status'),
            textAlign: TextAlign.center,
            style: taglineStyle,
          )
        else ...[
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.coral,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            context.tr('splash.status'),
            textAlign: TextAlign.center,
            style: taglineStyle,
          ),
        ],
      ],
    );
  }
}

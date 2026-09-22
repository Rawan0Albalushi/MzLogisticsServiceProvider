import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mz_logistics_service_provider_app/core/l10n/app_localizations.dart';
import 'package:mz_logistics_service_provider_app/features/auth/presentation/splash_screen.dart';

void main() {
  testWidgets('splash shows the English brand while the workspace is prepared', (tester) async {
    await tester.pumpWidget(_app(const Locale('en')));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('MoveX'), findsOneWidget);
    expect(find.text('Service provider operations'), findsOneWidget);
    expect(find.text('Preparing your workspace'), findsOneWidget);
  });

  testWidgets('splash follows Arabic layout and copy', (tester) async {
    await tester.pumpWidget(_app(const Locale('ar')));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('عمليات مزود الخدمة'), findsOneWidget);
    expect(find.text('جاري تجهيز مساحة العمل'), findsOneWidget);
    expect(Directionality.of(tester.element(find.text('عمليات مزود الخدمة'))), TextDirection.rtl);
  });
}

Widget _app(Locale locale) {
  return MaterialApp(
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: const SplashScreen(),
  );
}

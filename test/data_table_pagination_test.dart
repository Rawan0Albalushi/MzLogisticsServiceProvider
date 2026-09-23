import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mz_logistics_service_provider_app/core/l10n/app_localizations.dart';
import 'package:mz_logistics_service_provider_app/shared/widgets/responsive_data_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('wide tables keep pagination in the admin summary', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1100, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_app(const Locale('en'), 1100));
    await tester.pumpAndSettle();

    expect(find.text('REFERENCE'), findsOneWidget);
    expect(find.text('Showing 24 results · Page 1 of 3'), findsOneWidget);
    expect(find.text('Previous'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'Previous'),
          )
          .onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('narrow lists keep the same pagination controls', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_app(const Locale('ar'), 400));
    await tester.pumpAndSettle();

    expect(find.text('عرض 24 نتيجة · صفحة 1 من 3'), findsOneWidget);
    expect(find.text('السابق'), findsOneWidget);
    expect(find.text('التالي'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Widget _app(Locale locale, double width) {
  return MaterialApp(
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(
      body: SizedBox(
        width: width,
        child: ResponsiveDataView<String>(
          items: const ['MZ-1042'],
          columns: const [
            DataColumnSpec('Reference'),
            DataColumnSpec('Status'),
          ],
          rowCells: (item) => [Text(item), const Text('Active')],
          cardBuilder: (item) => ListTile(title: Text(item)),
          pagination: TablePagination(
            currentPage: 1,
            lastPage: 3,
            total: 24,
            onPage: (_) {},
          ),
        ),
      ),
    ),
  );
}

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mz_logistics_service_provider_app/core/l10n/app_localizations.dart';
import 'package:mz_logistics_service_provider_app/shared/widgets/responsive_data_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a vertical wheel over a wide table scrolls the page', (
    tester,
  ) async {
    await tester.pumpWidget(_page(wide: true));
    await tester.pump();

    expect(find.text('PAGE_HEADER'), findsOneWidget);
    expect(
      tester
          .widgetList<SingleChildScrollView>(find.byType(SingleChildScrollView))
          .every((view) => view.scrollDirection == Axis.horizontal),
      isTrue,
    );

    await tester.sendEventToBinding(
      PointerScrollEvent(
        position: tester.getCenter(find.textContaining('ROW-0').first),
        scrollDelta: const Offset(48, 280),
      ),
    );
    await tester.pump();

    expect(find.text('PAGE_HEADER'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Widget _page({bool wide = false}) {
  final columns = wide
      ? List<DataColumnSpec>.generate(
          12,
          (index) => DataColumnSpec('Column $index heading'),
        )
      : const [DataColumnSpec('Reference'), DataColumnSpec('Status')];
  return MaterialApp(
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(
      body: SizedBox(
        height: 320,
        child: ListView(
          primary: false,
          children: [
            const Text('PAGE_HEADER'),
            ResponsiveDataView<String>(
              items: List<String>.generate(16, (index) => 'ROW-$index'),
              columns: columns,
              rowCells: (item) => wide
                  ? [
                      for (final column in columns)
                        Text('$item ${column.label}'),
                    ]
                  : [Text(item), const Text('Active')],
              cardBuilder: (item) => ListTile(title: Text(item)),
              pagination: TablePagination(
                currentPage: 1,
                lastPage: 2,
                total: 16,
                onPage: (_) {},
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

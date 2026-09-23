import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mz_logistics_service_provider_app/core/l10n/app_localizations.dart';
import 'package:mz_logistics_service_provider_app/shared/widgets/record_actions.dart';
import 'package:mz_logistics_service_provider_app/shared/widgets/responsive_data_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('actions stay at the table end in both directions', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1100, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var views = 0;
    var edits = 0;
    await tester.pumpWidget(
      _table(const Locale('ar'), onView: () => views++, onEdit: () => edits++),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byTooltip('عرض'), findsOneWidget);
    expect(find.byTooltip('تعديل'), findsOneWidget);
    await tester.tap(find.byTooltip('تعديل'));
    await tester.pump();
    expect(edits, 1);
    expect(views, 0);
    await tester.tap(find.byTooltip('عرض'));
    await tester.pump();
    expect(views, 1);

    final hover = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await hover.addPointer();
    addTearDown(hover.removePointer);
    await hover.moveTo(tester.getCenter(find.byTooltip('عرض')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('عرض'), findsWidgets);

    await _expectEnd(tester, const Locale('ar'));
    await _expectEnd(tester, const Locale('en'));
  });
}

Future<void> _expectEnd(WidgetTester tester, Locale locale) async {
  final rtl = locale.languageCode == 'ar';
  final viewLabel = rtl ? 'عرض' : 'View';
  final editLabel = rtl ? 'تعديل' : 'Edit';
  await tester.pumpWidget(_table(locale, onView: () {}, onEdit: () {}));
  await tester.pump();
  await tester.pumpAndSettle();

  final plate = tester.getTopLeft(find.text('A 12345')).dx;
  final view = tester.getTopLeft(find.byTooltip(viewLabel)).dx;
  final edit = tester.getTopLeft(find.byTooltip(editLabel)).dx;

  if (rtl) {
    expect(view, lessThan(plate));
    expect(edit, lessThan(view));
  } else {
    expect(view, greaterThan(plate));
    expect(edit, greaterThan(view));
  }
}

Widget _table(
  Locale locale, {
  required VoidCallback onView,
  required VoidCallback onEdit,
}) {
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
        width: 1100,
        child: ResponsiveDataView<String>(
          items: const ['A 12345'],
          columns: const [DataColumnSpec('Plate'), DataColumnSpec('Actions')],
          rowCells: (item) => [
            Text(item),
            RecordActions(onView: onView, onEdit: onEdit),
          ],
          cardBuilder: (item) => ListTile(title: Text(item)),
        ),
      ),
    ),
  );
}

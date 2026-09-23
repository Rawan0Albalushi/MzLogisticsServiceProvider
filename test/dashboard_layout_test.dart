import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mz_logistics_service_provider_app/core/theme/page_visuals.dart';
import 'package:mz_logistics_service_provider_app/features/dashboard/presentation/widgets/dashboard_kpi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final metrics = [
    _metric('Open shipments', '12'),
    _metric('Pending quotations', '4'),
    _metric('Active jobs', '8'),
    _metric('Trips in transit', '3'),
  ];

  testWidgets('kpi grid lays out on a phone width', (tester) async {
    await _pumpGrid(tester, const Size(360, 900), metrics);

    expect(find.text('Open shipments'), findsOneWidget);
    expect(find.text('Trips in transit'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('kpi grid lays out on a wide screen', (tester) async {
    await _pumpGrid(tester, const Size(1280, 800), metrics);

    expect(find.text('Active jobs'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('attention list and quick actions fit a phone width', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                DashboardAttentionList(
                  items: [
                    DashboardAttentionItem(
                      label: 'Unassigned trips',
                      count: '3',
                      icon: Icons.route_outlined,
                      tone: DashboardKpiTone.danger,
                      viewLabel: 'View all',
                      onTap: () {},
                    ),
                  ],
                ),
                DashboardQuickLinkGrid(
                  links: [
                    DashboardQuickLink(
                      title: 'Review shipments',
                      hint: 'Open published requests and prepare quotations.',
                      icon: Icons.local_shipping_outlined,
                      tone: IconTone.teal,
                      onTap: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Unassigned trips'), findsOneWidget);
    expect(
      find.text('Open published requests and prepare quotations.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('kpi grid keeps labels in Arabic layout', (tester) async {
    await _pumpGrid(tester, const Size(400, 900), [
      _metric('شحنات مفتوحة', '١٢'),
      _metric('عروض معلّقة', '٤'),
    ], textDirection: TextDirection.rtl);

    expect(find.text('شحنات مفتوحة'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('شحنات مفتوحة'))),
      TextDirection.rtl,
    );
    expect(tester.takeException(), isNull);
  });
}

DashboardKpi _metric(String label, String value) {
  return DashboardKpi(
    label: label,
    value: value,
    hint: 'Published requests waiting for a quote',
    icon: Icons.local_shipping_outlined,
    onTap: () {},
  );
}

Future<void> _pumpGrid(
  WidgetTester tester,
  Size size,
  List<DashboardKpi> metrics, {
  TextDirection textDirection = TextDirection.ltr,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: Directionality(
        textDirection: textDirection,
        child: Scaffold(
          body: SingleChildScrollView(
            child: DashboardKpiGrid(metrics: metrics),
          ),
        ),
      ),
    ),
  );
}

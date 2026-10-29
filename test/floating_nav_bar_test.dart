import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visitor/shared/widgets/floating_nav_bar.dart';

void main() {
  const items = [
    FloatingNavItem(
      icon: Icons.space_dashboard_outlined,
      selectedIcon: Icons.space_dashboard_rounded,
      label: 'Dashboard',
    ),
    FloatingNavItem(
      icon: Icons.groups_outlined,
      selectedIcon: Icons.groups_rounded,
      label: 'Visitors',
    ),
    FloatingNavItem(
      icon: Icons.qr_code_scanner_rounded,
      selectedIcon: Icons.qr_code_scanner_rounded,
      label: 'Scan',
    ),
  ];

  Future<void> pumpBar(
    WidgetTester tester, {
    int currentIndex = 0,
    ValueChanged<int>? onSelected,
    Size size = const Size(375, 812),
    double textScale = 1.0,
  }) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: MaterialApp(
          home: Scaffold(
            extendBody: true,
            body: const SizedBox.expand(),
            bottomNavigationBar: FloatingNavBar(
              currentIndex: currentIndex,
              onSelected: onSelected ?? (_) {},
              items: items,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders every destination', (tester) async {
    await pumpBar(tester);

    expect(find.byIcon(Icons.space_dashboard_rounded), findsOneWidget);
    expect(find.byIcon(Icons.groups_outlined), findsOneWidget);
    expect(find.byIcon(Icons.qr_code_scanner_rounded), findsOneWidget);
  });

  testWidgets('every destination shows its label', (tester) async {
    await pumpBar(tester, currentIndex: 0);

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Visitors'), findsOneWidget);
    expect(find.text('Scan'), findsOneWidget);
  });

  testWidgets('the selected destination swaps to its filled icon',
      (tester) async {
    await pumpBar(tester, currentIndex: 2);

    expect(find.byIcon(Icons.space_dashboard_outlined), findsOneWidget);
    expect(find.byIcon(Icons.space_dashboard_rounded), findsNothing);
  });

  testWidgets('reports the tapped index', (tester) async {
    final tapped = <int>[];
    await pumpBar(tester, onSelected: tapped.add);

    await tester.tap(find.byIcon(Icons.groups_outlined));
    await tester.pumpAndSettle();

    expect(tapped, [1]);
  });

  testWidgets('fits a narrow phone', (tester) async {
    await pumpBar(tester, size: const Size(320, 568));

    expect(tester.takeException(), isNull);
  });

  testWidgets('fits at double the font scale', (tester) async {
    await pumpBar(tester, textScale: 2.0);

    expect(tester.takeException(), isNull);
  });

  testWidgets('fits at double the font scale on a narrow phone', (tester) async {
    await pumpBar(tester, size: const Size(320, 568), textScale: 2.0);

    expect(tester.takeException(), isNull);
  });

  testWidgets('labels every destination for assistive technology',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pumpBar(tester, currentIndex: 1);

    expect(find.bySemanticsLabel('Dashboard'), findsAtLeastNWidgets(1));
    expect(find.bySemanticsLabel('Visitors'), findsAtLeastNWidgets(1));
    expect(find.bySemanticsLabel('Scan'), findsAtLeastNWidgets(1));

    handle.dispose();
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visitor/shared/widgets/state_views.dart';

void main() {
  Future<void> pumpAt(
    WidgetTester tester,
    Widget child, {
    Size size = const Size(360, 640),
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
        child: MaterialApp(home: Scaffold(body: child)),
      ),
    );
    await tester.pump();
  }

  const longMessage =
      'No internet connection. Check your network and try again. '
      'The server could not be reached, so the visitor list could not be '
      'loaded and the statistics below may be out of date.';

  group('ErrorStateView', () {
    testWidgets('fits inside a dashboard card on a small phone', (tester) async {
      await pumpAt(
        tester,
        ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ErrorStateView(
                title: 'Could not load statistics',
                message: longMessage,
                onRetry: () async {},
              ),
            ),
          ],
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('fits on a very short screen', (tester) async {
      await pumpAt(
        tester,
        ErrorStateView(message: longMessage, onRetry: () async {}),
        size: const Size(320, 400),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('fits at double the font scale', (tester) async {
      await pumpAt(
        tester,
        ErrorStateView(message: longMessage, onRetry: () async {}),
        size: const Size(360, 640),
        textScale: 2.0,
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('shows the message and a retry control', (tester) async {
      await pumpAt(
        tester,
        ErrorStateView(message: 'No internet connection.', onRetry: () async {}),
      );

      expect(find.text('No internet connection.'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('offers no retry when none was given', (tester) async {
      await pumpAt(tester, const ErrorStateView(message: 'Broken.'));

      expect(find.text('Try again'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('EmptyStateView', () {
    testWidgets('fits on a small screen with a long message', (tester) async {
      await pumpAt(
        tester,
        const EmptyStateView(
          title: 'No visitors yet',
          message:
              'Registered visitors will appear here. Tap Register to add the '
              'first one, or scan an existing visitor pass to look someone up.',
          actionLabel: 'Register Visitor',
        ),
        size: const Size(320, 480),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('fits at double the font scale', (tester) async {
      await pumpAt(
        tester,
        const EmptyStateView(
          title: 'No matching visitors',
          message: 'Try a different name or number, or clear the filters.',
        ),
        textScale: 2.0,
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('LoadingView', () {
    testWidgets('fits in a short box', (tester) async {
      await pumpAt(
        tester,
        const SizedBox(
          height: 90,
          child: LoadingView(message: 'Loading visitors…'),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}

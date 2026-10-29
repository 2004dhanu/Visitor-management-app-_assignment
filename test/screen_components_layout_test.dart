import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visitor/core/theme/app_colors.dart';
import 'package:visitor/core/theme/app_theme.dart';
import 'package:visitor/features/visitors/data/visitor.dart';
import 'package:visitor/features/visitors/data/visitor_status.dart';
import 'package:visitor/features/visitors/widgets/dashboard_stat_card.dart';
import 'package:visitor/features/visitors/widgets/sparkline.dart';
import 'package:visitor/features/visitors/widgets/visit_timeline.dart';
import 'package:visitor/features/visitors/widgets/visitor_card.dart';
import 'package:visitor/shared/widgets/section_card.dart';
import 'package:visitor/shared/widgets/step_indicator.dart';

void main() {
  const longVisitor = Visitor(
    id: '12',
    name: 'Chandrasekhar Venkataraghavan',
    mobile: '9876543210',
    email: 'chandrasekhar.venkataraghavan@example.com',
    visitorType: 'Customer',
    project: 'Project A',
    purpose: 'Site visit to review the handover checklist',
    status: VisitorStatus.checkedIn,
    createdAt: '2026-10-29T09:15:00+05:30',
    checkInTime: '2026-10-29T10:24:00+05:30',
    checkOutTime: null,
  );

  Future<void> pumpAt(
    WidgetTester tester,
    Widget child, {
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
          theme: AppTheme.light(),
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.gutter),
              child: child,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('VisitorCard', () {
    testWidgets('fits a long name with both row actions', (tester) async {
      await pumpAt(
        tester,
        VisitorCard(visitor: longVisitor, onEdit: () {}, onDelete: () {}),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('fits on a 320px phone', (tester) async {
      await pumpAt(
        tester,
        VisitorCard(visitor: longVisitor, onEdit: () {}, onDelete: () {}),
        size: const Size(320, 568),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('fits at a large font scale', (tester) async {
      await pumpAt(
        tester,
        VisitorCard(visitor: longVisitor, onEdit: () {}, onDelete: () {}),
        textScale: 1.6,
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('the compact variant fits too', (tester) async {
      await pumpAt(
        tester,
        VisitorCard(visitor: longVisitor, compact: true),
        size: const Size(320, 568),
        textScale: 1.4,
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('shows the fields the brief requires', (tester) async {
      await pumpAt(
        tester,
        VisitorCard(visitor: longVisitor, onEdit: () {}, onDelete: () {}),
      );

      expect(find.textContaining('Chandrasekhar'), findsOneWidget);
      expect(find.text('9876543210'), findsOneWidget);
      expect(find.text('Project A'), findsOneWidget);
      expect(find.text('Customer'), findsOneWidget);
      expect(find.text('Checked In'), findsOneWidget);
    });
  });

  group('DashboardStatCard', () {
    testWidgets('fits three to a row on a 375px screen', (tester) async {
      await pumpAt(
        tester,
        const Row(
          children: [
            Expanded(
              child: DashboardStatCard(
                label: 'Total today',
                value: 12,
                icon: Icons.groups_rounded,
                color: AppColors.registered,
                trend: [1, 3, 2, 5, 4, 6, 12],
              ),
            ),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: DashboardStatCard(
                label: 'Inside now',
                value: 3,
                icon: Icons.login_rounded,
                color: AppColors.checkedIn,
                trend: [0, 1, 1, 2, 2, 3, 3],
              ),
            ),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: DashboardStatCard(
                label: 'Checked out',
                value: 9,
                icon: Icons.logout_rounded,
                color: AppColors.exit,
                trend: [1, 2, 1, 3, 2, 4, 9],
              ),
            ),
          ],
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('fits while loading', (tester) async {
      await pumpAt(
        tester,
        const DashboardStatCard(
          label: 'Total today',
          value: 0,
          icon: Icons.groups_rounded,
          color: AppColors.registered,
          isLoading: true,
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('Sparkline', () {
    testWidgets('draws nothing without at least two days of data',
        (tester) async {
      await pumpAt(
        tester,
        const Sparkline(values: [5], color: AppColors.registered),
      );

      expect(
        find.descendant(
          of: find.byType(Sparkline),
          matching: find.byType(CustomPaint),
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('draws nothing when every day is zero', (tester) async {
      await pumpAt(
        tester,
        const Sparkline(
          values: [0, 0, 0, 0, 0, 0, 0],
          color: AppColors.registered,
        ),
      );

      expect(
        find.descendant(
          of: find.byType(Sparkline),
          matching: find.byType(CustomPaint),
        ),
        findsNothing,
      );
    });

    testWidgets('survives a completely flat non-zero series', (tester) async {
      await pumpAt(
        tester,
        const Sparkline(
          values: [4, 4, 4, 4, 4, 4, 4],
          color: AppColors.registered,
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('SectionCard', () {
    testWidgets('fits a long subtitle and a trailing badge', (tester) async {
      await pumpAt(
        tester,
        const SectionCard(
          title: 'Visitor Information',
          subtitle:
              'Basic details about the visitor, including how to reach them',
          icon: Icons.person_outline_rounded,
          trailing: SoftBadge(label: 'Valid Pass', dense: true),
          children: [Text('Body')],
        ),
        size: const Size(320, 568),
        textScale: 1.3,
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('StepIndicator', () {
    testWidgets('fits on a narrow screen at a large font scale',
        (tester) async {
      await pumpAt(
        tester,
        const StepIndicator(
          steps: ['Visitor details', 'Pass issued'],
          currentIndex: 0,
        ),
        size: const Size(320, 568),
        textScale: 1.6,
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('VisitTimeline', () {
    testWidgets('shows pending stages rather than hiding them', (tester) async {
      await pumpAt(tester, const VisitTimeline(visitor: longVisitor));

      expect(find.text('Registered'), findsOneWidget);
      expect(find.text('Checked in'), findsOneWidget);
      expect(find.text('Checked out'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('fits at a large font scale', (tester) async {
      await pumpAt(
        tester,
        const VisitTimeline(visitor: longVisitor),
        size: const Size(320, 700),
        textScale: 1.4,
      );

      expect(tester.takeException(), isNull);
    });
  });
}

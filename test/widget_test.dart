import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:adaptive_ui_system/main.dart';

void main() {
  testWidgets('shows compact breakpoint and bottom navigation on narrow screens',
      (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const AdaptiveUIApp());
    await tester.pumpAndSettle();

    final chip = tester.widget<Chip>(find.byKey(const Key('breakpoint-indicator')));
    expect(((chip.label as Text).data), 'Compact');
    expect(chip.backgroundColor, const Color(0xFF245A9B));
    expect(find.byKey(const Key('adaptive-nav-bottom-bar')), findsOneWidget);
    expect(find.byKey(const Key('adaptive-nav-rail')), findsNothing);
    expect(find.byKey(const Key('adaptive-nav-drawer')), findsNothing);
  });

  testWidgets('shows rail on medium screens and drawer on expanded screens',
      (tester) async {
    tester.view.physicalSize = const Size(700, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const AdaptiveUIApp());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('adaptive-nav-rail')), findsOneWidget);
    expect(find.byKey(const Key('adaptive-nav-bottom-bar')), findsNothing);

    tester.view.physicalSize = const Size(1000, 800);
    await tester.pumpAndSettle();

    final chip = tester.widget<Chip>(find.byKey(const Key('breakpoint-indicator')));
    expect(((chip.label as Text).data), 'Expanded');
  expect(chip.backgroundColor, const Color(0xFF184E77));
    expect(find.byKey(const Key('adaptive-nav-drawer')), findsOneWidget);
    expect(find.byKey(const Key('adaptive-nav-bottom-bar')), findsNothing);
    expect(find.byKey(const Key('adaptive-nav-rail')), findsNothing);
  });

  testWidgets('navigates to the grid screen and keeps grid items mounted',
      (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const AdaptiveUIApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Grid').last);
    await tester.pumpAndSettle();

    expect(find.text('Adaptive Grid'), findsOneWidget);
    expect(find.byKey(const Key('grid-item-0')), findsOneWidget);
  });
}

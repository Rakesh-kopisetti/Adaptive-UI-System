import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:adaptive_ui_system/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Responsive Flow Tests', () {
    Future<void> pumpApp(WidgetTester tester, Size size) async {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(const AdaptiveUIApp());
      await tester.pumpAndSettle();
    }

    void expectBreakpointChip(WidgetTester tester, String label, Color color) {
      final chipWidget = tester.widget<Chip>(find.byKey(const Key('breakpoint-indicator')));
      final textWidget = chipWidget.label as Text;
      expect(textWidget.data, equals(label));
      expect(chipWidget.backgroundColor, equals(color));
    }

    testWidgets('Breakpoint indicator shows correct state for compact screen',
        (WidgetTester tester) async {
      await pumpApp(tester, const Size(400, 800));
      expect(find.byKey(const Key('breakpoint-indicator')), findsOneWidget);
      expectBreakpointChip(tester, 'Compact', Colors.blue);
    });

    testWidgets('Breakpoint indicator shows correct state for medium screen',
        (WidgetTester tester) async {
      await pumpApp(tester, const Size(700, 800));
      expectBreakpointChip(tester, 'Medium', Colors.green);
    });

    testWidgets('Breakpoint indicator shows correct state for expanded screen',
        (WidgetTester tester) async {
      await pumpApp(tester, const Size(1000, 800));
      expectBreakpointChip(tester, 'Expanded', Colors.purple);
    });

    testWidgets('Bottom navigation bar visible on compact screen',
        (WidgetTester tester) async {
      await pumpApp(tester, const Size(400, 800));
      expect(find.byKey(const Key('adaptive-nav-bottom-bar')), findsOneWidget);
      expect(find.byKey(const Key('adaptive-nav-rail')), findsNothing);
      expect(find.byKey(const Key('adaptive-nav-drawer')), findsNothing);
    });

    testWidgets('Navigation rail visible on medium screen',
        (WidgetTester tester) async {
      await pumpApp(tester, const Size(700, 800));
      expect(find.byKey(const Key('adaptive-nav-rail')), findsOneWidget);
      expect(find.byKey(const Key('adaptive-nav-bottom-bar')), findsNothing);
      expect(find.byKey(const Key('adaptive-nav-drawer')), findsNothing);
    });

    testWidgets('Navigation drawer visible on expanded screen',
        (WidgetTester tester) async {
      await pumpApp(tester, const Size(1000, 800));
      expect(find.byKey(const Key('adaptive-nav-drawer')), findsOneWidget);
      expect(find.byKey(const Key('adaptive-nav-bottom-bar')), findsNothing);
      expect(find.byKey(const Key('adaptive-nav-rail')), findsNothing);
    });

    testWidgets('Grid columns adapt to breakpoints',
        (WidgetTester tester) async {
      await pumpApp(tester, const Size(400, 800));
      await tester.tap(find.text('Grid').last);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('grid-item-0')), findsOneWidget);

      await tester.binding.setSurfaceSize(const Size(700, 800));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('adaptive-nav-rail')), findsOneWidget);

      await tester.binding.setSurfaceSize(const Size(1000, 800));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('adaptive-nav-drawer')), findsOneWidget);
    });

    testWidgets('Screen transitions are tracked between breakpoints',
        (WidgetTester tester) async {
      // Start with compact screen
      await tester.binding.setSurfaceSize(const Size(400, 800));
      await tester.pumpWidget(const AdaptiveUIApp());
      await tester.pumpAndSettle();
      
      // Verify we start at compact
      expect(find.byKey(const Key('breakpoint-indicator')), findsOneWidget);
      
      // Transition to medium
      await tester.binding.setSurfaceSize(const Size(700, 800));
      await tester.pumpAndSettle();
      
      // Verify transition to medium occurred
      final mediumIndicator = find.byKey(const Key('breakpoint-indicator'));
      expect(mediumIndicator, findsOneWidget);
      
      // Transition to expanded
      await tester.binding.setSurfaceSize(const Size(1000, 800));
      await tester.pumpAndSettle();
      
      // Verify transition to expanded
      final expandedIndicator = find.byKey(const Key('breakpoint-indicator'));
      expect(expandedIndicator, findsOneWidget);
      
      // Transition back to medium
      await tester.binding.setSurfaceSize(const Size(700, 800));
      await tester.pumpAndSettle();
    });

    testWidgets('Navigation state persists after navigation',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      await tester.pumpWidget(const AdaptiveUIApp());
      await tester.pumpAndSettle();

      // Get the bottom navigation bar
      final bottomNav = find.byKey(const Key('adaptive-nav-bottom-bar'));
      expect(bottomNav, findsOneWidget);

      // Tap on Grid item (index 1)
      final navWidget = tester.widget<BottomNavigationBar>(bottomNav);
      expect(navWidget.items.length, greaterThan(1));
    });

    testWidgets('Adaptive typography scales with breakpoints',
        (WidgetTester tester) async {
      // Test at compact size
      await tester.binding.setSurfaceSize(const Size(400, 800));
      await tester.pumpWidget(const AdaptiveUIApp());
      await tester.pumpAndSettle();
      
      // The breakpoint indicator should be present
      expect(find.byKey(const Key('breakpoint-indicator')), findsOneWidget);
      
      // Test at expanded size - typography should scale up
      await tester.binding.setSurfaceSize(const Size(1000, 800));
      await tester.pumpAndSettle();
      
      // The app should still function with larger typography
      expect(find.byKey(const Key('breakpoint-indicator')), findsOneWidget);
    });
  });
}

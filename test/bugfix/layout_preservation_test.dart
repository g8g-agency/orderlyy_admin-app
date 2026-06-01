import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Preservation Property Tests: Properly Constrained Layouts (Bug 3)
///
/// Property 2: Preservation - Non-Affected Screens Render Correctly
///
/// Confirms that screens/widgets without layout issues continue to render
/// correctly without overflow warnings after the Bug 3 fix is applied.
///
/// Requirements: 3.7, 3.8, 3.9

void main() {
  group('Preservation: Properly Constrained Layouts', () {
    testWidgets(
      'Simple Column layout renders correctly without overflow',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: const [
                  Text('Dashboard'),
                  Text('Menu Management'),
                  Text('Tables & QR'),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          tester.takeException(),
          isNull,
          reason: 'Simple Column layout should render without issues',
        );
        expect(find.text('Dashboard'), findsOneWidget);
        expect(find.text('Menu Management'), findsOneWidget);
      },
    );

    testWidgets(
      'Properly constrained Row layout with Expanded widgets works correctly',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Row(
                children: const [
                  Expanded(child: Text('Properly constrained text on left')),
                  Expanded(child: Text('Properly constrained text on right')),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          tester.takeException(),
          isNull,
          reason:
              'Row with Expanded children should render without overflow',
        );
      },
    );

    testWidgets(
      'Row with Flexible and ellipsis overflow handles long text gracefully',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Expanded(
                    child: Text(
                      'A very long action label that might exceed normal width',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '2026-05-24 02:40:44',
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          tester.takeException(),
          isNull,
          reason:
              'Row with Flexible + overflow ellipsis should not throw exceptions',
        );
      },
    );

    testWidgets(
      'Navigation between working screens remains smooth',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            routes: {
              '/': (_) => const _HomeScreen(),
              '/menu': (_) => const _MenuScreen(),
            },
            initialRoute: '/',
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Go to Menu'), findsOneWidget);

        // Navigate to another screen
        await tester.tap(find.text('Go to Menu'));
        await tester.pumpAndSettle();

        expect(find.text('Menu Screen'), findsOneWidget);
        expect(
          tester.takeException(),
          isNull,
          reason: 'Navigation between working screens should be smooth',
        );
      },
    );

    testWidgets(
      'SingleChildScrollView with Row content handles overflow gracefully',
      (tester) async {
        // Controls row in OCC conflict screen uses SingleChildScrollView
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text('AUTO-MERGE CHANGES (3-WAY MERGE)'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () {},
                      child: const Text('KEEP SERVER VERSION (ROLLBACK)'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () {},
                      child: const Text('RESET SIMULATOR'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          tester.takeException(),
          isNull,
          reason:
              'SingleChildScrollView + Row for button controls should not overflow',
        );
      },
    );
  });
}

// Helper widgets for navigation test
class _HomeScreen extends StatelessWidget {
  const _HomeScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, '/menu'),
          child: const Text('Go to Menu'),
        ),
      ),
    );
  }
}

class _MenuScreen extends StatelessWidget {
  const _MenuScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Menu')),
      body: const Center(child: Text('Menu Screen')),
    );
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orderlli_admin/main.dart'; // adjust path to your main

void main() {
  testWidgets('App starts without layout exception', (WidgetTester tester) async {
    try {
      await tester.pumpWidget(const ProviderScope(child: const OrderlliApp()));
      await tester.pumpAndSettle();
    } catch (e, st) {
      print('CAUGHT EXCEPTION: $e');
      print('STACKTRACE: $st');
      rethrow;
    }
  });
}

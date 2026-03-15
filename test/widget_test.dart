import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakhi/main.dart';

void main() {
  testWidgets('Sakhi app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: SakhiApp()),
    );
    expect(find.byType(SakhiApp), findsOneWidget);
  });
}
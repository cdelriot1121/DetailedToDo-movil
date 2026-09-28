import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:detailed_to_do/app/app.dart';

void main() {
  testWidgets('DetailedToDo app initializes smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: DetailedToDoApp(),
      ),
    );

    await tester.pump();
    expect(find.byType(DetailedToDoApp), findsOneWidget);
  });
}

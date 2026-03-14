import 'package:flutter_test/flutter_test.dart';
import 'package:vocabmaster/main.dart';

void main() {
  testWidgets('App smoke test renders VocabMaster shell', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('VocabMaster'), findsOneWidget);
  });
}

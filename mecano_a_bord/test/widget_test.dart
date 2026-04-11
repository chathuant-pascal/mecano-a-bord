// Test widget Mécano à Bord — smoke test
import 'package:flutter_test/flutter_test.dart';
import 'package:mecano_a_bord/main.dart';

void main() {
  testWidgets('App démarre et affiche Mécano à Bord', (WidgetTester tester) async {
    await tester.pumpWidget(const MabApp());
    await tester.pump();
    expect(find.text('Mécano à Bord'), findsOneWidget);
  });
}

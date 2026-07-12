import 'package:flutter_test/flutter_test.dart';
import 'package:trendvibe_app/main.dart';

void main() {
  testWidgets('TrendVibe inicia correctamente', (WidgetTester tester) async {
    await tester.pumpWidget(const TrendVibeApp());

    expect(find.text('¡Bienvenido de nuevo!'), findsOneWidget);
  });
}
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marketplace_ucss_ios/main.dart';

void main() {
  testWidgets('UCSS Marketplace app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: UcssMarketplaceApp(),
      ),
    );

    // Verifica que la app monte sin errores
    expect(find.byType(UcssMarketplaceApp), findsOneWidget);
  });
}

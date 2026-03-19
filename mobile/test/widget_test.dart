import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yazihanem_mobile/app.dart';

void main() {
  testWidgets('App renders login screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: YazihanemApp()),
    );

    // Wait for GoRouter to settle
    await tester.pumpAndSettle();

    // Verify the app renders and shows the login screen
    expect(find.text('Yazıhanem'), findsOneWidget);
    expect(find.text('Giriş Yap'), findsWidgets);
  });
}

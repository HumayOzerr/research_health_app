import 'package:flutter_test/flutter_test.dart';
import 'package:research_health_app/main.dart';

void main() {
  testWidgets('App renders welcome screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ResearchHealthApp(consentGiven: false));
    expect(find.text('Health Research Study'), findsOneWidget);
  });
}

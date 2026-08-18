import 'package:flutter_test/flutter_test.dart';
import 'package:smartops_app/main.dart';

void main() {
  testWidgets('SmartOpsApp starts on the login screen', (tester) async {
    await tester.pumpWidget(const SmartOpsApp());

    expect(find.text('SIGN IN'), findsOneWidget);
    expect(find.text('KIOSK TERMINAL'), findsOneWidget);
  });
}

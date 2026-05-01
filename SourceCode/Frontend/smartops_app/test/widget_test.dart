import 'package:flutter_test/flutter_test.dart';
import 'package:smartops_app/main.dart';

void main() {
  testWidgets('SmartOpsApp smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SmartOpsApp());

    // Verify that our app starts and shows the employee dashboard title.
    expect(find.text('Cổng thông tin Nhân viên'), findsOneWidget);

    // Verify that we have some buttons from the mockup.
    expect(find.text('[ MÃ QR ĐỘNG CỦA BẠN ]'), findsOneWidget);
  });
}

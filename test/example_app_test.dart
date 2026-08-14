import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../example/lib/main.dart';

void main() {
  group('NeatFormShowcaseApp Widget Tests', () {
    testWidgets('renders all tabs and allows switching', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const NeatFormShowcaseApp());
      await tester.pumpAndSettle();

      expect(find.text('neat_form Showcase'), findsOneWidget);
      expect(find.text('Tài khoản & Auth'), findsOneWidget);
      expect(find.text('Fintech & Thẻ'), findsOneWidget);
      expect(find.text('Booking & E-Com'), findsOneWidget);

      // Verify Tab 1 content
      expect(find.text('Đăng ký tài khoản & Bảo mật'), findsOneWidget);

      // Switch to Tab 2
      await tester.tap(find.text('Fintech & Thẻ'));
      await tester.pumpAndSettle();
      expect(find.text('Thanh toán thẻ & Fintech'), findsOneWidget);

      // Switch to Tab 3
      await tester.tap(find.text('Booking & E-Com'));
      await tester.pumpAndSettle();
      expect(find.text('Đặt phòng khách sạn & Cross-field'), findsOneWidget);
    });

    testWidgets('Tab 1 submission shows errors when required fields are empty',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const NeatFormShowcaseApp());
      await tester.pumpAndSettle();

      // Tap submit button without filling fields
      final submitButton = find.widgetWithText(ElevatedButton, 'Đăng Ký Ngay');
      expect(submitButton, findsOneWidget);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Error messages appear
      expect(find.text('Vui lòng nhập họ và tên'), findsOneWidget);
      expect(find.text('Vui lòng nhập email'), findsOneWidget);
      expect(find.text('Vui lòng nhập tên đăng nhập'), findsOneWidget);
    });
  });
}

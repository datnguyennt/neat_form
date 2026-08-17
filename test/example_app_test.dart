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

      expect(find.text('Dynamic Array'), findsOneWidget);

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

      // Switch to Tab 4
      await tester.tap(find.text('Dynamic Array'));
      await tester.pumpAndSettle();
      expect(find.text('Danh Sách Hành Khách Bay (1/4)'), findsOneWidget);

      // Add a passenger in Tab 4
      final addPassengerBtn = find.text('+ Thêm Hành Khách');
      expect(addPassengerBtn, findsOneWidget);
      await tester.tap(addPassengerBtn);
      await tester.pumpAndSettle();
      expect(find.text('Danh Sách Hành Khách Bay (2/4)'), findsOneWidget);
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

    testWidgets('DynamicCheckoutShowcaseScreen renders and navigates from AppBar',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const NeatFormShowcaseApp());
      await tester.pumpAndSettle();

      // Tap Full Demo action button
      final fullDemoBtn = find.text('Full Demo');
      expect(fullDemoBtn, findsOneWidget);
      await tester.tap(fullDemoBtn);
      await tester.pumpAndSettle();

      // Verify DynamicCheckoutShowcaseScreen is presented
      expect(find.text('✈️ Đặt Vé & Thanh Toán Toàn Diện'), findsOneWidget);
      expect(find.text('1. Danh Sách Hành Khách Bay (1/5)'), findsOneWidget);
      expect(find.text('2. Thông Tin Thanh Toán & Thẻ (Input Formatters & Masking)'), findsOneWidget);
      expect(find.text('3. Dữ Liệu Form Thời Gian Thực (Live JSON Output)'), findsOneWidget);

      // Add a guest
      final addGuestBtn = find.text('+ Thêm Hành Khách Mới');
      expect(addGuestBtn, findsOneWidget);
      await tester.tap(addGuestBtn);
      await tester.pumpAndSettle();
      expect(find.text('1. Danh Sách Hành Khách Bay (2/5)'), findsOneWidget);

      // Tap Submit without card info -> shows error snackbar
      final submitBtn = find.text('Xác Nhận & Xuất Vé');
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();
      expect(find.text('Vui lòng nhập số thẻ ngân hàng'), findsOneWidget);
    });
  });
}

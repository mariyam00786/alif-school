import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:alif_admin/main.dart';

void main() {
  testWidgets('renders admin login gate', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const AdminApp());
    await tester.pumpAndSettle();

    expect(find.text('Admin Login'), findsOneWidget);
    expect(find.text('Send OTP'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}

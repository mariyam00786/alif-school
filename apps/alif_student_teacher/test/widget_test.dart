import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:alif_student_teacher/main.dart';

void main() {
  testWidgets('renders student and teacher shell', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: StudentTeacherHomePage(
          onSignOut: () async {},
        ),
      ),
    );

    expect(find.text('Student & Teacher'), findsOneWidget);
    expect(find.text('Mark Today\'s Activities'), findsOneWidget);
  });
}

import 'package:BisonsTechs_app/core/Manufacturing/screens/manufacturing_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  testWidgets('Manufacturing stub dashboard shows title and placeholder',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const GetMaterialApp(
        home: ManufacturingDashboardScreen(),
      ),
    );

    expect(find.text('Manufacturing'), findsWidgets);
    expect(
      find.textContaining('will be added here'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.factory_outlined), findsOneWidget);
  });
}

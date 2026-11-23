import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:church_service_management_system/app/ui/responsive.dart';

void main() {
  Future<void> expectViewport(
    WidgetTester tester,
    double width, {
    required bool mobile,
    required bool tablet,
    required bool desktop,
  }) async {
    bool? actualMobile;
    bool? actualTablet;
    bool? actualDesktop;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: Size(width, 800)),
          child: Builder(
            builder: (context) {
              actualMobile = context.isMobile;
              actualTablet = context.isTablet;
              actualDesktop = context.isDesktop;
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    expect(actualMobile, mobile, reason: 'width=$width');
    expect(actualTablet, tablet, reason: 'width=$width');
    expect(actualDesktop, desktop, reason: 'width=$width');
  }

  testWidgets('responsive extensions use the declared breakpoints', (tester) async {
    await expectViewport(tester, 599, mobile: true, tablet: false, desktop: false);
    await expectViewport(tester, 600, mobile: false, tablet: true, desktop: false);
    await expectViewport(tester, 1099, mobile: false, tablet: true, desktop: false);
    await expectViewport(tester, 1100, mobile: false, tablet: false, desktop: true);
  });
}

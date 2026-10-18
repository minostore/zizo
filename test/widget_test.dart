import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:razor_booking/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows the ZIZO welcome screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const BarberBookingApp());
    expect(find.text('IZO'), findsOneWidget);
    expect(find.text('ابدأ الحجز'), findsOneWidget);
    expect(find.text('تسجيل الدخول'), findsOneWidget);
    // dispose the tree so no retry timer is left pending
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

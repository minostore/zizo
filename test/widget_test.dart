import 'package:flutter_test/flutter_test.dart';
import 'package:razor_booking/main.dart';

void main() {
  testWidgets('shows the Arabic barber welcome screen', (tester) async {
    await tester.pumpWidget(const BarberBookingApp());
    expect(find.text('حلاقة تليق بك'), findsOneWidget);
    expect(find.text('ابدأ الحجز'), findsOneWidget);
    expect(find.text('تسجيل الدخول'), findsOneWidget);
  });
}

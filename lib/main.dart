import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'salon_api.dart';

const ink = Color(0xFF090908);
const panel = Color(0xFF151512);
const gold = Color(0xFFD7B05F);
const goldLight = Color(0xFFE9CA83);
const muted = Color(0xFFA5A197);
const green = Color(0xFF66C49A);
final money = NumberFormat.currency(locale: 'ar_EG', symbol: 'ج.م.', decimalDigits: 0);
String egp(num amount) => money.format(amount);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar_EG');
  runApp(const BarberBookingApp());
}

class BarberBookingApp extends StatelessWidget {
  const BarberBookingApp({super.key});
  @override
  Widget build(BuildContext context) {
    final defaults = ThemeData.dark(useMaterial3: true);
    return MaterialApp(
      title: 'حلاقة تليق بك',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar', 'EG'),
      supportedLocales: const [Locale('ar', 'EG'), Locale('en', 'US')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: defaults.copyWith(
        scaffoldBackgroundColor: ink,
        colorScheme: defaults.colorScheme.copyWith(primary: gold, secondary: goldLight, surface: panel),
        appBarTheme: const AppBarTheme(backgroundColor: ink, foregroundColor: Colors.white, centerTitle: false, elevation: 0),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: panel,
          hintStyle: const TextStyle(color: Color(0xFF77746D), fontSize: 13),
          labelStyle: const TextStyle(color: muted, fontSize: 13),
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: Color(0xFF2B2A25))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: Color(0xFF2B2A25))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: gold, width: 1.2)),
        ),
        snackBarTheme: SnackBarThemeData(backgroundColor: const Color(0xFF24221D), contentTextStyle: const TextStyle(color: Colors.white), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        textSelectionTheme: const TextSelectionThemeData(cursorColor: gold, selectionHandleColor: gold),
      ),
      home: const WelcomeScreen(),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: LayoutBuilder(builder: (context, constraints) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(23, 18, 23, 20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    const BrandMark(),
                    Expanded(child: Center(child: SingleChildScrollView(child: Column(children: [
                      Container(width: constraints.maxWidth > 560 ? 205 : 174, height: constraints.maxWidth > 560 ? 205 : 174, padding: const EdgeInsets.all(9), decoration: BoxDecoration(borderRadius: BorderRadius.circular(36), border: Border.all(color: gold.withValues(alpha: .25)), boxShadow: [BoxShadow(color: gold.withValues(alpha: .08), blurRadius: 55, spreadRadius: 8)]), child: ClipRRect(borderRadius: BorderRadius.circular(27), child: Image.asset('assets/barber_app_icon.png', fit: BoxFit.cover)),),
                      const SizedBox(height: 27),
                      const Text('حلاقة تليق بك', textAlign: TextAlign.center, style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white)),
                      const SizedBox(height: 10),
                      const Text('اختار خدمتك وموعدك، وسيب علينا التفاصيل.\nحجز سهل من موبايلك في أي مكان في مصر.', textAlign: TextAlign.center, style: TextStyle(color: muted, height: 1.8, fontSize: 13)),
                      const SizedBox(height: 20),
                      const Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [FeaturePill(icon: Icons.location_on_outlined, label: 'مصر'), FeaturePill(icon: Icons.payments_outlined, label: 'الجنيه المصري'), FeaturePill(icon: Icons.timer_outlined, label: 'حجز سريع')]),
                    ])))),
                    GoldButton(label: 'ابدأ الحجز', icon: Icons.arrow_back_rounded, onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccessScreen()))),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccessScreen(showLogin: true))), icon: const Icon(Icons.person_outline_rounded, size: 18), label: const Text('تسجيل الدخول'), style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Color(0xFF34322B)), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)))),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WheelScreen())), icon: const Icon(Icons.card_giftcard, size: 18), label: const Text('عجلة الحظ والهدايا'), style: OutlinedButton.styleFrom(foregroundColor: goldLight, side: BorderSide(color: gold.withValues(alpha: .45)), padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)))),
                    const SizedBox(height: 12),
                    const Text('سجّل حسابك لحفظ بياناتك، ويمكنك تجربة عجلة الحظ للعروض والهدايا.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF89867D), fontSize: 10)),
                  ]),
                ),
              ),
            );
          }),
        ),
      );
}

class AccessScreen extends StatefulWidget {
  const AccessScreen({super.key, this.showLogin = false});
  final bool showLogin;
  @override
  State<AccessScreen> createState() => _AccessScreenState();
}

class _AccessScreenState extends State<AccessScreen> {
  late bool login = widget.showLogin;
  final name = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  bool busy = false;
  final api = SalonApi();
  @override
  void dispose() { name.dispose(); phone.dispose(); email.dispose(); password.dispose(); super.dispose(); }
  Future<void> continueBooking() async {
    final identifier = phone.text.trim();
    if (identifier.isEmpty || password.text.isEmpty) { message(context, login ? 'اكتب رقم الهاتف أو البريد الإلكتروني وكلمة المرور.' : 'اكتب رقم الهاتف وكلمة المرور.'); return; }
    if (!login && (name.text.trim().length < 2 || phone.text.replaceAll(RegExp(r'\D'), '').length < 9 || (email.text.trim().isNotEmpty && !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.text.trim())) || password.text.length < 8)) {
      message(context, 'اكتب الاسم ورقم هاتف صحيح، ولو هتضيف بريد إلكتروني اتأكد إنه صحيح، وكلمة المرور 8 أحرف على الأقل.'); return;
    }
    setState(() => busy = true);
    try {
      final customer = login
          ? await api.login(identifier: identifier, password: password.text)
          : await api.register(name: name.text.trim(), phone: identifier, email: email.text.trim(), password: password.text);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('customer_name', (customer['name'] as String?) ?? name.text.trim());
      await prefs.setString('customer_phone', (customer['phone'] as String?) ?? identifier);
      await prefs.setString('customer_email', (customer['email'] as String?) ?? email.text.trim());
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => BookingScreen(initialName: (customer['name'] as String?) ?? name.text.trim(), initialPhone: (customer['phone'] as String?) ?? identifier)));
    } catch (e) {
      if (mounted) message(context, e.toString().replaceFirst('Exception: ', ''));
    } finally { if (mounted) setState(() => busy = false); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(leading: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_forward_rounded)), title: const Text('حسابك في الصالون', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700))),
        body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 540), child: ListView(padding: const EdgeInsets.fromLTRB(22, 15, 22, 30), children: [
          const Text('أهلاً بيك', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(login ? 'سجّل برقم الهاتف أو البريد الإلكتروني وكلمة المرور.' : 'أنشئ حسابًا لحفظ بياناتك واستخدامها في الحجوزات القادمة.', style: const TextStyle(color: muted, fontSize: 13, height: 1.7)),
          const SizedBox(height: 22),
          Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(13)), child: Row(children: [Expanded(child: ModeButton(title: 'تسجيل الدخول', selected: login, onTap: () => setState(() => login = true))), Expanded(child: ModeButton(title: 'حساب جديد', selected: !login, onTap: () => setState(() => login = false)))])),
          const SizedBox(height: 19),
          if (!login) ...[const FieldLabel('الاسم'), const SizedBox(height: 7), TextField(controller: name, textInputAction: TextInputAction.next, decoration: const InputDecoration(hintText: 'اسمك بالكامل', prefixIcon: Icon(Icons.person_outline, color: gold))), const SizedBox(height: 15)],
          FieldLabel(login ? 'رقم الهاتف أو البريد الإلكتروني' : 'رقم الهاتف'), const SizedBox(height: 7),
          TextField(controller: phone, keyboardType: login ? TextInputType.emailAddress : TextInputType.phone, textDirection: ui.TextDirection.ltr, textAlign: TextAlign.left, decoration: InputDecoration(hintText: login ? 'رقم الهاتف أو email@example.com' : '01xxxxxxxxx', prefixIcon: const Icon(Icons.phone_outlined, color: gold))),
          if (!login) ...[
            const SizedBox(height: 14), const FieldLabel('البريد الإلكتروني (اختياري)'), const SizedBox(height: 7),
            TextField(controller: email, keyboardType: TextInputType.emailAddress, textDirection: ui.TextDirection.ltr, textAlign: TextAlign.left, decoration: const InputDecoration(hintText: 'تقدر تسيبه فاضي', prefixIcon: Icon(Icons.email_outlined, color: gold))),
          ],
          const SizedBox(height: 14), const FieldLabel('كلمة المرور'), const SizedBox(height: 7),
          TextField(controller: password, obscureText: true, textDirection: ui.TextDirection.ltr, decoration: const InputDecoration(hintText: '8 أحرف على الأقل', prefixIcon: Icon(Icons.lock_outline, color: gold))),
          const SizedBox(height: 20),
          GoldButton(label: busy ? 'جارٍ التحقق...' : (login ? 'تسجيل الدخول والمتابعة' : 'إنشاء الحساب وبدء الحجز'), icon: Icons.arrow_back_rounded, onPressed: busy ? null : continueBooking),
        ]))),
      );
}

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key, this.initialName = '', this.initialPhone = ''});
  final String initialName, initialPhone;
  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final api = SalonApi();
  late final name = TextEditingController(text: widget.initialName);
  late final phone = TextEditingController(text: widget.initialPhone);
  final coupon = TextEditingController();
  SalonBootstrap? data;
  String? loadError;
  DateTime date = DateTime.now();
  String time = '04:30 م';
  final Set<String> selected = {};
  DiscountPreview? discount;
  bool busy = false;
  static const times = ['10:00 ص', '12:00 م', '02:00 م', '04:30 م', '06:00 م', '08:30 م', '10:00 م'];
  @override
  void initState() { super.initState(); load(); }
  @override
  void dispose() { name.dispose(); phone.dispose(); coupon.dispose(); super.dispose(); }
  Future<void> load() async {
    try { final result = await api.bootstrap(); if (mounted) setState(() { data = result; loadError = null; }); }
    catch (error) { if (mounted) setState(() => loadError = error.toString()); }
  }
  List<SalonService> get picked => (data?.services ?? []).where((service) => selected.contains(service.id)).toList();
  int get subtotal => picked.fold(0, (sum, service) => sum + service.price);
  int get total => (subtotal - (discount?.amount ?? 0)).clamp(0, 1 << 30).toInt();
  void tell(String value) => message(context, value);
  Future<void> chooseDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final chosen = await showDatePicker(context: context, initialDate: date.isBefore(today) ? today : date, firstDate: today, lastDate: today.add(const Duration(days: 365)), locale: const Locale('ar', 'EG'), builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: Theme.of(context).colorScheme.copyWith(primary: gold, onPrimary: ink, surface: panel, onSurface: Colors.white)), child: child!));
    if (chosen != null) setState(() => date = chosen);
  }
  Future<void> applyDiscount() async {
    if (coupon.text.trim().isEmpty) { tell('اكتب كود الخصم الأول.'); return; }
    if (selected.isEmpty) { tell('اختار خدمة واحدة على الأقل قبل تطبيق الخصم.'); return; }
    setState(() => busy = true);
    try { final result = await api.validateDiscount(coupon.text.trim(), selected.toList()); if (mounted) { setState(() { discount = result; coupon.text = result.code; }); tell('تم تطبيق الخصم — وفرت ${egp(result.amount)}'); } }
    catch (error) { if (mounted) { setState(() => discount = null); tell(error.toString()); } }
    finally { if (mounted) setState(() => busy = false); }
  }
  Future<void> submit() async {
    if (name.text.trim().length < 2) { tell('اكتب الاسم علشان نأكد الحجز.'); return; }
    if (phone.text.replaceAll(RegExp(r'\D'), '').length < 9) { tell('اكتب رقم هاتف صحيح علشان نأكد الحجز.'); return; }
    if (selected.isEmpty) { tell('اختار خدمة واحدة على الأقل.'); return; }
    setState(() => busy = true);
    try {
      final result = await api.createBooking(name: name.text.trim(), phone: phone.text.trim(), date: date, time: time, serviceIds: selected.toList(), discountCode: discount?.code ?? '');
      if (mounted) await Navigator.push(context, MaterialPageRoute(builder: (_) => ConfirmationScreen(receipt: result, shopOpen: data?.shopOpen ?? true)));
    } catch (error) { if (mounted) tell(error.toString()); }
    finally { if (mounted) setState(() => busy = false); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(leading: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_forward_rounded)), title: const Text('إنشاء حجز', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)), actions: const [Padding(padding: EdgeInsetsDirectional.only(end: 15), child: BrandMark(compact: true))]),
        body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 720), child: loadError != null && data == null ? errorPanel() : ListView(padding: const EdgeInsets.fromLTRB(18, 8, 18, 32), children: [
          ShopStatus(open: data?.shopOpen ?? true),
          const SizedBox(height: 12),
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WheelScreen())),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(colors: [gold.withValues(alpha: .18), panel]),
                border: Border.all(color: gold.withValues(alpha: .45)),
              ),
              child: const Row(children: [
                CircleAvatar(backgroundColor: gold, child: Icon(Icons.card_giftcard_rounded, color: ink)),
                SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('عجلة الحظ والهدايا', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                  SizedBox(height: 4),
                  Text('جرّب حظك واكتشف هديتك', style: TextStyle(color: muted, fontSize: 12)),
                ])),
                Icon(Icons.arrow_back_ios_new_rounded, color: gold, size: 16),
              ]),
            ),
          ),
          if (data?.bookingsEnabled == false) ...[const SizedBox(height: 12), const NoticeBox("الحجز متوقف مؤقتًا من إدارة الصالون. لا يمكن إرسال حجز جديد حاليًا.")], const SizedBox(height: 18),
          const Text('تفاصيل الحجز', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800)), const SizedBox(height: 4), const Text('اختار خدمتك والموعد المناسب ليك.', style: TextStyle(color: muted, fontSize: 12)), const SizedBox(height: 19),
          const FieldLabel('الاسم'), const SizedBox(height: 7), TextField(controller: name, textInputAction: TextInputAction.next, decoration: const InputDecoration(hintText: 'اسمك بالكامل', prefixIcon: Icon(Icons.person_outline, color: gold))), const SizedBox(height: 14),
          const FieldLabel('رقم الهاتف'), const SizedBox(height: 7), TextField(controller: phone, keyboardType: TextInputType.phone, textDirection: ui.TextDirection.ltr, textAlign: TextAlign.left, decoration: const InputDecoration(hintText: '+20 1X XXXX XXXX', prefixIcon: Icon(Icons.phone_outlined, color: gold))), const SizedBox(height: 18),
          const FieldLabel('تاريخ الحجز'), const SizedBox(height: 7),
          InkWell(onTap: chooseDate, borderRadius: BorderRadius.circular(13), child: Container(padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15), decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(13), border: Border.all(color: const Color(0xFF2B2A25))), child: Row(children: [const Icon(Icons.calendar_month_outlined, color: gold, size: 19), const SizedBox(width: 11), Expanded(child: Text(DateFormat('EEEE d MMMM y', 'ar_EG').format(date), style: const TextStyle(color: Colors.white, fontSize: 13))), const Icon(Icons.keyboard_arrow_down, color: muted)]))),
          const SizedBox(height: 13), const FieldLabel('الوقت المناسب'), const SizedBox(height: 8), Wrap(spacing: 8, runSpacing: 8, children: times.map((item) => ChoicePill(title: item, selected: time == item, onTap: () => setState(() => time = item))).toList()),
          const SizedBox(height: 19), Row(children: [const Expanded(child: FieldHeading(title: 'الخدمات', subtitle: 'اختار خدمة واحدة أو أكثر')), Text('${selected.length} محدد', style: const TextStyle(color: goldLight, fontSize: 11))]), const SizedBox(height: 9),
          if (data == null) const Padding(padding: EdgeInsets.all(25), child: Center(child: CircularProgressIndicator(color: gold)))
          else if (data!.services.isEmpty) const NoticeBox('مفيش خدمات متاحة حالياً. تواصل مع الصالون أو ارجع لاحقاً.')
          else LayoutBuilder(builder: (context, constraints) { final columns = constraints.maxWidth > 560 ? 3 : 2; final width = (constraints.maxWidth - (columns - 1) * 9) / columns; return Wrap(spacing: 9, runSpacing: 9, children: data!.services.map((service) => SizedBox(width: width, child: ServiceCard(service: service, selected: selected.contains(service.id), onTap: () => setState(() { if (!selected.add(service.id)) selected.remove(service.id); discount = null; })))).toList()); }),
          const SizedBox(height: 20), const FieldHeading(title: 'كود الخصم', subtitle: 'اختياري'), const SizedBox(height: 8),
          Row(children: [Expanded(child: TextField(controller: coupon, textCapitalization: TextCapitalization.characters, textDirection: ui.TextDirection.ltr, textAlign: TextAlign.left, onChanged: (_) => setState(() => discount = null), decoration: const InputDecoration(hintText: 'اكتب الكود هنا', prefixIcon: Icon(Icons.local_offer_outlined, color: gold)))), const SizedBox(width: 8), OutlinedButton(onPressed: busy ? null : applyDiscount, style: OutlinedButton.styleFrom(foregroundColor: goldLight, side: BorderSide(color: gold.withValues(alpha: .55)), padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('تطبيق'))]),
          if (discount != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text('وفرت ${egp(discount!.amount)}', style: const TextStyle(color: green, fontSize: 12))), const SizedBox(height: 15),
          Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(14), border: Border.all(color: gold.withValues(alpha: .22))), child: Row(children: [const Expanded(child: Text('الإجمالي التقديري', style: TextStyle(color: muted, fontSize: 12))), Text(egp(total), style: const TextStyle(color: goldLight, fontWeight: FontWeight.w800, fontSize: 20))])), const SizedBox(height: 13),
          GoldButton(label: busy ? 'جارٍ تأكيد الحجز…' : 'تأكيد الحجز', icon: Icons.arrow_back_rounded, onPressed: (busy || data?.bookingsEnabled == false) ? null : submit), const SizedBox(height: 10), const Text('الأسعار بالجنيه المصري · الحجز متاح في الحالتين', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF858279), fontSize: 10)),
        ]))),
      );
  Widget errorPanel() => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.cloud_off_outlined, color: gold, size: 40), const SizedBox(height: 13), const Text('مش قادرين نتصل بالخادم', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)), const SizedBox(height: 7), Text(loadError ?? '', textAlign: TextAlign.center, style: const TextStyle(color: muted, fontSize: 12)), const SizedBox(height: 14), OutlinedButton(onPressed: load, child: const Text('إعادة المحاولة'))])));
}

class WheelScreen extends StatefulWidget {
  const WheelScreen({super.key});
  @override
  State<WheelScreen> createState() => _WheelScreenState();
}

class _WheelScreenState extends State<WheelScreen> {
  final api = SalonApi();
  bool loading = true, spinning = false;
  List<Map<String, dynamic>> prizes = [];
  String? result;
  @override
  void initState() { super.initState(); loadPrizes(); }
  Future<void> loadPrizes() async {
    try { final data = await api.bootstrap(); if (mounted) setState(() { prizes = data.wheelPrizes; loading = false; }); }
    catch (_) { if (mounted) setState(() { loading = false; }); }
  }
  Future<void> spin() async {
    if (spinning || prizes.isEmpty) return;
    setState(() { spinning = true; result = null; });
    await Future.delayed(const Duration(milliseconds: 500));
    try {
      final response = await api.spinWheel();
      if (!mounted) return;
      final prize = response['prize'] as Map<String, dynamic>? ?? {};
      setState(() { result = prize['label'] as String? ?? 'جائزة'; spinning = false; });
      message(context, 'مبروك! نتيجتك: $result');
    } catch (e) {
      if (mounted) { setState(() => spinning = false); message(context, e.toString().replaceFirst('Exception: ', '')); }
    }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('عجلة الحظ والهدايا'), leading: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_forward))),
    body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520), child: ListView(padding: const EdgeInsets.all(22), children: [
      Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(22), border: Border.all(color: gold.withValues(alpha: .25))), child: Column(children: [
        const Icon(Icons.card_giftcard, size: 66, color: gold), const SizedBox(height: 16),
        const Text('لف العجلة واكسب هدية', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900)), const SizedBox(height: 8),
        const Text('قد تكون جائزتك كوبون خصم أو خدمة من الصالون.', textAlign: TextAlign.center, style: TextStyle(color: muted, height: 1.7)),
        const SizedBox(height: 22),
        if (loading) const Center(child: CircularProgressIndicator())
        else if (prizes.isEmpty) const Text('لا توجد جوائز متاحة حاليًا. تابعنا قريبًا!', style: TextStyle(color: muted))
        else ...[
          Container(width: 190, height: 190, decoration: BoxDecoration(shape: BoxShape.circle, color: ink, border: Border.all(color: gold, width: 5), boxShadow: [BoxShadow(color: gold.withValues(alpha: .12), blurRadius: 25)]), child: Center(child: Padding(padding: const EdgeInsets.all(18), child: Text(spinning ? 'تدور العجلة...' : (result ?? 'حظ سعيد!'), textAlign: TextAlign.center, style: const TextStyle(color: goldLight, fontSize: 19, fontWeight: FontWeight.w900))))),
          const SizedBox(height: 20),
          GoldButton(label: spinning ? 'جاري الدوران...' : 'لف العجلة', icon: Icons.casino_outlined, onPressed: spinning ? null : spin),
          const SizedBox(height: 18),
          ...prizes.map((p) => ListTile(leading: const Icon(Icons.redeem, color: gold), title: Text(p['label'] as String? ?? 'جائزة'), subtitle: Text((p['kind'] == 'service') ? 'خدمة مجانية' : 'كوبون خصم', style: const TextStyle(color: muted))))
        ]
      ]))
    ])))
  );
}

class ConfirmationScreen extends StatelessWidget {
  const ConfirmationScreen({super.key, required this.receipt, required this.shopOpen});
  final BookingReceipt receipt;
  final bool shopOpen;
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(automaticallyImplyLeading: false, title: const BrandMark(compact: true), actions: [IconButton(onPressed: () => Navigator.popUntil(context, (route) => route.isFirst), icon: const Icon(Icons.close_rounded))]),
        body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 560), child: ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 28), children: [
          Container(padding: const EdgeInsets.all(21), decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(22), border: Border.all(color: gold.withValues(alpha: .24))), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Center(child: Container(width: 62, height: 62, decoration: BoxDecoration(shape: BoxShape.circle, color: green.withValues(alpha: .12)), child: const Icon(Icons.check_rounded, color: green, size: 35))), const SizedBox(height: 15), const Text('تم تسجيل حجزك', textAlign: TextAlign.center, style: TextStyle(color: goldLight, fontSize: 12, fontWeight: FontWeight.w700)), const SizedBox(height: 7), const Text('مستنيينك في معادك', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)), const SizedBox(height: 6), const Text('احتفظ برقم الحجز علشان تراجعه عند الوصول.', textAlign: TextAlign.center, style: TextStyle(color: muted, fontSize: 12)), const SizedBox(height: 18),
            Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: ink, borderRadius: BorderRadius.circular(15), border: Border.all(color: gold.withValues(alpha: .16))), child: Column(children: [const Text('رقم الحجز', style: TextStyle(color: muted, fontSize: 11)), const SizedBox(height: 3), Text(receipt.code, style: const TextStyle(color: goldLight, fontSize: 29, fontWeight: FontWeight.w900, letterSpacing: 2)), const Text('مصر · الجنيه المصري', style: TextStyle(color: muted, fontSize: 10))])), const SizedBox(height: 11),
            Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFF19170F), borderRadius: BorderRadius.circular(14)), child: Row(children: [const Icon(Icons.groups_outlined, color: gold, size: 22), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('ترتيب الانتظار', style: TextStyle(color: muted, fontSize: 10)), const SizedBox(height: 3), Text(receipt.queueAhead == 0 ? 'أنت أول شخص في الانتظار' : 'أمامك ${NumberFormat.decimalPattern('ar_EG').format(receipt.queueAhead)} أشخاص', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12))]))])), const SizedBox(height: 17),
            const Text('تفاصيل الحجز', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)), const SizedBox(height: 8),
            ReceiptLine('الاسم', receipt.name), ReceiptLine('رقم الهاتف', receipt.phone), ReceiptLine('الخدمات', receipt.services.map((item) => item.name).join('، ')), ReceiptLine('التاريخ', DateFormat('EEEE d MMMM y', 'ar_EG').format(receipt.date)), ReceiptLine('الوقت', receipt.time), if (receipt.discountCode.isNotEmpty) ReceiptLine('الخصم', '${receipt.discountCode} · −${egp(receipt.discountAmount)}'),
            const Divider(height: 18), Row(children: [const Expanded(child: Text('الإجمالي', style: TextStyle(color: muted, fontSize: 12))), Text(egp(receipt.total), style: const TextStyle(color: goldLight, fontWeight: FontWeight.w800, fontSize: 17))]), const SizedBox(height: 13),
            Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), decoration: BoxDecoration(color: (shopOpen ? green : gold).withValues(alpha: .09), borderRadius: BorderRadius.circular(11)), child: Text(shopOpen ? 'المحل مفتوح — تم تأكيد الحجز' : 'المحل مغلق الآن — حجزك اتسجل والحالة ظاهرة للصالون', style: TextStyle(color: shopOpen ? green : goldLight, fontSize: 11), textAlign: TextAlign.center)), const SizedBox(height: 16),
            GoldButton(label: 'العودة للرئيسية', icon: Icons.home_outlined, onPressed: () => Navigator.popUntil(context, (route) => route.isFirst)),
          ])),
        ]))),
      );
}

void message(BuildContext context, String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.compact = false});
  final bool compact;
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [ClipRRect(borderRadius: BorderRadius.circular(compact ? 9 : 12), child: Image.asset('assets/barber_app_icon.png', width: compact ? 35 : 45, height: compact ? 35 : 45, fit: BoxFit.cover)), if (!compact) ...[const SizedBox(width: 10), const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('صالون الحلاقة', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)), Text('احجزها بسهولة', style: TextStyle(color: goldLight, fontSize: 9))])]]);
}

class FeaturePill extends StatelessWidget {
  const FeaturePill({super.key, required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(30), border: Border.all(color: const Color(0xFF2B2A25))), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: gold, size: 13), const SizedBox(width: 5), Text(label, style: const TextStyle(color: muted, fontSize: 9))]));
}

class GoldButton extends StatelessWidget {
  const GoldButton({super.key, required this.label, required this.icon, required this.onPressed});
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => SizedBox(height: 51, child: FilledButton.icon(onPressed: onPressed, icon: Icon(icon, size: 18), label: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)), style: FilledButton.styleFrom(backgroundColor: gold, foregroundColor: ink, disabledBackgroundColor: gold.withValues(alpha: .35), disabledForegroundColor: ink.withValues(alpha: .7), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)))));
}

class ModeButton extends StatelessWidget {
  const ModeButton({super.key, required this.title, required this.selected, required this.onTap});
  final String title;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(10), child: AnimatedContainer(duration: const Duration(milliseconds: 160), padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: selected ? gold : Colors.transparent, borderRadius: BorderRadius.circular(10)), child: Text(title, textAlign: TextAlign.center, style: TextStyle(color: selected ? ink : muted, fontSize: 11, fontWeight: FontWeight.w700))));
}

class ShopStatus extends StatelessWidget {
  const ShopStatus({super.key, required this.open});
  final bool open;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11), decoration: BoxDecoration(color: (open ? green : gold).withValues(alpha: .08), borderRadius: BorderRadius.circular(13), border: Border.all(color: (open ? green : gold).withValues(alpha: .24))), child: Row(children: [Icon(open ? Icons.storefront_outlined : Icons.store_mall_directory_outlined, color: open ? green : goldLight, size: 19), const SizedBox(width: 9), Text(open ? 'المحل مفتوح' : 'المحل مغلق', style: TextStyle(color: open ? green : goldLight, fontWeight: FontWeight.w700, fontSize: 12)), const Spacer(), const Text('الحجز متاح في الحالتين', style: TextStyle(color: muted, fontSize: 10))]));
}

class FieldLabel extends StatelessWidget {
  const FieldLabel(this.title, {super.key});
  final String title;
  @override
  Widget build(BuildContext context) => Text(title, style: const TextStyle(color: muted, fontSize: 12));
}

class FieldHeading extends StatelessWidget {
  const FieldHeading({super.key, required this.title, required this.subtitle});
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text(subtitle, style: const TextStyle(color: muted, fontSize: 10))]);
}

class ChoicePill extends StatelessWidget {
  const ChoicePill({super.key, required this.title, required this.selected, required this.onTap});
  final String title;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(10), child: AnimatedContainer(duration: const Duration(milliseconds: 150), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), decoration: BoxDecoration(color: selected ? const Color(0xFF342B18) : panel, borderRadius: BorderRadius.circular(10), border: Border.all(color: selected ? gold : const Color(0xFF2C2A24))), child: Text(title, style: TextStyle(color: selected ? goldLight : muted, fontSize: 10, fontWeight: selected ? FontWeight.w700 : FontWeight.w500))));
}

class ServiceCard extends StatelessWidget {
  const ServiceCard({super.key, required this.service, required this.selected, required this.onTap});
  final SalonService service;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(14), child: AnimatedContainer(duration: const Duration(milliseconds: 170), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: selected ? const Color(0xFF282214) : panel, borderRadius: BorderRadius.circular(14), border: Border.all(color: selected ? gold : const Color(0xFF2C2A24))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Container(width: 32, height: 32, decoration: BoxDecoration(color: gold.withValues(alpha: .1), borderRadius: BorderRadius.circular(9)), child: Icon(serviceIcon(service.icon), color: gold, size: 17)), const Spacer(), Icon(selected ? Icons.check_circle : Icons.radio_button_unchecked, color: selected ? gold : const Color(0xFF615E56), size: 17)]), const SizedBox(height: 9), Text(service.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)), const SizedBox(height: 4), Text('${service.duration} دقيقة', style: const TextStyle(color: muted, fontSize: 9)), const SizedBox(height: 7), Text(egp(service.price), style: const TextStyle(color: goldLight, fontSize: 12, fontWeight: FontWeight.w800))])));
}

class ReceiptLine extends StatelessWidget {
  const ReceiptLine(this.title, this.value, {super.key});
  final String title, value;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 78, child: Text(title, style: const TextStyle(color: muted, fontSize: 11))), Expanded(child: Text(value, textAlign: TextAlign.left, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)))]));
}

class NoticeBox extends StatelessWidget {
  const NoticeBox(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(12)), child: Text(text, style: const TextStyle(color: muted, fontSize: 11, height: 1.7)));
}

IconData serviceIcon(String type) => switch (type) {
      'beard' => Icons.face_retouching_natural_outlined,
      'care' => Icons.spa_outlined,
      _ => Icons.content_cut_rounded,
    };

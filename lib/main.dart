import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'salon_api.dart';

const ink = Color(0xFF090908);
const panel = Color(0xFF151512);
const gold = Color(0xFFD7B05F);
const goldLight = Color(0xFFE9CA83);
const muted = Color(0xFFA5A197);
const green = Color(0xFF66C49A);
const red = Color(0xFFE07A6B);
final money = NumberFormat.currency(locale: 'ar_EG', symbol: 'ج.م.', decimalDigits: 0);
String egp(num amount) => money.format(amount);

/// تخزين محلي آمن: يحاول SharedPreferences أولًا، ولو فشلت الإضافة على الجهاز
/// يستخدم ملفًا محليًا ثم الذاكرة، بحيث لا يتعطل التسجيل أبدًا.
class Store {
  static final Map<String, String> _mem = {};
  static bool _fileLoaded = false;

  static File? _file() {
    try { return File('${Directory.systemTemp.path}/zizo_store.json'); } catch (_) { return null; }
  }

  static void _loadFile() {
    if (_fileLoaded) return;
    _fileLoaded = true;
    try {
      final file = _file();
      if (file != null && file.existsSync()) {
        final decoded = jsonDecode(file.readAsStringSync());
        if (decoded is Map) decoded.forEach((k, v) { _mem.putIfAbsent(k.toString(), () => v.toString()); });
      }
    } catch (_) {}
  }

  static void _writeFile() {
    try { _file()?.writeAsStringSync(jsonEncode(_mem)); } catch (_) {}
  }

  static Future<String?> get(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getString(key);
      if (value != null) return value;
    } catch (_) {}
    _loadFile();
    return _mem[key];
  }

  static Future<void> set(String key, String value) async {
    _loadFile();
    _mem[key] = value;
    _writeFile();
    try { final prefs = await SharedPreferences.getInstance(); await prefs.setString(key, value); } catch (_) {}
  }

  static Future<void> remove(String key) async {
    _loadFile();
    _mem.remove(key);
    _writeFile();
    try { final prefs = await SharedPreferences.getInstance(); await prefs.remove(key); } catch (_) {}
  }
}

/// حالة الحساب المحفوظة على الجهاز.
class Session {
  static Customer? customer;
  static final ValueNotifier<String?> photo = ValueNotifier<String?>(null);
  static final ValueNotifier<int> bookingsTick = ValueNotifier<int>(0);

  static Future<void> load() async {
    final phone = await Store.get('customer_phone') ?? '';
    if (phone.isEmpty) { customer = null; return; }
    var first = await Store.get('customer_first') ?? '';
    var last = await Store.get('customer_last') ?? '';
    if (first.isEmpty) {
      final parts = (await Store.get('customer_name') ?? '').trim().split(RegExp(r'\s+'));
      first = parts.first;
      last = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    }
    customer = Customer(firstName: first, lastName: last, phone: phone, email: await Store.get('customer_email') ?? '');
    photo.value = await Store.get('customer_photo');
  }

  static Future<void> save(Customer value) async {
    customer = value;
    await Store.set('customer_first', value.firstName);
    await Store.set('customer_last', value.lastName);
    await Store.set('customer_name', value.fullName);
    await Store.set('customer_phone', value.phone);
    await Store.set('customer_email', value.email);
  }

  static Future<void> savePhoto(String? base64Photo) async {
    photo.value = base64Photo;
    if (base64Photo == null) { await Store.remove('customer_photo'); } else { await Store.set('customer_photo', base64Photo); }
  }

  static Future<void> clear() async {
    customer = null;
    photo.value = null;
    for (final key in ['customer_first', 'customer_last', 'customer_name', 'customer_phone', 'customer_email', 'customer_photo']) { await Store.remove(key); }
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try { await initializeDateFormatting('ar_EG'); } catch (_) {}
  try { await Session.load().timeout(const Duration(seconds: 5)); } catch (_) { Session.customer = null; }
  runApp(const BarberBookingApp());
}

class BarberBookingApp extends StatelessWidget {
  const BarberBookingApp({super.key});
  @override
  Widget build(BuildContext context) {
    final defaults = ThemeData.dark(useMaterial3: true);
    return MaterialApp(
      title: 'ZIZO',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar', 'EG'),
      supportedLocales: const [Locale('ar', 'EG'), Locale('en', 'US')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: defaults.copyWith(
        scaffoldBackgroundColor: ink,
        colorScheme: defaults.colorScheme.copyWith(primary: gold, secondary: goldLight, surface: panel),
        appBarTheme: const AppBarTheme(backgroundColor: ink, foregroundColor: Colors.white, centerTitle: false, elevation: 0),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: panel,
          indicatorColor: gold.withValues(alpha: .18),
          labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: states.contains(WidgetState.selected) ? goldLight : muted)),
          iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(color: states.contains(WidgetState.selected) ? gold : muted)),
        ),
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
      home: Session.customer == null ? const WelcomeScreen() : const MainShell(),
    );
  }
}

// ───────────────────────── روابط خارجية ─────────────────────────

String normalizeUrl(String key, String raw) {
  final value = raw.trim();
  if (key == 'whatsapp' && !value.startsWith('http')) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.isNotEmpty) return 'https://wa.me/$digits';
  }
  if (value.startsWith('http://') || value.startsWith('https://')) return value;
  return 'https://$value';
}

Future<void> openLink(BuildContext context, String key, String raw) async {
  try {
    final uri = Uri.parse(normalizeUrl(key, raw));
    var ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) ok = await launchUrl(uri, mode: LaunchMode.platformDefault);
    if (!ok && context.mounted) message(context, 'تعذر فتح الرابط.');
  } catch (_) {
    if (context.mounted) message(context, 'تعذر فتح الرابط.');
  }
}

IconData socialIcon(String key) => switch (key) {
      'facebook' => Icons.facebook,
      'instagram' => Icons.camera_alt_outlined,
      'tiktok' => Icons.music_note_rounded,
      'whatsapp' => Icons.chat_rounded,
      'youtube' => Icons.smart_display_rounded,
      'telegram' => Icons.send_rounded,
      'x' => Icons.alternate_email_rounded,
      'snapchat' => Icons.chat_bubble_outline_rounded,
      _ => Icons.language_rounded,
    };

// ───────────────────────── الصفحة الرئيسية (قبل التسجيل) ─────────────────────────

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final api = SalonApi();
  List<SocialItem> social = [];
  String designerUrl = '';
  @override
  void initState() { super.initState(); loadCached(); loadLinks(); }
  Future<void> loadCached() async {
    try {
      final raw = await Store.get('welcome_links');
      if (raw == null) return;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final items = (json['social'] as List<dynamic>? ?? const []).whereType<Map<String, dynamic>>().map((e) => SocialItem(platform: (e['platform'] as String?) ?? 'website', label: (e['label'] as String?) ?? '', url: (e['url'] as String?) ?? '')).where((e) => e.url.isNotEmpty).toList();
      if (mounted && social.isEmpty) setState(() { social = items; designerUrl = (json['designerUrl'] as String?) ?? designerUrl; });
    } catch (_) {}
  }
  Timer? retryTimer;
  @override
  void dispose() { retryTimer?.cancel(); super.dispose(); }
  Future<void> loadLinks([int attempt = 0]) async {
    try {
      final data = await api.bootstrap();
      if (mounted) setState(() { social = data.social; designerUrl = data.designerUrl; });
      await Store.set('welcome_links', jsonEncode({'designerUrl': data.designerUrl, 'social': [for (final i in data.social) {'platform': i.platform, 'label': i.label, 'url': i.url}]}));
    } catch (_) {
      if (mounted && attempt < 2) retryTimer = Timer(const Duration(seconds: 3), () => loadLinks(attempt + 1));
    }
  }
  @override
  Widget build(BuildContext context) {
    final links = social;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(23, 18, 23, 14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const SizedBox(height: 6),
                  Expanded(child: Center(child: SingleChildScrollView(child: Column(children: [
                    ZizoLogo(height: constraints.maxWidth > 560 ? 190 : 150),
                    const SizedBox(height: 20),
                    const Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [FeaturePill(icon: Icons.location_on_outlined, label: 'مصر'), FeaturePill(icon: Icons.payments_outlined, label: 'الجنيه المصري'), FeaturePill(icon: Icons.timer_outlined, label: 'حجز سريع')]),
                  ])))),
                  GoldButton(label: 'ابدأ الحجز', icon: Icons.arrow_back_rounded, onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccessScreen()))),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccessScreen(showLogin: true))), icon: const Icon(Icons.person_outline_rounded, size: 18), label: const Text('تسجيل الدخول'), style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Color(0xFF34322B)), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)))),
                  if (links.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(alignment: WrapAlignment.center, spacing: 12, runSpacing: 10, children: [
                      for (final link in links)
                        Tooltip(
                          message: link.label,
                          child: InkWell(
                            onTap: () => openLink(context, link.platform, link.url),
                            customBorder: const CircleBorder(),
                            child: Container(width: 42, height: 42, decoration: BoxDecoration(shape: BoxShape.circle, color: panel, border: Border.all(color: gold.withValues(alpha: .35))), child: Center(child: Icon(socialIcon(link.platform), color: goldLight, size: 20))),
                          ),
                        ),
                    ]),
                  ],
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: designerUrl.isEmpty ? null : () => openLink(context, 'designer', designerUrl),
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(padding: EdgeInsets.symmetric(vertical: 6, horizontal: 10), child: Text('تصميم وتنفيذ mohamed ragab', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF89867D), fontSize: 11))),
                  ),
                ]),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ───────────────────────── التسجيل / الدخول ─────────────────────────

class AccessScreen extends StatefulWidget {
  const AccessScreen({super.key, this.showLogin = false});
  final bool showLogin;
  @override
  State<AccessScreen> createState() => _AccessScreenState();
}

class _AccessScreenState extends State<AccessScreen> {
  late bool login = widget.showLogin;
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final identifier = TextEditingController();
  final password = TextEditingController();
  bool busy = false;
  final api = SalonApi();
  @override
  void dispose() { firstName.dispose(); lastName.dispose(); phone.dispose(); email.dispose(); identifier.dispose(); password.dispose(); super.dispose(); }
  Future<void> continueBooking() async {
    if (login) {
      if (identifier.text.trim().length < 3) { message(context, 'اكتب رقم الهاتف أو البريد الإلكتروني.'); return; }
      if (password.text.isEmpty) { message(context, 'اكتب كلمة المرور.'); return; }
    } else {
      if (firstName.text.trim().length < 2 || lastName.text.trim().length < 2) { message(context, 'اكتب الاسم الأول والاسم الثاني.'); return; }
      if (phone.text.replaceAll(RegExp(r'\D'), '').length < 9) { message(context, 'اكتب رقم هاتف صحيح.'); return; }
      if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.text.trim())) { message(context, 'اكتب بريدًا إلكترونيًا صحيحًا.'); return; }
      if (password.text.length < 8) { message(context, 'كلمة المرور 8 أحرف على الأقل.'); return; }
    }
    setState(() => busy = true);
    try {
      final customer = login
          ? await api.login(identifier: identifier.text.trim(), password: password.text)
          : await api.register(firstName: firstName.text.trim(), lastName: lastName.text.trim(), phone: phone.text.trim(), email: email.text.trim(), password: password.text);
      await Session.save(customer);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const MainShell()), (route) => false);
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
          Text(login ? 'سجّل الدخول برقم الهاتف أو البريد الإلكتروني وكلمة المرور.' : 'أنشئ حسابًا لحفظ بياناتك واستخدامها في الحجوزات القادمة.', style: const TextStyle(color: muted, fontSize: 13, height: 1.7)),
          const SizedBox(height: 22),
          Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(13)), child: Row(children: [Expanded(child: ModeButton(title: 'تسجيل الدخول', selected: login, onTap: () => setState(() => login = true))), Expanded(child: ModeButton(title: 'حساب جديد', selected: !login, onTap: () => setState(() => login = false)))])),
          const SizedBox(height: 19),
          if (login) ...[
            const FieldLabel('رقم الهاتف أو البريد الإلكتروني'), const SizedBox(height: 7),
            TextField(controller: identifier, keyboardType: TextInputType.emailAddress, textDirection: ui.TextDirection.ltr, textAlign: TextAlign.left, decoration: const InputDecoration(hintText: '01xxxxxxxxx أو email@example.com', prefixIcon: Icon(Icons.person_outline, color: gold))),
          ] else ...[
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const FieldLabel('الاسم الأول'), const SizedBox(height: 7), TextField(controller: firstName, textInputAction: TextInputAction.next, decoration: const InputDecoration(hintText: 'الاسم الأول', prefixIcon: Icon(Icons.person_outline, color: gold)))])),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const FieldLabel('الاسم الثاني'), const SizedBox(height: 7), TextField(controller: lastName, textInputAction: TextInputAction.next, decoration: const InputDecoration(hintText: 'الاسم الثاني'))])),
            ]),
            const SizedBox(height: 14),
            const FieldLabel('رقم الهاتف'), const SizedBox(height: 7),
            TextField(controller: phone, keyboardType: TextInputType.phone, textDirection: ui.TextDirection.ltr, textAlign: TextAlign.left, textInputAction: TextInputAction.next, decoration: const InputDecoration(hintText: '01xxxxxxxxx', prefixIcon: Icon(Icons.phone_outlined, color: gold))),
            const SizedBox(height: 14),
            const FieldLabel('البريد الإلكتروني'), const SizedBox(height: 7),
            TextField(controller: email, keyboardType: TextInputType.emailAddress, textDirection: ui.TextDirection.ltr, textAlign: TextAlign.left, decoration: const InputDecoration(hintText: 'email@example.com', prefixIcon: Icon(Icons.email_outlined, color: gold))),
          ],
          const SizedBox(height: 14),
          const FieldLabel('كلمة المرور'), const SizedBox(height: 7),
          TextField(controller: password, obscureText: true, textDirection: ui.TextDirection.ltr, decoration: InputDecoration(hintText: login ? 'كلمة المرور' : '8 أحرف على الأقل', prefixIcon: const Icon(Icons.lock_outline, color: gold))),
          const SizedBox(height: 22),
          GoldButton(label: busy ? 'جارٍ التحقق...' : (login ? 'تسجيل الدخول' : 'إنشاء الحساب'), icon: Icons.arrow_back_rounded, onPressed: busy ? null : continueBooking),
        ]))),
      );
}

// ───────────────────────── الهيكل الرئيسي: 3 صفحات بالأسفل ─────────────────────────

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;
  void go(int i) { setState(() => index = i); if (i == 1) Session.bookingsTick.value++; }
  @override
  Widget build(BuildContext context) => Scaffold(
        body: IndexedStack(index: index, children: [BookingTab(onBooked: () => go(1)), const BookingsTab(), const ProfileTab()]),
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: go,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.content_cut_rounded), label: 'الحجز'),
            NavigationDestination(icon: Icon(Icons.event_note_rounded), label: 'الحجوزات'),
            NavigationDestination(icon: Icon(Icons.person_rounded), label: 'حسابي'),
          ],
        ),
      );
}

// ───────────────────────── الصفحة 1: الحجز ─────────────────────────

class BookingTab extends StatefulWidget {
  const BookingTab({super.key, required this.onBooked});
  final VoidCallback onBooked;
  @override
  State<BookingTab> createState() => _BookingTabState();
}

class _BookingTabState extends State<BookingTab> {
  final api = SalonApi();
  final coupon = TextEditingController();
  SalonBootstrap? data;
  String? loadError;
  DateTime date = DateTime.now();
  String time = '04:30 م';
  final Set<String> selected = {};
  DiscountPreview? discount;
  bool busy = false;
  int unread = 0;
  static const times = ['10:00 ص', '12:00 م', '02:00 م', '04:30 م', '06:00 م', '08:30 م', '10:00 م'];
  @override
  void initState() { super.initState(); load(); }
  @override
  void dispose() { coupon.dispose(); super.dispose(); }
  Future<void> load() async {
    try {
      final result = await api.bootstrap();
      final seen = await Store.get('notif_seen') ?? '';
      if (mounted) setState(() { data = result; loadError = null; unread = result.announcements.where((a) => a.createdAt.compareTo(seen) > 0).length; });
    } catch (error) { if (mounted) setState(() => loadError = error.toString()); }
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
    final customer = Session.customer;
    if (customer == null) return;
    if (selected.isEmpty) { tell('اختار خدمة واحدة على الأقل.'); return; }
    setState(() => busy = true);
    try {
      final result = await api.createBooking(name: customer.fullName, phone: customer.phone, date: date, time: time, serviceIds: selected.toList(), discountCode: discount?.code ?? '');
      Session.bookingsTick.value++;
      if (!mounted) return;
      setState(() { selected.clear(); discount = null; coupon.clear(); });
      await Navigator.push(context, MaterialPageRoute(builder: (_) => ConfirmationScreen(receipt: result, shopOpen: data?.shopOpen ?? true)));
      if (mounted) widget.onBooked();
    } catch (error) { if (mounted) tell(error.toString()); }
    finally { if (mounted) setState(() => busy = false); }
  }
  Future<void> openWheel() async {
    final d = data;
    if (d == null) { tell('جارٍ التحميل، حاول بعد لحظات.'); return; }
    if (!d.wheelEnabled) { tell('عجلة الحظ مقفولة حاليًا. تابعنا قريبًا!'); return; }
    await Navigator.push(context, MaterialPageRoute(builder: (_) => WheelScreen(prizes: d.wheelPrizes)));
  }
  Future<void> openNotifications() async {
    final d = data;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => NotificationsScreen(items: d?.announcements ?? const [])));
    if (mounted) setState(() => unread = 0);
  }
  @override
  Widget build(BuildContext context) {
    final customer = Session.customer;
    return SafeArea(
      child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 720), child: loadError != null && data == null ? errorPanel() : RefreshIndicator(
        color: gold,
        onRefresh: load,
        child: ListView(padding: const EdgeInsets.fromLTRB(18, 14, 18, 24), children: [
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('أهلاً ${customer?.firstName ?? ''} 👋', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              const Text('احجز موعدك في دقيقة', style: TextStyle(color: muted, fontSize: 12)),
            ])),
            const BrandMark(compact: true),
          ]),
          const SizedBox(height: 14),
          ShopStatus(open: data?.shopOpen ?? true),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: HomeCard(icon: (data?.wheelEnabled ?? true) ? Icons.card_giftcard_rounded : Icons.lock_outline_rounded, title: 'عجلة الحظ', subtitle: (data?.wheelEnabled ?? true) ? 'لف واكسب هدية' : 'مقفولة حاليًا', dim: data != null && !data!.wheelEnabled, onTap: openWheel)),
            const SizedBox(width: 10),
            Expanded(child: HomeCard(icon: Icons.notifications_none_rounded, title: 'الإشعارات', subtitle: unread > 0 ? '$unread جديد' : 'لا جديد', badge: unread, onTap: openNotifications)),
          ]),
          if (data?.bookingsEnabled == false) ...[const SizedBox(height: 12), const NoticeBox('الحجز متوقف مؤقتًا من إدارة الصالون. لا يمكن إرسال حجز جديد حاليًا.')],
          const SizedBox(height: 20),
          const Text('تفاصيل الحجز', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)), const SizedBox(height: 4), const Text('اختار خدمتك والموعد المناسب ليك.', style: TextStyle(color: muted, fontSize: 12)), const SizedBox(height: 16),
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
        ]),
      ))),
    );
  }
  Widget errorPanel() => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.cloud_off_outlined, color: gold, size: 40), const SizedBox(height: 13), const Text('مش قادرين نتصل بالخادم', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)), const SizedBox(height: 7), Text(loadError ?? '', textAlign: TextAlign.center, style: const TextStyle(color: muted, fontSize: 12)), const SizedBox(height: 14), OutlinedButton(onPressed: load, child: const Text('إعادة المحاولة'))])));
}

class HomeCard extends StatelessWidget {
  const HomeCard({super.key, required this.icon, required this.title, required this.subtitle, required this.onTap, this.badge = 0, this.dim = false});
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  final int badge;
  final bool dim;
  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Opacity(
          opacity: dim ? .55 : 1,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), gradient: LinearGradient(colors: [gold.withValues(alpha: .16), panel]), border: Border.all(color: gold.withValues(alpha: .4))),
            child: Row(children: [
              Stack(clipBehavior: Clip.none, children: [
                CircleAvatar(radius: 19, backgroundColor: gold, child: Icon(icon, color: ink, size: 20)),
                if (badge > 0) PositionedDirectional(top: -4, end: -4, child: Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1), decoration: BoxDecoration(color: red, borderRadius: BorderRadius.circular(10)), child: Text('$badge', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)))),
              ]),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                const SizedBox(height: 3),
                Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: muted, fontSize: 10)),
              ])),
            ]),
          ),
        ),
      );
}

// ───────────────────────── عجلة الحظ ─────────────────────────

class WheelScreen extends StatefulWidget {
  const WheelScreen({super.key, required this.prizes});
  final List<Map<String, dynamic>> prizes;
  @override
  State<WheelScreen> createState() => _WheelScreenState();
}

class _WheelScreenState extends State<WheelScreen> with SingleTickerProviderStateMixin {
  final api = SalonApi();
  late final AnimationController controller = AnimationController(vsync: this, duration: const Duration(seconds: 5));
  double rotation = 0;
  bool spinning = false;
  String? result;
  @override
  void dispose() { controller.dispose(); super.dispose(); }
  Future<void> spin() async {
    if (spinning || widget.prizes.isEmpty) return;
    setState(() { spinning = true; result = null; });
    try {
      final response = await api.spinWheel();
      final prize = response['prize'] as Map<String, dynamic>? ?? {};
      var index = widget.prizes.indexWhere((p) => p['id'] == prize['id']);
      if (index < 0) index = 0;
      final sweep = 2 * math.pi / widget.prizes.length;
      final center = (index + .5) * sweep;
      final start = rotation;
      var delta = (-center - start) % (2 * math.pi);
      if (delta < 0) delta += 2 * math.pi;
      final end = start + 6 * 2 * math.pi + delta;
      final animation = Tween<double>(begin: start, end: end).animate(CurvedAnimation(parent: controller, curve: Curves.easeOutCubic));
      void listener() => setState(() => rotation = animation.value);
      controller.reset();
      controller.addListener(listener);
      await controller.forward();
      controller.removeListener(listener);
      rotation = end % (2 * math.pi);
      if (!mounted) return;
      setState(() { result = prize['label'] as String? ?? 'جائزة'; spinning = false; });
      await showDialog<void>(context: context, builder: (_) => AlertDialog(
        backgroundColor: panel,
        title: const Text('🎉 مبروك!', textAlign: TextAlign.center),
        content: Text('جائزتك: $result', textAlign: TextAlign.center, style: const TextStyle(color: goldLight, fontSize: 18, fontWeight: FontWeight.w800)),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('تمام'))],
      ));
    } catch (e) {
      if (mounted) { setState(() => spinning = false); message(context, e.toString().replaceFirst('Exception: ', '')); }
    }
  }
  @override
  Widget build(BuildContext context) {
    final prizes = widget.prizes;
    return Scaffold(
      appBar: AppBar(title: const Text('عجلة الحظ'), leading: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_forward))),
      body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520), child: ListView(padding: const EdgeInsets.all(22), children: [
        const Text('لف العجلة واكسب هدية', textAlign: TextAlign.center, style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        const Text('قد تكون جائزتك كوبون خصم أو خدمة من الصالون.', textAlign: TextAlign.center, style: TextStyle(color: muted, height: 1.7)),
        const SizedBox(height: 24),
        if (prizes.isEmpty) const NoticeBox('لا توجد جوائز متاحة حاليًا. تابعنا قريبًا!')
        else ...[
          Center(child: SizedBox(width: 300, height: 316, child: Stack(alignment: Alignment.topCenter, children: [
            Positioned(top: 16, child: SizedBox(width: 284, height: 284, child: Transform.rotate(angle: rotation, child: CustomPaint(painter: WheelPainter([for (final p in prizes) (p['label'] as String?) ?? 'جائزة'])))),),
            const Positioned(top: 0, child: Icon(Icons.arrow_drop_down_rounded, color: goldLight, size: 46)),
            Positioned(top: 16 + 142 - 24, child: Container(width: 48, height: 48, decoration: BoxDecoration(shape: BoxShape.circle, color: ink, border: Border.all(color: gold, width: 3)), child: const Icon(Icons.star_rounded, color: gold, size: 22))),
          ]))),
          const SizedBox(height: 16),
          if (result != null) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text('آخر نتيجة: $result', textAlign: TextAlign.center, style: const TextStyle(color: goldLight, fontWeight: FontWeight.w800, fontSize: 15))),
          GoldButton(label: spinning ? 'جاري الدوران...' : 'لف العجلة', icon: Icons.casino_outlined, onPressed: spinning ? null : spin),
        ],
      ]))),
    );
  }
}

class WheelPainter extends CustomPainter {
  WheelPainter(this.labels);
  final List<String> labels;
  static const colors = [Color(0xFF2A2415), Color(0xFF3B3119), Color(0xFF1C1912), Color(0xFF4A3D1D)];
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final sweep = 2 * math.pi / labels.length;
    final rect = Rect.fromCircle(center: center, radius: radius - 3);
    for (var i = 0; i < labels.length; i++) {
      final start = -math.pi / 2 + i * sweep;
      canvas.drawArc(rect, start, sweep, true, Paint()..color = colors[i % colors.length]);
      canvas.drawArc(rect, start, sweep, true, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.5..color = gold.withValues(alpha: .6));
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(start + sweep / 2);
      final painter = TextPainter(text: TextSpan(text: labels[i], style: const TextStyle(color: goldLight, fontSize: 12, fontWeight: FontWeight.w800)), textDirection: ui.TextDirection.rtl, maxLines: 2, ellipsis: '…', textAlign: TextAlign.center)..layout(maxWidth: radius * .55);
      painter.paint(canvas, Offset(radius * .36, -painter.height / 2));
      canvas.restore();
    }
    canvas.drawCircle(center, radius - 3, Paint()..style = PaintingStyle.stroke..strokeWidth = 6..color = gold);
  }
  @override
  bool shouldRepaint(covariant WheelPainter old) => old.labels != labels;
}

// ───────────────────────── الإشعارات ─────────────────────────

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, required this.items});
  final List<Announcement> items;
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String seen = '';
  @override
  void initState() { super.initState(); markSeen(); }
  Future<void> markSeen() async {
    final previous = await Store.get('notif_seen') ?? '';
    if (mounted) setState(() => seen = previous);
    final newest = widget.items.fold<String>(previous, (a, b) => b.createdAt.compareTo(a) > 0 ? b.createdAt : a);
    await Store.set('notif_seen', newest);
  }
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('الإشعارات'), leading: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_forward))),
        body: widget.items.isEmpty
            ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.notifications_off_outlined, color: muted, size: 44), SizedBox(height: 12), Text('لا توجد إشعارات حاليًا', style: TextStyle(color: muted))]))
            : ListView.separated(
                padding: const EdgeInsets.all(18),
                itemCount: widget.items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final item = widget.items[i];
                  final isNew = item.createdAt.compareTo(seen) > 0;
                  final when = DateTime.tryParse(item.createdAt)?.toLocal();
                  return Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(14), border: Border.all(color: isNew ? gold.withValues(alpha: .6) : const Color(0xFF2B2A25))),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [const Icon(Icons.campaign_outlined, color: gold, size: 20), const SizedBox(width: 8), Expanded(child: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14))), if (isNew) const Text('جديد', style: TextStyle(color: goldLight, fontSize: 10, fontWeight: FontWeight.w800))]),
                      if (item.body.isNotEmpty) ...[const SizedBox(height: 7), Text(item.body, style: const TextStyle(color: muted, fontSize: 12, height: 1.6))],
                      if (when != null) ...[const SizedBox(height: 8), Text(DateFormat('d MMMM y', 'ar_EG').format(when), style: const TextStyle(color: Color(0xFF77746D), fontSize: 10))],
                    ]),
                  );
                },
              ),
      );
}

// ───────────────────────── الصفحة 2: الحجوزات ─────────────────────────

class BookingsTab extends StatefulWidget {
  const BookingsTab({super.key});
  @override
  State<BookingsTab> createState() => _BookingsTabState();
}

class _BookingsTabState extends State<BookingsTab> {
  final api = SalonApi();
  List<MyBooking> bookings = [];
  bool loading = true;
  String? error;
  @override
  void initState() { super.initState(); Session.bookingsTick.addListener(load); load(); }
  @override
  void dispose() { Session.bookingsTick.removeListener(load); super.dispose(); }
  Future<void> load() async {
    final phone = Session.customer?.phone;
    if (phone == null) return;
    try {
      final result = await api.myBookings(phone);
      if (mounted) setState(() { bookings = result; loading = false; error = null; });
    } catch (e) { if (mounted) setState(() { loading = false; error = e.toString(); }); }
  }
  List<MyBooking> by(String status) => bookings.where((b) => b.status == status).toList();
  @override
  Widget build(BuildContext context) {
    final pending = by('مؤكد'), done = by('مكتمل'), cancelled = by('ملغي');
    return SafeArea(
      child: DefaultTabController(
        length: 3,
        child: Column(children: [
          const Padding(padding: EdgeInsets.fromLTRB(20, 16, 20, 10), child: Align(alignment: AlignmentDirectional.centerStart, child: Text('الحجوزات', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)))),
          TabBar(
            indicatorColor: gold,
            labelColor: goldLight,
            unselectedLabelColor: muted,
            dividerColor: const Color(0xFF2B2A25),
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            tabs: [Tab(text: 'قيد التنفيذ (${pending.length})'), Tab(text: 'المكتمل (${done.length})'), Tab(text: 'الملغي (${cancelled.length})')],
          ),
          Expanded(child: loading
              ? const Center(child: CircularProgressIndicator(color: gold))
              : error != null && bookings.isEmpty
                  ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.cloud_off_outlined, color: gold, size: 38), const SizedBox(height: 10), Text(error!, textAlign: TextAlign.center, style: const TextStyle(color: muted, fontSize: 12)), const SizedBox(height: 12), OutlinedButton(onPressed: () { setState(() => loading = true); load(); }, child: const Text('إعادة المحاولة'))])))
                  : TabBarView(children: [
                      BookingList(items: pending, empty: 'لا توجد حجوزات قيد التنفيذ', onRefresh: load),
                      BookingList(items: done, empty: 'لا توجد حجوزات مكتملة', onRefresh: load),
                      BookingList(items: cancelled, empty: 'لا توجد حجوزات ملغية', onRefresh: load),
                    ])),
        ]),
      ),
    );
  }
}

class BookingList extends StatelessWidget {
  const BookingList({super.key, required this.items, required this.empty, required this.onRefresh});
  final List<MyBooking> items;
  final String empty;
  final Future<void> Function() onRefresh;
  @override
  Widget build(BuildContext context) => RefreshIndicator(
        color: gold,
        onRefresh: onRefresh,
        child: items.isEmpty
            ? ListView(children: [SizedBox(height: 120, child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.event_busy_outlined, color: muted, size: 40), const SizedBox(height: 10), Text(empty, style: const TextStyle(color: muted))])))])
            : ListView.separated(padding: const EdgeInsets.all(16), itemCount: items.length, separatorBuilder: (_, _) => const SizedBox(height: 10), itemBuilder: (_, i) => BookingCard(booking: items[i])),
      );
}

class BookingCard extends StatelessWidget {
  const BookingCard({super.key, required this.booking});
  final MyBooking booking;
  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (booking.status) {
      'مكتمل' => ('مكتمل', green),
      'ملغي' => ('ملغي', red),
      _ => ('قيد التنفيذ', goldLight),
    };
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0xFF2B2A25))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(booking.code, style: const TextStyle(color: goldLight, fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1))),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(20)), child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800))),
        ]),
        const SizedBox(height: 10),
        Text(booking.services.map((s) => s.name).join('، '), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 8),
        Row(children: [
          const Icon(Icons.calendar_month_outlined, color: muted, size: 15), const SizedBox(width: 5),
          Expanded(child: Text('${DateFormat('EEEE d MMMM', 'ar_EG').format(booking.date)} · ${booking.time}', style: const TextStyle(color: muted, fontSize: 11))),
          Text(egp(booking.total), style: const TextStyle(color: goldLight, fontWeight: FontWeight.w800, fontSize: 14)),
        ]),
        if (booking.discountCode.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text('خصم ${booking.discountCode} · −${egp(booking.discountAmount)}', style: const TextStyle(color: green, fontSize: 10))),
      ]),
    );
  }
}

// ───────────────────────── الصفحة 3: حسابي ─────────────────────────

class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.photo, this.size = 96});
  final String? photo;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: panel, border: Border.all(color: gold, width: 2)),
        child: ClipOval(child: photo == null ? Icon(Icons.person_rounded, color: gold, size: size * .55) : Image.memory(base64Decode(photo!), fit: BoxFit.cover, gaplessPlayback: true)),
      );
}

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});
  Future<void> logout(BuildContext context) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      backgroundColor: panel,
      title: const Text('تسجيل الخروج'),
      content: const Text('هل تريد تسجيل الخروج من حسابك؟', style: TextStyle(color: muted)),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')), TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('خروج', style: TextStyle(color: red)))],
    ));
    if (ok != true) return;
    await Session.clear();
    if (context.mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const WelcomeScreen()), (route) => false);
  }
  @override
  Widget build(BuildContext context) => SafeArea(
        child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 560), child: ListenableBuilder(
          listenable: Session.photo,
          builder: (context, _) {
            final c = Session.customer;
            return ListView(padding: const EdgeInsets.fromLTRB(20, 18, 20, 24), children: [
              const Text('حسابي', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 20),
              Center(child: Avatar(photo: Session.photo.value)),
              const SizedBox(height: 12),
              Text(c?.fullName ?? '', textAlign: TextAlign.center, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(c?.phone ?? '', textDirection: ui.TextDirection.ltr, textAlign: TextAlign.center, style: const TextStyle(color: muted, fontSize: 13)),
              if ((c?.email ?? '').isNotEmpty) Padding(padding: const EdgeInsets.only(top: 3), child: Text(c!.email, textDirection: ui.TextDirection.ltr, textAlign: TextAlign.center, style: const TextStyle(color: muted, fontSize: 12))),
              const SizedBox(height: 22),
              ProfileTile(icon: Icons.edit_outlined, title: 'تعديل الملف الشخصي', subtitle: 'الصورة والاسم ورقم الهاتف', onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())); }),
              const SizedBox(height: 10),
              ProfileTile(icon: Icons.info_outline_rounded, title: 'عن التطبيق', subtitle: 'معلومات عن تطبيق الصالون', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen()))),
              const SizedBox(height: 10),
              ProfileTile(icon: Icons.logout_rounded, title: 'تسجيل الخروج', subtitle: '', danger: true, onTap: () => logout(context)),
            ]);
          },
        ))),
      );
}

class ProfileTile extends StatelessWidget {
  const ProfileTile({super.key, required this.icon, required this.title, required this.subtitle, required this.onTap, this.danger = false});
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  final bool danger;
  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF2B2A25))),
          child: Row(children: [
            Icon(icon, color: danger ? red : gold, size: 22),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: danger ? red : Colors.white)), if (subtitle.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 2), child: Text(subtitle, style: const TextStyle(color: muted, fontSize: 10)))])),
            if (!danger) const Icon(Icons.arrow_back_ios_new_rounded, color: muted, size: 14),
          ]),
        ),
      );
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final api = SalonApi();
  final picker = ImagePicker();
  late final first = TextEditingController(text: Session.customer?.firstName ?? '');
  late final last = TextEditingController(text: Session.customer?.lastName ?? '');
  late final phone = TextEditingController(text: Session.customer?.phone ?? '');
  String? photo = Session.photo.value;
  bool busy = false;
  @override
  void dispose() { first.dispose(); last.dispose(); phone.dispose(); super.dispose(); }
  Future<void> pick(ImageSource source) async {
    try {
      final file = await picker.pickImage(source: source, maxWidth: 512, maxHeight: 512, imageQuality: 70);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (mounted) setState(() => photo = base64Encode(bytes));
    } catch (_) {
      if (mounted) message(context, 'تعذر الوصول للصورة. تأكد من السماح بالأذونات.');
    }
  }
  void choosePhoto() => showModalBottomSheet<void>(
        context: context,
        backgroundColor: panel,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (sheet) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          ListTile(leading: const Icon(Icons.photo_library_outlined, color: gold), title: const Text('اختيار من المعرض'), onTap: () { Navigator.pop(sheet); pick(ImageSource.gallery); }),
          ListTile(leading: const Icon(Icons.photo_camera_outlined, color: gold), title: const Text('التقاط صورة'), onTap: () { Navigator.pop(sheet); pick(ImageSource.camera); }),
          if (photo != null) ListTile(leading: const Icon(Icons.delete_outline, color: red), title: const Text('حذف الصورة', style: TextStyle(color: red)), onTap: () { Navigator.pop(sheet); setState(() => photo = null); }),
          const SizedBox(height: 8),
        ])),
      );
  Future<void> save() async {
    final current = Session.customer;
    if (current == null) return;
    if (first.text.trim().length < 2 || last.text.trim().length < 2) { message(context, 'اكتب الاسم الأول والاسم الثاني.'); return; }
    if (phone.text.replaceAll(RegExp(r'\D'), '').length < 9) { message(context, 'اكتب رقم هاتف صحيح.'); return; }
    setState(() => busy = true);
    try {
      final updated = await api.updateCustomer(currentPhone: current.phone, firstName: first.text.trim(), lastName: last.text.trim(), phone: phone.text.trim());
      await Session.save(Customer(firstName: updated.firstName, lastName: updated.lastName, phone: updated.phone, email: updated.email.isEmpty ? current.email : updated.email));
      await Session.savePhoto(photo);
      Session.bookingsTick.value++;
      if (!mounted) return;
      message(context, 'تم حفظ التعديلات');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) message(context, e.toString().replaceFirst('Exception: ', ''));
    } finally { if (mounted) setState(() => busy = false); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('تعديل الملف الشخصي'), leading: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_forward))),
        body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 540), child: ListView(padding: const EdgeInsets.fromLTRB(22, 18, 22, 30), children: [
          Center(child: GestureDetector(onTap: choosePhoto, child: Stack(children: [
            Avatar(photo: photo, size: 110),
            PositionedDirectional(bottom: 0, end: 0, child: Container(padding: const EdgeInsets.all(7), decoration: const BoxDecoration(shape: BoxShape.circle, color: gold), child: const Icon(Icons.photo_camera_rounded, color: ink, size: 17))),
          ]))),
          const SizedBox(height: 8),
          Center(child: TextButton(onPressed: choosePhoto, child: const Text('تغيير الصورة'))),
          const SizedBox(height: 10),
          const FieldLabel('الاسم الأول'), const SizedBox(height: 7),
          TextField(controller: first, textInputAction: TextInputAction.next, decoration: const InputDecoration(prefixIcon: Icon(Icons.person_outline, color: gold))),
          const SizedBox(height: 14),
          const FieldLabel('الاسم الثاني'), const SizedBox(height: 7),
          TextField(controller: last, textInputAction: TextInputAction.next, decoration: const InputDecoration(prefixIcon: Icon(Icons.person_outline, color: gold))),
          const SizedBox(height: 14),
          const FieldLabel('رقم الهاتف'), const SizedBox(height: 7),
          TextField(controller: phone, keyboardType: TextInputType.phone, textDirection: ui.TextDirection.ltr, textAlign: TextAlign.left, decoration: const InputDecoration(prefixIcon: Icon(Icons.phone_outlined, color: gold))),
          const SizedBox(height: 24),
          GoldButton(label: busy ? 'جارٍ الحفظ...' : 'حفظ التعديلات', icon: Icons.check_rounded, onPressed: busy ? null : save),
        ]))),
      );
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('عن التطبيق'), leading: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_forward))),
        body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520), child: ListView(padding: const EdgeInsets.all(24), children: [
          const Center(child: ZizoLogo(height: 110)),
          const SizedBox(height: 18),
          const Text('ZIZO', textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 4)),
          const SizedBox(height: 6),
          const Text('الإصدار 1.0.0', textAlign: TextAlign.center, style: TextStyle(color: muted, fontSize: 12)),
          const SizedBox(height: 20),
          const NoticeBox('تطبيق صالون ZIZO لحجز مواعيد الحلاقة بسهولة من موبايلك. اختار خدمتك والموعد المناسب، وتابع حجوزاتك (قيد التنفيذ والمكتملة والملغية) من مكان واحد، وجرّب حظك في عجلة الحظ لتكسب خصومات وهدايا من الصالون.'),
          const SizedBox(height: 14),
          const NoticeBox('الأسعار بالجنيه المصري، والحجز متاح سواء كان المحل مفتوحًا أو مغلقًا وقت الحجز.'),
        ]))),
      );
}

// ───────────────────────── تأكيد الحجز ─────────────────────────

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

/// شعار ZIZO: حرف Z (الشعار بدون خلفية) ثم IZO نصًا.
class ZizoLogo extends StatelessWidget {
  const ZizoLogo({super.key, this.height = 90});
  final double height;
  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: ui.TextDirection.ltr,
        child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
          Image.asset('assets/zizo_z.png', height: height, fit: BoxFit.contain),
          SizedBox(width: height * .04),
          Padding(
            padding: EdgeInsets.only(bottom: height * .02),
            child: Text('IZO', style: TextStyle(color: Colors.white, fontSize: height * .5, height: 1, fontWeight: FontWeight.w800, letterSpacing: height * .04, fontFamily: 'serif', shadows: [Shadow(color: gold.withValues(alpha: .35), blurRadius: 18)])),
          ),
        ]),
      );
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.compact = false});
  final bool compact;
  @override
  Widget build(BuildContext context) => ZizoLogo(height: compact ? 30 : 38);
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

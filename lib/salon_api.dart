import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class SalonApiException implements Exception {
  const SalonApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class SalonService {
  const SalonService({required this.id, required this.name, required this.description, required this.price, required this.duration, required this.icon});
  final String id, name, description, icon;
  final int price, duration;
  factory SalonService.fromJson(Map<String, dynamic> json) => SalonService(
        id: (json['id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        description: (json['description'] as String?) ?? '',
        price: (json['price'] as num?)?.toInt() ?? 0,
        duration: (json['duration'] as num?)?.toInt() ?? 30,
        icon: (json['icon'] as String?) ?? 'cut',
      );
}

class Announcement {
  const Announcement({required this.id, required this.title, required this.body, required this.createdAt});
  final String id, title, body, createdAt;
  factory Announcement.fromJson(Map<String, dynamic> json) => Announcement(
        id: (json['id'] as String?) ?? '',
        title: (json['title'] as String?) ?? '',
        body: (json['body'] as String?) ?? '',
        createdAt: (json['createdAt'] as String?) ?? '',
      );
}

class SocialItem {
  const SocialItem({required this.platform, required this.label, required this.url});
  final String platform, label, url;
}

class SalonBootstrap {
  const SalonBootstrap({required this.shopOpen, required this.bookingsEnabled, required this.wheelEnabled, required this.wheelPrizes, required this.services, required this.social, required this.designerUrl, required this.announcements});
  final bool shopOpen, bookingsEnabled, wheelEnabled;
  final List<Map<String, dynamic>> wheelPrizes;
  final List<SalonService> services;
  final List<SocialItem> social;
  final String designerUrl;
  final List<Announcement> announcements;
  factory SalonBootstrap.fromJson(Map<String, dynamic> json) {
    final social = (json['social'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .where((item) => item['enabled'] != false && ((item['url'] as String?) ?? '').trim().isNotEmpty)
        .map((item) => SocialItem(platform: (item['platform'] as String?) ?? 'website', label: (item['label'] as String?) ?? '', url: (item['url'] as String).trim()))
        .toList();
    return SalonBootstrap(
      shopOpen: json['shopOpen'] == true,
      bookingsEnabled: json['bookingsEnabled'] != false,
      wheelEnabled: json['wheelEnabled'] != false,
      wheelPrizes: (json['wheelPrizes'] as List<dynamic>? ?? const []).whereType<Map<String, dynamic>>().toList(),
      services: (json['services'] as List<dynamic>? ?? const []).map((item) => SalonService.fromJson(item as Map<String, dynamic>)).toList(),
      social: social,
      designerUrl: ((json['designerUrl'] as String?) ?? '').trim(),
      announcements: (json['announcements'] as List<dynamic>? ?? const []).whereType<Map<String, dynamic>>().map(Announcement.fromJson).toList(),
    );
  }
}

class Customer {
  const Customer({required this.firstName, required this.lastName, required this.phone, required this.email});
  final String firstName, lastName, phone, email;
  String get fullName => '$firstName $lastName'.trim();
  factory Customer.fromJson(Map<String, dynamic> json) {
    var first = (json['firstName'] as String?) ?? '';
    var last = (json['lastName'] as String?) ?? '';
    if (first.isEmpty) {
      final parts = ((json['name'] as String?) ?? '').trim().split(RegExp(r'\s+'));
      first = parts.first;
      last = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    }
    return Customer(firstName: first, lastName: last, phone: (json['phone'] as String?) ?? '', email: (json['email'] as String?) ?? '');
  }
}

class MyBooking {
  const MyBooking({required this.code, required this.date, required this.time, required this.status, required this.services, required this.total, required this.discountCode, required this.discountAmount});
  final String code, time, status, discountCode;
  final DateTime date;
  final List<SalonService> services;
  final int total, discountAmount;
  factory MyBooking.fromJson(Map<String, dynamic> json) => MyBooking(
        code: json['bookingCode'] as String,
        date: DateTime.parse(json['date'] as String),
        time: json['time'] as String,
        status: json['status'] as String,
        services: (json['serviceItems'] as List<dynamic>? ?? const []).map((item) => SalonService.fromJson(item as Map<String, dynamic>)).toList(),
        total: (json['total'] as num).toInt(),
        discountCode: (json['discountCode'] as String?) ?? '',
        discountAmount: (json['discountAmount'] as num?)?.toInt() ?? 0,
      );
}

class DiscountPreview {
  const DiscountPreview({required this.code, required this.amount, required this.total});
  final String code;
  final int amount, total;
  factory DiscountPreview.fromJson(Map<String, dynamic> json) => DiscountPreview(
        code: json['code'] as String,
        amount: (json['amount'] as num).toInt(),
        total: (json['total'] as num).toInt(),
      );
}

class BookingReceipt {
  const BookingReceipt({required this.code, required this.name, required this.phone, required this.date, required this.time, required this.services, required this.discountCode, required this.discountAmount, required this.queueAhead, required this.total});
  final String code, name, phone, time, discountCode;
  final DateTime date;
  final List<SalonService> services;
  final int discountAmount, queueAhead, total;
  factory BookingReceipt.fromJson(Map<String, dynamic> json) => BookingReceipt(
        code: json['bookingCode'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String,
        date: DateTime.parse(json['date'] as String),
        time: json['time'] as String,
        services: (json['serviceItems'] as List<dynamic>? ?? const []).map((item) => SalonService.fromJson(item as Map<String, dynamic>)).toList(),
        discountCode: (json['discountCode'] as String?) ?? '',
        discountAmount: (json['discountAmount'] as num).toInt(),
        queueAhead: (json['queueAhead'] as num).toInt(),
        total: (json['total'] as num).toInt(),
      );
}

class SalonApi {
  SalonApi({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  // ملاحظة: لو تم تمرير API_BASE_URL فارغًا (مثل متغير GitHub غير مضبوط) نستخدم العنوان الافتراضي.
  static const _envBase = String.fromEnvironment('API_BASE_URL');
  static const _defaultBase = 'https://zizo-admin3.vercel.app';

  String get _baseUrl {
    final configured = _envBase.trim();
    return (configured.isEmpty ? _defaultBase : configured).replaceFirst(RegExp(r'/+$'), '');
  }

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');
  Map<String, String> get _headers => const {'Content-Type': 'application/json', 'Accept': 'application/json'};

  Future<Map<String, dynamic>> _get(String path) async {
    try {
      final response = await _client.get(_uri(path), headers: _headers).timeout(const Duration(seconds: 35));
      return _decode(response);
    } on TimeoutException {
      throw const SalonApiException('الخادم اتأخر في الرد. اتأكد من الإنترنت وحاول مرة أخرى.');
    } on FormatException {
      throw const SalonApiException('استجابة الخادم غير مفهومة. حاول مرة أخرى بعد قليل.');
    } on http.ClientException {
      throw const SalonApiException('تعذر الاتصال بالخادم. تأكد من الإنترنت وحاول مرة أخرى.');
    }
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    try {
      final response = await _client.post(_uri(path), headers: _headers, body: jsonEncode(body)).timeout(const Duration(seconds: 45));
      return _decode(response);
    } on TimeoutException {
      throw const SalonApiException('طلبك استغرق وقتًا أطول من المعتاد. اتأكد من الإنترنت وحاول مرة أخرى. لو المشكلة مستمرة، راجع حالة خادم لوحة التحكم.');
    } on FormatException {
      throw const SalonApiException('استجابة الخادم غير مفهومة. حاول مرة أخرى بعد قليل.');
    } on http.ClientException {
      throw const SalonApiException('تعذر الاتصال بالخادم. تأكد من الإنترنت وحاول مرة أخرى.');
    }
  }

  Map<String, dynamic> _decode(http.Response response) {
    Map<String, dynamic> decoded = <String, dynamic>{};
    try {
      if (response.body.isNotEmpty) decoded = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      if (response.statusCode >= 200 && response.statusCode < 300) throw const SalonApiException('استجابة الخادم غير مفهومة. حاول مرة أخرى بعد قليل.');
      throw SalonApiException('الخادم لا يعمل حاليًا (رمز ${response.statusCode}). تأكد من نشر لوحة التحكم وإعدادات Firebase على Vercel.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SalonApiException((decoded['error'] as String?) ?? 'تعذر الاتصال بالخادم. حاول مرة أخرى.');
    }
    return decoded;
  }

  Future<Map<String, dynamic>> spinWheel() => _post('/api/mobile/wheel/spin', {});
  Future<Customer> register({required String firstName, required String lastName, required String phone, required String email, required String password}) async =>
      Customer.fromJson(await _post('/api/mobile/auth/register', {'firstName': firstName, 'lastName': lastName, 'phone': phone, 'email': email, 'password': password}));
  Future<Customer> login({required String identifier, required String password}) async => Customer.fromJson(await _post('/api/mobile/auth/login', {'identifier': identifier, 'password': password}));
  Future<Customer> updateCustomer({required String currentPhone, required String firstName, required String lastName, required String phone}) async =>
      Customer.fromJson(await _post('/api/mobile/customer/update', {'currentPhone': currentPhone, 'firstName': firstName, 'lastName': lastName, 'phone': phone}));
  Future<List<MyBooking>> myBookings(String phone) async {
    final result = await _post('/api/mobile/bookings/mine', {'phone': phone});
    return (result['bookings'] as List<dynamic>? ?? const []).map((item) => MyBooking.fromJson(item as Map<String, dynamic>)).toList();
  }
  Future<SalonBootstrap> bootstrap() async => SalonBootstrap.fromJson(await _get('/api/mobile/bootstrap'));
  Future<DiscountPreview> validateDiscount(String code, List<String> serviceIds) async => DiscountPreview.fromJson(await _post('/api/mobile/discounts/validate', {'code': code, 'serviceIds': serviceIds}));

  Future<BookingReceipt> createBooking({required String name, required String phone, required DateTime date, required String time, required List<String> serviceIds, required String discountCode}) async {
    final result = await _post('/api/mobile/bookings', {
      'name': name,
      'phone': phone,
      'date': DateFormat('yyyy-MM-dd').format(date),
      'time': time,
      'serviceIds': serviceIds,
      'discountCode': discountCode,
    });
    return BookingReceipt.fromJson(result);
  }
}

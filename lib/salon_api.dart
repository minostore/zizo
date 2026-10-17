import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
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
        id: json['id'] as String,
        name: json['name'] as String,
        description: (json['description'] as String?) ?? '',
        price: (json['price'] as num).toInt(),
        duration: (json['duration'] as num).toInt(),
        icon: (json['icon'] as String?) ?? 'cut',
      );
}

class SalonBootstrap {
  const SalonBootstrap({required this.shopOpen, required this.bookingsEnabled, required this.wheelPrizes, required this.services});
  final bool shopOpen, bookingsEnabled;
  final List<Map<String, dynamic>> wheelPrizes;
  final List<SalonService> services;
  factory SalonBootstrap.fromJson(Map<String, dynamic> json) => SalonBootstrap(
        shopOpen: json['shopOpen'] == true,
        bookingsEnabled: json['bookingsEnabled'] != false,
        wheelPrizes: (json['wheelPrizes'] as List<dynamic>? ?? const []).whereType<Map<String, dynamic>>().toList(),
        services: (json['services'] as List<dynamic>? ?? const []).map((item) => SalonService.fromJson(item as Map<String, dynamic>)).toList(),
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
  static const _configuredBase = String.fromEnvironment('API_BASE_URL', defaultValue: 'https://zizo-admin3.vercel.app');

  String get _baseUrl {
    if (_configuredBase.trim().isNotEmpty) return _configuredBase.trim().replaceFirst(RegExp(r'/+$'), '');
    if (kIsWeb) return Uri.base.origin;
    if (defaultTargetPlatform == TargetPlatform.iOS) return 'http://127.0.0.1:3000';
    return 'http://10.0.2.2:3000';
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
    }
  }

  Map<String, dynamic> _decode(http.Response response) {
    final decoded = response.body.isEmpty ? <String, dynamic>{} : jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SalonApiException((decoded['error'] as String?) ?? 'تعذر الاتصال بالخادم. حاول مرة أخرى.');
    }
    return decoded;
  }

  Future<Map<String, dynamic>> spinWheel() => _post('/api/mobile/wheel/spin', {});
  Future<Map<String, dynamic>> register({required String name, required String phone, required String email, required String password}) => _post('/api/mobile/auth/register', {'name': name, 'phone': phone, 'email': email, 'password': password});
  Future<Map<String, dynamic>> login({required String identifier, required String password}) => _post('/api/mobile/auth/login', {'identifier': identifier, 'password': password});
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

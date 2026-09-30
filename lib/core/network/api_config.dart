import 'package:flutter/foundation.dart';

/// Configuration for REST API endpoints and base URL per rule-api.md
class ApiConfig {
  ApiConfig._();

  /// Default local development port for NestJS backend (apps/api) per rule-api.md
  static const int defaultPort = 4000;

  /// Default Base URL logic:
  /// - Web / macOS / Windows / Linux: http://localhost:3000/api/v1
  /// - Android Emulator: http://10.0.2.2:3000/api/v1
  /// - Physical device (LAN): http://YOUR_LAN_IP:3000/api/v1
  static String get defaultBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:$defaultPort/api/v1';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:$defaultPort/api/v1';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      default:
        return 'http://localhost:$defaultPort/api/v1';
    }
  }

  /// Dynamic Base URL (can be customized at runtime or loaded from SharedPreferences)
  static String _customBaseUrl = '';

  static String get baseUrl =>
      _customBaseUrl.isNotEmpty ? _customBaseUrl : defaultBaseUrl;

  static void setCustomBaseUrl(String url) {
    _customBaseUrl = url.trim();
    if (_customBaseUrl.endsWith('/')) {
      _customBaseUrl = _customBaseUrl.substring(0, _customBaseUrl.length - 1);
    }
  }

  static void resetBaseUrl() {
    _customBaseUrl = '';
  }

  /// Network timeout configuration
  static const Duration connectTimeout = Duration(seconds: 8);
  static const Duration receiveTimeout = Duration(seconds: 10);

  // ---------------------------------------------------------------------------
  // Endpoint Paths (Prefix: /api/v1 is already in baseUrl)
  // ---------------------------------------------------------------------------

  // Auth & User
  static const String authLogin = '/auth/login';
  static const String authRegister = '/auth/register';
  static const String authRequestOtp = '/auth/register/request-otp';
  static const String authVerifyOtp = '/auth/register/verify-otp';
  static const String authRefresh = '/auth/refresh';
  static const String authLogout = '/auth/logout';
  static const String me = '/me';

  // Trips
  static const String tripsSearch = '/trips/search';
  static String tripDetail(dynamic tripId) => '/trips/$tripId';
  static String tripSeats(dynamic tripId) => '/trips/$tripId/seats';

  // Seats & Seat Hold (Owner: Người B)
  static const String seatHolds = '/seat-holds';
  static String seatHoldRelease(String holdToken) => '/seat-holds/$holdToken';

  // Bookings (Owner: Người B)
  static const String bookingQuote = '/bookings/quote';
  static const String bookings = '/bookings';
  static String bookingDetail(dynamic bookingId) => '/bookings/$bookingId';
  static String bookingCancel(dynamic bookingId) => '/bookings/$bookingId/cancel';

  // Promotions (Owner: Người B)
  static const String promotions = '/promotions';
  static const String promotionsValidate = '/promotions/validate';

  // Payments (Owner: Người B)
  static const String payments = '/payments';
  static String paymentDetail(dynamic paymentId) => '/payments/$paymentId';
  static String paymentStatus(dynamic paymentId) => '/payments/$paymentId/status';

  // Tickets (Owner: Người B)
  static const String tickets = '/tickets';
  static String ticketDetail(dynamic ticketId) => '/tickets/$ticketId';
  static const String ticketLookup = '/tickets/lookup';
}

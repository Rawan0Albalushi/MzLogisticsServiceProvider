import 'package:flutter/foundation.dart';

class AppConfig {
  const AppConfig._();

  static const String _apiBaseUrlFromEnv = String.fromEnvironment('API_BASE_URL');
  static const int apiPort = 8000;
  static const String lanApiHost = '192.168.100.94';

  static String get apiBaseUrl {
    if (_apiBaseUrlFromEnv.isNotEmpty) return _apiBaseUrlFromEnv;
    if (kIsWeb) {
      final host = Uri.base.host;
      if (host == 'localhost' || host == '127.0.0.1') {
        return 'http://127.0.0.1:$apiPort/api/v1';
      }
      if (host.isNotEmpty) {
        return 'http://$host:$apiPort/api/v1';
      }
    }
    return 'http://$lanApiHost:$apiPort/api/v1';
  }

  static const String demoEmail = 'provider@omanhaulers.om';
  static const String demoPassword = 'Password123!';

  /// Temporarily hidden until live tracking is ready to ship.
  static const bool liveTrackingEnabled = false;
  static const String defaultCurrency = 'OMR';
  static const List<String> truckTypes = [
    'flatbed',
    'box',
    'reefer',
    'tanker',
    'lowbed',
    'dump',
    'curtain',
  ];
  static const List<String> tripStatuses = [
    'unassigned',
    'assigned',
    'arrived_at_pickup',
    'loaded',
    'in_transit',
    'arrived',
    'delivered',
    'completed',
  ];
  static const List<String> truckStatuses = [
    'available',
    'assigned',
    'maintenance',
    'inactive',
  ];
  static const List<String> equipmentStatuses = [
    'available',
    'in_use',
    'maintenance',
    'inactive',
  ];
  static const List<String> driverStatuses = [
    'available',
    'on_trip',
    'inactive',
  ];
  static const List<String> paymentMethods = [
    'thawani',
    'cash',
  ];
  static const List<String> paymentStatuses = [
    'pending',
    'processing',
    'completed',
    'failed',
    'refunded',
  ];
  static const List<String> invoiceStatuses = [
    'issued',
    'paid',
    'void',
  ];
  static const List<String> invoiceTypes = [
    'customer',
    'provider',
  ];
  static const List<String> settlementStatuses = [
    'pending',
    'processing',
    'completed',
  ];
  static const List<String> walletTransactionTypes = [
    'job_earning',
    'earning_released',
    'payout_reserved',
    'payout_completed',
    'payout_rejected',
    'adjustment',
  ];
}

class AppConfig {
  const AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api/v1',
  );

  static const String demoEmail = 'provider@omanhaulers.om';
  static const String demoPassword = 'Password123!';
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
    'commission',
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

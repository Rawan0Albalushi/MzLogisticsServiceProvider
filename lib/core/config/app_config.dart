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
}

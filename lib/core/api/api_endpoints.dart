class ApiEndpoints {
  const ApiEndpoints._();

  static const login = '/auth/login';
  static const registerProvider = '/auth/register/provider';
  static const logout = '/auth/logout';
  static const me = '/auth/me';
  static const password = '/auth/password';
  static const dashboard = '/dashboard';
  static const shipments = '/shipments';
  static const quotations = '/quotations';
  static const jobs = '/jobs';
  static const trips = '/trips';
  static const trucks = '/trucks';
  static const equipment = '/equipment';
  static const drivers = '/drivers';
  static const payments = '/payments';
  static const invoices = '/invoices';
  static const settlements = '/settlements';
  static const notifications = '/notifications';
  static const organizations = '/organizations';

  static String shipment(int id) => '/shipments/$id';
  static String shipmentQuotations(int id) => '/shipments/$id/quotations';
  static String quotation(int id) => '/quotations/$id';
  static String withdrawQuotation(int id) => '/quotations/$id/withdraw';
  static String job(int id) => '/jobs/$id';
  static String trip(int id) => '/trips/$id';
  static String assignTrip(int id) => '/trips/$id/assign';
  static String tripStatus(int id) => '/trips/$id/status';
  static String truck(int id) => '/trucks/$id';
  static String organization(int id) => '/organizations/$id';
  static String readNotification(String id) => '/notifications/$id/read';
  static const readAllNotifications = '/notifications/read-all';
}

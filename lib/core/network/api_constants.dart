class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'https://api.kwikcabs.in';

  static const String driverLogin = '$baseUrl/api/drivers/login';
  static const String driverRegister = '$baseUrl/api/drivers/register';
  static const String driverResubmit = '$baseUrl/api/drivers/resubmit';
  static const String driverProfile = '$baseUrl/api/drivers/profile';
  static const String profileUpdate = '$baseUrl/api/drivers/profile-update';
  static const String carCategories = '$baseUrl/api/car-categories/active';
  static const String toggleOnline = '$baseUrl/api/drivers/toggle-online';
  static const String updateLocation = '$baseUrl/api/drivers/update-location';
  static const String getPendingRequests = '$baseUrl/api/trips/requests/pending';
  static const String respondToRide = '$baseUrl/api/trips/requests';
  static const String executeArrived = '$baseUrl/api/trips/execute/:bookingId/arrived';
  static const String executeStart = '$baseUrl/api/trips/execute/:bookingId/start';
  static const String executeStopArrived = '$baseUrl/api/trips/execute/:bookingId/stops/:stopIndex/arrived';
  static const String executeStopComplete = '$baseUrl/api/trips/execute/:bookingId/stops/:stopIndex/complete';
  static const String executeCancel = '$baseUrl/api/trips/execute/:bookingId/cancel';
  static const String executeEnd = '$baseUrl/api/trips/execute/:bookingId/end';
  static const String initiatePayment = '$baseUrl/api/trips/execute/:bookingId/initiate-payment';
  static const String getDriverTrips = '$baseUrl/api/trips/driver/my-trips';
  static const String getSingleBooking = '$baseUrl/api/bookings/:bookingId';
  static const String rateUser = '$baseUrl/api/bookings/:bookingId/rate-user';
  static const String getWallet = '$baseUrl/api/wallet/my-wallet';
  static const String requestWithdrawal = '$baseUrl/api/wallet/withdraw';
  
  // Support
  static const String createSupportTicket = '$baseUrl/api/support/create';
  static const String getMyTickets = '$baseUrl/api/support/my-tickets';
  static const String getSupportSummary = '$baseUrl/api/support/report-summary';

  // Notifications
  static const String getMyNotifications = '$baseUrl/api/notifications/my-notifications';

  // Bulk Bookings
  static const String getMyBulkAssignments = '$baseUrl/api/bulk-bookings/driver/my-assignments';
  static const String startBulkBooking = '$baseUrl/api/bulk-bookings/driver/start'; // + /:bookingId
  static const String endBulkBooking = '$baseUrl/api/bulk-bookings/driver/end';     // + /:bookingId

  // FCM Token
  static const String updateFcmToken = '$baseUrl/api/drivers/update-fcm-token';

  // Agent Leads
  static const String agentLeadMarketplace = '$baseUrl/api/agent-leads/marketplace';
  static const String agentLeadMyAccepted = '$baseUrl/api/agent-leads/driver/my-accepted-leads';
  static String agentLeadInitiatePayment(String id) => '$baseUrl/api/agent-leads/$id/initiate-payment';
  static String agentLeadComplete(String id) => '$baseUrl/api/agent-leads/$id/complete';
}

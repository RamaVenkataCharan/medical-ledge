/// All named route paths for MedTrack
class AppRoutes {
  AppRoutes._();

  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String otp = '/otp';

  // Main tabs
  static const String home = '/home';
  static const String customers = '/customers';
  static const String reports = '/reports';
  static const String more = '/more';

  // Customer sub-routes (constructed dynamically)
  static String customerProfile(String id) => '/customers/$id';
  static String editCustomer(String id) => '/customers/$id/edit';
  static String newPurchase(String id) => '/customers/$id/purchases/new';
  static String collectPayment(String id) => '/customers/$id/payment';
  static const String newCustomer = '/customers/new';

  // Purchases
  static String purchaseDetails(String id) => '/purchases/$id';
  static const String purchaseSuccess = '/purchase-success';

  // Medicines
  static const String medicineSearch = '/medicines/search';

  // Notifications
  static const String notifications = '/notifications';

  // Settings sub-screens
  static const String shopInfo = '/settings/shop';
  static const String pharmacist = '/settings/pharmacist';
  static const String reminders = '/settings/reminders';
  static const String dataManagement = '/settings/data';
  static const String recycleBin = '/settings/recycle-bin';
  static String deletedCustomer(String id) => '/settings/recycle-bin/$id';
}

import 'package:flutter/material.dart';
import 'app_routes.dart';
import '../presentation/screens/splash_screen.dart';
import '../features/auth/presentation/screens/welcome_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/registration_screen.dart';
import '../features/auth/presentation/screens/status_screens.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/profile/presentation/screens/edit_profile_screen.dart';
import '../features/profile/presentation/screens/agent_lead_marketplace_screen.dart';
import '../features/profile/presentation/screens/my_accepted_leads_screen.dart';
import '../features/profile/presentation/screens/hdfc_payment_webview.dart';
import '../features/fixed_packages/presentation/screens/fixed_package_marketplace_screen.dart';
import '../features/fixed_packages/presentation/screens/my_accepted_fixed_packages_screen.dart';
import '../features/fixed_packages/presentation/screens/fixed_package_details_screen.dart';
import '../features/ride/presentation/screens/incoming_ride_screen.dart';
import '../features/profile/presentation/screens/destination_filter_screen.dart';

class RouteGenerator {
  RouteGenerator._();

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments is Map<String, dynamic> ? settings.arguments as Map<String, dynamic> : null;

    switch (settings.name) {
      case AppRoutes.splash:
        return _route(const SplashScreen());
      case AppRoutes.welcome:
        return _route(const WelcomeScreen());
      case AppRoutes.login:
        return _route(const LoginScreen());
      case AppRoutes.registration:
        return _route(RegistrationScreen(driverData: args?['driverData']));
      case AppRoutes.home:
        return _route(const HomeScreen());
      case AppRoutes.pending:
        return _route(PendingScreen(message: args?['message']));
      case AppRoutes.rejected:
        return _route(RejectedScreen(message: args?['message'], driverData: args?['driverData']));
      case AppRoutes.blocked:
        return _route(BlockedScreen(message: args?['message']));
      case AppRoutes.editProfile:
        return _route(EditProfileScreen(driverData: args?['driverData']));
      case AppRoutes.agentLeadMarketplace:
        return _route(const AgentLeadMarketplaceScreen());
      case AppRoutes.myAcceptedLeads:
        return _route(const MyAcceptedLeadsScreen());
      case AppRoutes.hdfcPaymentWebview:
        return _route(HdfcPaymentWebviewScreen(paymentUrl: settings.arguments as String));
      case AppRoutes.fixedPackageMarketplace:
        return _route(const FixedPackageMarketplaceScreen());
      case AppRoutes.myAcceptedFixedPackages:
        return _route(const MyAcceptedFixedPackagesScreen());
      case AppRoutes.fixedPackageDetails:
        return _route(FixedPackageDetailsScreen(package: settings.arguments as Map<String, dynamic>));
      case AppRoutes.incomingRide:
        return _route(IncomingRideScreen(payload: args ?? {}));
      case AppRoutes.destinationFilter:
        return _route(const DestinationFilterScreen());
      default:
        return _route(const SplashScreen());
    }
  }

  static MaterialPageRoute _route(Widget page) =>
      MaterialPageRoute(builder: (_) => page);
}

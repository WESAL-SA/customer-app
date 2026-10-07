import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/domain/auth_repository.dart';
import '../features/auth/presentation/auth_controller.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/onboarding_screen.dart';
import '../features/auth/presentation/otp_screen.dart';
import '../features/auth/presentation/profile_setup_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/account/presentation/account_screen.dart';
import '../features/legal/presentation/legal_screen.dart';
import '../features/payments/presentation/payment_methods_screen.dart';
import '../features/shell/home_shell.dart';
import '../features/trips/domain/models.dart';
import '../features/trips/presentation/active/active_trip_screen.dart';
import '../features/trips/presentation/confirm/location_confirm_screen.dart';
import '../features/trips/presentation/history/trip_details_screen.dart';
import '../features/trips/presentation/history/trips_screen.dart';
import '../features/trips/presentation/home/home_screen.dart';
import '../features/trips/presentation/receipt/receipt_screen.dart';
import '../features/trips/presentation/ride_select/ride_select_screen.dart';
import '../features/trips/presentation/search/destination_search_screen.dart';

/// Route path constants to avoid stringly-typed navigation errors.
abstract final class Routes {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const otp = '/otp';
  static const profileSetup = '/profile-setup';
  static const home = '/home';
  static const trips = '/trips';
  static const account = '/account';
  static const search = '/search';
  static const confirm = '/confirm';
  static const rideSelect = '/ride-select';
  static const activeTrip = '/trip';
  static const receipt = '/receipt';
  static const tripDetails = '/trips/details';
  static const paymentMethods = '/payment-methods';
  static const terms = '/legal/terms';
  static const privacy = '/legal/privacy';
}

final _rootKey = GlobalKey<NavigatorState>();
final _shellKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefresh(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final loc = state.matchedLocation;

      switch (auth.status) {
        case AuthStatus.unknown:
          return loc == Routes.splash ? null : Routes.splash;
        case AuthStatus.unauthenticated:
          const allowed = {Routes.onboarding, Routes.login, Routes.otp};
          return allowed.contains(loc) ? null : Routes.onboarding;
        case AuthStatus.needsProfile:
          return loc == Routes.profileSetup ? null : Routes.profileSetup;
        case AuthStatus.authenticated:
          const authFlow = {
            Routes.splash,
            Routes.onboarding,
            Routes.login,
            Routes.otp,
            Routes.profileSetup,
          };
          return authFlow.contains(loc) ? Routes.home : null;
      }
    },
    routes: [
      GoRoute(path: Routes.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(
        path: Routes.onboarding,
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(path: Routes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: Routes.otp,
        builder: (_, state) => OtpScreen(challenge: state.extra as OtpChallenge),
      ),
      GoRoute(
        path: Routes.profileSetup,
        builder: (_, __) => const ProfileSetupScreen(),
      ),

      // Bottom-nav shell.
      StatefulShellRoute.indexedStack(
        parentNavigatorKey: _rootKey,
        builder: (_, __, shell) => HomeShell(shell: shell),
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellKey,
            routes: [
              GoRoute(path: Routes.home, builder: (_, __) => const HomeScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: Routes.trips, builder: (_, __) => const TripsScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.account,
                builder: (_, __) => const AccountScreen(),
              ),
            ],
          ),
        ],
      ),

      // Booking + trip flow (over the shell, root navigator).
      GoRoute(
        path: Routes.search,
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const DestinationSearchScreen(),
      ),
      GoRoute(
        path: Routes.confirm,
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const LocationConfirmScreen(),
      ),
      GoRoute(
        path: Routes.rideSelect,
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const RideSelectScreen(),
      ),
      GoRoute(
        path: Routes.activeTrip,
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const ActiveTripScreen(),
      ),
      GoRoute(
        path: Routes.receipt,
        parentNavigatorKey: _rootKey,
        builder: (_, state) => ReceiptScreen(trip: state.extra as Trip),
      ),
      GoRoute(
        path: Routes.tripDetails,
        parentNavigatorKey: _rootKey,
        builder: (_, state) => TripDetailsScreen(trip: state.extra as Trip),
      ),
      GoRoute(
        path: Routes.paymentMethods,
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const PaymentMethodsScreen(),
      ),
      GoRoute(
        path: Routes.terms,
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const LegalScreen(kind: LegalKind.terms),
      ),
      GoRoute(
        path: Routes.privacy,
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const LegalScreen(kind: LegalKind.privacy),
      ),
    ],
  );
});

/// Bridges Riverpod auth state changes into go_router's refresh mechanism.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(this._ref) {
    _sub = _ref.listen(authControllerProvider, (_, __) => notifyListeners());
  }
  final Ref _ref;
  late final ProviderSubscription<AuthState> _sub;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}

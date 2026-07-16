import 'package:go_router/go_router.dart';

import '../models/listing.dart';
import '../models/user.dart';
import '../screens/advisor/land_advisor_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/dashboard/buyer_dashboard_screen.dart';
import '../screens/dashboard/owner_dashboard_screen.dart';
import '../screens/favorites/favorites_screen.dart';
import '../screens/listings/home_feed_screen.dart';
import '../screens/listings/listing_detail_screen.dart';
import '../screens/listings/post_listing_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/splash_screen.dart';
import '../state/auth_session.dart';

const _buyerRoutePrefixes = ['/dashboard/buyer', '/home', '/favorites', '/advisor', '/post-listing', '/profile', '/listing/'];

GoRouter buildAppRouter(AuthSession session) => GoRouter(
      initialLocation: '/splash',
      refreshListenable: session,
      redirect: (context, state) {
        final location = state.matchedLocation;
        if (location == '/splash') return null; // splash owns its own navigation

        // Bootstrap (reading persisted session) hasn't finished yet — stay put.
        if (!session.bootstrapped) return null;

        final loggedIn = session.isLoggedIn;
        final onAuthScreen = location == '/login' || location == '/signup';

        if (!loggedIn) return onAuthScreen ? null : '/login';

        final homeRoute = session.user!.role == UserRole.owner ? '/dashboard/owner' : '/home';
        if (onAuthScreen) return homeRoute;

        final isBuyerRoute = _buyerRoutePrefixes.any((prefix) => location.startsWith(prefix));
        if (session.user!.role == UserRole.owner && isBuyerRoute) return '/dashboard/owner';
        if (session.user!.role == UserRole.buyer && location.startsWith('/dashboard/owner')) return '/home';

        return null;
      },
      routes: [
        GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
        GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
        GoRoute(path: '/signup', builder: (context, state) => const SignupScreen()),

        GoRoute(path: '/dashboard/buyer', builder: (context, state) => const BuyerDashboardScreen()),
        GoRoute(path: '/dashboard/owner', builder: (context, state) => const OwnerDashboardScreen()),

        GoRoute(path: '/home', builder: (context, state) => const HomeFeedScreen()),
        GoRoute(path: '/favorites', builder: (context, state) => const FavoritesScreen()),
        GoRoute(path: '/advisor', builder: (context, state) => const LandAdvisorScreen()),
        GoRoute(path: '/post-listing', builder: (context, state) => const PostListingScreen()),
        GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),

        GoRoute(
          path: '/listing/:id',
          builder: (context, state) => ListingDetailScreen(
            listingId: state.pathParameters['id']!,
            initialListing: state.extra as Listing?,
          ),
        ),
      ],
    );

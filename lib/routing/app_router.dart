import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Import all your screens here
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/home_screen.dart';
import '../screens/report_screen.dart' as report;
import '../screens/weather_safezone_screen.dart';
import '../screens/learn_screen.dart';
import '../screens/alerts_screen.dart';
import '../screens/change_password_screen.dart';
import '../screens/report_detail_screen.dart';
import '../screens/report_list_screen.dart';

// Error page
class ErrorPage extends StatelessWidget {
  final Exception? error;
  const ErrorPage({super.key, this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(error?.toString() ?? 'An error occurred', textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    );
  }
}

class AppRouter {
  static final GoRouter _router = GoRouter(
    initialLocation: '/splash',
    errorBuilder: (context, state) => ErrorPage(error: state.error),
    routes: [
      // Authentication Routes
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
GoRoute(
  path: '/report-list',
  name: 'report-list',
  builder: (context, state) => const ReportListScreen(),
),


      // Main App Routes
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/report',
        name: 'report',
        builder: (context, state) => const report.ReportScreen(),
      ),
      GoRoute(
        path: '/report/:reportId',
        name: 'report-detail',
        builder: (context, state) {
          final reportId = state.pathParameters['reportId']!;
          return ReportDetailScreen(reportId: reportId);
        },
      ),
      GoRoute(
        path: '/weather-safezone',
        name: 'weather-safezone',
        builder: (context, state) => const WeatherSafeZonesScreen(),
      ),
      GoRoute(
        path: '/learn',
        name: 'learn',
        builder: (context, state) => const LearnScreen(),
      ),
      GoRoute(
        path: '/alerts',
        name: 'alerts',
        builder: (context, state) => const AlertsScreen(),
      ),
      GoRoute(
        path: '/change-password',
        name: 'change-password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      // Removed the safe-zone-detail route here
    ],
    redirect: (context, state) {
      final user = FirebaseAuth.instance.currentUser;
      final loggedIn = user != null;

      final loggingInPaths = ['/login', '/signup', '/forgot-password', '/splash'];
      final isLoggingIn = loggingInPaths.contains(state.uri.path);

      // Allow splash screen without checks
      if (state.uri.path == '/splash') return null;

      // Redirect unauthorized users to splash screen
      if (!loggedIn && !isLoggingIn) return '/splash';

      // Prevent logged-in users from going to login or signup screens
      if (loggedIn && isLoggingIn) return '/home';

      return null;
    },
  );

  static GoRouter get router => _router;

  // Helper to handle notification deep linking or external navigation
  static void navigateFromNotification(Map<String, dynamic> data) {
    final router = _router;

    if (data.containsKey('route')) {
      final route = data['route'] as String;
      if (route == '/report') {
        router.goNamed('report');
      } else if (route == '/weather-safezone') {
        router.goNamed('weather-safezone');
      } else {
        router.goNamed('home');
      }
    }

    if (data.containsKey('reportId')) {
      router.goNamed('report-detail', pathParameters: {'reportId': data['reportId'].toString()});
    }
    // Removed zoneId related navigation
  }
}

// Navigation extension for ease of use
extension NavigationExtensions on BuildContext {
  void goToHome() => GoRouter.of(this).go('/home');
  void goToLogin() => GoRouter.of(this).go('/login');
  void goToReport() => GoRouter.of(this).go('/report');
  void goToReportDetail(String reportId) => GoRouter.of(this).go('/report/$reportId');
  // Removed goToSafeZoneDetail
}

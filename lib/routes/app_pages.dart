import 'package:flutter/material.dart';

import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/splash_screen.dart';

import '../features/home/screens/home_screen.dart';

import '../features/Profile/screens/profile_screen.dart';
import '../features/Profile/screens/edit_profile_screen.dart';

import '../features/attendance/screens/attendance_screen.dart';
import '../features/attendance/screens/checkin_screen.dart';
import '../features/attendance/screens/checkout_screen.dart';

import '../features/history/screens/history_screen.dart';

class AppPages {
  static Map<String, WidgetBuilder> routes = {
    '/': (context) => const SplashScreen(),

    // Auth
    '/login': (context) => const LoginScreen(),
    '/register': (context) => const RegisterScreen(),

    // Home
    '/home': (context) => const HomeScreen(),

    // Profile
    '/profile': (context) => const ProfileScreen(),
    '/edit-profile': (context) =>
        const EditProfileScreen(),

    // Attendance
    '/attendance': (context) =>
        const AttendanceScreen(),

    '/checkin': (context) =>
        const CheckinScreen(),

    '/checkout': (context) =>
        const CheckoutScreen(),

    // History
    '/history': (context) =>
        const HistoryScreen(),
  };
}

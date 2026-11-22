import 'package:e_season/screens/dashboard_screen.dart';
import 'package:e_season/screens/home_screen.dart';
import 'package:e_season/screens/login_screen.dart';
import 'package:e_season/screens/apply_ticket_screen.dart';
import 'package:e_season/screens/register_screen.dart';
import 'package:flutter/material.dart';

Map<String, WidgetBuilder> getRoutes() {
  return {
    '/': (context) => const HomeScreen(),
    '/login': (context) => const LoginScreen(),
    '/register': (context) => const RegisterScreen(),
    '/apply-season': (context) => const ApplyTicketScreen(),
    '/dashboard': (context) => const DashboardScreen(),
  };
}

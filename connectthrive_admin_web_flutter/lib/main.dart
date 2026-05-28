import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

void main() {
  runApp(const ConnectThriveAdminWeb());
}

class ConnectThriveAdminWeb extends StatelessWidget {
  const ConnectThriveAdminWeb({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ConnectThrive Admin Control Panel',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B2677),
          primary: const Color(0xFF1B2677),
        ),
        useMaterial3: true,
        fontFamily: 'Outfit',
        canvasColor: Colors.white,
        cardTheme: const CardThemeData(
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
        popupMenuTheme: const PopupMenuThemeData(
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
        menuTheme: const MenuThemeData(
          style: MenuStyle(
            backgroundColor: MaterialStatePropertyAll<Color>(Colors.white),
            surfaceTintColor: MaterialStatePropertyAll<Color>(
              Colors.transparent,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF5F7FA),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF1B2677), width: 1.5),
          ),
          labelStyle: const TextStyle(color: Colors.black54),
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
      },
    );
  }
}

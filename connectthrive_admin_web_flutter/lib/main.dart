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
          seedColor: const Color(0xFF225663),
          primary: const Color(0xFF225663),
        ),
        useMaterial3: true,
        fontFamily: 'Outfit',
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
      },
    );
  }
}

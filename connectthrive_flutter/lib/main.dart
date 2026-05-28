import 'package:flutter/material.dart';
import 'config/global_user.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GlobalUser.loadFromPrefs();
  runApp(const ConnectThriveApp());
}

class ConnectThriveApp extends StatelessWidget {
  const ConnectThriveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ConnectThrive',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF225663),
          primary: const Color(0xFF225663),
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      initialRoute: GlobalUser.isLoggedIn ? '/courses' : '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/courses': (context) => const DashboardScreen(),
      },
    );
  }
}

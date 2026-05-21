import 'package:flutter/material.dart';
import '../config/global_user.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String _currentSubScreen = "account"; // account | about | help

  String _getInitials(String name) {
    if (name.isEmpty) return "U";
    final parts = name.trim().split(" ");
    String initials = parts[0][0];
    if (parts.length > 1 && parts.last.isNotEmpty) {
      initials += parts.last[0];
    }
    return initials.toUpperCase();
  }

  Widget _buildSubScreen(String title, String content) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF225663)),
          onPressed: () {
            setState(() {
              _currentSubScreen = "account";
            });
          },
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF225663),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Text(
          content,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentSubScreen == "about") {
      return _buildSubScreen("About App", "hi (About App)");
    }
    if (_currentSubScreen == "help") {
      return _buildSubScreen("Help & Support", "hi (Help & Support)");
    }

    final String name = GlobalUser.username;
    final String phone = GlobalUser.mobileNumber.startsWith("+91")
        ? GlobalUser.mobileNumber
        : "+91 ${GlobalUser.mobileNumber}";

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Profile
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: const Color(0xFF225663),
                      child: Text(
                        _getInitials(name),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      phone,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              // Support Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Support",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        "About App",
                        style: TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                      trailing: const Text(
                        "›",
                        style: TextStyle(fontSize: 24, color: Colors.grey),
                      ),
                      onTap: () {
                        setState(() {
                          _currentSubScreen = "about";
                        });
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        "Help and Support",
                        style: TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                      trailing: const Text(
                        "›",
                        style: TextStyle(fontSize: 24, color: Colors.grey),
                      ),
                      onTap: () {
                        setState(() {
                          _currentSubScreen = "help";
                        });
                      },
                    ),
                    const Divider(height: 1),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              // Sign out
              TextButton(
                onPressed: () {
                  GlobalUser.clear();
                  Navigator.of(context).pushReplacementNamed('/login');
                },
                child: const Text(
                  "Sign out",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF225663),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "v1.0.0",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

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

  Widget _buildAboutSubScreen() {
    final releaseNotes = [
      {
        "title": "Batch-First Organization",
        "description": "Grouped course materials by assigned Batches at the top level for a clearer overview."
      },
      {
        "title": "Expandable Topics",
        "description": "Made individual Topics (Modules) within each batch expandable and collapsible to save vertical screen space."
      },
      {
        "title": "Setup & Transaction Segregation",
        "description": "Segregated videos under separate \"Setup Videos\" and \"Transaction Videos\" headings within each expanded topic."
      },
      {
        "title": "Cleaner Video Rows",
        "description": "Removed redundant Setup/Transaction badges next to each video's duration text for a cleaner, unified row layout."
      },
      {
        "title": "No Pagination Scrolling",
        "description": "Replaced page-based pagination controls with a natural scroll flow for all videos under a topic."
      },
      {
        "title": "Performance & Clean-up",
        "description": "Removed the outcome widget section and cleaned up unused compiler helpers."
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF225663)),
          onPressed: () {
            setState(() {
              _currentSubScreen = "account";
            });
          },
        ),
        title: const Text(
          "About App",
          style: TextStyle(
            color: Color(0xFF225663),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF225663).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        color: Color(0xFF225663),
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "ConnectThrive",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Version 2.3.3 (Build 23)",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 0.5, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 24),
              const Text(
                "What's New in Version 2.3.3",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 16),
              ...releaseNotes.map((note) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 3),
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          color: Color(0xFF225663),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.done_rounded,
                          color: Colors.white,
                          size: 10,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              note["title"]!,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              note["description"]!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentSubScreen == "about") {
      return _buildAboutSubScreen();
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
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
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
                onPressed: () async {
                  await GlobalUser.clear();
                  if (context.mounted) {
                    Navigator.of(context).pushReplacementNamed('/login');
                  }
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
                "v2.3.3",
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

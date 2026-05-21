import 'package:flutter/material.dart';
import 'batches_view.dart';
import 'modules_view.dart';
import 'instance_view.dart';
import 'batch_videos_view.dart';
import 'upload_video_view.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _activeTab = 'batchVideos';

  final Map<String, Widget> _views = const {
    'batchVideos': BatchVideosView(),
    'upload': UploadVideoView(),
    'batches': BatchesView(),
    'modules': ModulesView(),
    'instance': InstanceView(),
  };

  final List<Map<String, dynamic>> _menuItems = const [
    {"text": "BatchVideos", "icon": Icons.school, "path": "batchVideos"},
    {"text": "Upload Video", "icon": Icons.video_library, "path": "upload"},
    {"text": "Batches", "icon": Icons.class_, "path": "batches"},
    {"text": "Modules", "icon": Icons.menu_book, "path": "modules"},
    {"text": "Instance", "icon": Icons.dns, "path": "instance"},
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFE8EAF6),
      appBar: AppBar(
        title: const Text(
          "🎓 Admin Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF225663),
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: "Logout",
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      drawer: isWide
          ? null
          : Drawer(
              child: _buildSidebar(),
            ),
      body: Row(
        children: [
          if (isWide)
            Container(
              width: 260,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: _buildSidebar(),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: _views[_activeTab] ?? const Center(child: Text("Select a tab")),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            "Navigation Menu",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: _menuItems.length,
            itemBuilder: (context, index) {
              final item = _menuItems[index];
              final path = item['path'];
              final isSelected = _activeTab == path;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: ListTile(
                  leading: Icon(
                    item['icon'],
                    color: isSelected ? const Color(0xFF225663) : Colors.grey[600],
                  ),
                  title: Text(
                    item['text'],
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? const Color(0xFF225663) : Colors.black87,
                    ),
                  ),
                  selected: isSelected,
                  selectedTileColor: const Color(0xFF225663).withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onTap: () {
                    setState(() {
                      _activeTab = path;
                    });
                    if (Scaffold.of(context).isDrawerOpen) {
                      Navigator.pop(context);
                    }
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

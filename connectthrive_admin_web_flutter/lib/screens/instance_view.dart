import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api.dart';

class InstanceView extends StatefulWidget {
  const InstanceView({super.key});

  @override
  State<InstanceView> createState() => _InstanceViewState();
}

class _InstanceViewState extends State<InstanceView> {
  List<dynamic> _instances = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchInstances();
  }

  Future<void> _fetchInstances() async {
    setState(() {
      _loading = true;
    });

    final url = Uri.parse("$baseUrl/v2/admin/getAllInstances");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          _instances = jsonDecode(response.body) ?? [];
        });
      }
    } catch (e) {
      debugPrint("Error fetching instances: $e");
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _handleSubmit(String link, String username, String password, int? id) async {
    final isEdit = id != null;
    final url = isEdit
        ? Uri.parse("$baseUrl/v2/admin/instance/$id")
        : Uri.parse("$baseUrl/v2/admin/addInstance");

    final payload = {
      "link": link,
      "username": username,
      "password": password,
    };

    try {
      final response = isEdit
          ? await http.put(
              url,
              headers: {"Content-Type": "application/json"},
              body: jsonEncode(payload),
            )
          : await http.post(
              url,
              headers: {"Content-Type": "application/json"},
              body: jsonEncode(payload),
            );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEdit ? "Instance updated!" : "Instance added!")),
        );
        _fetchInstances();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Action failed")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error submitting instance")),
      );
    }
  }

  void _showInstanceDialog([dynamic instance]) {
    final isEdit = instance != null;
    final linkController = TextEditingController(text: isEdit ? instance['link'] : '');
    final userController = TextEditingController(text: isEdit ? instance['username'] : '');
    final passController = TextEditingController(text: isEdit ? instance['password'] : '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEdit ? "Edit Instance" : "Add New Instance"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: linkController,
                decoration: const InputDecoration(
                  labelText: "Instance Link*",
                  hintText: "Enter instance link URL",
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: userController,
                decoration: const InputDecoration(
                  labelText: "Instance Username*",
                  hintText: "Enter username",
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passController,
                decoration: const InputDecoration(
                  labelText: "Instance Password*",
                  hintText: "Enter password",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                final link = linkController.text.trim();
                final user = userController.text.trim();
                final pass = passController.text.trim();
                if (link.isNotEmpty && user.isNotEmpty && pass.isNotEmpty) {
                  Navigator.pop(context);
                  _handleSubmit(link, user, pass, isEdit ? instance['id'] : null);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B2677),
                foregroundColor: Colors.white,
              ),
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Add/Edit Instance",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B2677),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showInstanceDialog(),
                icon: const Icon(Icons.add),
                label: const Text("Add New Instance"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B2677),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "Manage practice instances for hands-on sessions",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          if (_loading)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF1B2677)),
            )
          else if (_instances.isEmpty)
            Center(
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Column(
                    children: [
                      const Icon(Icons.dns_outlined, size: 60, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        "No instances found",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _showInstanceDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text("Add Instance"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B2677),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Wrap(
              spacing: 24,
              runSpacing: 24,
              children: _instances.map((instance) {
                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: Colors.white,
                  child: Container(
                    width: 320,
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: Colors.blueAccent,
                              child: Icon(
                                Icons.verified_user_outlined,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    instance['username'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    instance['link'] ?? '',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Color(0xFF1B2677),
                              ),
                              onPressed: () => _showInstanceDialog(instance),
                              tooltip: "Edit",
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

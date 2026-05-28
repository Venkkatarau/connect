import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api.dart';

class ModulesView extends StatefulWidget {
  const ModulesView({super.key});

  @override
  State<ModulesView> createState() => _ModulesViewState();
}

class _ModulesViewState extends State<ModulesView> {
  List<dynamic> _modules = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchModules();
  }

  Future<void> _fetchModules() async {
    setState(() {
      _loading = true;
    });

    final url = Uri.parse("$baseUrl/v2/admin/getAllModules");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          _modules = jsonDecode(response.body) ?? [];
        });
      }
    } catch (e) {
      debugPrint("Error fetching modules: $e");
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _handleSubmit(String name, String description, String tier, int? id) async {
    final isEdit = id != null;
    final url = isEdit
        ? Uri.parse("$baseUrl/v2/admin/updateModule/$id")
        : Uri.parse("$baseUrl/v2/admin/addModule");

    final payload = {
      "name": name,
      "description": description,
      "tier": tier,
      "course": {"id": 1}
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
          SnackBar(content: Text(isEdit ? "Module updated!" : "Module added!")),
        );
        _fetchModules();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Action failed")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error submitting module")),
      );
    }
  }

  void _showModuleDialog([dynamic module]) {
    final isEdit = module != null;
    final nameController = TextEditingController(text: isEdit ? module['name'] : '');
    final descController = TextEditingController(text: isEdit ? module['description'] : '');
    String tier = isEdit ? (module['tier'] ?? 'free').toString().toLowerCase() : 'free';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Text(isEdit ? "Edit Module" : "Add New Module"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: "Module Name*",
                      hintText: "Enter module name",
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(
                      labelText: "Module Description",
                      hintText: "Enter module description",
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Text("Module Type: ", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 16),
                      Radio<String>(
                        value: 'free',
                        groupValue: tier,
                        onChanged: (val) {
                          setModalState(() {
                            tier = val!;
                          });
                        },
                      ),
                      const Text("Free"),
                      const SizedBox(width: 16),
                      Radio<String>(
                        value: 'paid',
                        groupValue: tier,
                        onChanged: (val) {
                          setModalState(() {
                            tier = val!;
                          });
                        },
                      ),
                      const Text("Paid"),
                    ],
                  )
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isNotEmpty) {
                      Navigator.pop(context);
                      _handleSubmit(name, descController.text.trim(), tier, isEdit ? module['id'] : null);
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
                "Add/Edit Modules",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B2677),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showModuleDialog(),
                icon: const Icon(Icons.add),
                label: const Text("Add New Module"),
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
            "Manage your curriculum modules - create new ones or modify existing modules",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          if (_loading)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF1B2677)),
            )
          else if (_modules.isEmpty)
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
                      const Icon(Icons.book_outlined, size: 60, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        "No modules found",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _showModuleDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text("Add Module"),
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
              children: _modules.map((module) {
                final isFree = (module['tier'] ?? '').toString().toLowerCase() == 'free';
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
                            CircleAvatar(
                              backgroundColor:
                                  const Color(0xFF1B2677).withOpacity(0.1),
                              child: const Icon(
                                Icons.collections_bookmark,
                                color: Color(0xFF1B2677),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    module['name'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    module['description'] ?? 'No description',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isFree
                                    ? Colors.green.withOpacity(0.1)
                                    : const Color(0xFF1B2677).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isFree ? "Free" : "Paid",
                                style: TextStyle(
                                  color: isFree ? Colors.green : const Color(0xFF1B2677),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Color(0xFF1B2677),
                              ),
                              onPressed: () => _showModuleDialog(module),
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

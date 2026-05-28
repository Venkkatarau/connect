import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api.dart';

class BatchesView extends StatefulWidget {
  const BatchesView({super.key});

  @override
  State<BatchesView> createState() => _BatchesViewState();
}

class _BatchesViewState extends State<BatchesView> {
  List<dynamic> _batches = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchBatches();
  }

  Future<void> _fetchBatches() async {
    setState(() {
      _loading = true;
    });

    final url = Uri.parse("$baseUrl/v1/admin/getAllBatches");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          _batches = jsonDecode(response.body) ?? [];
        });
      }
    } catch (e) {
      debugPrint("Error fetching batches: $e");
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _handleSubmit(String name, int? id) async {
    final isEdit = id != null;
    final url = isEdit
        ? Uri.parse("$baseUrl/v1/admin/updateBatch/$id")
        : Uri.parse("$baseUrl/v1/admin/addBatch");

    try {
      final response = isEdit
          ? await http.put(
              url,
              headers: {"Content-Type": "application/json"},
              body: jsonEncode({"name": name}),
            )
          : await http.post(
              url,
              headers: {"Content-Type": "application/json"},
              body: jsonEncode({"name": name}),
            );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEdit ? "Batch updated!" : "Batch added!")),
        );
        _fetchBatches();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Action failed")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error submitting batch")),
      );
    }
  }

  void _showBatchDialog([dynamic batch]) {
    final isEdit = batch != null;
    final controller = TextEditingController(text: isEdit ? batch['name'] : '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEdit ? "Edit Batch" : "Add New Batch"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: "Batch Name*",
              hintText: "Enter batch name",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  Navigator.pop(context);
                  _handleSubmit(name, isEdit ? batch['id'] : null);
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
                "Add/Edit Batches",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B2677),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showBatchDialog(),
                icon: const Icon(Icons.add),
                label: const Text("Add New Batch"),
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
            "Manage your batches - create new ones or modify existing batches",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          if (_loading)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF1B2677)),
            )
          else if (_batches.isEmpty)
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
                      const Icon(Icons.group_outlined, size: 60, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        "No batches found",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _showBatchDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text("Add Batch"),
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
              children: _batches.map((batch) {
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
                                Icons.group,
                                color: Color(0xFF1B2677),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                batch['name'] ?? '',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "ID: ${batch['id']}",
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Color(0xFF1B2677),
                              ),
                              onPressed: () => _showBatchDialog(batch),
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

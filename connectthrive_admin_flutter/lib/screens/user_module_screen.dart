import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api.dart';

class UserModuleScreen extends StatefulWidget {
  const UserModuleScreen({super.key});

  @override
  State<UserModuleScreen> createState() => _UserModuleScreenState();
}

class _UserModuleScreenState extends State<UserModuleScreen> {
  List<dynamic> _users = [];
  List<dynamic> _filteredUsers = [];
  List<dynamic> _batches = [];
  bool _loading = false;
  bool _batchLoading = false;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _fetchBatches();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _loading = true;
    });

    final url = Uri.parse("$baseUrl/v1/getUserList");
    try {
      debugPrint("[API Request] GET: $url");
      final response = await http.get(url);
      debugPrint(
        "[API Response] GET: $url | Status: ${response.statusCode} | Body: ${response.body}",
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _users = data;
          _filteredUsers = data;
        });
        _applySearch(_searchQuery);
      } else {
        debugPrint("Error fetching users status: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching users: $e");
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _fetchBatches() async {
    final url = Uri.parse("$baseUrl/v1/admin/getAllBatches");
    try {
      debugPrint("[API Request] GET: $url");
      final response = await http.get(url);
      debugPrint(
        "[API Response] GET: $url | Status: ${response.statusCode} | Body: ${response.body}",
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _batches = data;
        });
      }
    } catch (e) {
      debugPrint("Error fetching batches: $e");
    }
  }

  void _applySearch(String text) {
    setState(() {
      _searchQuery = text;
      if (text.trim().isEmpty) {
        _filteredUsers = _users;
      } else {
        final lower = text.toLowerCase();
        _filteredUsers = _users.where((u) {
          final username = (u['username'] ?? '').toString().toLowerCase();
          final mobile = (u['mobileNumber'] ?? '').toString();
          return username.contains(lower) || mobile.contains(text);
        }).toList();
      }
    });
  }

  Future<void> _updateUserBatch(int userId, Set<int> batchIds) async {
    setState(() {
      _batchLoading = true;
    });

    final queryParams = batchIds.map((id) => "batchIds=$id").join("&");
    final url = Uri.parse("$baseUrl/v1/users/updateBatch/$userId?$queryParams");
    try {
      debugPrint("[API Request] PUT: $url");
      final response = await http.put(url);
      debugPrint(
        "[API Response] PUT: $url | Status: ${response.statusCode} | Body: ${response.body}",
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Batch updated successfully!")),
        );
        _fetchUsers();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Failed to update batch")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Connection error. Try again.")),
      );
    } finally {
      setState(() {
        _batchLoading = false;
      });
    }
  }

  void _showBatchSelectionDialog(dynamic user) {
    Set<int> selectedBatchIds = {};
    if (user['batchIds'] != null && user['batchIds'] is List) {
      selectedBatchIds = (user['batchIds'] as List)
          .map((e) => int.tryParse(e.toString()) ?? 0)
          .toSet();
    } else if (user['batchId'] != null) {
      selectedBatchIds = {int.tryParse(user['batchId'].toString()) ?? 0};
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Assign Batch to ${user['username']}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF225663),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  if (_batches.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        "No batches available",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _batches.length,
                        itemBuilder: (context, index) {
                          final batch = _batches[index];
                          final batchId =
                              int.tryParse(batch['id'].toString()) ?? 0;
                          final isSelected = selectedBatchIds.contains(batchId);
                          return ListTile(
                            leading: Icon(
                              isSelected
                                  ? Icons.check_box
                                  : Icons.check_box_outline_blank,
                              color: const Color(0xFF225663),
                            ),
                            title: Text(batch['name'] ?? ''),
                            onTap: () {
                              setModalState(() {
                                if (isSelected) {
                                  selectedBatchIds.remove(batchId);
                                } else {
                                  selectedBatchIds.add(batchId);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: (_batchLoading || selectedBatchIds.isEmpty)
                        ? null
                        : () async {
                            Navigator.pop(context);
                            await _updateUserBatch(
                              user['id'],
                              selectedBatchIds,
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF225663),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _batchLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "Submit",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F4F9),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  onChanged: _applySearch,
                  decoration: const InputDecoration(
                    hintText: "Search by name or phone...",
                    border: InputBorder.none,
                    icon: Icon(Icons.search, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF225663),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchUsers,
                        color: const Color(0xFF225663),
                        child: _filteredUsers.isEmpty
                            ? const Center(
                                child: Text(
                                  "No users found",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _filteredUsers.length,
                                itemBuilder: (context, index) {
                                  final user = _filteredUsers[index];
                                  return Card(
                                    color: Colors.white,
                                    margin: const EdgeInsets.only(bottom: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.all(16),
                                      title: Text(
                                        user['username'] ?? '',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      subtitle: Padding(
                                        padding: const EdgeInsets.only(
                                          top: 8.0,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Phone: ${user['mobileNumber'] ?? ''}",
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "Batch: ${user['batchNames'] != null && (user['batchNames'] as List).isNotEmpty ? (user['batchNames'] as List).join(', ') : (user['batchName'] ?? 'No Batch Assigned')}",
                                            ),
                                          ],
                                        ),
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Color(0xFF225663),
                                        ),
                                        onPressed: () =>
                                            _showBatchSelectionDialog(user),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

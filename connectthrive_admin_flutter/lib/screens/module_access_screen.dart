import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api.dart';

class ModuleAccessScreen extends StatefulWidget {
  const ModuleAccessScreen({super.key});

  @override
  State<ModuleAccessScreen> createState() => _ModuleAccessScreenState();
}

class _ModuleAccessScreenState extends State<ModuleAccessScreen> {
  List<dynamic> _requests = [];
  List<dynamic> _filteredRequests = [];
  bool _loading = true;
  String _searchQuery = "";
  final List<int> _loadingIds = [];

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    setState(() {
      _loading = true;
    });

    final url = Uri.parse("$baseUrl/api/modules/pending-requests");
    try {
      debugPrint("[API Request] GET: $url");
      final response = await http.get(url);
      debugPrint("[API Response] GET: $url | Status: ${response.statusCode} | Body: ${response.body}");
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _requests = data;
          _filteredRequests = data;
        });
        _applySearch(_searchQuery);
      }
    } catch (e) {
      debugPrint("Error fetching requests: $e");
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _applySearch(String text) {
    setState(() {
      _searchQuery = text;
      if (text.trim().isEmpty) {
        _filteredRequests = _requests;
      } else {
        final lower = text.toLowerCase();
        _filteredRequests = _requests.where((r) {
          final username = (r['username'] ?? '').toString().toLowerCase();
          final mobile = (r['mobileNumber'] ?? '').toString().toLowerCase();
          return username.contains(lower) || mobile.contains(lower);
        }).toList();
      }
    });
  }

  Future<void> _approveRequest(int id) async {
    setState(() {
      _loadingIds.add(id);
    });

    final url = Uri.parse("$baseUrl/api/modules/approve/$id");
    try {
      debugPrint("[API Request] GET: $url");
      final response = await http.get(url);
      debugPrint("[API Response] GET: $url | Status: ${response.statusCode} | Body: ${response.body}");
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == false) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? "Error approving request")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Request approved successfully")),
          );
          // Remove from local list
          setState(() {
            _requests.removeWhere((r) => r['id'] == id);
            _filteredRequests.removeWhere((r) => r['id'] == id);
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to approve request")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Connection error. Try again.")),
      );
    } finally {
      setState(() {
        _loadingIds.remove(id);
      });
    }
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
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  onChanged: _applySearch,
                  decoration: const InputDecoration(
                    hintText: "Search by name or mobile number...",
                    border: InputBorder.none,
                    icon: Icon(Icons.search, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(color: Color(0xFF225663)),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchRequests,
                        color: const Color(0xFF225663),
                        child: _filteredRequests.isEmpty
                            ? const Center(
                                child: Text("No pending requests found", style: TextStyle(color: Colors.grey)),
                              )
                            : ListView.builder(
                                itemCount: _filteredRequests.length,
                                itemBuilder: (context, index) {
                                  final req = _filteredRequests[index];
                                  final reqId = req['id'];
                                  final isApproving = _loadingIds.contains(reqId);

                                  return Card(
                                    color: Colors.white,
                                    margin: const EdgeInsets.only(bottom: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    elevation: 2,
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "Name: ${req['username'] ?? ''}",
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                ),
                                                const SizedBox(height: 6),
                                                Text("Mobile No: ${req['mobileNumber'] ?? ''}"),
                                                const SizedBox(height: 4),
                                                Text("Module Name: ${req['moduleName'] ?? ''}"),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          isApproving
                                              ? const SizedBox(
                                                  width: 24,
                                                  height: 24,
                                                  child: CircularProgressIndicator(
                                                    color: Colors.green,
                                                    strokeWidth: 2,
                                                  ),
                                                )
                                              : CircleAvatar(
                                                  backgroundColor: Colors.green.withOpacity(0.1),
                                                  child: IconButton(
                                                    icon: const Icon(Icons.check, color: Colors.green),
                                                    onPressed: () => _approveRequest(reqId),
                                                  ),
                                                ),
                                        ],
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

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api.dart';
import '../config/global_user.dart';
import '../models/module.dart';
import 'concept_video_screen.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  List<Module> _modules = [];
  int? _expandedModuleId;
  bool _loading = true;
  int? _accessLoadingModuleId;

  @override
  void initState() {
    super.initState();
    _fetchModules();
  }

  Future<void> _fetchModules() async {
    setState(() {
      _loading = true;
    });
    try {
      final url = '$baseUrl/v1/admin/${GlobalUser.batchId}/modules?userId=${GlobalUser.userId}';
      debugPrint("[API Request] GET: $url");
      final res = await http.get(Uri.parse(url));
      debugPrint("[API Response] GET: $url | Status: ${res.statusCode} | Body: ${res.body}");
      if (res.statusCode == 200) {
        final List data = json.decode(res.body);
        setState(() {
          _modules = data.map((m) => Module.fromJson(m)).toList();
        });
      } else {
        setState(() {
          _modules = [];
        });
      }
    } catch (e) {
      debugPrint("Error fetching modules: $e");
      setState(() {
        _modules = [];
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _requestModuleAccess(int moduleId) async {
    setState(() {
      _accessLoadingModuleId = moduleId;
    });
    try {
      final url = '$baseUrl/api/modules/$moduleId/request-access?userId=${GlobalUser.userId}';
      debugPrint("[API Request] POST: $url");
      final res = await http.post(Uri.parse(url));
      debugPrint("[API Response] POST: $url | Status: ${res.statusCode} | Body: ${res.body}");

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Access request sent successfully')),
          );
        }
      } else {
        throw Exception("Failed request");
      }
    } catch (e) {
      debugPrint("Error requesting access: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to request access. Please try again.')),
        );
      }
    } finally {
      setState(() {
        _accessLoadingModuleId = null;
      });
    }
  }

  Widget _buildOutcomeSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Outcome",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF225663),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Connect Thrive Technologies is your all-in-one mobile app to learn Oracle Fusion Financials on the go. "
            "Access module-wise concept videos (GL, AP, AR, FA, CM), real-time scenarios, interview Q&A, and advanced topics—all in one place.",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConceptRow(Concept concept, Module module) {
    final thumbnailUrl = Uri.encodeFull('https://dbp6bbvk4lzrp.cloudfront.net/${concept.thumbnailFileName}');

    return InkWell(
      onTap: () {
        if (module.accessible) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ConceptVideoScreen(concept: concept, moduleName: module.name),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This module is locked. Please request access.')),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    thumbnailUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey[300],
                      child: const Icon(Icons.video_library_outlined, color: Colors.grey),
                    ),
                  ),
                ),
                if (module.accessible)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                concept.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: module.accessible ? Colors.black87 : Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleCard(Module module) {
    final isExpanded = _expandedModuleId == module.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: module.accessible ? Colors.grey[200]! : Colors.red[100]!,
          width: 1,
        ),
      ),
      color: module.accessible ? Colors.white : const Color(0xFFF9F9F9),
      child: Column(
        children: [
          ListTile(
            onTap: () {
              setState(() {
                _expandedModuleId = isExpanded ? null : module.id;
              });
            },
            title: Text(
              module.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: module.accessible ? const Color(0xFF225663) : Colors.black54,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!module.accessible) ...[
                  _accessLoadingModuleId == module.id
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
                        )
                      : IconButton(
                          icon: const Icon(Icons.lock_outline, color: Colors.redAccent),
                          onPressed: () => _requestModuleAccess(module.id),
                        ),
                ],
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: const Color(0xFF225663),
                ),
              ],
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (module.concepts.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        "SetUp:——>",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey),
                      ),
                    ),
                    ...module.concepts.map((c) => _buildConceptRow(c, module)),
                  ],
                  if (module.transactionConcepts.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        "Transaction:—>",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey),
                      ),
                    ),
                    ...module.transactionConcepts.map((t) => _buildConceptRow(t, module)),
                  ],
                  if (module.concepts.isEmpty && module.transactionConcepts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        "No videos available in this module.",
                        style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F4F9),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF225663)),
              )
            : RefreshIndicator(
                color: const Color(0xFF225663),
                onRefresh: _fetchModules,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16, top: 12),
                      child: Text(
                        "Oracle Fusion Financials",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    _buildOutcomeSection(),
                    ..._modules.map((m) => _buildModuleCard(m)),
                  ],
                ),
              ),
      ),
    );
  }
}

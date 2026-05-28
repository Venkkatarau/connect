import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api.dart';

class BatchVideosView extends StatefulWidget {
  const BatchVideosView({super.key});

  @override
  State<BatchVideosView> createState() => _BatchVideosViewState();
}

class _BatchVideosViewState extends State<BatchVideosView> {
  List<dynamic> _modules = [];
  List<dynamic> _batches = [];
  bool _loading = true;
  final String _thumbnailBaseUrl = 'https://dbp6bbvk4lzrp.cloudfront.net/';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _loading = true;
    });

    final modulesUrl = Uri.parse("$baseUrl/v2/conceptsGroupByModule");
    final batchesUrl = Uri.parse("$baseUrl/v1/admin/getAllBatches");

    try {
      debugPrint("[API Request] GET: $modulesUrl");
      debugPrint("[API Request] GET: $batchesUrl");
      final responses = await Future.wait([
        http.get(modulesUrl),
        http.get(batchesUrl),
      ]);

      debugPrint(
        "[API Response] GET: $modulesUrl | Status: ${responses[0].statusCode}",
      );
      _printLongString("Body: ${responses[0].body}");
      debugPrint(
        "[API Response] GET: $batchesUrl | Status: ${responses[1].statusCode}",
      );
      _printLongString("Body: ${responses[1].body}");

      if (responses[0].statusCode == 200 && responses[1].statusCode == 200) {
        if (!mounted) return;
        final rawModules = jsonDecode(responses[0].body) ?? [];

        setState(() {
          _modules = rawModules;
          _batches = jsonDecode(responses[1].body) ?? [];
        });
      }
    } catch (e) {
      debugPrint("Error fetching batch videos data: $e");
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _syncBatchConcepts(int conceptId, List<int> batchIds) async {
    final url = Uri.parse("$baseUrl/v1/admin/syncBatchConcepts");
    final payload = {"batchId": batchIds, "conceptIds": conceptId};
    final body = jsonEncode(payload);

    try {
      debugPrint("[API Request] POST: $url | Body: $body");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );
      debugPrint(
        "[API Response] POST: $url | Status: ${response.statusCode} | Body: ${response.body}",
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Batch concepts synced successfully")),
        );
        _fetchData();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Sync failed")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Error during sync")));
    }
  }

  void _showBatchSyncDialog(dynamic concept) {
    // Check which batches currently have this concept
    final List<dynamic> currentBatches = concept['batchList'] ?? [];
    final List<int> selectedBatchIds = currentBatches
        .map<int>((b) => b['id'] as int)
        .toList();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Text("Select Batches for '${concept['title']}'"),
              content: SizedBox(
                width: 320,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _batches.length,
                  itemBuilder: (context, index) {
                    final batch = _batches[index];
                    final batchId = batch['id'] as int;
                    final isChecked = selectedBatchIds.contains(batchId);

                    return CheckboxListTile(
                      title: Text(batch['name'] ?? ''),
                      value: isChecked,
                      onChanged: (val) {
                        setModalState(() {
                          if (val == true) {
                            selectedBatchIds.add(batchId);
                          } else {
                            selectedBatchIds.remove(batchId);
                          }
                        });
                      },
                      activeColor: const Color(0xFF1B2677),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _syncBatchConcepts(concept['id'], selectedBatchIds);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B2677),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Sync"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteConcept(int conceptId) async {
    final url = Uri.parse("$baseUrl/v2/admin/concepts/$conceptId");
    try {
      debugPrint("[API Request] DELETE: $url");
      final response = await http.delete(url);
      debugPrint(
        "[API Response] DELETE: $url | Status: ${response.statusCode}",
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Video deleted successfully")),
        );
        _fetchData();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Failed to delete video")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Error deleting video")));
    }
  }

  void _confirmDeleteConcept(dynamic concept) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Delete '${concept['title']}'?"),
          content: const Text(
            "Are you sure you want to delete this video lecture? This action cannot be undone.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteConcept(concept['id'] as int);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteBatch(int batchId) async {
    final url = Uri.parse("$baseUrl/v1/admin/deleteBatch/$batchId");
    try {
      debugPrint("[API Request] DELETE: $url");
      final response = await http.delete(url);
      debugPrint(
        "[API Response] DELETE: $url | Status: ${response.statusCode} | Body: ${response.body}",
      );
      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Batch deleted successfully")),
          );
        }
        _fetchData();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to delete batch")),
          );
        }
      }
    } catch (e) {
      debugPrint("Error deleting batch: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Error deleting batch")));
      }
    }
  }

  void _confirmDeleteBatch(int batchId, String batchName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Batch"),
          content: const Text("Do you want to delete this batch?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteBatch(batchId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildConceptBox(dynamic concept) {
    final String thumbUrl =
        "$_thumbnailBaseUrl${concept['thumbnailFileName'] ?? ''}";
    final List<dynamic> currentBatches = concept['batchList'] ?? [];
    final String assignedBatches = currentBatches
        .map((b) => b['name'] ?? '')
        .join(', ');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF1F3F5)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.network(
              thumbUrl,
              width: 90,
              height: 55,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 90,
                  height: 55,
                  color: Colors.grey[300],
                  child: const Icon(Icons.video_library, color: Colors.grey),
                );
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  concept['title'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Assigned Batches: ${assignedBatches.isEmpty ? 'None' : assignedBatches}",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.grey),
            onPressed: () => _showBatchSyncDialog(concept),
            tooltip: "Assign Batches",
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => _confirmDeleteConcept(concept),
            tooltip: "Delete Video",
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1B2677)),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Batch Videos Alignment",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B2677),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "View and sync video assignments per batch",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ..._batches.map((batch) {
              final batchId = batch['id'];
              final batchName = batch['name'] ?? '';

              // Filter modules containing concepts in this batch
              final List<dynamic> batchModules = [];
              for (var module in _modules) {
                final List<dynamic> concepts = (module['concepts'] ?? []).where(
                  (c) {
                    final List<dynamic> bl = c['batchList'] ?? [];
                    return bl.any((b) => b['id'] == batchId);
                  },
                ).toList();

                final List<dynamic> transConcepts =
                    (module['transactionConcepts'] ?? []).where((c) {
                      final List<dynamic> bl = c['batchList'] ?? [];
                      return bl.any((b) => b['id'] == batchId);
                    }).toList();

                if (concepts.isNotEmpty || transConcepts.isNotEmpty) {
                  batchModules.add({
                    ...module,
                    "concepts": concepts,
                    "transactionConcepts": transConcepts,
                  });
                }
              }

              final totalVideos = batchModules.fold<int>(0, (acc, m) {
                return acc +
                    (m['concepts'] as List).length +
                    (m['transactionConcepts'] as List).length;
              });

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ExpansionTile(
                  onExpansionChanged: (isExpanded) {
                    if (isExpanded) {
                      debugPrint(
                        "--- Batch Expanded: $batchName (ID: $batchId) ---",
                      );
                      for (var module in batchModules) {
                        debugPrint(
                          "  Module: ${module['name']} (ID: ${module['id']})",
                        );
                        final concepts = module['concepts'] as List;
                        final transConcepts =
                            module['transactionConcepts'] as List;
                        for (var c in concepts) {
                          debugPrint(
                            "    - [SetUp] ${c['title']} (ID: ${c['id']}, File: ${c['videoUrl']})",
                          );
                        }
                        for (var c in transConcepts) {
                          debugPrint(
                            "    - [Transaction] ${c['title']} (ID: ${c['id']}, File: ${c['videoUrl']})",
                          );
                        }
                      }
                      debugPrint(
                        "---------------------------------------------",
                      );
                    }
                  },
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              batchName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Color(0xFF1B2677),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              "Batch ID: $batchId",
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(
                          "$totalVideos Videos",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor: const Color(0xFF1B2677),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                        ),
                        onPressed: () =>
                            _confirmDeleteBatch(batchId as int, batchName),
                        tooltip: "Delete Batch",
                      ),
                    ],
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: batchModules.isEmpty
                          ? const Text(
                              "No videos assigned to this batch.",
                              style: TextStyle(color: Colors.grey),
                            )
                          : Column(
                              children: batchModules.map<Widget>((module) {
                                final List<dynamic> concepts =
                                    module['concepts'] ?? [];
                                final List<dynamic> transConcepts =
                                    module['transactionConcepts'] ?? [];

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey[200]!,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.white,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        module['name'] ?? '',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const Divider(height: 24),
                                      if (concepts.isNotEmpty) ...[
                                        const Text(
                                          "SetUp: ——>",
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ...concepts.map(_buildConceptBox),
                                      ],
                                      if (transConcepts.isNotEmpty) ...[
                                        if (concepts.isNotEmpty)
                                          const SizedBox(height: 12),
                                        const Text(
                                          "Transaction: ——>",
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ...transConcepts.map(_buildConceptBox),
                                      ],
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _printLongString(String text) {
    final RegExp pattern = RegExp('.{1,800}');
    pattern.allMatches(text).forEach((match) => debugPrint(match.group(0)));
  }
}

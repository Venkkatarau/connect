import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api.dart';
import '../config/global_user.dart';
import '../models/module.dart';
import '../utils/video_duration_manager.dart';
import 'concept_video_screen.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  List<Module> _modules = [];
  int? _expandedBatchId;
  bool _loading = true;
  int? _accessLoadingModuleId;
  final Set<String> _expandedTopicKeys = {};

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
      // Changed API to use /v1/admin/users/{userId}/modules
      final url = '$baseUrl/v1/admin/users/${GlobalUser.userId}/modules';
      debugPrint("[API Request] GET: $url");
      final res = await http.get(Uri.parse(url));
      debugPrint(
        "[API Response] GET: $url | Status: ${res.statusCode} | Body: ${res.body}",
      );
      if (res.statusCode == 200) {
        final List data = json.decode(res.body);
        setState(() {
          _modules = data.map((m) => Module.fromJson(m)).toList();
        });
        _precacheThumbnails();
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

  void _precacheThumbnails() {
    if (!mounted) return;
    for (final module in _modules) {
      for (final concept in module.concepts) {
        _precacheSingleThumbnail(concept.thumbnailFileName);
      }
      for (final concept in module.transactionConcepts) {
        _precacheSingleThumbnail(concept.thumbnailFileName);
      }
    }
  }

  void _precacheSingleThumbnail(String fileName) {
    try {
      final urlText = Uri.encodeFull(
        'https://dbp6bbvk4lzrp.cloudfront.net/$fileName',
      );
      final provider = ResizeImage(
        NetworkImage(urlText),
        width: 150,
        height: 150,
      );
      precacheImage(provider, context).catchError((e) {
        debugPrint("Failed to precache image $fileName: $e");
      });
    } catch (e) {
      debugPrint("Error creating image provider for precaching: $e");
    }
  }

  Future<void> _requestModuleAccess(int moduleId) async {
    setState(() {
      _accessLoadingModuleId = moduleId;
    });
    try {
      final url =
          '$baseUrl/api/modules/$moduleId/request-access?userId=${GlobalUser.userId}';
      debugPrint("[API Request] POST: $url");
      final res = await http.post(Uri.parse(url));
      debugPrint(
        "[API Response] POST: $url | Status: ${res.statusCode} | Body: ${res.body}",
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                data['message'] ?? 'Access request sent successfully',
              ),
            ),
          );
        }
      } else {
        throw Exception("Failed request");
      }
    } catch (e) {
      debugPrint("Error requesting access: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to request access. Please try again.'),
          ),
        );
      }
    } finally {
      setState(() {
        _accessLoadingModuleId = null;
      });
    }
  }

  List<_BatchGroup> _getBatchGroups() {
    final Map<int, _BatchGroup> batchMap = {};

    for (final module in _modules) {
      void addConceptToBatch(Concept concept) {
        for (final batch in concept.batchList) {
          final bg = batchMap.putIfAbsent(
            batch.id,
            () => _BatchGroup(id: batch.id, name: batch.name),
          );

          _TopicGroup? tg;
          for (final existingTg in bg.topics) {
            if (existingTg.id == module.id) {
              tg = existingTg;
              break;
            }
          }
          if (tg == null) {
            tg = _TopicGroup(module: module);
            bg.topics.add(tg);
          }

          tg.videos.add(concept);
        }
      }

      for (final concept in module.concepts) {
        addConceptToBatch(concept);
      }
      for (final concept in module.transactionConcepts) {
        addConceptToBatch(concept);
      }
    }

    final sortedBatches = batchMap.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    for (final bg in sortedBatches) {
      bg.topics.sort((a, b) => a.id.compareTo(b.id));
    }

    return sortedBatches;
  }

  Widget _buildConceptRow(
    Concept concept,
    Module module,
    List<Concept> allVideos,
  ) {
    final thumbnailUrl = Uri.encodeFull(
      'https://dbp6bbvk4lzrp.cloudfront.net/${concept.thumbnailFileName}',
    );

    return InkWell(
      onTap: () async {
        if (module.accessible) {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ConceptVideoScreen(
                concept: concept,
                moduleName: module.name,
                allVideos: allVideos,
              ),
            ),
          );
          if (mounted) {
            setState(() {});
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This module is locked. Please request access.'),
            ),
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
                    cacheWidth: 150,
                    cacheHeight: 150,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.video_library_outlined,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    concept.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                      color: module.accessible
                          ? Colors.black87
                          : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  VideoDurationWidget(videoUrl: concept.videoUrl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBatchCard(_BatchGroup batchGroup) {
    final isExpanded = _expandedBatchId == batchGroup.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      color: Colors.white,
      child: Column(
        children: [
          ListTile(
            onTap: () {
              setState(() {
                _expandedBatchId = isExpanded ? null : batchGroup.id;
              });
            },
            title: Text(
              batchGroup.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF225663),
              ),
            ),
            trailing: Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: const Color(0xFF225663),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: batchGroup.topics.map((topicGroup) {
                  final allVideos = topicGroup.videos;
                  final String topicKey = "${batchGroup.id}_${topicGroup.id}";
                  final isTopicExpanded = _expandedTopicKeys.contains(topicKey);

                  final setupVideos = allVideos
                      .where((c) => c.videoType.toLowerCase().contains('setup'))
                      .toList()
                      .reversed
                      .toList();
                  final transactionVideos = allVideos
                      .where(
                        (c) => !c.videoType.toLowerCase().contains('setup'),
                      )
                      .toList()
                      .reversed
                      .toList();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: topicGroup.module.accessible
                            ? Colors.grey[100]!
                            : Colors.red[50]!,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: () {
                            setState(() {
                              if (isTopicExpanded) {
                                _expandedTopicKeys.remove(topicKey);
                              } else {
                                _expandedTopicKeys.add(topicKey);
                              }
                            });
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Icon(
                                      topicGroup.module.accessible
                                          ? Icons.folder_open_outlined
                                          : Icons.folder_off_outlined,
                                      size: 16,
                                      color: topicGroup.module.accessible
                                          ? const Color(0xFF225663)
                                          : Colors.red[300],
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        topicGroup.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: topicGroup.module.accessible
                                              ? const Color(0xFF225663)
                                              : Colors.black54,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!topicGroup.module.accessible) ...[
                                    _accessLoadingModuleId ==
                                            topicGroup.module.id
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.grey,
                                            ),
                                          )
                                        : InkWell(
                                            onTap: () => _requestModuleAccess(
                                              topicGroup.module.id,
                                            ),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              margin: const EdgeInsets.only(
                                                right: 8,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.red[50],
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.lock_outline,
                                                    color: Colors.redAccent,
                                                    size: 12,
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    "Request Access",
                                                    style: TextStyle(
                                                      color: Colors.redAccent,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                  ],
                                  Icon(
                                    isTopicExpanded
                                        ? Icons.keyboard_arrow_up
                                        : Icons.keyboard_arrow_down,
                                    color: const Color(0xFF225663),
                                    size: 20,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (isTopicExpanded) ...[
                          const Divider(height: 16, thickness: 0.5),
                          if (allVideos.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                "No videos available in this topic.",
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey,
                                ),
                              ),
                            )
                          else ...[
                            if (setupVideos.isNotEmpty) ...[
                              const Padding(
                                padding: EdgeInsets.only(top: 6, bottom: 4),
                                child: Text(
                                  "SETUP VIDEOS",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 10,
                                    letterSpacing: 1.0,
                                    color: Color(0xFF225663),
                                  ),
                                ),
                              ),
                              ...setupVideos.map(
                                (c) => _buildConceptRow(
                                  c,
                                  topicGroup.module,
                                  setupVideos,
                                ),
                              ),
                            ],
                            if (transactionVideos.isNotEmpty) ...[
                              const Padding(
                                padding: EdgeInsets.only(top: 10, bottom: 4),
                                child: Text(
                                  "TRANSACTION VIDEOS",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 10,
                                    letterSpacing: 1.0,
                                    color: Color(0xFFD97706),
                                  ),
                                ),
                              ),
                              ...transactionVideos.map(
                                (c) => _buildConceptRow(
                                  c,
                                  topicGroup.module,
                                  transactionVideos,
                                ),
                              ),
                            ],
                          ],
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
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    ..._getBatchGroups().map((bg) => _buildBatchCard(bg)),
                  ],
                ),
              ),
      ),
    );
  }
}

class VideoDurationWidget extends StatefulWidget {
  final String videoUrl;
  const VideoDurationWidget({super.key, required this.videoUrl});

  @override
  State<VideoDurationWidget> createState() => _VideoDurationWidgetState();
}

class _VideoDurationWidgetState extends State<VideoDurationWidget> {
  String _durationText = "";
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _loadDuration();
  }

  @override
  void didUpdateWidget(covariant VideoDurationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadDuration();
  }

  Future<void> _loadDuration() async {
    try {
      final duration = await VideoDurationManager.getDuration(widget.videoUrl);
      if (mounted && !_disposed) {
        setState(() {
          _durationText = duration;
        });
      }
    } catch (e) {
      debugPrint("Error loading duration widget: $e");
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_durationText.isEmpty) {
      return const SizedBox.shrink();
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.access_time, size: 11, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          _durationText,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _BatchGroup {
  final int id;
  final String name;
  final List<_TopicGroup> topics = [];
  _BatchGroup({required this.id, required this.name});
}

class _TopicGroup {
  final Module module;
  final List<Concept> videos = [];
  _TopicGroup({required this.module});
  int get id => module.id;
  String get name => module.name;
}

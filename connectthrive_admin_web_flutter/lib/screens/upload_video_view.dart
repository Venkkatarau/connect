import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../config/api.dart';

class UploadVideoView extends StatefulWidget {
  const UploadVideoView({super.key});

  @override
  State<UploadVideoView> createState() => _UploadVideoViewState();
}

class _UploadVideoViewState extends State<UploadVideoView> {
  List<dynamic> _batches = [];
  List<dynamic> _modules = [];
  final List<Map<String, String>> _videoTypes = [
    {"id": "1", "name": "Setup Videos"},
    {"id": "2", "name": "Transaction Videos"}
  ];

  int? _selectedBatchId;
  int? _selectedModuleId;
  String? _selectedVideoType;
  final TextEditingController _conceptNameController = TextEditingController();

  PlatformFile? _videoFile;
  PlatformFile? _thumbnailFile;
  final List<PlatformFile> _supportingDocs = [];

  bool _loadingDropdowns = true;
  bool _submitting = false;
  double _uploadProgress = 0;
  String _uploadStatus = "";

  @override
  void initState() {
    super.initState();
    _fetchDropdownData();
  }

  Future<void> _fetchDropdownData() async {
    setState(() {
      _loadingDropdowns = true;
    });

    final batchesUrl = Uri.parse("$baseUrl/v1/admin/getAllBatches");
    final modulesUrl = Uri.parse("$baseUrl/v2/admin/getAllModules");

    try {
      final responses = await Future.wait([
        http.get(batchesUrl),
        http.get(modulesUrl),
      ]);

      if (responses[0].statusCode == 200 && responses[1].statusCode == 200) {
        setState(() {
          _batches = jsonDecode(responses[0].body) ?? [];
          _modules = jsonDecode(responses[1].body) ?? [];
        });
      }
    } catch (e) {
      debugPrint("Error loading dropdown data: $e");
    } finally {
      setState(() {
        _loadingDropdowns = false;
      });
    }
  }

  Future<void> _pickVideo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _videoFile = result.files.first;
      });
    }
  }

  Future<void> _pickThumbnail() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _thumbnailFile = result.files.first;
      });
    }
  }

  Future<void> _pickDoc() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'txt'],
      allowMultiple: false,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _supportingDocs.add(result.files.first);
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (_videoFile == null ||
        _thumbnailFile == null ||
        _selectedBatchId == null ||
        _selectedModuleId == null ||
        _selectedVideoType == null ||
        _conceptNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    setState(() {
      _submitting = true;
      _uploadProgress = 0.1;
      _uploadStatus = "Uploading lecture and assets...";
    });

    final url = Uri.parse("$baseUrl/v2/admin/upload/supportingDocuments");
    final request = http.MultipartRequest("POST", url);

    // Add fields
    request.fields["batchId"] = _selectedBatchId.toString();
    request.fields["moduleId"] = _selectedModuleId.toString();
    request.fields["title"] = _conceptNameController.text.trim();
    request.fields["videoType"] = _selectedVideoType!;

    // Add files
    if (kIsWeb) {
      // On Web, use the bytes
      if (_videoFile!.bytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          "files",
          _videoFile!.bytes!,
          filename: _videoFile!.name,
          contentType: MediaType('video', 'mp4'),
        ));
      }
      if (_thumbnailFile!.bytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          "thubminalFile",
          _thumbnailFile!.bytes!,
          filename: _thumbnailFile!.name,
          contentType: MediaType('image', 'png'),
        ));
      }
      for (var doc in _supportingDocs) {
        if (doc.bytes != null) {
          request.files.add(http.MultipartFile.fromBytes(
            "files",
            doc.bytes!,
            filename: doc.name,
            contentType: MediaType('application', 'octet-stream'),
          ));
        }
      }
    } else {
      // On native platform, use paths
      if (_videoFile!.path != null) {
        request.files.add(await http.MultipartFile.fromPath("files", _videoFile!.path!));
      }
      if (_thumbnailFile!.path != null) {
        request.files.add(await http.MultipartFile.fromPath("thubminalFile", _thumbnailFile!.path!));
      }
      for (var doc in _supportingDocs) {
        if (doc.path != null) {
          request.files.add(await http.MultipartFile.fromPath("files", doc.path!));
        }
      }
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          _uploadProgress = 1.0;
          _uploadStatus = "Finalized and saved successfully!";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Lecture uploaded successfully!")),
        );
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _videoFile = null;
              _thumbnailFile = null;
              _supportingDocs.clear();
              _conceptNameController.clear();
              _selectedBatchId = null;
              _selectedModuleId = null;
              _selectedVideoType = null;
              _submitting = false;
              _uploadProgress = 0;
            });
          }
        });
      } else {
        throw Exception("Upload failed with status: ${response.statusCode}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed: $e")),
      );
      setState(() {
        _submitting = false;
        _uploadProgress = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingDropdowns) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF225663)),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "Upload Video Lecture",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF225663),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Upload and manage your lecture videos with supporting materials",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          // Configuration Form
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Lecture Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  LayoutBuilder(builder: (context, constraints) {
                    return Column(
                      children: [
                        Row(
                          children: [
                             Expanded(
                              child: DropdownButtonFormField<int>(
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: "Select Batch*",
                                  border: OutlineInputBorder(),
                                ),
                                value: _selectedBatchId,
                                items: _batches.map((b) {
                                  return DropdownMenuItem<int>(
                                    value: b['id'] as int,
                                    child: Text(b['name'] ?? ''),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _selectedBatchId = val;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: "Select Module*",
                                  border: OutlineInputBorder(),
                                ),
                                value: _selectedModuleId,
                                items: _modules.map((m) {
                                  return DropdownMenuItem<int>(
                                    value: m['id'] as int,
                                    child: Text("${m['name'] ?? ''} (${m['tier'] ?? ''})"),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _selectedModuleId = val;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: "Select Video Type*",
                                  border: OutlineInputBorder(),
                                ),
                                value: _selectedVideoType,
                                items: _videoTypes.map((type) {
                                  return DropdownMenuItem<String>(
                                    value: type['name'],
                                    child: Text(type['name'] ?? ''),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _selectedVideoType = val;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                controller: _conceptNameController,
                                decoration: const InputDecoration(
                                  labelText: "Concept Name*",
                                  border: OutlineInputBorder(),
                                  hintText: "Enter concept name",
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // File Selection Cards
          if (_selectedModuleId != null)
            Wrap(
              spacing: 24,
              runSpacing: 24,
              alignment: WrapAlignment.center,
              children: [
                // Video Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Container(
                    width: 320,
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "📹 Video File",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF225663)),
                            ),
                            Text("Required*", style: TextStyle(color: Colors.red, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Upload a lecture video in MP4, MOV, or AVI format to share with learners.",
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        const SizedBox(height: 24),
                        if (_videoFile != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.videocam, color: Color(0xFF225663)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _videoFile!.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        "${(_videoFile!.size / (1024 * 1024)).toStringAsFixed(2)} MB",
                                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      _videoFile = null;
                                    });
                                  },
                                ),
                              ],
                            ),
                          )
                        else
                          ElevatedButton.icon(
                            onPressed: _pickVideo,
                            icon: const Icon(Icons.cloud_upload),
                            label: const Text("Choose Video File"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF225663).withOpacity(0.1),
                              foregroundColor: const Color(0xFF225663),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                // Thumbnail Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Container(
                    width: 320,
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "🖼️ Thumbnail Image",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF225663)),
                            ),
                            Text("Required*", style: TextStyle(color: Colors.red, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Upload a lecture thumbnail image in PNG, JPEG, or JPG format.",
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        const SizedBox(height: 24),
                        if (_thumbnailFile != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.photo, color: Color(0xFF225663)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _thumbnailFile!.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        "${(_thumbnailFile!.size / (1024 * 1024)).toStringAsFixed(2)} MB",
                                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      _thumbnailFile = null;
                                    });
                                  },
                                ),
                              ],
                            ),
                          )
                        else
                          ElevatedButton.icon(
                            onPressed: _pickThumbnail,
                            icon: const Icon(Icons.cloud_upload),
                            label: const Text("Choose Thumbnail File"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF225663).withOpacity(0.1),
                              foregroundColor: const Color(0xFF225663),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                // Supporting Docs Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Container(
                    width: 320,
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "📄 Supporting Documents",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF225663)),
                            ),
                            Text("Optional", style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Add supplementary materials like PDFs or slides to accompany your video.",
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        const SizedBox(height: 24),
                        if (_supportingDocs.isNotEmpty)
                          ..._supportingDocs.map((doc) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.description, color: Color(0xFF225663)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      doc.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      setState(() {
                                        _supportingDocs.remove(doc);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            );
                          })
                        else
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 12.0),
                              child: Text(
                                "No documents added yet",
                                style: TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ),
                          ),
                        ElevatedButton.icon(
                          onPressed: _pickDoc,
                          icon: const Icon(Icons.add),
                          label: const Text("Add Document"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF225663).withOpacity(0.1),
                            foregroundColor: const Color(0xFF225663),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 40),
          // Submit Section
          if (_submitting)
            Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: _uploadProgress,
                      backgroundColor: Colors.grey[200],
                      color: const Color(0xFF225663),
                      minHeight: 8,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _uploadStatus,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            )
          else if (_selectedModuleId != null)
            Center(
              child: ElevatedButton.icon(
                onPressed: _handleSubmit,
                icon: const Icon(Icons.send),
                label: const Text("Submit Lecture"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF225663),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

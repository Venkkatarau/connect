import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../models/module.dart';

class ConceptVideoScreen extends StatefulWidget {
  final Concept concept;
  final String moduleName;

  const ConceptVideoScreen({
    super.key,
    required this.concept,
    required this.moduleName,
  });

  @override
  State<ConceptVideoScreen> createState() => _ConceptVideoScreenState();
}

class _ConceptVideoScreenState extends State<ConceptVideoScreen> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    final rawUrl = 'https://dbp6bbvk4lzrp.cloudfront.net/${widget.concept.videoUrl}';
    final encodedUrl = Uri.encodeFull(rawUrl);

    debugPrint("Initializing Video Player with URL: $encodedUrl");

    _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(encodedUrl));

    try {
      await _videoPlayerController.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoPlayerController.value.aspectRatio,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        placeholder: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
      setState(() {});
    } catch (e) {
      debugPrint("Error initializing video player: $e");
      setState(() {
        _hasError = true;
      });
    }
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.concept.title),
        backgroundColor: const Color(0xFF225663),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: _hasError
                    ? const Text(
                        "Failed to load video. Please try again.",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      )
                    : (_chewieController != null
                        ? Chewie(controller: _chewieController!)
                        : const CircularProgressIndicator(color: Colors.white)),
              ),
            ),
            Container(
              color: Colors.white,
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.moduleName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.concept.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "S3 Storage Key: ${widget.concept.videoUrl}",
                    style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../models/module.dart';
import '../utils/video_duration_manager.dart';

class ConceptVideoScreen extends StatefulWidget {
  final Concept concept;
  final String moduleName;
  final List<Concept> allVideos;

  const ConceptVideoScreen({
    super.key,
    required this.concept,
    required this.moduleName,
    this.allVideos = const [],
  });

  @override
  State<ConceptVideoScreen> createState() => _ConceptVideoScreenState();
}

class _ConceptVideoScreenState extends State<ConceptVideoScreen> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _hasError = false;
  late Concept _currentConcept;

  @override
  void initState() {
    super.initState();
    _currentConcept = widget.concept;
    _initializePlayer();
  }

  Future<void> _playConcept(Concept newConcept) async {
    _chewieController?.dispose();
    await _videoPlayerController.dispose();

    setState(() {
      _currentConcept = newConcept;
      _chewieController = null;
      _hasError = false;
    });

    _initializePlayer();
  }

  List<Concept> get _nextVideos {
    if (widget.allVideos.isEmpty) return [];
    final currentIndex = widget.allVideos.indexWhere(
      (c) => c.id == _currentConcept.id,
    );
    if (currentIndex == -1 || currentIndex >= widget.allVideos.length - 1)
      return [];
    return widget.allVideos.sublist(currentIndex + 1);
  }

  Future<void> _initializePlayer() async {
    final rawUrl =
        'https://dbp6bbvk4lzrp.cloudfront.net/${_currentConcept.videoUrl}';
    final encodedUrl = Uri.encodeFull(rawUrl);

    debugPrint("Initializing Video Player with URL: $encodedUrl");

    _videoPlayerController = VideoPlayerController.networkUrl(
      Uri.parse(encodedUrl),
    );

    try {
      await _videoPlayerController.initialize();

      // Save/cache the loaded video duration
      try {
        final duration = _videoPlayerController.value.duration;
        await VideoDurationManager.saveDuration(
          _currentConcept.videoUrl,
          duration,
        );
      } catch (ex) {
        debugPrint("Error saving video duration: $ex");
      }

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoPlayerController.value.aspectRatio,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        allowedScreenSleep: false,
        customControls: YoutubeControls(
          title: _currentConcept.title,
          onShowSpeedMenu: () => _showPlaybackSpeedBottomSheet(context),
        ),
        routePageBuilder: (context, animation, secondaryAnimation, provider) {
          return AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              return Scaffold(
                backgroundColor: Colors.black,
                body: LayoutBuilder(
                  builder: (context, constraints) {
                    return InteractiveViewer(
                      clipBehavior: Clip.none,
                      minScale: 1.0,
                      maxScale: 5.0,
                      child: SizedBox(
                        width: constraints.maxWidth,
                        height: constraints.maxHeight,
                        child: Chewie(controller: provider.controller),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
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

  void _showPlaybackSpeedBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final currentSpeed = _videoPlayerController.value.playbackSpeed;
        final speeds = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 16),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 16, right: 16, bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.av_timer, color: Color(0xFF2E7D32)),
                      SizedBox(width: 8),
                      Text(
                        "Play Speed",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                ...speeds.map((speed) {
                  final isSelected = currentSpeed == speed;
                  return ListTile(
                    leading: Icon(
                      Icons.av_timer,
                      color: isSelected ? const Color(0xFF2E7D32) : Colors.grey,
                    ),
                    title: Text(
                      speed == 1.0 ? "Normal" : "${speed}x",
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected
                            ? const Color(0xFF2E7D32)
                            : Colors.black87,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: Color(0xFF2E7D32))
                        : null,
                    onTap: () {
                      _videoPlayerController.setPlaybackSpeed(speed);
                      Navigator.pop(context);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
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
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: _videoPlayerController.value.isInitialized
                      ? _videoPlayerController.value.aspectRatio
                      : 16 / 9,
                  child: Container(
                    color: Colors.black,
                    child: Center(
                      child: _hasError
                          ? const Text(
                              "Failed to load video. Please try again.",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            )
                          : (_chewieController != null
                                ? LayoutBuilder(
                                    builder: (context, constraints) {
                                      return InteractiveViewer(
                                        clipBehavior: Clip.none,
                                        minScale: 1.0,
                                        maxScale: 5.0,
                                        child: SizedBox(
                                          width: constraints.maxWidth,
                                          height: constraints.maxHeight,
                                          child: Chewie(
                                            controller: _chewieController!,
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                : const CircularProgressIndicator(
                                    color: Colors.white,
                                  )),
                    ),
                  ),
                ),
                if (_chewieController != null &&
                    !_chewieController!.isFullScreen &&
                    Theme.of(context).platform == TargetPlatform.iOS)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.black38,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                        _currentConcept.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      if (_currentConcept.supportingDocuments.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Text(
                          "Supporting Documents",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ..._currentConcept.supportingDocuments.map((doc) {
                          IconData iconData = Icons.insert_drive_file;
                          Color iconBgColor = Colors.grey.shade100;
                          Color iconColor = Colors.grey.shade600;

                          final lowerDoc = doc.toLowerCase();
                          if (lowerDoc.endsWith('.xlsx') ||
                              lowerDoc.endsWith('.xls')) {
                            iconData = Icons.table_chart;
                            iconBgColor = const Color(0xE8EAF6EC);
                            iconColor = const Color(0xFF2E7D32);
                          } else if (lowerDoc.endsWith('.pdf')) {
                            iconData = Icons.picture_as_pdf;
                            iconBgColor = const Color(0xFFFCE4EC);
                            iconColor = const Color(0xFFC2185B);
                          } else if (lowerDoc.endsWith('.docx') ||
                              lowerDoc.endsWith('.doc')) {
                            iconData = Icons.description;
                            iconBgColor = const Color(0xFFE3F2FD);
                            iconColor = const Color(0xFF1565C0);
                          }

                          final displayName = doc.replaceAll(
                            RegExp(
                              r'\.(xlsx|pdf|docx|zip|txt|csv)$',
                              caseSensitive: false,
                            ),
                            '',
                          );
                          final extension = doc.split('.').last.toUpperCase();

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey.shade200,
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Downloading $doc..."),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: iconBgColor,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Icon(
                                          iconData,
                                          color: iconColor,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              displayName,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              "$extension File",
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.download_rounded,
                                        color: Colors.grey.shade400,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                      if (_nextVideos.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Text(
                          "Up Next",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ..._nextVideos.map((c) => _buildNextVideoRow(c)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextVideoRow(Concept concept) {
    final thumbnailUrl = Uri.encodeFull(
      'https://dbp6bbvk4lzrp.cloudfront.net/${concept.thumbnailFileName}',
    );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _playConcept(concept),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
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
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      concept.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.play_circle_outline,
                          size: 12,
                          color: Color(0xFF225663),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "Next Video",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}

class YoutubeControls extends StatefulWidget {
  final String title;
  final VoidCallback onShowSpeedMenu;
  const YoutubeControls({
    super.key,
    required this.title,
    required this.onShowSpeedMenu,
  });

  @override
  State<YoutubeControls> createState() => _YoutubeControlsState();
}

class _YoutubeControlsState extends State<YoutubeControls> {
  bool _visible = true;
  Timer? _hideTimer;
  VideoPlayerController? _videoController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newController = ChewieController.of(context).videoPlayerController;
    if (_videoController != newController) {
      _videoController?.removeListener(_videoListener);
      _videoController = newController;
      _videoController?.addListener(_videoListener);
    }
  }

  @override
  void dispose() {
    _videoController?.removeListener(_videoListener);
    _hideTimer?.cancel();
    super.dispose();
  }

  void _videoListener() {
    if (mounted) {
      if (_videoController!.value.isPlaying) {
        if (_hideTimer == null || !_hideTimer!.isActive) {
          _startHideTimer();
        }
      } else {
        _hideTimer?.cancel();
      }
    }
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    if (!_videoController!.value.isPlaying) return;
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _visible = false;
        });
      }
    });
  }

  void _toggleVisibility() {
    setState(() {
      _visible = !_visible;
    });
    if (_visible) {
      _startHideTimer();
    }
  }

  void _cancelAndRestartTimer() {
    if (_visible) {
      _startHideTimer();
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return "${twoDigits(duration.inHours)}:$minutes:$seconds";
    }
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final chewieController = ChewieController.of(context);
    final videoPlayerController = chewieController.videoPlayerController;

    return GestureDetector(
      onTap: _toggleVisibility,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          if (_visible)
            AnimatedOpacity(
              opacity: _visible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                color: Colors.black45,
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: SafeArea(
                        child: Row(
                          children: [
                            if (chewieController.isFullScreen)
                              IconButton(
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  chewieController.exitFullScreen();
                                },
                              ),
                            Expanded(
                              child: Text(
                                widget.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            decoration: const BoxDecoration(
                              color: Colors.black38,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.skip_previous,
                                color: Colors.white,
                              ),
                              iconSize: 32,
                              onPressed: () {
                                _cancelAndRestartTimer();
                                final newPos =
                                    videoPlayerController.value.position -
                                    const Duration(seconds: 10);
                                videoPlayerController.seekTo(
                                  newPos < Duration.zero
                                      ? Duration.zero
                                      : newPos,
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 32),
                          ValueListenableBuilder(
                            valueListenable: videoPlayerController,
                            builder: (context, VideoPlayerValue value, child) {
                              return Container(
                                decoration: const BoxDecoration(
                                  color: Colors.black38,
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    value.isPlaying
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                    color: Colors.white,
                                  ),
                                  iconSize: 48,
                                  onPressed: () {
                                    _cancelAndRestartTimer();
                                    if (value.isPlaying) {
                                      chewieController.pause();
                                    } else {
                                      chewieController.play();
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 32),
                          Container(
                            decoration: const BoxDecoration(
                              color: Colors.black38,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.skip_next,
                                color: Colors.white,
                              ),
                              iconSize: 32,
                              onPressed: () {
                                _cancelAndRestartTimer();
                                final newPos =
                                    videoPlayerController.value.position +
                                    const Duration(seconds: 10);
                                videoPlayerController.seekTo(
                                  newPos > videoPlayerController.value.duration
                                      ? videoPlayerController.value.duration
                                      : newPos,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ValueListenableBuilder(
                              valueListenable: videoPlayerController,
                              builder:
                                  (context, VideoPlayerValue value, child) {
                                    final position = value.position;
                                    final duration = value.duration;
                                    final maxVal = duration.inMilliseconds > 0
                                        ? duration.inMilliseconds.toDouble()
                                        : 1.0;
                                    final val = position.inMilliseconds
                                        .toDouble()
                                        .clamp(0.0, maxVal);

                                    return SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        trackHeight: 3,
                                        thumbShape: const RoundSliderThumbShape(
                                          enabledThumbRadius: 6,
                                        ),
                                        overlayShape:
                                            const RoundSliderOverlayShape(
                                              overlayRadius: 14,
                                            ),
                                        activeTrackColor: Colors.red,
                                        inactiveTrackColor: Colors.white24,
                                        thumbColor: Colors.red,
                                      ),
                                      child: Slider(
                                        value: val,
                                        min: 0.0,
                                        max: maxVal,
                                        onChanged: (double newValue) {
                                          _cancelAndRestartTimer();
                                          videoPlayerController.seekTo(
                                            Duration(
                                              milliseconds: newValue.toInt(),
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  },
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 16,
                                right: 16,
                                bottom: 8,
                              ),
                              child: Row(
                                children: [
                                  ValueListenableBuilder(
                                    valueListenable: videoPlayerController,
                                    builder:
                                        (
                                          context,
                                          VideoPlayerValue value,
                                          child,
                                        ) {
                                          return Text(
                                            "${_formatDuration(value.position)} / ${_formatDuration(value.duration)}",
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          );
                                        },
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.speed,
                                      color: Colors.white,
                                    ),
                                    onPressed: () {
                                      _cancelAndRestartTimer();
                                      widget.onShowSpeedMenu();
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      chewieController.isFullScreen
                                          ? Icons.fullscreen_exit
                                          : Icons.fullscreen,
                                      color: Colors.white,
                                    ),
                                    onPressed: () {
                                      _cancelAndRestartTimer();
                                      chewieController.toggleFullScreen();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

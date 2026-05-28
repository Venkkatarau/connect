import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VideoDurationManager {
  static final Map<String, String> _memoryCache = {};

  /// Retrieves the duration from cache (memory or SharedPreferences).
  /// Returns empty string if not cached.
  static Future<String> getDuration(String videoUrl) async {
    // 1. Check memory cache
    if (_memoryCache.containsKey(videoUrl)) {
      return _memoryCache[videoUrl]!;
    }

    // 2. Check SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('dur_$videoUrl');
      if (cached != null) {
        _memoryCache[videoUrl] = cached;
        return cached;
      }
    } catch (e) {
      debugPrint("SharedPreferences error in VideoDurationManager: $e");
    }

    // Do NOT fetch over network here to prevent main thread blocking/scrolling lag.
    return "";
  }

  /// Saves duration to memory cache and SharedPreferences.
  static Future<void> saveDuration(String videoUrl, Duration duration) async {
    final durationText = formatDuration(duration);
    _memoryCache[videoUrl] = durationText;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('dur_$videoUrl', durationText);
      debugPrint("Saved duration for $videoUrl: $durationText");
    } catch (e) {
      debugPrint("SharedPreferences write error in VideoDurationManager: $e");
    }
  }

  /// Formats raw duration to MM:SS or HH:MM:SS format.
  static String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return "${twoDigits(duration.inHours)}:$minutes:$seconds";
    }
    return "$minutes:$seconds";
  }
}

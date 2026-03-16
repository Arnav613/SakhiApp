import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class ShieldService {
  static CameraController? _cameraController;
  static bool _isRecording = false;
  static String? _recordingPath;

  // ── Request all permissions upfront ───────────────────────────────────────
  static Future<Map<String, bool>> requestAllPermissions() async {
    final results = await [
      Permission.location,
      Permission.camera,
      Permission.microphone,
      Permission.sms,
      Permission.storage,
    ].request();

    return {
      'location':   results[Permission.location]!.isGranted,
      'camera':     results[Permission.camera]!.isGranted,
      'microphone': results[Permission.microphone]!.isGranted,
      'sms':        results[Permission.sms]!.isGranted,
      'storage':    results[Permission.storage]!.isGranted,
    };
  }

  // ── Get current GPS location ───────────────────────────────────────────────
  static Future<Position?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      debugPrint('Location error: $e');
      return null;
    }
  }

  // ── Send SMS automatically (Android only) ────────────────────────────────
  static Future<bool> sendEmergencySms({
    required List<String> contacts,
    required String reason,
  }) async {
    if (contacts.isEmpty) return false;

    final position = await getCurrentLocation();
    String locationText;
    if (position != null) {
      final lat = position.latitude.toStringAsFixed(6);
      final lng = position.longitude.toStringAsFixed(6);
      locationText =
      'My live location: https://maps.google.com/?q=$lat,$lng';
    } else {
      locationText = 'Location unavailable — please track my phone.';
    }

    final message =
        '🚨 SAKHI EMERGENCY ALERT 🚨\n'
        '$reason\n\n'
        '$locationText\n\n'
        'This is an automated alert from the Sakhi safety app.\n'
        'Please check on me immediately.';

    // Build a single SMS URI with all numbers separated by semicolons
    final numbers  = contacts.map((c) => c.replaceAll(' ', '')).join(';');
    final encoded  = Uri.encodeComponent(message);
    final uri      = Uri.parse('sms:$numbers?body=$encoded');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('SMS error: $e');
      return false;
    }
  }

  // ── Start video + audio recording ─────────────────────────────────────────
  static Future<bool> startRecording() async {
    try {
      if (_isRecording) return true;

      // Get available cameras
      final cameras = await availableCameras();
      if (cameras.isEmpty) return false;

      // Use front camera if available, otherwise rear
      final camera = cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio:    true,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();

      // Get save path
      final dir       = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _recordingPath  = '${dir.path}/sakhi_shield_$timestamp.mp4';

      await _cameraController!.startVideoRecording();
      _isRecording = true;

      debugPrint('Shield recording started: $_recordingPath');
      return true;
    } catch (e) {
      debugPrint('Recording start error: $e');
      return false;
    }
  }

  // ── Stop recording and save to device ─────────────────────────────────────
  static Future<String?> stopRecording() async {
    try {
      if (!_isRecording || _cameraController == null) return null;

      final file = await _cameraController!.stopVideoRecording();
      _isRecording = false;

      // Save to the path we set
      if (_recordingPath != null) {
        await file.saveTo(_recordingPath!);
        debugPrint('Shield recording saved to: $_recordingPath');
      }

      await _cameraController!.dispose();
      _cameraController = null;

      return _recordingPath;
    } catch (e) {
      debugPrint('Recording stop error: $e');
      return null;
    }
  }

  // ── Check if currently recording ──────────────────────────────────────────
  static bool get isRecording => _isRecording;

  // ── Get camera preview widget (to show small indicator) ───────────────────
  static CameraController? get cameraController => _cameraController;

  // ── Stream live location updates ──────────────────────────────────────────
  static Stream<Position> getLiveLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy:          LocationAccuracy.high,
        distanceFilter:    10, // update every 10 metres
      ),
    );
  }

  // ── Format location as Google Maps link ───────────────────────────────────
  static String formatLocationLink(Position position) {
    final lat = position.latitude.toStringAsFixed(6);
    final lng = position.longitude.toStringAsFixed(6);
    return 'https://maps.google.com/?q=$lat,$lng';
  }
}
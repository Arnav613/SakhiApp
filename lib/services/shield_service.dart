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

  // ── Request all permissions ───────────────────────────────────────────────
  static Future<void> requestAllPermissions() async {
    await [
      Permission.location,
      Permission.camera,
      Permission.microphone,
      Permission.storage,
      Permission.manageExternalStorage,
    ].request();
  }

  // ── Get current GPS ───────────────────────────────────────────────────────
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

  // ── Live location stream ──────────────────────────────────────────────────
  static Stream<Position> getLiveLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );
  }

  // ── Send WhatsApp alert ───────────────────────────────────────────────────
  static Future<void> sendEmergencySms({
    required List<String> contacts,
    required String reason,
  }) async {
    if (contacts.isEmpty) return;

    final position = await getCurrentLocation();
    String locationText;
    if (position != null) {
      final lat = position.latitude.toStringAsFixed(6);
      final lng = position.longitude.toStringAsFixed(6);
      locationText = 'https://maps.google.com/?q=$lat,$lng';
    } else {
      locationText = 'Location unavailable';
    }

    final message =
        '🚨 SAKHI EMERGENCY ALERT 🚨\n'
        '$reason\n\n'
        'My location: $locationText\n\n'
        'Sent from Sakhi safety app. Please check on me immediately.';

    for (final contact in contacts) {
      final number  = contact.replaceAll(RegExp(r'[\s\-\(\)]'), '');
      final encoded = Uri.encodeComponent(message);
      final uri     = Uri.parse('https://wa.me/$number?text=$encoded');
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        await Future.delayed(const Duration(milliseconds: 800));
      } catch (e) {
        debugPrint('WhatsApp error for $number: $e');
      }
    }
  }

  // ── Start recording ───────────────────────────────────────────────────────
  static Future<bool> startRecording() async {
    try {
      if (_isRecording) return true;

      final cameras = await availableCameras();
      if (cameras.isEmpty) return false;

      final camera = cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        camera,
        ResolutionPreset.low,
        enableAudio: true,
      );

      await _cameraController!.initialize();
      await _cameraController!.prepareForVideoRecording();
      await _cameraController!.startVideoRecording();
      _isRecording = true;

      debugPrint('Recording started');
      return true;
    } catch (e) {
      debugPrint('Recording start error: $e');
      _isRecording = false;
      _cameraController = null;
      return false;
    }
  }

  // ── Stop recording — saves to DCIM so gallery can see it ─────────────────
  static Future<String?> stopRecording() async {
    try {
      if (!_isRecording || _cameraController == null) return null;
      if (!_cameraController!.value.isRecordingVideo) return null;

      final xFile = await _cameraController!.stopVideoRecording();
      _isRecording = false;

      await _cameraController!.dispose();
      _cameraController = null;

      // Save to DCIM/Sakhi — this appears in the gallery
      String? savePath;
      try {
        final dcim      = Directory('/storage/emulated/0/DCIM/Sakhi');
        if (!await dcim.exists()) await dcim.create(recursive: true);
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        savePath        = '${dcim.path}/sakhi_$timestamp.mp4';
        await File(xFile.path).copy(savePath);
        debugPrint('Saved to DCIM: $savePath');
      } catch (e) {
        // Fallback to external storage root
        debugPrint('DCIM save failed, trying external: $e');
        try {
          final ext = await getExternalStorageDirectory();
          if (ext != null) {
            final timestamp = DateTime.now().millisecondsSinceEpoch;
            savePath        = '${ext.path}/sakhi_$timestamp.mp4';
            await File(xFile.path).copy(savePath);
            debugPrint('Saved to external: $savePath');
          }
        } catch (e2) {
          // Final fallback — app documents
          debugPrint('External failed, using app docs: $e2');
          final docs      = await getApplicationDocumentsDirectory();
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          savePath        = '${docs.path}/sakhi_$timestamp.mp4';
          await File(xFile.path).copy(savePath);
          debugPrint('Saved to app docs: $savePath');
        }
      }

      // Tell Android media scanner about the new file so gallery picks it up
      if (savePath != null && Platform.isAndroid) {
        try {
          await Process.run('am', [
            'broadcast',
            '-a', 'android.intent.action.MEDIA_SCANNER_SCAN_FILE',
            '-d', 'file://$savePath',
          ]);
        } catch (_) {}
      }

      return savePath;
    } catch (e) {
      debugPrint('Stop recording error: $e');
      try { await _cameraController?.dispose(); } catch (_) {}
      _cameraController = null;
      _isRecording = false;
      return null;
    }
  }

  static bool get isRecording => _isRecording;
  static CameraController? get cameraController => _cameraController;
}
import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:record/record.dart';

class VoiceChatService {
  VoiceChatService._();

  static final VoiceChatService instance =
      VoiceChatService._();

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final AudioRecorder _recorder =
      AudioRecorder();

  bool _isRecording = false;

  DateTime? _recordingStartedAt;

  String? _recordingPath;

  Timer? _recordingTimer;

  Duration _recordingDuration =
      Duration.zero;

  final StreamController<Duration>
      _recordingDurationController =
      StreamController<Duration>.broadcast();

  // ============================================================
  // GETTERS
  // ============================================================

  bool get isRecording => _isRecording;

  Duration get recordingDuration =>
      _recordingDuration;

  Stream<Duration>
      get recordingDurationStream =>
          _recordingDurationController.stream;

  // ============================================================
  // START RECORDING
  // ============================================================

  Future<void> startRecording({
    required String conversationId,
  }) async {
    if (_isRecording) {
      return;
    }

    final User? user =
        _auth.currentUser;

    if (user == null) {
      throw StateError(
        'User is not authenticated.',
      );
    }

    final String id =
        conversationId.trim();

    if (id.isEmpty) {
      throw ArgumentError(
        'Conversation ID is required.',
      );
    }

    final bool permission =
        await _recorder.hasPermission();

    if (!permission) {
      throw StateError(
        'Microphone permission is required.',
      );
    }

    final Directory directory =
        Directory.systemTemp;

    final String filePath =
        '${directory.path}/dojo_voice_'
        '${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
        numChannels: 1,
      ),
      path: filePath,
    );

    _recordingPath =
        filePath;

    _recordingStartedAt =
        DateTime.now();

    _recordingDuration =
        Duration.zero;

    _isRecording = true;

    _startRecordingTimer();
  }

  // ============================================================
  // STOP RECORDING
  //
  // IMPORTANT:
  // No Firebase Storage upload happens here.
  //
  // The returned VoiceRecordingResult contains the local file.
  // Your Cloud/Cloudinary uploader should upload this file and
  // return the final cloud URL.
  // ============================================================

  Future<VoiceRecordingResult?> stopRecording({
    required String conversationId,
  }) async {
    if (!_isRecording) {
      return null;
    }

    final String? recordedPath =
        await _recorder.stop();

    _stopRecordingTimer();

    final DateTime? startedAt =
        _recordingStartedAt;

    final String? fallbackPath =
        _recordingPath;

    _isRecording = false;

    _recordingStartedAt = null;

    _recordingPath = null;

    final String? path =
        recordedPath ?? fallbackPath;

    if (path == null ||
        path.trim().isEmpty) {
      return null;
    }

    final File audioFile =
        File(path);

    if (!await audioFile.exists()) {
      return null;
    }

    final Duration duration =
        startedAt == null
            ? Duration.zero
            : DateTime.now()
                .difference(startedAt);

    if (duration.inMilliseconds < 500) {
      await _deleteFile(audioFile);

      throw StateError(
        'Voice recording is too short.',
      );
    }

    final String id =
        conversationId.trim();

    if (id.isEmpty) {
      await _deleteFile(audioFile);

      throw ArgumentError(
        'Conversation ID is required.',
      );
    }

    return VoiceRecordingResult(
      conversationId: id,
      file: audioFile,
      durationSeconds:
          duration.inSeconds,
    );
  }

  // ============================================================
  // CANCEL RECORDING
  // ============================================================

  Future<void> cancelRecording() async {
    if (!_isRecording) {
      return;
    }

    try {
      await _recorder.stop();
    } catch (_) {}

    _stopRecordingTimer();

    _isRecording = false;

    _recordingStartedAt = null;

    final String? path =
        _recordingPath;

    _recordingPath = null;

    if (path == null ||
        path.trim().isEmpty) {
      return;
    }

    await _deleteFile(
      File(path),
    );
  }

  // ============================================================
  // DELETE LOCAL RECORDING
  //
  // Call this AFTER your cloud uploader has successfully uploaded
  // the file and you no longer need the local copy.
  // ============================================================

  Future<void> deleteLocalRecording(
    File file,
  ) async {
    await _deleteFile(file);
  }

  // ============================================================
  // RECORDING TIMER
  // ============================================================

  void _startRecordingTimer() {
    _recordingTimer?.cancel();

    _recordingTimer =
        Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        final DateTime? startedAt =
            _recordingStartedAt;

        if (startedAt == null ||
            !_isRecording) {
          return;
        }

        _recordingDuration =
            DateTime.now()
                .difference(startedAt);

        if (!_recordingDurationController
            .isClosed) {
          _recordingDurationController
              .add(
            _recordingDuration,
          );
        }
      },
    );
  }

  void _stopRecordingTimer() {
    _recordingTimer?.cancel();

    _recordingTimer = null;
  }

  // ============================================================
  // DELETE FILE
  // ============================================================

  Future<void> _deleteFile(
    File file,
  ) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  Future<void> dispose() async {
    _stopRecordingTimer();

    try {
      await cancelRecording();
    } catch (_) {}

    await _recordingDurationController.close();

    _recorder.dispose();
  }
}

// ================================================================
// LOCAL VOICE RECORDING RESULT
// ================================================================

class VoiceRecordingResult {
  const VoiceRecordingResult({
    required this.conversationId,
    required this.file,
    required this.durationSeconds,
  });

  final String conversationId;

  final File file;

  final int durationSeconds;
}

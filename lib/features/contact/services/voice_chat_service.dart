import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:record/record.dart';
import 'package:video_player/video_player.dart';

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
  // VOICE PLAYBACK
  // ============================================================

  final Map<String, VideoPlayerController>
      _audioControllers =
      <String, VideoPlayerController>{};

  final Map<String, StreamSubscription<void>>
      _audioSubscriptions =
      <String, StreamSubscription<void>>{};

  String? _playingMessageId;

  final StreamController<String?>
      _playingMessageIdController =
      StreamController<String?>.broadcast();

  // ============================================================
  // GETTERS
  // ============================================================

  bool get isRecording => _isRecording;

  Duration get recordingDuration =>
      _recordingDuration;

  Stream<Duration>
      get recordingDurationStream =>
          _recordingDurationController.stream;

  String? get playingMessageId =>
      _playingMessageId;

  Stream<String?>
      get playingMessageIdStream =>
          _playingMessageIdController.stream;

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
  // ============================================================

  Future<void> deleteLocalRecording(
    File file,
  ) async {
    await _deleteFile(file);
  }

  // ============================================================
  // TOGGLE VOICE PLAYBACK
  //
  // messageId = Firestore message ID
  // audioUrl  = Cloudinary secure URL
  // ============================================================

  Future<void> togglePlayback({
    required String messageId,
    required String audioUrl,
  }) async {
    final String id =
        messageId.trim();

    final String url =
        audioUrl.trim();

    if (id.isEmpty) {
      throw ArgumentError(
        'Message ID is required.',
      );
    }

    if (url.isEmpty) {
      throw ArgumentError(
        'Audio URL is required.',
      );
    }

    // ------------------------------------------------------------
    // If another message is currently playing, stop it first.
    // ------------------------------------------------------------

    if (_playingMessageId != null &&
        _playingMessageId != id) {
      await _stopPlayback(
        _playingMessageId!,
      );
    }

    // ------------------------------------------------------------
    // If this message already has a controller, toggle it.
    // ------------------------------------------------------------

    final VideoPlayerController?
        existingController =
        _audioControllers[id];

    if (existingController != null) {
      if (existingController.value.isPlaying) {
        await existingController.pause();

        _setPlayingMessageId(null);
        return;
      }

      if (existingController.value.isInitialized) {
        await existingController.play();

        _setPlayingMessageId(id);
        return;
      }

      await _disposeAudioController(id);
    }

    // ------------------------------------------------------------
    // Create audio/video controller from Cloudinary URL.
    //
    // video_player is already present in the project and can
    // control media playback without adding another audio package.
    // ------------------------------------------------------------

    final VideoPlayerController controller =
        VideoPlayerController.networkUrl(
      Uri.parse(url),
    );

    _audioControllers[id] =
        controller;

    try {
      await controller.initialize();

      await controller.setLooping(false);

      await controller.play();

      _setPlayingMessageId(id);

      final StreamSubscription<void>
          subscription =
          controller.addListener(
            () {},
          ) as StreamSubscription<void>;

      _audioSubscriptions[id] =
          subscription;
    } catch (error) {
      await _disposeAudioController(id);

      _setPlayingMessageId(null);

      rethrow;
    }

    // ------------------------------------------------------------
    // Monitor playback completion.
    // ------------------------------------------------------------

    void checkPlaybackState() {
      if (!_audioControllers.containsKey(id)) {
        return;
      }

      final VideoPlayerValue value =
          controller.value;

      if (value.isInitialized &&
          !value.isPlaying &&
          value.position >= value.duration &&
          value.duration > Duration.zero) {
        unawaited(
          _handlePlaybackCompleted(id),
        );
      }
    }

    controller.addListener(
      checkPlaybackState,
    );
  }

  // ============================================================
  // PLAYBACK COMPLETED
  // ============================================================

  Future<void> _handlePlaybackCompleted(
    String messageId,
  ) async {
    if (_playingMessageId ==
        messageId) {
      _setPlayingMessageId(null);
    }

    final VideoPlayerController?
        controller =
        _audioControllers[messageId];

    if (controller == null) {
      return;
    }

    try {
      await controller.pause();

      await controller.seekTo(
        Duration.zero,
      );
    } catch (_) {}
  }

  // ============================================================
  // STOP PLAYBACK
  // ============================================================

  Future<void> _stopPlayback(
    String messageId,
  ) async {
    final VideoPlayerController?
        controller =
        _audioControllers[messageId];

    if (controller == null) {
      _setPlayingMessageId(null);
      return;
    }

    try {
      await controller.pause();

      await controller.seekTo(
        Duration.zero,
      );
    } catch (_) {}

    _setPlayingMessageId(null);
  }

  // ============================================================
  // SET PLAYING MESSAGE
  // ============================================================

  void _setPlayingMessageId(
    String? messageId,
  ) {
    _playingMessageId =
        messageId;

    if (!_playingMessageIdController
        .isClosed) {
      _playingMessageIdController.add(
        messageId,
      );
    }
  }

  // ============================================================
  // DISPOSE ONE AUDIO CONTROLLER
  // ============================================================

  Future<void> _disposeAudioController(
    String messageId,
  ) async {
    final StreamSubscription<void>?
        subscription =
        _audioSubscriptions.remove(
      messageId,
    );

    if (subscription != null) {
      try {
        await subscription.cancel();
      } catch (_) {}
    }

    final VideoPlayerController?
        controller =
        _audioControllers.remove(
      messageId,
    );

    if (controller != null) {
      try {
        await controller.dispose();
      } catch (_) {}
    }
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

    _setPlayingMessageId(null);

    final List<String> controllerIds =
        List<String>.from(
      _audioControllers.keys,
    );

    for (final String id
        in controllerIds) {
      await _disposeAudioController(id);
    }

    await _recordingDurationController
        .close();

    await _playingMessageIdController
        .close();

    await _recorder.dispose();
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

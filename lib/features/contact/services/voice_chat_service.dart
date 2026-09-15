import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';

class VoiceChatService {
  VoiceChatService._();

  static final VoiceChatService instance =
      VoiceChatService._();

  final FirebaseStorage _storage =
      FirebaseStorage.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final AudioRecorder _recorder =
      AudioRecorder();

  final AudioPlayer _player =
      AudioPlayer();

  bool _isRecording = false;

  DateTime? _recordingStartedAt;

  String? _recordingPath;

  String? _playingMessageId;

  Timer? _recordingTimer;

  Duration _recordingDuration =
      Duration.zero;

  final StreamController<Duration>
      _recordingDurationController =
      StreamController<Duration>.broadcast();

  bool get isRecording => _isRecording;

  String? get playingMessageId =>
      _playingMessageId;

  Duration get recordingDuration =>
      _recordingDuration;

  Stream<Duration>
      get recordingDurationStream =>
          _recordingDurationController.stream;

  Stream<PlayerState>
      get playerStateStream =>
          _player.playerStateStream;

  Stream<Duration>
      get positionStream =>
          _player.positionStream;

  Duration get audioDuration =>
      _player.duration ?? Duration.zero;

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

    _recordingPath = filePath;

    _recordingStartedAt =
        DateTime.now();

    _recordingDuration =
        Duration.zero;

    _isRecording = true;

    _startRecordingTimer();
  }

  Future<VoiceUploadResult?> stopRecording({
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
            : DateTime.now().difference(
                startedAt,
              );

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

    try {
      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}.m4a';

      final Reference storageRef =
          _storage
              .ref()
              .child('contact_media')
              .child(id)
              .child('voice')
              .child(fileName);

      final UploadTask uploadTask =
          storageRef.putFile(
        audioFile,
        SettableMetadata(
          contentType: 'audio/mp4',
        ),
      );

      final TaskSnapshot snapshot =
          await uploadTask;

      final String downloadUrl =
          await snapshot.ref.getDownloadURL();

      return VoiceUploadResult(
        audioUrl: downloadUrl,
        durationSeconds:
            duration.inSeconds,
      );
    } finally {
      await _deleteFile(audioFile);
    }
  }

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

  Future<void> togglePlayback({
    required String messageId,
    required String audioUrl,
  }) async {
    final String id =
        messageId.trim();

    final String url =
        audioUrl.trim();

    if (id.isEmpty ||
        url.isEmpty) {
      return;
    }

    if (_playingMessageId == id &&
        _player.playing) {
      await _player.pause();
      return;
    }

    if (_playingMessageId != id) {
      await _player.stop();

      _playingMessageId = id;

      await _player.setUrl(url);
    }

    await _player.play();

    _player.playerStateStream
        .firstWhere(
          (PlayerState state) =>
              state.processingState ==
                  ProcessingState.completed,
        )
        .then((_) async {
      if (_playingMessageId == id) {
        _playingMessageId = null;

        await _player.stop();
      }
    });
  }

  Future<void> stopPlayback() async {
    await _player.stop();

    _playingMessageId = null;
  }

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
            DateTime.now().difference(
          startedAt,
        );

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

  Future<void> _deleteFile(
    File file,
  ) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  Future<void> dispose() async {
    _stopRecordingTimer();

    try {
      await cancelRecording();
    } catch (_) {}

    try {
      await _player.dispose();
    } catch (_) {}

    try {
      _recorder.dispose();
    } catch (_) {}

    await _recordingDurationController.close();
  }
}

class VoiceUploadResult {
  const VoiceUploadResult({
    required this.audioUrl,
    required this.durationSeconds,
  });

  final String audioUrl;
  final int durationSeconds;
}

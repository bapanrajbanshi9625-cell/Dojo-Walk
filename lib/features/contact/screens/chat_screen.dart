import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../../../core/theme/dojo_walk_design_system.dart';
import '../models/contact_model.dart';
import '../services/conversation_service.dart';
import '../services/voice_chat_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.walkId,
    required this.requestId,
    required this.sessionId,
    required this.ownerUid,
    required this.walkerUid,
    this.ownerPhone = '',
    this.walkerPhone = '',
    this.title = 'Chat',
  });

  final String walkId;
  final String requestId;
  final String sessionId;

  final String ownerUid;
  final String walkerUid;

  final String ownerPhone;
  final String walkerPhone;

  final String title;

  @override
  State<ChatScreen> createState() =>
      _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final FirebaseStorage _storage =
      FirebaseStorage.instance;

  final ImagePicker _picker =
      ImagePicker();

  final ConversationService
      _conversationService =
      ConversationService.instance;

  final VoiceChatService
      _voiceService =
      VoiceChatService.instance;

  final TextEditingController
      _messageController =
      TextEditingController();

  final ScrollController
      _scrollController =
      ScrollController();

  StreamSubscription<Duration>?
      _recordingSubscription;

  String? _conversationId;

  bool _isUploadingMedia = false;

  Duration _recordingDuration =
      Duration.zero;

  @override
  void initState() {
    super.initState();

    _recordingSubscription =
        _voiceService
            .recordingDurationStream
            .listen(
      (Duration duration) {
        if (!mounted) {
          return;
        }

        setState(() {
          _recordingDuration =
              duration;
        });
      },
    );

    _initializeConversation();
  }

  @override
  void dispose() {
    _recordingSubscription?.cancel();

    _messageController.dispose();
    _scrollController.dispose();

    super.dispose();
  }

  Future<void>
      _initializeConversation() async {
    try {
      final String id =
          await _conversationService
              .createConversation(
        walkId: widget.walkId,
        requestId: widget.requestId,
        sessionId: widget.sessionId,
        ownerUid: widget.ownerUid,
        walkerUid: widget.walkerUid,
        ownerPhone: widget.ownerPhone,
        walkerPhone: widget.walkerPhone,
        status: 'active',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _conversationId = id;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showError(
        'Unable to open chat: $error',
      );
    }
  }

  String get _currentUid =>
      _auth.currentUser?.uid ?? '';

  String get _receiverUid {
    if (_currentUid == widget.ownerUid) {
      return widget.walkerUid;
    }

    return widget.ownerUid;
  }

  bool get _canChat =>
      _currentUid.isNotEmpty &&
      _conversationId != null &&
      _conversationId!.isNotEmpty;

  Future<void> _sendText() async {
    final String text =
        _messageController.text.trim();

    if (text.isEmpty ||
        !_canChat) {
      return;
    }

    _messageController.clear();

    try {
      await _conversationService
          .sendMessage(
        walkId: widget.walkId,
        requestId: widget.requestId,
        sessionId: widget.sessionId,
        senderUid: _currentUid,
        receiverUid: _receiverUid,
        text: text,
      );

      _scrollToBottom();
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showError(
        'Message failed: $error',
      );
    }
  }

  Future<void> _pickImage() async {
    if (!_canChat ||
        _isUploadingMedia) {
      return;
    }

    try {
      final XFile? image =
          await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image == null) {
        return;
      }

      await _uploadImage(image);
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showError(
        'Image upload failed: $error',
      );
    }
  }

  Future<void> _uploadImage(
    XFile image,
  ) async {
    final String conversationId =
        _conversationId!;

    setState(() {
      _isUploadingMedia = true;
    });

    try {
      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}.jpg';

      final Reference ref =
          _storage
              .ref()
              .child('contact_media')
              .child(conversationId)
              .child('images')
              .child(fileName);

      final UploadTask task =
          ref.putFile(
        File(image.path),
        SettableMetadata(
          contentType: 'image/jpeg',
        ),
      );

      final TaskSnapshot snapshot =
          await task;

      final String url =
          await snapshot.ref
              .getDownloadURL();

      await _conversationService
          .sendImageMessage(
        walkId: widget.walkId,
        requestId: widget.requestId,
        sessionId: widget.sessionId,
        senderUid: _currentUid,
        receiverUid: _receiverUid,
        imageUrl: url,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingMedia = false;
        });
      }
    }
  }

  Future<void> _pickVideo() async {
    if (!_canChat ||
        _isUploadingMedia) {
      return;
    }

    try {
      final XFile? video =
          await _picker.pickVideo(
        source: ImageSource.gallery,
      );

      if (video == null) {
        return;
      }

      await _uploadVideo(video);
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showError(
        'Video upload failed: $error',
      );
    }
  }

  Future<void> _uploadVideo(
    XFile video,
  ) async {
    final String conversationId =
        _conversationId!;

    setState(() {
      _isUploadingMedia = true;
    });

    try {
      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}.mp4';

      final Reference ref =
          _storage
              .ref()
              .child('contact_media')
              .child(conversationId)
              .child('videos')
              .child(fileName);

      final UploadTask task =
          ref.putFile(
        File(video.path),
        SettableMetadata(
          contentType: 'video/mp4',
        ),
      );

      final TaskSnapshot snapshot =
          await task;

      final String url =
          await snapshot.ref
              .getDownloadURL();

      await _conversationService
          .sendVideoMessage(
        walkId: widget.walkId,
        requestId: widget.requestId,
        sessionId: widget.sessionId,
        senderUid: _currentUid,
        receiverUid: _receiverUid,
        videoUrl: url,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingMedia = false;
        });
      }
    }
  }

  Future<void>
      _toggleVoiceRecording() async {
    if (!_canChat) {
      return;
    }

    try {
      if (_voiceService.isRecording) {
        final VoiceUploadResult? result =
            await _voiceService
                .stopRecording(
          conversationId:
              _conversationId!,
        );

        if (result == null) {
          return;
        }

        await _conversationService
            .sendVoiceMessage(
          walkId: widget.walkId,
          requestId: widget.requestId,
          sessionId: widget.sessionId,
          senderUid: _currentUid,
          receiverUid: _receiverUid,
          audioUrl: result.audioUrl,
          durationSeconds:
              result.durationSeconds,
        );

        if (mounted) {
          setState(() {
            _recordingDuration =
                Duration.zero;
          });
        }

        return;
      }

      await _voiceService
          .startRecording(
        conversationId:
            _conversationId!,
      );

      if (mounted) {
        setState(() {
          _recordingDuration =
              Duration.zero;
        });
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showError(
        'Voice recording failed: $error',
      );
    }
  }

  Future<void> _cancelVoiceRecording() async {
    try {
      await _voiceService
          .cancelRecording();

      if (!mounted) {
        return;
      }

      setState(() {
        _recordingDuration =
            Duration.zero;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showError(
        'Unable to cancel recording: $error',
      );
    }
  }

  Future<void> _toggleVoicePlayback(
    ContactMessage message,
  ) async {
    if (message.mediaUrl == null ||
        message.mediaUrl!.isEmpty) {
      return;
    }

    try {
      await _voiceService
          .togglePlayback(
        messageId: message.id,
        audioUrl: message.mediaUrl!,
      );

      if (mounted) {
        setState(() {});
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showError(
        'Unable to play voice: $error',
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance
        .addPostFrameCallback(
      (_) {
        if (!_scrollController
            .hasClients) {
          return;
        }

        _scrollController.animateTo(
          _scrollController
              .position
              .maxScrollExtent,
          duration:
              const Duration(
            milliseconds: 250,
          ),
          curve: Curves.easeOut,
        );
      },
    );
  }

  void _showError(
    String message,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  String _formatDuration(
    Duration duration,
  ) {
    final int minutes =
        duration.inMinutes;

    final int seconds =
        duration.inSeconds % 60;

    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final bool recording =
        _voiceService.isRecording;

    return Scaffold(
      backgroundColor:
          DojoWalkColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor:
            DojoWalkColors.surface,
        foregroundColor:
            DojoWalkColors.textPrimary,
        title: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                fontWeight:
                    FontWeight.w700,
              ),
            ),
            Text(
              'Current walk',
              style: TextStyle(
                fontSize: 12,
                color:
                    DojoWalkColors
                        .textSecondary,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildWalkHeader(),
          Expanded(
            child: _buildMessages(),
          ),
          if (_isUploadingMedia)
            _buildUploadIndicator(),
          if (recording)
            _buildRecordingBar(),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildWalkHeader() {
    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        4,
      ),
      padding:
          const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color:
            DojoWalkColors.primaryLight,
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color:
              DojoWalkColors.primary
                  .withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.directions_walk_rounded,
            color:
                DojoWalkColors.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Walk ${widget.walkId.isEmpty ? widget.requestId : widget.walkId}',
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight:
                    FontWeight.w700,
                color:
                    DojoWalkColors
                        .textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    if (!_canChat) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return StreamBuilder<
        List<ContactMessage>>(
      stream:
          _conversationService
              .messagesStream(
        walkId: widget.walkId,
        requestId: widget.requestId,
        sessionId: widget.sessionId,
      ),
      builder: (
        BuildContext context,
        AsyncSnapshot<
                List<ContactMessage>>
            snapshot,
      ) {
        if (snapshot.connectionState ==
                ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child:
                CircularProgressIndicator(),
          );
        }

        final List<ContactMessage>
            messages =
            snapshot.data ??
                <ContactMessage>[];

        if (messages.isEmpty) {
          return const Center(
            child: Text(
              'Start a conversation',
              style: TextStyle(
                color:
                    DojoWalkColors
                        .textSecondary,
              ),
            ),
          );
        }

        WidgetsBinding.instance
            .addPostFrameCallback(
          (_) => _scrollToBottom(),
        );

        return ListView.builder(
          controller:
              _scrollController,
          padding:
              const EdgeInsets.fromLTRB(
            16,
            12,
            16,
            16,
          ),
          itemCount:
              messages.length,
          itemBuilder: (
            BuildContext context,
            int index,
          ) {
            final ContactMessage
                message =
                messages[index];

            final bool isMine =
                message.senderUid ==
                    _currentUid;

            return _buildMessageBubble(
              message,
              isMine,
            );
          },
        );
      },
    );
  }

  Widget _buildMessageBubble(
    ContactMessage message,
    bool isMine,
  ) {
    return Align(
      alignment: isMine
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        constraints:
            const BoxConstraints(
          maxWidth: 310,
        ),
        margin:
            const EdgeInsets.only(
          bottom: 10,
        ),
        padding:
            message.type == 'image' ||
                    message.type == 'video'
                ? const EdgeInsets.all(5)
                : const EdgeInsets
                    .symmetric(
                    horizontal: 13,
                    vertical: 10,
                  ),
        decoration: BoxDecoration(
          color: isMine
              ? DojoWalkColors.primary
              : DojoWalkColors.surface,
          borderRadius:
              BorderRadius.circular(18),
          border: isMine
              ? null
              : Border.all(
                  color:
                      DojoWalkColors.border,
                ),
        ),
        child: _buildMessageContent(
          message,
          isMine,
        ),
      ),
    );
  }

  Widget _buildMessageContent(
    ContactMessage message,
    bool isMine,
  ) {
    switch (message.type) {
      case 'image':
        return _buildImageMessage(
          message,
        );

      case 'video':
        return _buildVideoMessage(
          message,
        );

      case 'voice':
        return _buildVoiceMessage(
          message,
          isMine,
        );

      default:
        return Text(
          message.text,
          style: TextStyle(
            color: isMine
                ? DojoWalkColors.white
                : DojoWalkColors
                    .textPrimary,
            fontSize: 15,
          ),
        );
    }
  }

  Widget _buildImageMessage(
    ContactMessage message,
  ) {
    final String? url =
        message.mediaUrl;

    if (url == null ||
        url.isEmpty) {
      return const SizedBox(
        width: 180,
        height: 120,
        child: Center(
          child: Icon(
            Icons.broken_image_outlined,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                _FullScreenImage(
              imageUrl: url,
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(14),
        child: Image.network(
          url,
          width: 260,
          height: 220,
          fit: BoxFit.cover,
          errorBuilder: (
            context,
            error,
            stackTrace,
          ) {
            return const SizedBox(
              width: 260,
              height: 220,
              child: Center(
                child: Icon(
                  Icons
                      .broken_image_outlined,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildVideoMessage(
    ContactMessage message,
  ) {
    final String? url =
        message.mediaUrl;

    if (url == null ||
        url.isEmpty) {
      return const SizedBox(
        width: 260,
        height: 180,
        child: Center(
          child: Icon(
            Icons.videocam_off_outlined,
          ),
        ),
      );
    }

    return _VideoMessageCard(
      videoUrl: url,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                VideoPlayerScreen(
              videoUrl: url,
            ),
          ),
        );
      },
    );
  }

  Widget _buildVoiceMessage(
    ContactMessage message,
    bool isMine,
  ) {
    final bool isPlaying =
        _voiceService
                .playingMessageId ==
            message.id;

    final int seconds =
        message.durationSeconds ??
            0;

    return SizedBox(
      width: 220,
      child: Row(
        children: [
          GestureDetector(
            onTap: () =>
                _toggleVoicePlayback(
              message,
            ),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isMine
                    ? DojoWalkColors.white
                    : DojoWalkColors
                        .primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPlaying
                    ? Icons.pause_rounded
                    : Icons
                        .play_arrow_rounded,
                color: DojoWalkColors
                    .primary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Voice message',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.w600,
                    color: isMine
                        ? DojoWalkColors
                            .white
                        : DojoWalkColors
                            .textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDuration(
                    Duration(
                      seconds: seconds,
                    ),
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    color: isMine
                        ? DojoWalkColors
                            .white
                            .withValues(
                              alpha: 0.75,
                            )
                        : DojoWalkColors
                            .textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadIndicator() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 7,
      ),
      color:
          DojoWalkColors.primaryLight,
      child: const Row(
        children: [
          SizedBox(
            width: 15,
            height: 15,
            child:
                CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
          SizedBox(width: 9),
          Text(
            'Uploading media...',
            style: TextStyle(
              fontSize: 13,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingBar() {
    return Container(
      padding:
          const EdgeInsets.fromLTRB(
        16,
        8,
        16,
        8,
      ),
      color:
          DojoWalkColors.redLight,
      child: Row(
        children: [
          const Icon(
            Icons.mic_rounded,
            color:
                DojoWalkColors.red,
          ),
          const SizedBox(width: 8),
          Text(
            _formatDuration(
              _recordingDuration,
            ),
            style: const TextStyle(
              color:
                  DojoWalkColors.red,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Recording voice...',
              style: TextStyle(
                color:
                    DojoWalkColors
                        .textPrimary,
              ),
            ),
          ),
          IconButton(
            onPressed:
                _cancelVoiceRecording,
            icon: const Icon(
              Icons.delete_outline_rounded,
              color:
                  DojoWalkColors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    final bool recording =
        _voiceService.isRecording;

    return SafeArea(
      top: false,
      child: Padding(
        padding:
            const EdgeInsets.fromLTRB(
          10,
          8,
          10,
          10,
        ),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.end,
          children: [
            IconButton(
              onPressed:
                  recording ||
                          _isUploadingMedia
                      ? null
                      : _pickImage,
              icon: const Icon(
                Icons
                    .photo_outlined,
              ),
              color:
                  DojoWalkColors
                      .textSecondary,
            ),
            IconButton(
              onPressed:
                  recording ||
                          _isUploadingMedia
                      ? null
                      : _pickVideo,
              icon: const Icon(
                Icons
                    .videocam_outlined,
              ),
              color:
                  DojoWalkColors
                      .textSecondary,
            ),
            Expanded(
              child: Container(
                constraints:
                    const BoxConstraints(
                  minHeight: 48,
                ),
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 14,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      DojoWalkColors
                          .surface,
                  borderRadius:
                      BorderRadius
                          .circular(
                    24,
                  ),
                  border: Border.all(
                    color:
                        DojoWalkColors
                            .border,
                  ),
                ),
                child: TextField(
                  controller:
                      _messageController,
                  enabled: !recording,
                  minLines: 1,
                  maxLines: 5,
                  textCapitalization:
                      TextCapitalization
                          .sentences,
                  decoration:
                      const InputDecoration(
                    hintText:
                        'Type a message...',
                    border:
                        InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 5),
            GestureDetector(
              onLongPress:
                  _canChat
                      ? _toggleVoiceRecording
                      : null,
              onTap:
                  _canChat
                      ? () async {
                          if (recording) {
                            await _toggleVoiceRecording();
                            return;
                          }

                          if (_messageController
                              .text
                              .trim()
                              .isNotEmpty) {
                            await _sendText();
                          } else {
                            await _toggleVoiceRecording();
                          }
                        }
                      : null,
              child: Container(
                width: 48,
                height: 48,
                decoration:
                    BoxDecoration(
                  color: recording
                      ? DojoWalkColors
                          .red
                      : DojoWalkColors
                          .primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  recording
                      ? Icons.stop_rounded
                      : _messageController
                              .text
                              .trim()
                              .isNotEmpty
                          ? Icons
                              .send_rounded
                          : Icons
                              .mic_rounded,
                  color:
                      DojoWalkColors
                          .white,
                  size: 21,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoMessageCard
    extends StatefulWidget {
  const _VideoMessageCard({
    required this.videoUrl,
    required this.onTap,
  });

  final String videoUrl;
  final VoidCallback onTap;

  @override
  State<_VideoMessageCard> createState() =>
      _VideoMessageCardState();
}

class _VideoMessageCardState
    extends State<_VideoMessageCard> {
  VideoPlayerController?
      _controller;

  @override
  void initState() {
    super.initState();

    _initialize();
  }

  Future<void> _initialize() async {
    final VideoPlayerController
        controller =
        VideoPlayerController
            .networkUrl(
      Uri.parse(
        widget.videoUrl,
      ),
    );

    _controller = controller;

    try {
      await controller.initialize();

      if (mounted) {
        setState(() {});
      }
    } catch (_) {
      await controller.dispose();
      _controller = null;

      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final VideoPlayerController?
        controller =
        _controller;

    return GestureDetector(
      onTap: widget.onTap,
      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(14),
        child: SizedBox(
          width: 260,
          height: 190,
          child: controller != null &&
                  controller
                      .value
                      .isInitialized
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: controller
                            .value
                            .size
                            .width,
                        height: controller
                            .value
                            .size
                            .height,
                        child:
                            VideoPlayer(
                          controller,
                        ),
                      ),
                    ),
                    Container(
                      color: Colors.black
                          .withValues(
                        alpha: 0.18,
                      ),
                    ),
                    const Center(
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor:
                            DojoWalkColors
                                .white,
                        child: Icon(
                          Icons
                              .play_arrow_rounded,
                          color:
                              DojoWalkColors
                                  .primary,
                          size: 34,
                        ),
                      ),
                    ),
                  ],
                )
              : const Center(
                  child:
                      CircularProgressIndicator(),
                ),
        ),
      ),
    );
  }
}

class VideoPlayerScreen
    extends StatefulWidget {
  const VideoPlayerScreen({
    super.key,
    required this.videoUrl,
  });

  final String videoUrl;

  @override
  State<VideoPlayerScreen> createState() =>
      _VideoPlayerScreenState();
}

class _VideoPlayerScreenState
    extends State<VideoPlayerScreen> {
  late final VideoPlayerController
      _controller;

  @override
  void initState() {
    super.initState();

    _controller =
        VideoPlayerController.networkUrl(
      Uri.parse(
        widget.videoUrl,
      ),
    )..initialize().then(
            (_) {
          if (mounted) {
            setState(() {});
            _controller.play();
          }
        },
      );
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Colors.black,
      appBar: AppBar(
        backgroundColor:
            Colors.black,
        foregroundColor:
            Colors.white,
        title:
            const Text('Video'),
      ),
      body: Center(
        child: _controller
                .value
                .isInitialized
            ? AspectRatio(
                aspectRatio:
                    _controller
                        .value
                        .aspectRatio,
                child: VideoPlayer(
                  _controller,
                ),
              )
            : const CircularProgressIndicator(
                color:
                    DojoWalkColors.white,
              ),
      ),
      floatingActionButton:
          _controller.value.isInitialized
              ? FloatingActionButton(
                  backgroundColor:
                      DojoWalkColors
                          .primary,
                  onPressed: () {
                    setState(() {
                      if (_controller
                          .value
                          .isPlaying) {
                        _controller.pause();
                      } else {
                        _controller.play();
                      }
                    });
                  },
                  child: Icon(
                    _controller
                            .value
                            .isPlaying
                        ? Icons
                            .pause_rounded
                        : Icons
                            .play_arrow_rounded,
                  ),
                )
              : null,
    );
  }
}

class _FullScreenImage
    extends StatelessWidget {
  const _FullScreenImage({
    required this.imageUrl,
  });

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Colors.black,
      appBar: AppBar(
        backgroundColor:
            Colors.black,
        foregroundColor:
            Colors.white,
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/contact_model.dart';

class ConversationService {
  ConversationService._();

  static final ConversationService instance =
      ConversationService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>>
      get _conversations =>
          _firestore.collection('conversations');

  // ==========================================================
  // CONVERSATION ID
  // ==========================================================

  String getConversationId({
    required String walkId,
    required String requestId,
    required String sessionId,
  }) {
    final String walk = walkId.trim();

    if (walk.isNotEmpty) {
      return walk;
    }

    final String request = requestId.trim();

    if (request.isNotEmpty) {
      return request;
    }

    return sessionId.trim();
  }

  // ==========================================================
  // REFERENCES
  // ==========================================================

  DocumentReference<Map<String, dynamic>> _conversationRef(
    String conversationId,
  ) {
    return _conversations.doc(conversationId);
  }

  CollectionReference<Map<String, dynamic>> _messagesRef(
    String conversationId,
  ) {
    return _conversationRef(conversationId).collection(
      'messages',
    );
  }

  // ==========================================================
  // CREATE / UPDATE CONVERSATION
  // ==========================================================

  Future<String> createConversation({
    required String walkId,
    required String requestId,
    required String sessionId,
    required String ownerUid,
    required String walkerUid,
    String ownerPhone = '',
    String walkerPhone = '',
    String status = 'active',
  }) async {
    final String conversationId = getConversationId(
      walkId: walkId,
      requestId: requestId,
      sessionId: sessionId,
    );

    if (conversationId.isEmpty) {
      throw ArgumentError(
        'walkId, requestId or sessionId is required.',
      );
    }

    final DocumentReference<Map<String, dynamic>> ref =
        _conversationRef(conversationId);

    final DocumentSnapshot<Map<String, dynamic>> existing =
        await ref.get();

    final Map<String, dynamic> data =
        <String, dynamic>{
      'contactId': conversationId,
      'walkId': walkId.trim(),
      'requestId': requestId.trim(),
      'sessionId': sessionId.trim(),
      'ownerUid': ownerUid.trim(),
      'walkerUid': walkerUid.trim(),
      'ownerPhone': ownerPhone.trim(),
      'walkerPhone': walkerPhone.trim(),
      'status': status.trim().isEmpty
          ? 'active'
          : status.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (!existing.exists) {
      data['createdAt'] =
          FieldValue.serverTimestamp();
    }

    await ref.set(
      data,
      SetOptions(merge: true),
    );

    return conversationId;
  }

  // ==========================================================
  // CONVERSATION STREAM
  // ==========================================================

  Stream<DocumentSnapshot<Map<String, dynamic>>>
      conversationStream({
    required String walkId,
    required String requestId,
    required String sessionId,
  }) {
    final String conversationId = getConversationId(
      walkId: walkId,
      requestId: requestId,
      sessionId: sessionId,
    );

    if (conversationId.isEmpty) {
      return const Stream.empty();
    }

    return _conversationRef(conversationId).snapshots();
  }

  // ==========================================================
  // MESSAGE STREAM
  // ==========================================================

  Stream<List<ContactMessage>> messagesStream({
    required String walkId,
    required String requestId,
    required String sessionId,
  }) {
    final String conversationId = getConversationId(
      walkId: walkId,
      requestId: requestId,
      sessionId: sessionId,
    );

    if (conversationId.isEmpty) {
      return const Stream.empty();
    }

    return _messagesRef(conversationId)
        .orderBy(
          'createdAt',
          descending: false,
        )
        .snapshots()
        .map(
          (
            QuerySnapshot<Map<String, dynamic>> snapshot,
          ) {
            return snapshot.docs
                .map(ContactMessage.fromDocument)
                .toList();
          },
        );
  }

  // ==========================================================
  // TEXT MESSAGE
  // ==========================================================

  Future<void> sendMessage({
    required String walkId,
    required String requestId,
    required String sessionId,
    required String senderUid,
    required String receiverUid,
    required String text,
  }) async {
    final String message = text.trim();

    if (message.isEmpty) {
      return;
    }

    final String conversationId = getConversationId(
      walkId: walkId,
      requestId: requestId,
      sessionId: sessionId,
    );

    if (conversationId.isEmpty) {
      throw ArgumentError(
        'Current walk ID is required.',
      );
    }

    await _validateCurrentConversation(
      conversationId: conversationId,
      walkId: walkId,
      requestId: requestId,
      sessionId: sessionId,
    );

    await _messagesRef(conversationId).add(
      <String, dynamic>{
        'type': 'text',
        'senderUid': senderUid.trim(),
        'receiverUid': receiverUid.trim(),
        'text': message,
        'mediaUrl': null,
        'durationSeconds': null,
        'createdAt': FieldValue.serverTimestamp(),
      },
    );

    await _updateConversation(conversationId);
  }

  // ==========================================================
  // IMAGE MESSAGE
  // ==========================================================

  Future<void> sendImageMessage({
    required String walkId,
    required String requestId,
    required String sessionId,
    required String senderUid,
    required String receiverUid,
    required String imageUrl,
  }) async {
    final String url = imageUrl.trim();

    if (url.isEmpty) {
      return;
    }

    final String conversationId = getConversationId(
      walkId: walkId,
      requestId: requestId,
      sessionId: sessionId,
    );

    if (conversationId.isEmpty) {
      throw ArgumentError(
        'Current walk ID is required.',
      );
    }

    await _validateCurrentConversation(
      conversationId: conversationId,
      walkId: walkId,
      requestId: requestId,
      sessionId: sessionId,
    );

    await _messagesRef(conversationId).add(
      <String, dynamic>{
        'type': 'image',
        'senderUid': senderUid.trim(),
        'receiverUid': receiverUid.trim(),
        'text': '',
        'mediaUrl': url,
        'durationSeconds': null,
        'createdAt': FieldValue.serverTimestamp(),
      },
    );

    await _updateConversation(conversationId);
  }

  // ==========================================================
  // VIDEO MESSAGE
  // ==========================================================

  Future<void> sendVideoMessage({
    required String walkId,
    required String requestId,
    required String sessionId,
    required String senderUid,
    required String receiverUid,
    required String videoUrl,
  }) async {
    final String url = videoUrl.trim();

    if (url.isEmpty) {
      return;
    }

    final String conversationId = getConversationId(
      walkId: walkId,
      requestId: requestId,
      sessionId: sessionId,
    );

    if (conversationId.isEmpty) {
      throw ArgumentError(
        'Current walk ID is required.',
      );
    }

    await _validateCurrentConversation(
      conversationId: conversationId,
      walkId: walkId,
      requestId: requestId,
      sessionId: sessionId,
    );

    await _messagesRef(conversationId).add(
      <String, dynamic>{
        'type': 'video',
        'senderUid': senderUid.trim(),
        'receiverUid': receiverUid.trim(),
        'text': '',
        'mediaUrl': url,
        'durationSeconds': null,
        'createdAt': FieldValue.serverTimestamp(),
      },
    );

    await _updateConversation(conversationId);
  }

  // ==========================================================
  // VOICE MESSAGE
  // ==========================================================

  Future<void> sendVoiceMessage({
    required String walkId,
    required String requestId,
    required String sessionId,
    required String senderUid,
    required String receiverUid,
    required String audioUrl,
    int durationSeconds = 0,
  }) async {
    final String url = audioUrl.trim();

    if (url.isEmpty) {
      return;
    }

    final String conversationId = getConversationId(
      walkId: walkId,
      requestId: requestId,
      sessionId: sessionId,
    );

    if (conversationId.isEmpty) {
      throw ArgumentError(
        'Current walk ID is required.',
      );
    }

    await _validateCurrentConversation(
      conversationId: conversationId,
      walkId: walkId,
      requestId: requestId,
      sessionId: sessionId,
    );

    await _messagesRef(conversationId).add(
      <String, dynamic>{
        'type': 'voice',
        'senderUid': senderUid.trim(),
        'receiverUid': receiverUid.trim(),
        'text': '',
        'mediaUrl': url,
        'durationSeconds':
            durationSeconds < 0 ? 0 : durationSeconds,
        'createdAt': FieldValue.serverTimestamp(),
      },
    );

    await _updateConversation(conversationId);
  }

  // ==========================================================
  // CLOSE CONVERSATION
  // ==========================================================

  Future<void> closeConversation({
    required String walkId,
    required String requestId,
    required String sessionId,
  }) async {
    final String conversationId = getConversationId(
      walkId: walkId,
      requestId: requestId,
      sessionId: sessionId,
    );

    if (conversationId.isEmpty) {
      return;
    }

    await _conversationRef(conversationId).set(
      <String, dynamic>{
        'status': 'completed',
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  // ==========================================================
  // GET CONVERSATION
  // ==========================================================

  Future<ContactModel?> getConversation({
    required String walkId,
    required String requestId,
    required String sessionId,
  }) async {
    final String conversationId = getConversationId(
      walkId: walkId,
      requestId: requestId,
      sessionId: sessionId,
    );

    if (conversationId.isEmpty) {
      return null;
    }

    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await _conversationRef(conversationId).get();

    if (!snapshot.exists) {
      return null;
    }

    final Map<String, dynamic> data =
        snapshot.data() ?? <String, dynamic>{};

    final String storedWalkId =
        data['walkId']?.toString().trim() ?? '';

    final String storedRequestId =
        data['requestId']?.toString().trim() ?? '';

    final String storedSessionId =
        data['sessionId']?.toString().trim() ?? '';

    if (walkId.trim().isNotEmpty &&
        storedWalkId != walkId.trim()) {
      return null;
    }

    if (requestId.trim().isNotEmpty &&
        storedRequestId != requestId.trim()) {
      return null;
    }

    if (sessionId.trim().isNotEmpty &&
        storedSessionId != sessionId.trim()) {
      return null;
    }

    return ContactModel.fromMap(data);
  }

  // ==========================================================
  // VALIDATE CURRENT CONVERSATION
  // ==========================================================

  Future<void> _validateCurrentConversation({
    required String conversationId,
    required String walkId,
    required String requestId,
    required String sessionId,
  }) async {
    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await _conversationRef(conversationId).get();

    if (!snapshot.exists) {
      throw StateError(
        'Current walk conversation does not exist.',
      );
    }

    final Map<String, dynamic> data =
        snapshot.data() ?? <String, dynamic>{};

    final String storedWalkId =
        data['walkId']?.toString().trim() ?? '';

    final String storedRequestId =
        data['requestId']?.toString().trim() ?? '';

    final String storedSessionId =
        data['sessionId']?.toString().trim() ?? '';

    if (walkId.trim().isNotEmpty &&
        storedWalkId != walkId.trim()) {
      throw StateError(
        'Conversation does not belong to current walk.',
      );
    }

    if (requestId.trim().isNotEmpty &&
        storedRequestId != requestId.trim()) {
      throw StateError(
        'Conversation does not belong to current request.',
      );
    }

    if (sessionId.trim().isNotEmpty &&
        storedSessionId != sessionId.trim()) {
      throw StateError(
        'Conversation does not belong to current session.',
      );
    }
  }

  // ==========================================================
  // UPDATE CONVERSATION
  // ==========================================================

  Future<void> _updateConversation(
    String conversationId,
  ) async {
    await _conversationRef(conversationId).set(
      <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}

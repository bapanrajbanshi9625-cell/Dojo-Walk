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

  // ============================================================
  // CURRENT CONVERSATION ID
  // ============================================================

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

  // ============================================================
  // CONVERSATION DOCUMENT
  // ============================================================

  DocumentReference<Map<String, dynamic>> _conversationRef(
    String conversationId,
  ) {
    return _conversations.doc(conversationId);
  }

  // ============================================================
  // MESSAGES COLLECTION
  // ============================================================

  CollectionReference<Map<String, dynamic>> _messagesRef(
    String conversationId,
  ) {
    return _conversationRef(conversationId).collection('messages');
  }

  // ============================================================
  // CREATE / UPDATE CURRENT WALK CONVERSATION
  // ============================================================

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

  // ============================================================
  // CURRENT CONVERSATION STREAM
  // ============================================================

  Stream<DocumentSnapshot<Map<String, dynamic>>>
      conversationStream({
    required String walkId,
    required String requestId,
    required String sessionId,
  }) {
    final String conversationId =
        getConversationId(
      walkId: walkId,
      requestId: requestId,
      sessionId: sessionId,
    );

    if (conversationId.isEmpty) {
      return const Stream.empty();
    }

    return _conversationRef(conversationId).snapshots();
  }

  // ============================================================
  // CURRENT WALK MESSAGES ONLY
  // ============================================================

  Stream<List<ContactMessage>> messagesStream({
    required String walkId,
    required String requestId,
    required String sessionId,
  }) {
    final String conversationId =
        getConversationId(
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

  // ============================================================
  // SEND MESSAGE
  // ============================================================

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

    final String conversationId =
        getConversationId(
      walkId: walkId,
      requestId: requestId,
      sessionId: sessionId,
    );

    if (conversationId.isEmpty) {
      throw ArgumentError(
        'Current walk ID is required.',
      );
    }

    final DocumentReference<Map<String, dynamic>>
        conversationRef =
        _conversationRef(conversationId);

    final DocumentSnapshot<Map<String, dynamic>>
        conversationSnapshot =
        await conversationRef.get();

    // ==========================================================
    // SAFETY CHECK
    // ==========================================================
    //
    // Message sirf usi conversation mein jayega jo
    // CURRENT walk se belong karti hai.
    //

    if (conversationSnapshot.exists) {
      final Map<String, dynamic> data =
          conversationSnapshot.data() ??
              <String, dynamic>{};

      final String storedWalkId =
          data['walkId']?.toString().trim() ?? '';

      final String storedRequestId =
          data['requestId']?.toString().trim() ?? '';

      final String storedSessionId =
          data['sessionId']?.toString().trim() ?? '';

      final bool walkMatches =
          walkId.trim().isEmpty ||
          storedWalkId == walkId.trim();

      final bool requestMatches =
          requestId.trim().isEmpty ||
          storedRequestId == requestId.trim();

      final bool sessionMatches =
          sessionId.trim().isEmpty ||
          storedSessionId == sessionId.trim();

      if (!walkMatches ||
          !requestMatches ||
          !sessionMatches) {
        throw StateError(
          'Conversation does not belong to the current walk.',
        );
      }
    } else {
      throw StateError(
        'Current walk conversation does not exist.',
      );
    }

    // ==========================================================
    // ADD MESSAGE
    // ==========================================================

    await _messagesRef(conversationId).add(
      <String, dynamic>{
        'senderUid': senderUid.trim(),
        'receiverUid': receiverUid.trim(),
        'text': message,
        'createdAt': FieldValue.serverTimestamp(),
      },
    );

    // ==========================================================
    // UPDATE CONVERSATION
    // ==========================================================

    await conversationRef.update(
      <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );
  }

  // ============================================================
  // CLOSE CURRENT CONVERSATION
  // ============================================================

  Future<void> closeConversation({
    required String walkId,
    required String requestId,
    required String sessionId,
  }) async {
    final String conversationId =
        getConversationId(
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

  // ============================================================
  // GET CURRENT CONVERSATION ONCE
  // ============================================================

  Future<ContactModel?> getConversation({
    required String walkId,
    required String requestId,
    required String sessionId,
  }) async {
    final String conversationId =
        getConversationId(
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

    // ==========================================================
    // EXTRA CURRENT-WALK VALIDATION
    // ==========================================================

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
}

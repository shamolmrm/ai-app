import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../../core/constants/app_constants.dart';
import 'package:uuid/uuid.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // ─── Chat CRUD ────────────────────────────────────────────────────────────

  Future<ChatModel> createChat(String userId, String firstMessage) async {
    final id = _uuid.v4();
    final title = firstMessage.length > 40
        ? '${firstMessage.substring(0, 40)}…'
        : firstMessage;

    final chat = ChatModel(
      id: id,
      userId: userId,
      title: title,
      lastMessage: firstMessage,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _db
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .collection(AppConstants.chatsCollection)
        .doc(id)
        .set(chat.toMap());

    await _incrementUserStat(userId, 'totalChats');
    return chat;
  }

  Stream<List<ChatModel>> watchChats(String userId) {
    return _db
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .collection(AppConstants.chatsCollection)
        .orderBy('updatedAt', descending: true)
        .limit(AppConstants.chatsPerPage)
        .snapshots()
        .map((snap) => snap.docs.map(ChatModel.fromFirestore).toList());
  }

  Future<void> deleteChat(String userId, String chatId) async {
    final messagesRef = _db
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .collection(AppConstants.chatsCollection)
        .doc(chatId)
        .collection(AppConstants.messagesSubcollection);

    final batch = _db.batch();
    final messages = await messagesRef.get();
    for (final doc in messages.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_db
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .collection(AppConstants.chatsCollection)
        .doc(chatId));

    await batch.commit();
  }

  Future<void> updateChatTitle(String userId, String chatId, String title) async {
    await _db
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .collection(AppConstants.chatsCollection)
        .doc(chatId)
        .update({'title': title});
  }

  // ─── Message CRUD ─────────────────────────────────────────────────────────

  Future<MessageModel> saveMessage({
    required String userId,
    required String chatId,
    required String content,
    required MessageRole role,
  }) async {
    final id = _uuid.v4();
    final message = MessageModel(
      id: id,
      chatId: chatId,
      content: content,
      role: role,
      timestamp: DateTime.now(),
    );

    await _db
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .collection(AppConstants.chatsCollection)
        .doc(chatId)
        .collection(AppConstants.messagesSubcollection)
        .doc(id)
        .set(message.toMap());

    // Update chat metadata
    await _db
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .collection(AppConstants.chatsCollection)
        .doc(chatId)
        .update({
      'lastMessage': content.length > 80 ? '${content.substring(0, 80)}…' : content,
      'updatedAt': Timestamp.now(),
      'messageCount': FieldValue.increment(1),
    });

    await _incrementUserStat(userId, 'totalMessages');
    return message;
  }

  Stream<List<MessageModel>> watchMessages(String userId, String chatId) {
    return _db
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .collection(AppConstants.chatsCollection)
        .doc(chatId)
        .collection(AppConstants.messagesSubcollection)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map(MessageModel.fromFirestore).toList());
  }

  Future<List<MessageModel>> getMessages(String userId, String chatId) async {
    final snap = await _db
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .collection(AppConstants.chatsCollection)
        .doc(chatId)
        .collection(AppConstants.messagesSubcollection)
        .orderBy('timestamp', descending: false)
        .get();
    return snap.docs.map(MessageModel.fromFirestore).toList();
  }

  // ─── User stats ───────────────────────────────────────────────────────────

  Future<void> _incrementUserStat(String userId, String field) async {
    await _db
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .update({field: FieldValue.increment(1)});
  }
}

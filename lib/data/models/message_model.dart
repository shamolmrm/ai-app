import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageRole { user, assistant }
enum MessageStatus { sending, sent, error }

class MessageModel {
  final String id;
  final String chatId;
  final String content;
  final MessageRole role;
  final MessageStatus status;
  final DateTime timestamp;
  final int? tokenCount;

  const MessageModel({
    required this.id,
    required this.chatId,
    required this.content,
    required this.role,
    this.status = MessageStatus.sent,
    required this.timestamp,
    this.tokenCount,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      chatId: data['chatId'] ?? '',
      content: data['content'] ?? '',
      role: data['role'] == 'user' ? MessageRole.user : MessageRole.assistant,
      status: MessageStatus.sent,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      tokenCount: data['tokenCount'],
    );
  }

  Map<String, dynamic> toMap() => {
    'chatId': chatId,
    'content': content,
    'role': role == MessageRole.user ? 'user' : 'assistant',
    'timestamp': Timestamp.fromDate(timestamp),
    'tokenCount': tokenCount,
  };

  MessageModel copyWith({String? content, MessageStatus? status, int? tokenCount}) =>
      MessageModel(
        id: id,
        chatId: chatId,
        content: content ?? this.content,
        role: role,
        status: status ?? this.status,
        timestamp: timestamp,
        tokenCount: tokenCount ?? this.tokenCount,
      );

  bool get isUser => role == MessageRole.user;
  bool get isAssistant => role == MessageRole.assistant;
}

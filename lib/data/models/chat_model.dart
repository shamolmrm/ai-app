import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String id;
  final String userId;
  final String title;
  final String lastMessage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int messageCount;
  final bool isPinned;

  const ChatModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.lastMessage,
    required this.createdAt,
    required this.updatedAt,
    this.messageCount = 0,
    this.isPinned = false,
  });

  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? 'New Chat',
      lastMessage: data['lastMessage'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      messageCount: data['messageCount'] ?? 0,
      isPinned: data['isPinned'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'title': title,
    'lastMessage': lastMessage,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
    'messageCount': messageCount,
    'isPinned': isPinned,
  };

  ChatModel copyWith({
    String? title,
    String? lastMessage,
    DateTime? updatedAt,
    int? messageCount,
    bool? isPinned,
  }) =>
      ChatModel(
        id: id,
        userId: userId,
        title: title ?? this.title,
        lastMessage: lastMessage ?? this.lastMessage,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        messageCount: messageCount ?? this.messageCount,
        isPinned: isPinned ?? this.isPinned,
      );

  String get formattedDate {
    final now = DateTime.now();
    final diff = now.difference(updatedAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${updatedAt.day}/${updatedAt.month}/${updatedAt.year}';
  }
}

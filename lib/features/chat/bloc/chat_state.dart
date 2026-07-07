import 'package:equatable/equatable.dart';
import '../../../data/models/chat_model.dart';
import '../../../data/models/message_model.dart';

abstract class ChatState extends Equatable {
  const ChatState();
  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {
  const ChatInitial();
}

class ChatHistoryLoading extends ChatState {
  const ChatHistoryLoading();
}

class ChatHistoryLoaded extends ChatState {
  final List<ChatModel> chats;
  const ChatHistoryLoaded({required this.chats});
  @override
  List<Object?> get props => [chats];
}

class ChatSessionActive extends ChatState {
  final String chatId;
  final String userId;
  final List<MessageModel> messages;
  final bool isStreaming;
  final String streamingContent;
  final String? errorMessage;

  const ChatSessionActive({
    required this.chatId,
    required this.userId,
    required this.messages,
    this.isStreaming = false,
    this.streamingContent = '',
    this.errorMessage,
  });

  ChatSessionActive copyWith({
    String? chatId,
    String? userId,
    List<MessageModel>? messages,
    bool? isStreaming,
    String? streamingContent,
    String? errorMessage,
  }) =>
      ChatSessionActive(
        chatId: chatId ?? this.chatId,
        userId: userId ?? this.userId,
        messages: messages ?? this.messages,
        isStreaming: isStreaming ?? this.isStreaming,
        streamingContent: streamingContent ?? this.streamingContent,
        errorMessage: errorMessage,
      );

  @override
  List<Object?> get props =>
      [chatId, userId, messages, isStreaming, streamingContent, errorMessage];
}

class ChatError extends ChatState {
  final String message;
  const ChatError({required this.message});
  @override
  List<Object?> get props => [message];
}

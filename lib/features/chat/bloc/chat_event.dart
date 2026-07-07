import 'package:equatable/equatable.dart';
import '../../../data/models/message_model.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();
  @override
  List<Object?> get props => [];
}

class ChatLoadHistory extends ChatEvent {
  final String userId;
  const ChatLoadHistory({required this.userId});
  @override
  List<Object?> get props => [userId];
}

class ChatStartNew extends ChatEvent {
  const ChatStartNew();
}

class ChatOpenExisting extends ChatEvent {
  final String chatId;
  final String userId;
  const ChatOpenExisting({required this.chatId, required this.userId});
  @override
  List<Object?> get props => [chatId, userId];
}

class ChatSendMessage extends ChatEvent {
  final String userId;
  final String content;
  const ChatSendMessage({required this.userId, required this.content});
  @override
  List<Object?> get props => [userId, content];
}

class ChatStreamChunkReceived extends ChatEvent {
  final String chunk;
  const ChatStreamChunkReceived({required this.chunk});
  @override
  List<Object?> get props => [chunk];
}

class ChatStreamCompleted extends ChatEvent {
  const ChatStreamCompleted();
}

class ChatStreamError extends ChatEvent {
  final String error;
  const ChatStreamError({required this.error});
  @override
  List<Object?> get props => [error];
}

class ChatDeleteChat extends ChatEvent {
  final String userId;
  final String chatId;
  const ChatDeleteChat({required this.userId, required this.chatId});
  @override
  List<Object?> get props => [userId, chatId];
}

class ChatMessagesUpdated extends ChatEvent {
  final List<MessageModel> messages;
  const ChatMessagesUpdated({required this.messages});
  @override
  List<Object?> get props => [messages];
}

class ChatHistoryUpdated extends ChatEvent {
  final List<dynamic> chats;
  const ChatHistoryUpdated({required this.chats});
  @override
  List<Object?> get props => [chats];
}

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/chat_model.dart';
import '../../../data/models/message_model.dart';
import '../../../data/repositories/chat_repository.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _chatRepository;
  StreamSubscription? _historySub;
  StreamSubscription? _messagesSub;
  StreamSubscription? _aiStreamSub;

  ChatBloc({required ChatRepository chatRepository})
      : _chatRepository = chatRepository,
        super(const ChatInitial()) {
    on<ChatLoadHistory>(_onLoadHistory);
    on<ChatHistoryUpdated>(_onHistoryUpdated);
    on<ChatStartNew>(_onStartNew);
    on<ChatOpenExisting>(_onOpenExisting);
    on<ChatSendMessage>(_onSendMessage);
    on<ChatStreamChunkReceived>(_onStreamChunk);
    on<ChatStreamCompleted>(_onStreamCompleted);
    on<ChatStreamError>(_onStreamError);
    on<ChatDeleteChat>(_onDeleteChat);
    on<ChatMessagesUpdated>(_onMessagesUpdated);
  }

  void _onLoadHistory(ChatLoadHistory event, Emitter<ChatState> emit) {
    emit(const ChatHistoryLoading());
    _historySub?.cancel();
    _historySub = _chatRepository
        .watchChats(event.userId)
        .listen(
          (chats) => add(ChatHistoryUpdated(chats: chats)),
          onError: (_) {},
        );
  }

  void _onHistoryUpdated(ChatHistoryUpdated event, Emitter<ChatState> emit) {
    // Never overwrite an active chat session
    if (state is ChatHistoryLoading || state is ChatHistoryLoaded || state is ChatInitial) {
      emit(ChatHistoryLoaded(chats: List<ChatModel>.from(event.chats)));
    }
  }

  void _onStartNew(ChatStartNew event, Emitter<ChatState> emit) {
    _messagesSub?.cancel();
    _aiStreamSub?.cancel();
    emit(const ChatInitial());
  }

  void _onOpenExisting(ChatOpenExisting event, Emitter<ChatState> emit) {
    _messagesSub?.cancel();
    emit(ChatSessionActive(
      chatId: event.chatId,
      userId: event.userId,
      messages: const [],
    ));
    _messagesSub = _chatRepository
        .watchMessages(event.userId, event.chatId)
        .listen((messages) => add(ChatMessagesUpdated(messages: messages)));
  }

  void _onMessagesUpdated(ChatMessagesUpdated event, Emitter<ChatState> emit) {
    final current = state;
    if (current is ChatSessionActive && !current.isStreaming) {
      // Only sync from Firestore when not actively streaming
      emit(current.copyWith(messages: event.messages));
    }
  }

  Future<void> _onSendMessage(
    ChatSendMessage event,
    Emitter<ChatState> emit,
  ) async {
    await _chatRepository.loadAiConfig();

    String chatId;
    List<MessageModel> currentMessages;

    final current = state;
    if (current is ChatSessionActive) {
      chatId = current.chatId;
      currentMessages = List.from(current.messages);
    } else {
      final chat = await _chatRepository.createChat(event.userId, event.content);
      chatId = chat.id;
      currentMessages = [];

      _messagesSub?.cancel();
      _messagesSub = _chatRepository
          .watchMessages(event.userId, chatId)
          .listen((messages) => add(ChatMessagesUpdated(messages: messages)));
    }

    // Add user message to state immediately — no Firestore wait
    final userMsg = MessageModel(
      id: const Uuid().v4(),
      chatId: chatId,
      content: event.content,
      role: MessageRole.user,
      status: MessageStatus.sending,
      timestamp: DateTime.now(),
    );
    currentMessages = [...currentMessages, userMsg];

    emit(ChatSessionActive(
      chatId: chatId,
      userId: event.userId,
      messages: currentMessages,
      isStreaming: true,
      streamingContent: '',
    ));

    // Save user message to Firestore in background
    _chatRepository
        .saveMessage(
          userId: event.userId,
          chatId: chatId,
          content: event.content,
          role: MessageRole.user,
        )
        .ignore();

    // Start AI stream
    _aiStreamSub?.cancel();
    _aiStreamSub = _chatRepository
        .streamAiResponse(currentMessages.where((m) => m.status == MessageStatus.sent).toList(), event.content)
        .listen(
          (chunk) => add(ChatStreamChunkReceived(chunk: chunk)),
          onDone: () => add(const ChatStreamCompleted()),
          onError: (e) => add(ChatStreamError(error: e.toString())),
        );
  }

  void _onStreamChunk(ChatStreamChunkReceived event, Emitter<ChatState> emit) {
    final current = state;
    if (current is ChatSessionActive) {
      emit(current.copyWith(
        streamingContent: current.streamingContent + event.chunk,
      ));
    }
  }

  Future<void> _onStreamCompleted(
    ChatStreamCompleted event,
    Emitter<ChatState> emit,
  ) async {
    final current = state;
    if (current is! ChatSessionActive) return;

    final fullResponse = current.streamingContent;
    if (fullResponse.isEmpty) return;

    // Add AI message to state immediately — no Firestore wait
    final aiMsg = MessageModel(
      id: const Uuid().v4(),
      chatId: current.chatId,
      content: fullResponse,
      role: MessageRole.assistant,
      status: MessageStatus.sent,
      timestamp: DateTime.now(),
    );

    emit(current.copyWith(
      isStreaming: false,
      streamingContent: '',
      messages: [...current.messages, aiMsg],
    ));

    // Save AI message to Firestore in background
    _chatRepository
        .saveMessage(
          userId: current.userId,
          chatId: current.chatId,
          content: fullResponse,
          role: MessageRole.assistant,
        )
        .ignore();
  }

  void _onStreamError(ChatStreamError event, Emitter<ChatState> emit) {
    final current = state;
    if (current is ChatSessionActive) {
      emit(current.copyWith(
        isStreaming: false,
        streamingContent: '',
        errorMessage: event.error.replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> _onDeleteChat(
    ChatDeleteChat event,
    Emitter<ChatState> emit,
  ) async {
    await _chatRepository.deleteChat(event.userId, event.chatId);
    add(ChatLoadHistory(userId: event.userId));
  }

  @override
  Future<void> close() {
    _historySub?.cancel();
    _messagesSub?.cancel();
    _aiStreamSub?.cancel();
    return super.close();
  }
}

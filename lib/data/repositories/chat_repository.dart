import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../services/firestore_service.dart';
import '../services/ai_service.dart';

class ChatRepository {
  final FirestoreService _firestoreService;
  final AiService _aiService;

  ChatRepository({
    FirestoreService? firestoreService,
    AiService? aiService,
  })  : _firestoreService = firestoreService ?? FirestoreService(),
        _aiService = aiService ?? AiService();

  Stream<List<ChatModel>> watchChats(String userId) =>
      _firestoreService.watchChats(userId);

  Future<ChatModel> createChat(String userId, String firstMessage) =>
      _firestoreService.createChat(userId, firstMessage);

  Future<void> deleteChat(String userId, String chatId) =>
      _firestoreService.deleteChat(userId, chatId);

  Future<void> updateChatTitle(String userId, String chatId, String title) =>
      _firestoreService.updateChatTitle(userId, chatId, title);

  Stream<List<MessageModel>> watchMessages(String userId, String chatId) =>
      _firestoreService.watchMessages(userId, chatId);

  Future<List<MessageModel>> getMessages(String userId, String chatId) =>
      _firestoreService.getMessages(userId, chatId);

  Future<MessageModel> saveMessage({
    required String userId,
    required String chatId,
    required String content,
    required MessageRole role,
  }) =>
      _firestoreService.saveMessage(
        userId: userId,
        chatId: chatId,
        content: content,
        role: role,
      );

  Stream<String> streamAiResponse(
    List<MessageModel> history,
    String userMessage,
  ) =>
      _aiService.streamResponse(history, userMessage);

  Future<void> configureAi({
    required String apiKey,
    String? customModel,
    String? provider,
  }) =>
      _aiService.saveConfig(
        apiKey: apiKey,
        customModel: customModel,
        provider: provider,
      );

  Future<void> loadAiConfig() => _aiService.loadConfig();
  bool get isAiConfigured => _aiService.isConfigured;
  String get activeAiProvider => _aiService.activeProvider;
}

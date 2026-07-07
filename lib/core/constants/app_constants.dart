class AppConstants {
  AppConstants._();

  static const String appName = 'AI Assistant';
  static const String appVersion = '1.0.0';

  // AI Provider - switch between 'anthropic' or 'openai'
  static const String aiProvider = 'anthropic';

  // Anthropic (Claude) configuration
  static const String anthropicBaseUrl = 'https://api.anthropic.com/v1';
  static const String anthropicModel = 'claude-sonnet-4-6';
  // To use your own fine-tuned model, replace the model ID above.

  // OpenAI configuration
  static const String openaiBaseUrl = 'https://api.openai.com/v1';
  static const String openaiModel = 'gpt-4o';

  // Groq configuration (FREE - fast Llama 3)
  static const String groqBaseUrl = 'https://api.groq.com/openai/v1';
  static const String groqModel = 'llama-3.3-70b-versatile';

  // Firestore collection names
  static const String usersCollection = 'users';
  static const String chatsCollection = 'chats';
  static const String messagesSubcollection = 'messages';

  // SharedPreferences keys
  static const String themeKey = 'theme_mode';
  static const String apiKeyKey = 'api_key';
  static const String aiProviderKey = 'ai_provider';
  static const String customModelKey = 'custom_model';

  // Pagination
  static const int messagesPerPage = 20;
  static const int chatsPerPage = 15;

  // Animation durations
  static const Duration shortAnim = Duration(milliseconds: 200);
  static const Duration medAnim = Duration(milliseconds: 350);
  static const Duration longAnim = Duration(milliseconds: 600);
}

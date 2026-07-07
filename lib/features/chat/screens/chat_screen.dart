import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';
import '../widgets/message_bubble.dart';
import '../widgets/chat_input.dart';
import '../../../core/theme/app_colors.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _scrollCtrl = ScrollController();

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final userId = authState is AuthAuthenticated ? authState.user.uid : '';

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: _buildAppBar(context),
      body: BlocConsumer<ChatBloc, ChatState>(
        listener: (context, state) {
          if (state is ChatSessionActive) _scrollToBottom();
        },
        builder: (context, state) {
          if (state is ChatInitial) {
            return _buildWelcomeView(context, userId);
          }

          if (state is ChatSessionActive) {
            return Column(
              children: [
                Expanded(
                  child: _buildMessageList(state),
                ),
                if (state.errorMessage != null)
                  _buildErrorBanner(state.errorMessage!),
                ChatInputBar(
                  isStreaming: state.isStreaming,
                  onSend: (text) {
                    context.read<ChatBloc>().add(
                          ChatSendMessage(userId: userId, content: text),
                        );
                  },
                ),
              ],
            );
          }

          return _buildWelcomeView(context, userId);
        },
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.darkSurface,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          const Text('AI Assistant'),
        ],
      ),
      actions: [
        BlocBuilder<ChatBloc, ChatState>(
          builder: (context, state) {
            if (state is ChatSessionActive) {
              return IconButton(
                icon: const Icon(Icons.more_vert_rounded),
                onPressed: () => _showChatOptions(context, state.chatId,
                    context.read<AuthBloc>().state is AuthAuthenticated
                        ? (context.read<AuthBloc>().state as AuthAuthenticated)
                            .user
                            .uid
                        : ''),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildMessageList(ChatSessionActive state) {
    final allMessages = <Widget>[];

    for (int i = 0; i < state.messages.length; i++) {
      allMessages.add(
        MessageBubble(message: state.messages[i], index: i),
      );
    }

    if (state.isStreaming) {
      allMessages.add(StreamingBubble(content: state.streamingContent));
    }

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      itemCount: allMessages.length,
      itemBuilder: (_, i) => allMessages[i],
    );
  }

  Widget _buildWelcomeView(BuildContext context, String userId) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 24,
                          spreadRadius: 4,
                        )
                      ],
                    ),
                    child: const Icon(Icons.auto_awesome,
                        color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'How can I help you today?',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Ask me anything — questions, analysis, creative writing, code, and much more.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  _buildSuggestions(context, userId),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
        ChatInputBar(
          onSend: (text) {
            context.read<ChatBloc>().add(
                  ChatSendMessage(userId: userId, content: text),
                );
          },
        ),
      ],
    );
  }

  Widget _buildSuggestions(BuildContext context, String userId) {
    const suggestions = [
      'Explain quantum computing simply',
      'Write a short poem about the ocean',
      'Give me a recipe for pasta',
      'Help me debug my code',
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: suggestions
          .map((s) => GestureDetector(
                onTap: () => context.read<ChatBloc>().add(
                      ChatSendMessage(userId: userId, content: s),
                    ),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.darkCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.darkBorder),
                  ),
                  child: Text(s,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.primary,
                            fontSize: 13,
                          )),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                    color: AppColors.error, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  void _showChatOptions(
      BuildContext context, String chatId, String userId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.darkBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.error),
              title: const Text('Delete Chat',
                  style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(context);
                context.read<ChatBloc>().add(
                      ChatDeleteChat(userId: userId, chatId: chatId),
                    );
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_rounded,
                  color: AppColors.primary),
              title: const Text('New Chat'),
              onTap: () {
                Navigator.pop(context);
                context.read<ChatBloc>().add(const ChatStartNew());
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

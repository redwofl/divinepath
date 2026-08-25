import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/locale_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/chat_model.dart';
import '../../utils/helpers.dart';
import '../../utils/translations.dart';
import '../../widgets/common/language_switcher_button.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _showSuggestions = true;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    context.read<ChatProvider>().sendMessage(text);
    _messageController.clear();
    _showSuggestions = false;

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textOnDark : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.textLight : AppColors.textSecondary;
    final textLight = AppColors.textLight;
    final cardColor = isDark ? AppColors.darkCard : Colors.white;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.secondary;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: AppColors.sunsetGradient,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.2),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.auto_awesome_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Translations.t('chat_empty_title',
                              locale: context
                                  .read<LocaleProvider>()
                                  .localeCode),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          Translations.t('chat_spiritual_assistant',
                              locale: context
                                  .read<LocaleProvider>()
                                  .localeCode),
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const LanguageSwitcherButton(),
                  const SizedBox(width: 8),
                  // New chat
                  GestureDetector(
                    onTap: () {
                      provider.startNewConversation();
                      _showSuggestions = true;
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.edit_rounded,
                          color: AppColors.primary, size: 20),
                    ),
                  ),
                ],
              ),
            ),

            // Messages
            Expanded(
              child: provider.messages.isEmpty
                  ? _buildEmptyState(provider, isDark, textPrimary, textSecondary, cardColor, surfaceColor, textLight)
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(20),
                      itemCount: provider.messages.length + (_showSuggestions ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= provider.messages.length) {
                          return _showSuggestions ? _buildSuggestions(provider, isDark, textPrimary, textSecondary, cardColor, surfaceColor, textLight) : const SizedBox.shrink();
                        }
                         final message = provider.messages[index];
                         return _buildMessageBubble(message, isDark, textPrimary, textSecondary, cardColor, surfaceColor, textLight);
                      },
                    ),
            ),

            // Loading indicator
            if (provider.isLoading)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              ),

            // Input area
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Voice input
                  GestureDetector(
                    onTap: () {
                      if (provider.isListening) {
                        provider.stopVoiceInput();
                      } else {
                        provider.startVoiceInput();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: provider.isListening
                            ? AppColors.error.withOpacity(0.1)
                            : AppColors.secondary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        provider.isListening
                            ? Icons.mic_rounded
                            : Icons.mic_none_rounded,
                        color: provider.isListening
                            ? AppColors.error
                            : AppColors.primary,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Text input
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: textLight.withOpacity(0.2),
                        ),
                      ),
                      child: TextField(
                        controller: _messageController,
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: 1,
                        style: TextStyle(color: textPrimary),
                        decoration: InputDecoration(
                          hintText: Translations.t('chat_hint',
                              locale:
                                  context.read<LocaleProvider>().localeCode),
                          hintStyle: TextStyle(color: textSecondary),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Send button
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.send_rounded,
                          color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ChatProvider provider, bool isDark, Color textPrimary, Color textSecondary, Color cardColor, Color surfaceColor, Color textLight) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 40),
        // Avatar
        Center(
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: AppColors.sunsetGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                size: 50, color: Colors.white),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Text(
            Translations.t('chat_empty_title',
                locale: context.read<LocaleProvider>().localeCode),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
        ),
        SizedBox(height: 8),
        Center(
          child: Text(
            Translations.t('chat_empty_description',
                locale: context.read<LocaleProvider>().localeCode),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: textSecondary,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Suggested questions
        _buildSuggestions(provider, isDark, textPrimary, textSecondary, cardColor, surfaceColor, textLight),
      ],
    );
  }

  Widget _buildSuggestions(ChatProvider provider, bool isDark, Color textPrimary, Color textSecondary, Color cardColor, Color surfaceColor, Color textLight) {
    final questions = provider.getSuggestedQuestions();
    final locale = context.read<LocaleProvider>().localeCode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            Translations.t('chat_try_asking', locale: locale),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textSecondary,
            ),
          ),
        ),
        ...questions.map((q) {
          final localizedQuestion = q.translationKey.isNotEmpty
              ? Translations.t(q.translationKey, locale: locale)
              : q.question;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () {
                provider.sendMessage(localizedQuestion);
                _showSuggestions = false;
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.1),
                  ),
                ),
                child: Row(
                  children: [
                    if (q.icon != null) ...[
                      Text(q.icon!, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Text(
                        localizedQuestion,
                        style: TextStyle(
                          fontSize: 13,
                          color: textPrimary,
                        ),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded,
                        size: 12, color: textLight),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isDark, Color textPrimary, Color textSecondary, Color cardColor, Color surfaceColor, Color textLight) {
    final provider = context.read<ChatProvider>();
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: AppColors.sunsetGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
          ],

          // Message content
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : cardColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(
                      isUser ? 16 : 4),
                  bottomRight: Radius.circular(
                      isUser ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isUser ? AppColors.primary : textLight)
                        .withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    message.content,
                    style: TextStyle(
                      fontSize: 15,
                      color: isUser ? Colors.white : textPrimary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        Helpers.timeAgo(message.timestamp),
                        style: TextStyle(
                          fontSize: 11,
                          color: isUser
                              ? Colors.white.withOpacity(0.6)
                              : textLight,
                        ),
                      ),
                      if (!isUser) ...[
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () {
                            // Tap again to stop, tap to play
                            if (provider.isVoicePlaying &&
                                provider.voicePlayingMessageId == message.id) {
                              provider.stopVoicePlayback();
                            } else {
                              provider.startVoicePlayback(
                                  message.content, message.id);
                            }
                          },
                          child: Icon(
                            provider.isVoicePlaying &&
                                    provider.voicePlayingMessageId == message.id
                                ? Icons.volume_up_rounded
                                : Icons.volume_up_outlined,
                            size: 16,
                            color: textLight,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () async {
                            await Clipboard.setData(
                                ClipboardData(text: message.content));
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(Translations.t(
                                      'copied_to_clipboard',
                                      locale: context
                                          .read<LocaleProvider>()
                                          .localeCode)),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            }
                          },
                           child: Icon(Icons.copy_rounded,
                               size: 16, color: textLight),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.person_rounded,
                  color: AppColors.primary, size: 18),
            ),
          ],
        ],
      ),
    );
  }
}



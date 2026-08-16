import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/gemini_service.dart';
import '../services/firebase_service.dart';
import '../services/audio_service.dart';
import '../models/chat_model.dart';

class ChatProvider extends ChangeNotifier {
  final GeminiService _geminiService = GeminiService();
  final FirebaseService _firebaseService = FirebaseService.instance;

  List<ChatMessage> _messages = [];
  List<ChatConversation> _conversations = [];
  String? _currentConversationId;
  bool _isLoading = false;
  bool _isListening = false;
  bool _isVoicePlaying = false;
  String? _voicePlayingMessageId;
  String? _error;

  // Getters
  List<ChatMessage> get messages => _messages;
  List<ChatConversation> get conversations => _conversations;
  String? get currentConversationId => _currentConversationId;
  bool get isLoading => _isLoading;
  bool get isListening => _isListening;
  bool get isVoicePlaying => _isVoicePlaying;
  String? get voicePlayingMessageId => _voicePlayingMessageId;
  String? get error => _error;

  /// Initialize chat provider
  Future<void> initialize() async {
    // Initialize Gemini (API key should come from user config)
    // await _geminiService.initialize('YOUR_GEMINI_API_KEY');

    // Keep the speaker icon in sync with real TTS playback state
    AudioService.instance.ttsPlaying.addListener(_onTtsStateChanged);

    await _loadConversations();
    startNewConversation();
  }

  void _onTtsStateChanged() {
    final playing = AudioService.instance.ttsPlaying.value;
    if (_isVoicePlaying != playing) {
      _isVoicePlaying = playing;
      if (!playing) _voicePlayingMessageId = null;
      notifyListeners();
    }
  }

  /// Initialize Gemini AI with API key
  Future<void> initializeGemini(String apiKey) async {
    await _geminiService.initialize(apiKey);
  }

  /// Start a new conversation
  void startNewConversation() {
    _currentConversationId = DateTime.now().millisecondsSinceEpoch.toString();
    _messages = [];
    _geminiService.startNewChat();

    // Add welcome message
    _messages.add(ChatMessage(
      id: 'welcome',
      content: 'Namaste! 🙏 I am Divine Guide AI, a spiritual assistant inspired by sacred teachings. How may I help you on your spiritual journey today? You can ask me about meditation, mantra chanting, spiritual texts like the Bhagavad Gita, or any questions about life and spirituality.',
      isUser: false,
      timestamp: DateTime.now(),
    ));

    notifyListeners();
  }

  /// Send a message
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    // Add user message
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content.trim(),
      isUser: true,
    );
    _messages.add(userMessage);
    _isLoading = true;
    notifyListeners();

    try {
      // Get AI response
      final response = await _geminiService.sendMessage(content);

      final aiMessage = ChatMessage(
        id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
        content: response,
        isUser: false,
      );
      _messages.add(aiMessage);

      // Save conversation
      await _saveConversation(content, response);
    } catch (e) {
      _error = 'Failed to get response. Please try again.';
      debugPrint('Chat error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Start voice input
  void startVoiceInput() {
    _isListening = true;
    notifyListeners();
    // Speech-to-text would be implemented with speech_to_text package
  }

  /// Stop voice input
  void stopVoiceInput() {
    _isListening = false;
    notifyListeners();
  }

  /// Play AI response as voice using the app's TTS service
  Future<void> startVoicePlayback(String text, String messageId) async {
    // Stop any ongoing playback before starting a new one
    await AudioService.instance.stopSpeaking();
    _voicePlayingMessageId = messageId;
    _isVoicePlaying = true;
    notifyListeners();
    await AudioService.instance.speak(text);
  }

  /// Stop voice playback
  Future<void> stopVoicePlayback() async {
    await AudioService.instance.stopSpeaking();
    _isVoicePlaying = false;
    _voicePlayingMessageId = null;
    notifyListeners();
  }

  /// Save conversation to Firestore and local storage
  Future<void> _saveConversation(String userMessage, String aiResponse) async {
    try {
      // Save locally
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = _messages.map((m) => {
        'id': m.id,
        'content': m.content,
        'isUser': m.isUser,
        'timestamp': m.timestamp.toIso8601String(),
      }).toList();
      await prefs.setString('chat_messages_$_currentConversationId', json.encode(messagesJson));

      // Save to Firestore if user is authenticated
      final user = _firebaseService.currentUser;
      if (user != null && _currentConversationId != null) {
        final conversationData = {
          'userId': user.uid,
          'title': _getConversationTitle(),
          'messages': [
            {'content': userMessage, 'isUser': true, 'timestamp': DateTime.now().toIso8601String()},
            {'content': aiResponse, 'isUser': false, 'timestamp': DateTime.now().toIso8601String()},
          ],
          'timestamp': DateTime.now().toIso8601String(),
        };

        await _firebaseService.getDocument('chats', _currentConversationId!)
            .set(conversationData, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Error saving conversation: $e');
    }
  }

  /// Load conversations from local storage
  Future<void> _loadConversations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith('chat_'));
      for (final key in keys) {
        final jsonStr = prefs.getString(key);
        if (jsonStr != null) {
          try {
            final data = json.decode(jsonStr) as List;
            final messages = data.map((m) => ChatMessage(
              id: m['id'],
              content: m['content'],
              isUser: m['isUser'],
              timestamp: DateTime.parse(m['timestamp']),
            )).toList();

            if (messages.isNotEmpty) {
              final title = messages.first.content;
              _conversations.add(ChatConversation(
                id: key.replaceFirst('chat_messages_', ''),
                title: title.length > 30
                    ? '${title.substring(0, 30)}...'
                    : title,
                messages: messages,
              ));
            }
          } catch (e) {
            debugPrint('Error loading conversation $key: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading conversations: $e');
    }
  }

  /// Load a specific conversation
  void loadConversation(String conversationId) {
    _currentConversationId = conversationId;
    final conversation = _conversations.firstWhere(
      (c) => c.id == conversationId,
      orElse: () => ChatConversation(id: conversationId, title: 'Chat'),
    );
    _messages = conversation.messages;
    notifyListeners();
  }

  /// Delete a conversation
  Future<void> deleteConversation(String conversationId) async {
    try {
      _conversations.removeWhere((c) => c.id == conversationId);

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('chat_messages_$conversationId');

      if (_currentConversationId == conversationId) {
        startNewConversation();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting conversation: $e');
    }
  }

  /// Get conversation title from first user message
  String _getConversationTitle() {
    final firstUserMessage = _messages.firstWhere(
      (m) => m.isUser,
      orElse: () => ChatMessage(id: 'default', content: 'Spiritual Chat', isUser: true),
    );
    return firstUserMessage.content.length > 40
        ? '${firstUserMessage.content.substring(0, 40)}...'
        : firstUserMessage.content;
  }

  /// Copy message to clipboard
  String getCopyText(int index) {
    if (index < _messages.length) {
      return _messages[index].content;
    }
    return '';
  }

  /// Get suggested questions
  List<SuggestedQuestion> getSuggestedQuestions() {
    return SuggestedQuestion.spiritualQuestions;
  }
}

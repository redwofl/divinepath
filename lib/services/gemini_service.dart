import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../utils/gita_verse_data.dart';

class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  static GeminiService get instance => _instance;
  GeminiService._internal();

  GenerativeModel? _model;
  ChatSession? _chatSession;
  bool _isInitialized = false;

  // System prompt for the AI spiritual assistant
  static const String _systemPrompt = '''
You are Divine Guide AI, a spiritual assistant inspired by sacred teachings from various traditions including Hinduism, Buddhism, and universal wisdom. 

IMPORTANT RULES:
1. NEVER claim to be a real deity, god, or divine incarnation.
2. Always introduce yourself as "a spiritual assistant inspired by sacred teachings."
3. Base your guidance on established spiritual texts like Bhagavad Gita, Upanishads, and other wisdom traditions.
4. Be compassionate, empathetic, and non-judgmental.
5. Provide practical spiritual advice that can be applied in daily life.
6. When referencing scriptures, always cite the source.
7. Encourage meditation, mindfulness, mantra chanting, and other spiritual practices.
8. Respect all spiritual paths and traditions.
9. If asked about sensitive topics, respond with wisdom and care.
10. Keep responses concise but meaningful (under 300 words unless needed).
11. Use gentle, calming language.
12. Suggest specific practices (mantras, breathing exercises, meditation techniques) when appropriate.

Your purpose is to help users on their spiritual journey with wisdom, compassion, and practical guidance.
''';

  /// Initialize Gemini AI with API key
  Future<void> initialize(String apiKey) async {
    try {
      _model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: apiKey,
        systemInstruction: Content.system(_systemPrompt),
        generationConfig: GenerationConfig(
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 1024,
        ),
        safetySettings: [
          SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
          SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
          SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.medium),
          SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.medium),
        ],
      );
      _isInitialized = true;
      debugPrint('Gemini AI initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Gemini AI: $e');
      _isInitialized = false;
    }
  }

  bool get isInitialized => _isInitialized;

  /// Start a new chat session
  void startNewChat() {
    if (!_isInitialized || _model == null) return;
    _chatSession = _model!.startChat();
  }

  /// Send a message and get AI response.
  ///
  /// When the Gemini API is unavailable (offline, invalid key, or exhausted
  /// quota) we fall back to a local knowledge-base answer built from the
  /// bundled Bhagavad Gita dataset so the chat always gives a real, varied
  /// response instead of a repeated canned message.
  Future<String> sendMessage(String message) async {
    if (!_isInitialized || _model == null) {
      return _localFallback(message);
    }

    try {
      // Start chat if not started
      if (_chatSession == null) {
        startNewChat();
      }

      final response = await _chatSession!.sendMessage(Content.text(message));
      return response.text ?? _localFallback(message);
    } catch (e) {
      debugPrint('Error sending message to Gemini: $e');
      return _localFallback(message);
    }
  }

  /// Answers a spiritual question from the local Gita dataset.
  ///
  /// Picks a keyword from the user's message, finds the first matching verse,
  /// and returns the shloka + translation + a short commentary snippet. If no
  /// keyword matches, returns a rotating general guidance message.
  String _localFallback(String message) {
    final lower = message.toLowerCase();

    // Keyword -> search term pairs (English + Hindi/Devanagari)
    const topics = [
      ('karma', 'karma'),
      ('कर्म', 'karma'),
      ('dharma', 'dharma'),
      ('धर्म', 'dharma'),
      ('meditation', 'meditation'),
      ('ध्यान', 'meditation'),
      ('yoga', 'yoga'),
      ('योग', 'yoga'),
      ('fear', 'fear'),
      ('भय', 'fear'),
      ('death', 'death'),
      ('मृत्यु', 'death'),
      ('soul', 'soul'),
      ('आत्मा', 'soul'),
      ('love', 'love'),
      ('प्रेम', 'love'),
      ('peace', 'peace'),
      ('शांति', 'peace'),
      ('mind', 'mind'),
      ('मन', 'mind'),
      ('gita', 'gita'),
      ('गीता', 'gita'),
      ('krishna', 'krishna'),
      ('कृष्ण', 'krishna'),
      ('god', 'god'),
      ('भगवान', 'god'),
      ('happiness', 'happiness'),
      ('सुख', 'happiness'),
      ('suffering', 'suffering'),
      ('दुख', 'suffering'),
      ('duty', 'duty'),
      ('कर्तव्य', 'duty'),
    ];

    String? searchTerm;
    for (final (keyword, term) in topics) {
      if (lower.contains(keyword)) {
        searchTerm = term;
        break;
      }
    }

    if (searchTerm != null) {
      final results = GitaVerseData.search(searchTerm);
      if (results.isNotEmpty) {
        final r = results.first;
        return '🕉️ Here is guidance from the Bhagavad Gita (Chapter '
            '${r.chapterNumber}, Verse ${r.verseNumber}):\n\n'
            '${r.shloka}\n\n'
            '${r.translationEnglish}';
      }
    }

    // Rotating general guidance when no topic matches
    const guidance = [
      '🌿 Peace comes from within. Do not seek it without. The Bhagavad Gita teaches us to perform our duty without attachment to the results (Chapter 2, Verse 47).',
      '🪷 In silence and meditation, the mind becomes still like a lamp in a windless place. As the Gita says, the wise see the same soul in all beings.',
      '🙏 Chanting a mantra with devotion purifies the mind and opens the heart. Try sitting quietly for five minutes and focusing on your breath.',
      '✨ The Gita reminds us: "You have the right to perform your duty, but never to the fruits of your actions." Act with sincerity and let go of the outcome.',
      '🌅 Every day is a new beginning. Let go of yesterday\'s worries, act with love, and trust the divine plan. "The soul is eternal; it is never born and never dies."',
    ];
    final index = message.length % guidance.length;
    return guidance[index];
  }

  /// Generate a daily spiritual quote
  Future<String> generateDailyQuote() async {
    if (!_isInitialized || _model == null) {
      return 'The soul is neither born, nor does it ever die. - Bhagavad Gita';
    }

    try {
      final response = await _model!.generateContent([
        Content.text('Generate an inspiring spiritual quote for today. Include the source. Keep it under 50 words.')
      ]);
      return response.text ?? 'Peace comes from within. Do not seek it without. - Buddha';
    } catch (e) {
      debugPrint('Error generating daily quote: $e');
      return 'When meditation is mastered, the mind is unwavering like the flame of a lamp in a windless place. - Bhagavad Gita';
    }
  }

  /// Get meditation guidance
  Future<String> getMeditationGuidance(String type) async {
    if (!_isInitialized || _model == null) {
      return 'Sit comfortably, close your eyes, and focus on your breath. Let go of all thoughts and be present in the moment.';
    }

    try {
      final response = await _model!.generateContent([
        Content.text('Provide a brief $type meditation guidance (under 200 words):')
      ]);
      return response.text ?? 'Focus on your breath and find inner peace.';
    } catch (e) {
      debugPrint('Error getting meditation guidance: $e');
      return 'Take a deep breath in... and slowly breathe out... Feel the peace within you.';
    }
  }

  /// Get explanation of a Gita verse
  Future<String> explainGitaVerse(int chapter, int verse) async {
    if (!_isInitialized || _model == null) {
      return 'This verse from the Bhagavad Gita teaches us about the eternal wisdom of the soul.';
    }

    try {
      final response = await _model!.generateContent([
        Content.text('Explain Bhagavad Gita chapter $chapter, verse $verse in simple terms (under 200 words):')
      ]);
      return response.text ?? 'This verse teaches profound spiritual wisdom. Study it with an open heart.';
    } catch (e) {
      debugPrint('Error explaining Gita verse: $e');
      return 'This verse contains deep spiritual meaning. Reflect on it during your meditation.';
    }
  }

  /// Get mantra meaning
  Future<String> getMantraMeaning(String mantra) async {
    if (!_isInitialized || _model == null) {
      return 'This mantra is a powerful spiritual vibration that connects you with divine consciousness.';
    }

    try {
      final response = await _model!.generateContent([
        Content.text('Explain the meaning and significance of the mantra "$mantra" (under 200 words):')
      ]);
      return response.text ?? 'This mantra carries profound spiritual vibrations. Chant it with devotion.';
    } catch (e) {
      debugPrint('Error getting mantra meaning: $e');
      return 'Mantras are sacred sound vibrations that purify the mind and elevate consciousness.';
    }
  }
}

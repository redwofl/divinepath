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
13. ALWAYS respond in the language the user's message asks for (e.g. Hindi, Marathi, Gujarati). If a language instruction is attached to the message, follow it strictly — even if earlier messages in the conversation were in English.

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
  Future<String> sendMessage(String message, {String locale = 'en'}) async {
    if (!_isInitialized || _model == null) {
      return _localFallback(message, locale: locale);
    }

    try {
      // Start chat if not started
      if (_chatSession == null) {
        startNewChat();
      }

      // Add a strict language instruction if not English, so replies follow
      // the app's selected language even mid-conversation.
      final localizedMessage = locale == 'en'
          ? message
          : '$message\n\n'
              '[LANGUAGE INSTRUCTION] Respond ONLY in '
              '${_getLanguageName(locale)}. Do not reply in English. Keep any '
              'scripture quotes in their original script with the explanation '
              'in ${_getLanguageName(locale)}.';

      final response = await _chatSession!.sendMessage(Content.text(localizedMessage));
      return response.text ?? _localFallback(message, locale: locale);
    } catch (e) {
      debugPrint('Error sending message to Gemini: $e');
      return _localFallback(message, locale: locale);
    }
  }

  String _getLanguageName(String locale) {
    switch (locale) {
      case 'hi':
        return 'Hindi (हिंदी)';
      case 'mr':
        return 'Marathi (मराठी)';
      case 'gu':
        return 'Gujarati (ગુજરાતી)';
      default:
        return 'English';
    }
  }

  /// Answers a spiritual question from the local Gita dataset.
  ///
  /// Picks a keyword from the user's message, finds the first matching verse,
  /// and returns the shloka + translation + a short commentary snippet. If no
  /// keyword matches, returns a rotating general guidance message.
  String _localFallback(String message, {String locale = 'en'}) {
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
        return '${_gitaHeader(locale, r.chapterNumber, r.verseNumber)}\n\n'
            '${r.shloka}\n\n'
            '${r.translationEnglish}';
      }
    }

    // Rotating general guidance when no topic matches (localized)
    final guidance = _guidanceFor(locale);
    final index = message.length % guidance.length;
    return guidance[index];
  }

  /// Localized "Here is guidance from the Bhagavad Gita..." header
  String _gitaHeader(String locale, int chapter, int verse) {
    switch (locale) {
      case 'hi':
        return '🕉️ भगवद् गीता से मार्गदर्शन (अध्याय $chapter, श्लोक $verse):';
      case 'mr':
        return '🕉️ भगवद् गीतेमधून मार्गदर्शन (अध्याय $chapter, श्लोक $verse):';
      case 'gu':
        return '🕉️ ભગવદ્ ગીતામાંથી માર્ગદર્શન (અધ્યાય $chapter, શ્લોક $verse):';
      default:
        return '🕉️ Here is guidance from the Bhagavad Gita (Chapter '
            '$chapter, Verse $verse):';
    }
  }

  /// Offline guidance messages in the selected language
  List<String> _guidanceFor(String locale) {
    switch (locale) {
      case 'hi':
        return const [
          '🌿 शांति भीतर से आती है। इसे बाहर न खोजें। भगवद् गीता हमें बिना फल की इच्छा के अपना कर्तव्य निभाना सिखाती है (अध्याय 2, श्लोक 47)।',
          '🪷 मौन और ध्यान में मन बिना हवा के स्थान में जलते दीपक की लौ जैसा स्थिर हो जाता है। जैसा गीता कहती है, ज्ञानी सभी प्राणियों में एक ही आत्मा देखते हैं।',
          '🙏 भक्ति के साथ मंत्र जप से मन शुद्ध होता है और हृदय खुल जाता है। पाँच मिनट शांति से बैठकर अपनी सांस पर ध्यान देने की कोशिश करें।',
          '✨ गीता हमें याद दिलाती है: "तुम्हें अपने कर्तव्य के पालन का अधिकार है, परंतु उसके फलों पर कोई अधिकार नहीं।" ईमानदारी से कार्य करें और परिणाम की चिंता छोड़ दें।',
          '🌅 हर दिन एक नई शुरुआत है। कल की चिंताओं को छोड़ दें, प्रेम से कार्य करें और दिव्य योजना पर भरोसा रखें। "आत्मा अमर है; इसका न जन्म होता है और न मृत्यु।"',
        ];
      case 'mr':
        return const [
          '🌿 शांती आतून येते. ती बाहेर शोधू नका. भगवद् गीता आपला फळाची इच्छा न धरता कर्तव्य पाळण्यास शिकवते (अध्याय 2, श्लोक 47).',
          '🪷 मौन व ध्यानात मन विरळ जागी लागणाऱ्या दिव्याच्या ज्योतीसारखे स्थिर होते. गीता म्हणते, ज्ञानी सर्व प्राण्यांमध्ये एकच आत्मा पाहतात.',
          '🙏 भक्तीने मंत्र जप केल्याने मन शुद्ध होते व हृदय उघडे होते. पाच मिनिटे शांत बसून आपल्या श्वासावर लक्ष द्या.',
          '✨ गीता आठवण करून देते: "कर्तव्य करण्याचा तुझा अधिकार आहे, पण त्याच्या फळावर अधिकार नाही." इमानदारीने कार्य कर आणि फळाची चिंता सोड.',
          '🌅 प्रत्येक दिवस नवीन सुरुवात आहे. कालच्या चिंता सोड, प्रेमाने कार्य कर आणि दिव्य नियोजनावर विश्वास ठेव. "आत्मा अमर आहे; त्याला न जन्म न मृत्यू."',
        ];
      case 'gu':
        return const [
          '🌿 શાંતિ અંદરથી આવે છે. તેને બહાર શોધશો નહીં. ભગવદ્ ગીતા આપણને ફળની ઇચ્છા વગર કર્તવ્ય કરવાનું શીખવે છે (અધ્યાય 2, શ્લોક 47).',
          '🪷 મૌન અને ધ્યાનમાં મન હવા વગરની જગ્યામાં સળગતા દીવાની જ્યોત જેવું સ્થિર થાય છે. ગીતા કહે છે, જ્ઞાની સૌ પ્રાણીઓમાં એક જ આત્મા જુએ છે.',
          '🙏 ભક્તિપૂર્વક મંત્ર જપથી મન શુદ્ધ થાય છે અને હૃદય ખુલે છે. પાંચ મિનિટ શાંતિથી બેસી પોતાના શ્વાસ પર ધ્યાન આપો.',
          '✨ ગીતા યાદ અપાવે છે: "કર્તવ્ય કરવાનો તારો અધિકાર છે, પરંતુ ફળો પર અધિકાર નથી." પ્રામાણિકતાથી કાર્ય કર અને પરિણામની ચિંતા છોડી દે.',
          '🌅 દરેક દિવસ નવી શરૂઆત છે. ગઈકાલની ચિંતા છોડી દે, પ્રેમથી કાર્ય કર અને દિવ્ય યોજના પર વિશ્વાસ રાખ. "આત્મા અમર છે; તેને ન જન્મ છે ન મૃત્યુ."',
        ];
      default:
        return const [
          '🌿 Peace comes from within. Do not seek it without. The Bhagavad Gita teaches us to perform our duty without attachment to the results (Chapter 2, Verse 47).',
          '🪷 In silence and meditation, the mind becomes still like a lamp in a windless place. As the Gita says, the wise see the same soul in all beings.',
          '🙏 Chanting a mantra with devotion purifies the mind and opens the heart. Try sitting quietly for five minutes and focusing on your breath.',
          '✨ The Gita reminds us: "You have the right to perform your duty, but never to the fruits of your actions." Act with sincerity and let go of the outcome.',
          '🌅 Every day is a new beginning. Let go of yesterday\'s worries, act with love, and trust the divine plan. "The soul is eternal; it is never born and never dies."',
        ];
    }
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

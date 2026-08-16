import 'package:flutter/material.dart';

class AppConstants {
  // App Info
  static const String appName = 'DivinePath';
  static const String appTagline = 'Your Spiritual Companion';
  static const String appVersion = '1.0.0';

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String mantrasCollection = 'mantras';
  static const String storiesCollection = 'stories';
  static const String gitaCollection = 'bhagavad_gita';
  static const String versesCollection = 'verses';
  static const String quotesCollection = 'quotes';
  static const String challengesCollection = 'challenges';
  static const String communityCollection = 'community_posts';
  static const String chatCollection = 'chat_history';
  static const String announcementsCollection = 'announcements';
  static const String meditationCollection = 'meditation_sessions';
  static const String achievementsCollection = 'achievements';
  static const String settingsCollection = 'user_settings';

  // Mantra Constants
  static const int malaCount = 108;
  static const int dailyGoalDefault = 108;

  // Streak
  static const int streakFreezeDays = 3;

  // XP System
  static const int xpPerChant = 1;
  static const int xpPerMala = 10;
  static const int xpPerStory = 20;
  static const int xpPerVerse = 5;
  static const int xpPerChallenge = 50;
  static const int xpPerMeditationMinute = 2;

  // Levels
  static const List<Map<String, dynamic>> levels = [
    {'name': 'Seeker', 'minXp': 0, 'icon': '🧭'},
    {'name': 'Devotee', 'minXp': 100, 'icon': '🙏'},
    {'name': 'Sadhak', 'minXp': 500, 'icon': '🕉️'},
    {'name': 'Yogi', 'minXp': 1000, 'icon': '🧘'},
    {'name': 'Bhakta', 'minXp': 2500, 'icon': '💛'},
    {'name': 'Saint', 'minXp': 5000, 'icon': '✨'},
    {'name': 'Enlightened', 'minXp': 10000, 'icon': '🔆'},
  ];

  // Meditation Durations
  static const List<int> meditationDurations = [5, 10, 15, 30];

  // Notification Times
  static const TimeOfDay morningNotification = TimeOfDay(hour: 6, minute: 0);
  static const TimeOfDay eveningNotification = TimeOfDay(hour: 19, minute: 0);

  // Premium Pricing
  static const double premiumMonthlyPrice = 4.99;
  static const double premiumYearlyPrice = 39.99;

  // Gemini
  static const String geminiModel = 'gemini-2.0-flash';
  static const int maxChatHistory = 50;

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double cardRadius = 20.0;
  static const double buttonRadius = 16.0;
  static const double smallRadius = 12.0;
  static const double avatarRadius = 28.0;

  // Animation Durations
  static const Duration fastAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration slowAnimation = Duration(milliseconds: 600);

  // Supported Languages
  static const List<Map<String, String>> languages = [
    {'code': 'en', 'name': 'English', 'native': 'English'},
    {'code': 'hi', 'name': 'Hindi', 'native': 'हिन्दी'},
    {'code': 'mr', 'name': 'Marathi', 'native': 'मराठी'},
    {'code': 'gu', 'name': 'Gujarati', 'native': 'ગુજરાતી'},
    {'code': 'sa', 'name': 'Sanskrit', 'native': 'संस्कृतम्'},
  ];

  // Spiritual Interests
  static const List<Map<String, dynamic>> spiritualInterests = [
    {'name': 'Krishna', 'icon': '🦚', 'color': Color(0xFF2563EB)},
    {'name': 'Shiva', 'icon': '🔱', 'color': Color(0xFF7C3AED)},
    {'name': 'Rama', 'icon': '🏹', 'color': Color(0xFF059669)},
    {'name': 'Hanuman', 'icon': '🐵', 'color': Color(0xFFD97706)},
    {'name': 'Devi', 'icon': '🌸', 'color': Color(0xFFDB2777)},
    {'name': 'Meditation', 'icon': '🧘', 'color': Color(0xFF6366F1)},
    {'name': 'Bhagavad Gita', 'icon': '📖', 'color': Color(0xFFF59E0B)},
    {'name': 'Yoga', 'icon': '🧘‍♀️', 'color': Color(0xFF8B5CF6)},
    {'name': 'Vedanta', 'icon': '🕉️', 'color': Color(0xFFEC4899)},
    {'name': 'Bhakti Yoga', 'icon': '💛', 'color': Color(0xFFF97316)},
  ];

  // Deities
  static const List<Map<String, dynamic>> deities = [
    {'name': 'Krishna', 'mantra': 'Hare Krishna Hare Krishna, Krishna Krishna Hare Hare'},
    {'name': 'Shiva', 'mantra': 'Om Namah Shivaya'},
    {'name': 'Rama', 'mantra': 'Shri Ram Jai Ram Jai Jai Ram'},
    {'name': 'Hanuman', 'mantra': 'Om Hanumate Namah'},
    {'name': 'Devi', 'mantra': 'Om Aim Hreem Kleem Chamundaye Vichhe'},
    {'name': 'Ganesha', 'mantra': 'Om Gam Ganapataye Namah'},
    {'name': 'Saraswati', 'mantra': 'Om Aim Saraswatyai Namah'},
    {'name': 'Lakshmi', 'mantra': 'Om Shreem Maha Lakshmiyei Namah'},
  ];

  // Default Mantras
  static const List<Map<String, String>> defaultMantras = [
    {'name': 'Om Namah Shivaya', 'translation': 'I bow to Shiva'},
    {'name': 'Hare Krishna', 'translation': 'Oh Lord Krishna'},
    {'name': 'Shri Ram', 'translation': 'Lord Rama'},
    {'name': 'Om', 'translation': 'The Primordial Sound'},
    {'name': 'Gayatri Mantra', 'translation': 'May we attain the divine light'},
    {'name': 'Om Mani Padme Hum', 'translation': 'The jewel in the lotus'},
    {'name': 'Radhe Radhe', 'translation': 'Radha, the beloved'},
    {'name': 'Sita Ram', 'translation': 'Sita and Rama'},
    {'name': 'Hanuman Chalisa', 'translation': 'Forty verses on Hanuman'},
    {'name': 'Om Namo Bhagavate Vasudevaya', 'translation': 'I bow to Lord Vasudeva'},
    {'name': 'Maha Mrityunjaya Mantra', 'translation': 'The great death-conquering mantra'},
    {'name': 'Om Gam Ganapataye Namah', 'translation': 'I bow to Lord Ganesha'},
    {'name': 'Om Shreem Maha Lakshmiyei Namah', 'translation': 'I bow to Goddess Lakshmi'},
    {'name': 'Om Aim Saraswatyai Namah', 'translation': 'I bow to Goddess Saraswati'},
    {'name': 'Om Namo Narayanaya', 'translation': 'I bow to Lord Narayana'},
    {'name': 'Jai Siya Ram', 'translation': 'Victory to Sita and Ram'},
    {'name': 'Om Hreem Shreem Kleem', 'translation': 'The supreme goddess seed mantra'},
    {'name': 'Om Dum Durgayei Namah', 'translation': 'I bow to Goddess Durga'},
    {'name': 'Jai Shri Krishna', 'translation': 'Victory to Lord Krishna'},
    {'name': 'Om Shanti Om', 'translation': 'Peace, peace, peace'},
    {'name': 'So Hum', 'translation': 'I am That'},
    {'name': 'Aham Brahmasmi', 'translation': 'I am Brahman'},
    {'name': 'Shivoham', 'translation': 'I am Shiva'},
    {'name': 'Sai Ram', 'translation': 'The sacred name of Sai Baba'},
    {'name': 'Govinda Jaya Jaya', 'translation': 'Victory to Govinda'},
    {'name': 'Radha Krishna', 'translation': 'Radha and Krishna, the divine couple'},
    {'name': 'Lakshmi Narayana', 'translation': 'Lakshmi and Narayana'},
    {'name': 'Om Hanumate Namah', 'translation': 'I bow to Lord Hanuman'},
    {'name': 'Hare Murare', 'translation': 'O Hari, O slayer of Mura'},
    {'name': 'Narayana Narayana', 'translation': 'The eternal name of Narayana'},
    {'name': 'Hare Krishna Hare Krishna, Krishna Krishna Hare Hare', 'translation': 'The full Hare Krishna Maha Mantra'},
    {'name': 'Om Tryambakam Yajamahe', 'translation': 'We worship the three-eyed one (Shiva), who nourishes all beings'},
    {'name': 'Om Namo Bhagavate Rudraya', 'translation': 'I bow to Lord Rudra (Shiva)'},
    {'name': 'Om Vishnave Namah', 'translation': 'I bow to Lord Vishnu'},
    {'name': 'Om Shri Ganeshaya Namah', 'translation': 'I bow to Lord Ganesha'},
    {'name': 'Om Sri Durgayai Namah', 'translation': 'I bow to Goddess Durga'},
    {'name': 'Om Kleem Krishnaya Namah', 'translation': 'I bow to Krishna, the all-attractive'},
    {'name': 'Krishnaya Vasudevaya Haraye Paramatmane', 'translation': 'Salutations to Krishna, Vasudeva, Hari, the Supreme Self'},
    {'name': 'Om Tat Sat', 'translation': 'That (Brahman) is the Absolute Truth'},
    {'name': 'Asato Ma Sadgamaya', 'translation': 'Lead me from untruth to truth, from darkness to light'},
    {'name': 'Om Sarve Bhavantu Sukhinah', 'translation': 'May all beings be happy and free from suffering'},
    {'name': 'Lokah Samastah Sukhino Bhavantu', 'translation': 'May all beings everywhere be happy and free'},
    {'name': 'Om Purnamadah Purnamidam', 'translation': 'That is whole, this is whole; from wholeness emerges wholeness'},
    {'name': 'Gurur Brahma Gurur Vishnu', 'translation': 'The Guru is Brahma, the Guru is Vishnu, the Guru is Shiva'},
    {'name': 'Om Guruve Namah', 'translation': 'I bow to the Guru'},
    {'name': 'Hari Om', 'translation': 'The divine name of Vishnu'},
    {'name': 'Om Saha Navavatu', 'translation': 'May we be protected together, may we be nourished together'},
    {'name': 'Adi Shakti', 'translation': 'The Primordial Divine Power'},
    {'name': 'Om Shakti Om', 'translation': 'The power of the divine feminine'},
    {'name': 'Durga Durgati Nashini', 'translation': 'She who removes all distress and suffering'},
    {'name': 'Om Bhur Bhuva Svaha', 'translation': 'The sacred invocation of the Gayatri Mantra'},
    {'name': 'Shivaya Namah', 'translation': 'Salutations to Shiva'},
    {'name': 'Om Sri Gurubhyo Namah', 'translation': 'I bow to all the Gurus'},
    {'name': 'Jai Shri Ram', 'translation': 'Victory to Lord Rama'},
  ];

  // Daily Quotes
  static const List<String> dailyQuotes = [
    'The soul is neither born, nor does it ever die. - Bhagavad Gita',
    'Peace comes from within. Do not seek it without. - Buddha',
    'The mind is everything. What you think you become. - Buddha',
    'Yoga is the journey of the self, through the self, to the self. - Bhagavad Gita',
    'When meditation is mastered, the mind is unwavering like the flame of a lamp in a windless place. - Bhagavad Gita',
    'Your duty is to act, not to be attached to the fruits of action. - Bhagavad Gita',
    'The happiness which comes from long practice brings tears to the eyes. - Yogi Bhajan',
    'In the middle of difficulty lies opportunity. - Albert Einstein',
    'The greatest glory in living lies not in never falling, but in rising every time we fall. - Nelson Mandela',
    'The only way to do great work is to love what you do. - Steve Jobs',
  ];

  // Ambient Sounds
  // NOTE: 'file' must point to a real file bundled under assets/sounds/
  static const List<Map<String, String>> ambientSounds = [
    {'name': 'Om Chanting', 'file': 'assets/sounds/om_chant.mp3', 'icon': '🕉️'},
    {'name': 'Temple Bells', 'file': 'assets/sounds/temple_bells.mp3', 'icon': '🔔'},
    {'name': 'Flute', 'file': 'assets/sounds/flute.mp3', 'icon': '🎵'},
    {'name': 'Nature', 'file': 'assets/sounds/nature.mp3', 'icon': '🌿'},
    {'name': 'Rain', 'file': 'assets/sounds/rain.mp3', 'icon': '🌧️'},
    {'name': 'Ocean Waves', 'file': 'assets/sounds/ocean.mp3', 'icon': '🌊'},
    {'name': 'Wind Chimes', 'file': 'assets/sounds/wind_chimes.mp3', 'icon': '🎐'},
    {'name': 'Cricket Night', 'file': 'assets/sounds/cricket.mp3', 'icon': '🦗'},
  ];

  // Story Categories
  static const List<Map<String, dynamic>> storyCategories = [
    {'name': 'Ramayan', 'icon': '🏹', 'color': Color(0xFF059669), 'count': 25},
    {'name': 'Mahabharat', 'icon': '⚔️', 'color': Color(0xFFD97706), 'count': 30},
    {'name': 'Bhagavad Gita', 'icon': '📖', 'color': Color(0xFFF59E0B), 'count': 18},
    {'name': 'Krishna Leela', 'icon': '🦚', 'color': Color(0xFF2563EB), 'count': 20},
    {'name': 'Shiv Puran', 'icon': '🔱', 'color': Color(0xFF7C3AED), 'count': 15},
    {'name': 'Hanuman Stories', 'icon': '🐵', 'color': Color(0xFFDC2626), 'count': 12},
    {'name': 'Devi Stories', 'icon': '🌸', 'color': Color(0xFFDB2777), 'count': 18},
    {'name': 'Saints & Sages', 'icon': '✨', 'color': Color(0xFF6366F1), 'count': 15},
  ];

  // Gita Chapters (nameHindi for Hindi-language display)
  static const List<Map<String, String>> gitaChapters = [
    {'number': '1', 'name': 'Arjuna Vishada Yoga', 'nameHindi': 'अर्जुन विषाद योग', 'verses': '47'},
    {'number': '2', 'name': 'Sankhya Yoga', 'nameHindi': 'सांख्य योग', 'verses': '72'},
    {'number': '3', 'name': 'Karma Yoga', 'nameHindi': 'कर्म योग', 'verses': '43'},
    {'number': '4', 'name': 'Jnana Karma Sanyasa Yoga', 'nameHindi': 'ज्ञान कर्म संन्यास योग', 'verses': '42'},
    {'number': '5', 'name': 'Karma Sanyasa Yoga', 'nameHindi': 'कर्म संन्यास योग', 'verses': '29'},
    {'number': '6', 'name': 'Dhyana Yoga', 'nameHindi': 'ध्यान योग', 'verses': '47'},
    {'number': '7', 'name': 'Jnana Vijnana Yoga', 'nameHindi': 'ज्ञान विज्ञान योग', 'verses': '30'},
    {'number': '8', 'name': 'Akshara Brahma Yoga', 'nameHindi': 'अक्षर ब्रह्म योग', 'verses': '28'},
    {'number': '9', 'name': 'Raja Vidya Raja Guhya Yoga', 'nameHindi': 'राज विद्या राज गुह्य योग', 'verses': '34'},
    {'number': '10', 'name': 'Vibhuti Yoga', 'nameHindi': 'विभूति योग', 'verses': '42'},
    {'number': '11', 'name': 'Vishvarupa Darshana Yoga', 'nameHindi': 'विश्वरूप दर्शन योग', 'verses': '55'},
    {'number': '12', 'name': 'Bhakti Yoga', 'nameHindi': 'भक्ति योग', 'verses': '20'},
    {'number': '13', 'name': 'Kshetra Kshetrajna Vibhaga Yoga', 'nameHindi': 'क्षेत्र क्षेत्रज्ञ विभाग योग', 'verses': '35'},
    {'number': '14', 'name': 'Guna Traya Vibhaga Yoga', 'nameHindi': 'गुण त्रय विभाग योग', 'verses': '27'},
    {'number': '15', 'name': 'Purushottama Yoga', 'nameHindi': 'पुरुषोत्तम योग', 'verses': '20'},
    {'number': '16', 'name': 'Daivasura Sampad Vibhaga Yoga', 'nameHindi': 'दैवासुर सम्पद् विभाग योग', 'verses': '24'},
    {'number': '17', 'name': 'Shraddha Traya Vibhaga Yoga', 'nameHindi': 'श्रद्धा त्रय विभाग योग', 'verses': '28'},
    {'number': '18', 'name': 'Moksha Sanyasa Yoga', 'nameHindi': 'मोक्ष संन्यास योग', 'verses': '78'},
  ];
}

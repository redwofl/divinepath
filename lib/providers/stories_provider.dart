import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/app_config.dart';
import '../services/firebase_service.dart';
import '../models/story_model.dart';

class StoriesProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService.instance;

  List<StoryModel> _stories = [];
  List<StoryModel> _filteredStories = [];
  List<StoryBookmark> _bookmarks = [];
  String? _selectedCategory;
  String _searchQuery = '';
  bool _isLoading = false;
  String? _error;

  // Getters
  List<StoryModel> get stories => _filteredStories.isNotEmpty ? _filteredStories : _stories;
  List<StoryBookmark> get bookmarks => _bookmarks;
  String? get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Initialize stories provider
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _loadStories();
      await _loadBookmarks();
    } catch (e) {
      _error = 'Failed to load stories.';
      debugPrint('Error loading stories: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load stories from Firestore
  Future<void> _loadStories() async {
    // Developer toggle: always use the built-in sample stories and never let
    // Firestore override them (useful while the stories collection is empty
    // or missing the full story text).
    if (AppConfig.useSampleStoriesOnly) {
      _stories = _getSampleStories();
      _applyFilters();
      return;
    }

    try {
      final snapshot = await _firebaseService.queryCollection('stories')
          .orderBy('createdAt', descending: true)
          .get();

      if (snapshot.docs.isEmpty) {
        debugPrint('No stories in Firestore - using sample data');
        _stories = _getSampleStories();
      } else {
        final loaded = snapshot.docs.map((doc) =>
            StoryModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
        _stories = _mergeWithSamples(loaded);
      }

      _applyFilters();
    } catch (e) {
      debugPrint('Error loading stories from Firestore: $e');
      // Use sample data if Firestore fails
      _stories = _getSampleStories();
      _applyFilters();
    }
  }

  /// Guarantee the story text is ALWAYS visible:
  /// 1. Firestore docs that are missing their `content` field get the full
  ///    story text from the matching sample story (matched by title).
  /// 2. If Firestore only has a handful of docs, pad with sample stories so
  ///    the page never looks empty or truncated.
  List<StoryModel> _mergeWithSamples(List<StoryModel> loaded) {
    final samples = _getSampleStories();
    final result = <StoryModel>[];

    for (final story in loaded) {
      if (story.content.trim().isNotEmpty) {
        result.add(story);
        continue;
      }
      // Find the sample story with the closest matching title.
      // Guard against blank/short titles (an empty string matches every
      // sample via .contains('') == true).
      final title = story.title.trim().toLowerCase();
      StoryModel? match;
      if (title.length >= 3) {
        for (final s in samples) {
          final sampleTitle = s.title.toLowerCase();
          if (sampleTitle == title ||
              sampleTitle.contains(title) ||
              title.contains(sampleTitle)) {
            match = s;
            break;
          }
        }
      }
      if (match != null) {
        result.add(StoryModel(
          id: story.id,
          title: story.title,
          titleHindi: story.titleHindi ?? match.titleHindi,
          category: story.category,
          content: match.content,
          contentHindi: story.contentHindi ?? match.contentHindi,
          summary: story.summary ?? match.summary,
          imageUrl: story.imageUrl ?? match.imageUrl,
          audioUrl: story.audioUrl ?? match.audioUrl,
          readingTimeMinutes: story.readingTimeMinutes,
          author: story.author ?? match.author,
          source: story.source ?? match.source,
          tags: story.tags.isNotEmpty ? story.tags : match.tags,
          isPremium: story.isPremium,
          likes: story.likes,
          reads: story.reads,
          createdAt: story.createdAt,
          updatedAt: story.updatedAt,
        ));
      } else {
        result.add(story);
      }
    }

    // Pad with samples when Firestore returned very few stories
    if (result.length < 4) {
      final existingTitles = result.map((s) => s.title.toLowerCase()).toSet();
      for (final s in samples) {
        if (result.length >= 4) break;
        if (existingTitles.contains(s.title.toLowerCase())) continue;
        result.add(s);
        existingTitles.add(s.title.toLowerCase());
      }
    }

    return result;
  }

  /// Load bookmarks from Firestore
  Future<void> _loadBookmarks() async {
    try {
      final user = _firebaseService.currentUser;
      if (user == null) return;

      final snapshot = await _firebaseService.queryCollection('bookmarks')
          .where('userId', isEqualTo: user.uid)
          .where('type', isEqualTo: 'story')
          .get();

      _bookmarks = snapshot.docs.map((doc) =>
          StoryBookmark.fromMap(doc.data() as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error loading bookmarks: $e');
    }
  }

  /// Filter by category
  void filterByCategory(String? category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  /// Search stories
  void search(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  /// Apply filters
  void _applyFilters() {
    var filtered = List<StoryModel>.from(_stories);

    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      filtered = filtered.where((s) =>
          s.category.toLowerCase() == _selectedCategory!.toLowerCase()).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((s) =>
          s.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (s.summary?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          s.tags.any((t) => t.toLowerCase().contains(_searchQuery.toLowerCase()))
      ).toList();
    }

    _filteredStories = filtered;
  }

  /// Toggle bookmark
  Future<void> toggleBookmark(StoryModel story) async {
    try {
      final user = _firebaseService.currentUser;
      if (user == null) return;

      final existingIndex = _bookmarks.indexWhere((b) => b.storyId == story.id);

      if (existingIndex >= 0) {
        // Remove bookmark
        _bookmarks.removeAt(existingIndex);
        await _firebaseService.queryCollection('bookmarks')
            .where('userId', isEqualTo: user.uid)
            .where('storyId', isEqualTo: story.id)
            .get()
            .then((snapshot) {
          for (var doc in snapshot.docs) {
            doc.reference.delete();
          }
        });
      } else {
        // Add bookmark
        final bookmark = StoryBookmark(
          storyId: story.id,
          title: story.title,
          imageUrl: story.imageUrl,
          category: story.category,
        );
        _bookmarks.add(bookmark);
        await _firebaseService.addDocument('bookmarks', {
          ...bookmark.toMap(),
          'userId': user.uid,
          'type': 'story',
        });
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling bookmark: $e');
    }
  }

  /// Check if story is bookmarked
  bool isBookmarked(String storyId) {
    return _bookmarks.any((b) => b.storyId == storyId);
  }

  /// Increment story reads
  Future<void> incrementRead(String storyId) async {
    try {
      await _firebaseService.updateDocument('stories', storyId, {
        'reads': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Error incrementing read count: $e');
    }
  }

  /// Increment story likes
  Future<void> toggleLike(String storyId) async {
    try {
      final user = _firebaseService.currentUser;
      if (user == null) return;

      final likeRef = _firebaseService.getDocument('story_likes', '${user.uid}_$storyId');
      final likeDoc = await likeRef.get();

      if (likeDoc.exists) {
        await likeRef.delete();
        await _firebaseService.updateDocument('stories', storyId, {
          'likes': FieldValue.increment(-1),
        });
      } else {
        await likeRef.set({
          'userId': user.uid,
          'storyId': storyId,
          'timestamp': DateTime.now().toIso8601String(),
        });
        await _firebaseService.updateDocument('stories', storyId, {
          'likes': FieldValue.increment(1),
        });
      }
    } catch (e) {
      debugPrint('Error toggling like: $e');
    }
  }

  /// Sample stories for development
  List<StoryModel> _getSampleStories() {
    return [
      StoryModel(
        id: '1',
        title: 'The Birth of Lord Krishna',
        titleHindi: 'भगवान कृष्ण का जन्म',
        category: 'Krishna Leela',
        content: 'In the prison of Mathura, Devaki gave birth to the eighth son, who was none other than Lord Vishnu Himself. The prison walls trembled as a divine radiance filled the dark chamber. Chains fell away, guards fell into deep slumber, and the gates swung open by themselves. Vasudeva carried the newborn across the river Yamuna, which parted to make way for them. Lord Vishnu, now in the form of baby Krishna, was safely exchanged with Yashoda\'s daughter in Gokul. The divine plan had begun — the avatar who would vanquish evil and restore dharma had arrived. The people of Gokul rejoiced, unaware that this little boy would one day steal their hearts and become the beloved of all.',
        contentHindi: 'मथुरा के कारागार में देवकी ने आठवें पुत्र को जन्म दिया, जो स्वयं भगवान विष्णु थे। कारागार की दीवारें काँप उठीं और अंधेरी कोठरी दिव्य ज्योति से भर गई। बेड़ियाँ अपने आप टूट गईं, पहरेदार गहरी नींद में सो गए और द्वार स्वयं खुल गए। वसुदेव नवजात शिशु को लेकर यमुना नदी पार कर गए, जिसने उनके लिए रास्ता बना दिया। भगवान विष्णु, अब बाल कृष्ण के रूप में, गोकुल में यशोदा की पुत्री के साथ सुरक्षित बदल दिए गए। दिव्य योजना आरंभ हो चुकी थी — वह अवतार आ चुका था जो बुराई का नाश करेगा और धर्म की पुनर्स्थापना करेगा। गोकुल के लोग आनंदित हुए, यह नहीं जानते थे कि यह बालक एक दिन उनके दिल चुरा लेगा और सबका प्रिय बन जाएगा।',
        summary: 'The divine story of Lord Krishna\'s birth in the prison of Kamsa.',
        readingTimeMinutes: 8,
        author: 'DivinePath',
        tags: ['krishna', 'birth', 'divine', 'leela'],
      ),
      StoryModel(
        id: '2',
        title: 'Hanuman Crosses the Ocean',
        titleHindi: 'हनुमान का समुद्र पार करना',
        category: 'Hanuman Stories',
        content: 'When the monkey army stood helpless before the vast ocean, Hanuman remembered his divine powers. He recalled the boons given by his father, Vayu, the wind god. Standing at the edge of the southern shore, Hanuman gazed across the endless blue waters stretching to Lanka. With a silent prayer to Rama, he began to expand his body. Mountains rose and fell beneath his feet as he grew to a colossal size. Then, with a mighty leap, he soared into the sky. The wind gods cheered him on, the sun refused to burn him, and the ocean goddess raised him higher. He flew across the ocean in a single bound, his devotion carrying him faster than any arrow. Lanka appeared on the horizon, and Hanuman landed softly on its shores, ready to find Sita.',
        contentHindi: 'जब वानर सेना विशाल समुद्र के सामने असहाय खड़ी थी, हनुमान ने अपनी दिव्य शक्तियों को स्मरण किया। उन्होंने अपने पिता वायु देवता द्वारा दिए गए वरदानों को याद किया। दक्षिणी तट पर खड़े होकर हनुमान ने लंका तक फैले असीम नीले जल की ओर देखा। राम से मौन प्रार्थना करते हुए उन्होंने अपने शरीर का विस्तार करना शुरू किया। उनके पैरों के नीचे पर्वत उठते और गिरते रहे। फिर एक शक्तिशाली छलांग के साथ वे आकाश में उड़ गए। वायु देवताओं ने उनका उत्साह बढ़ाया, सूर्य ने उन्हें जलाने से मना किया और समुद्र देवी ने उन्हें और ऊपर उठाया। उन्होंने एक ही छलांग में समुद्र पार किया, उनकी भक्ति उन्हें किसी भी बाण से अधिक तेज़ ले जा रही थी। क्षितिज पर लंका दिखाई दी और हनुमान धीरे से उसके तट पर उतरे, सीता को खोजने के लिए तैयार।',
        summary: 'Hanuman\'s leap across the ocean to find Sita in Lanka.',
        readingTimeMinutes: 10,
        author: 'DivinePath',
        tags: ['hanuman', 'ramayan', 'devotion', 'strength'],
      ),
      StoryModel(
        id: '3',
        title: 'Arjuna\'s Dilemma',
        titleHindi: 'अर्जुन का संशय',
        category: 'Mahabharat',
        content: 'Standing on the battlefield of Kurukshetra, Arjuna saw his relatives, teachers, and friends on both sides. His heart sank as he realized the war meant killing those he loved. His bow, Gandiva, slipped from his hands. "Krishna," he cried, "what use is victory if it costs the lives of my family?" He spoke of the sins of destroying a dynasty, of widows and orphans, of traditions lost forever. His mind was clouded with confusion and grief. He sat down in his chariot, refusing to fight. This moment of surrender was the turning point. Krishna smiled, for now He could reveal the deepest spiritual truths. The Bhagavad Gita began — a conversation that would illuminate the path of dharma for all humanity.',
        contentHindi: 'कुरुक्षेत्र के युद्धभूमि पर खड़े होकर अर्जुन ने दोनों ओर अपने संबंधियों, गुरुओं और मित्रों को देखा। उनका हृदय भारी हो गया क्योंकि उन्होंने महसूस किया कि युद्ध का अर्थ अपने प्रियजनों की हत्या करना है। उनके हाथों से गांडीव धनुष गिर गया। "कृष्ण," उन्होंने पुकारा, "यदि विजय के लिए मेरे परिवार की जान की कीमत चुकानी पड़े तो उसका क्या लाभ?" उन्होंने वंश के नाश के पापों, विधवाओं और अनाथों की बात की। उनका मन भ्रम और शोक से घिर गया था। वे रथ में बैठ गए और युद्ध करने से मना कर दिया। समर्पण का यही क्षण निर्णायक सिद्ध हुआ। कृष्ण मुस्कुराए, क्योंकि अब वे सबसे गहरे आध्यात्मिक सत्य प्रकट कर सकते थे। श्रीमद्भगवद्गीता आरंभ हुई — एक ऐसा संवाद जो समस्त मानवता के लिए धर्म का मार्ग प्रशस्त करेगा।',
        summary: 'The moment before the Bhagavad Gita was spoken - Arjuna\'s crisis of conscience.',
        readingTimeMinutes: 12,
        author: 'DivinePath',
        tags: ['arjuna', 'mahabharat', 'gita', 'dharma'],
      ),
      StoryModel(
        id: '4',
        title: 'The Churning of the Ocean',
        titleHindi: 'समुद्र मंथन',
        category: 'Shiv Puran',
        content: 'The devas and asuras came together to churn the cosmic ocean for the nectar of immortality. Using Mount Mandara as the churning rod and Vasuki, the serpent king, as the rope, they began the great Samudra Manthan. The ocean roared and churned. First emerged Surabhi, the divine cow, followed by Varuni, the goddess of wine. Then came the Parijata tree, the Airavata elephant, and the Kaustubha gem. As they churned deeper, a deadly poison called Halahala arose, threatening to destroy all of creation. The devas and asuras ran in terror. Lord Shiva stepped forward, gathered the poison in his palm, and drank it. His throat turned blue forever — earning him the name Neelakantha. Finally, Dhanvantari emerged carrying the pot of Amrita, the nectar of immortality. The cosmic churning had revealed treasures beyond imagination.',
        contentHindi: 'देवता और असुर अमृत प्राप्त करने के लिए ब्रह्मांडीय समुद्र का मंथन करने एकत्र हुए। मंदराचल पर्वत को मथनी और वासुकि नाग को रस्सी बनाकर उन्होंने महान समुद्र मंथन आरंभ किया। समुद्र गरजा और मंथित होने लगा। पहले सुरभि गाय प्रकट हुई, फिर वारुणी देवी। तब पारिजात वृक्ष, ऐरावत हाथी और कौस्तुभ मणि निकले। जब वे और गहराई तक मंथन करने लगे, तो हलाहल नामक घातक विष उत्पन्न हुआ, जो संपूर्ण सृष्टि को नष्ट करने की धमकी दे रहा था। देवता और असुर भयभीत होकर भाग गए। भगवान शिव आगे बढ़े, विष को अपनी हथेली में एकत्र किया और उसे पी गए। उनका कंठ सदा के लिए नीला हो गया — इसीलिए उन्हें नीलकंठ कहा गया। अंततः धन्वंतरि अमृत का कलश लिए प्रकट हुए। ब्रह्मांडीय मंथन ने कल्पना से परे खजाने प्रकट कर दिए थे।',
        summary: 'The ancient tale of Samudra Manthan - the churning of the cosmic ocean.',
        readingTimeMinutes: 15,
        author: 'DivinePath',
        tags: ['shiva', 'samudra manthan', 'amrit', 'cosmic'],
      ),
      StoryModel(
        id: '5',
        title: 'Goddess Durga Slays Mahishasura',
        titleHindi: 'दुर्गा का महिषासुर वध',
        category: 'Devi Stories',
        content: 'When the demon Mahishasura terrorized the heavens and earth, the gods combined their powers. From the combined energy of Brahma, Vishnu, and Shiva emerged a brilliant light. From this light took form the Goddess Durga — beautiful, fierce, and radiant. She rode a lion and carried weapons gifted by all the gods: a trident from Shiva, a discus from Vishnu, a bow from Surya, and a sword from Yama. Mahishasura laughed when he saw her, thinking a woman could never defeat him. He sent his entire army against her. Durga fought for nine days and nights. Each time Mahishasura changed his form — buffalo, lion, elephant — she matched him with her divine weapons. Finally, she pinned him down with her foot and pierced his chest with her trident. The demon fell, and the heavens erupted in celebration. The nine nights of battle are celebrated as Navaratri.',
        contentHindi: 'जब असुर महिषासुर ने स्वर्ग और पृथ्वी को आतंकित किया, तो देवताओं ने अपनी शक्तियाँ एकत्र कीं। ब्रह्मा, विष्णु और शिव की संयुक्त ऊर्जा से एक तेजस्वी प्रकाश उत्पन्न हुआ। इस प्रकाश से देवी दुर्गा का जन्म हुआ — सुंदर, उग्र और तेजस्वी। वे सिंह पर सवार थीं और उनके पास सभी देवताओं द्वारा दिए गए अस्त्र थे: शिव का त्रिशूल, विष्णु का चक्र, सूर्य का धनुष और यम की तलवार। महिषासुर उन्हें देखकर हँसा, यह सोचकर कि एक स्त्री उसे कभी पराजित नहीं कर सकती। उसने अपनी पूरी सेना उनके विरुद्ध भेज दी। दुर्गा ने नौ दिन और नौ रातें युद्ध किया। जब-जब महिषासुर ने अपना रूप बदला — भैंसा, सिंह, हाथी — वे उसका मुकाबला अपने दिव्य अस्त्रों से करती रहीं। अंत में उन्होंने उसे अपने पैर से दबाया और त्रिशूल से उसकी छाती बेध दी। असुर गिर गया और स्वर्ग में उत्सव मनाया गया। नौ रातों के युद्ध को नवरात्रि के रूप में मनाया जाता है।',
        summary: 'The epic battle between Goddess Durga and the buffalo demon Mahishasura.',
        readingTimeMinutes: 10,
        author: 'DivinePath',
        tags: ['durga', 'devi', 'victory', 'shakti'],
      ),
      StoryModel(
        id: '6',
        title: 'Lord Rama\'s Exile',
        titleHindi: 'भगवान राम का वनवास',
        category: 'Ramayan',
        content: 'Prince Rama, the beloved of Ayodhya, accepted 14 years of exile to honor his father\'s word. On the very day of his coronation, Queen Kaikeyi demanded that Rama be banished and her son Bharata be crowned. King Dasharatha was bound by his promise to Kaikeyi and could not refuse. When Rama heard the news, he bowed his head and said, "Father, your word is my command." He removed his royal garments, donned tree bark, and prepared to leave for the forest. Sita insisted on accompanying him, and Lakshmana refused to stay behind. The people of Ayodhya wept as they watched their beloved prince walk away. Even the rivers and trees seemed to mourn. But Rama walked with steady steps, his heart pure and his purpose clear — to uphold his father\'s honor above his own happiness. The exile that was meant to break him would become the foundation of his glory.',
        contentHindi: 'अयोध्या के प्रिय राजकुमार राम ने अपने पिता के वचन का सम्मान करने के लिए चौदह वर्ष का वनवास स्वीकार किया। राज्याभिषेक के ठीक दिन रानी कैकेयी ने मांग की कि राम को वनवास भेजा जाए और उनके पुत्र भरत को राजा बनाया जाए। राजा दशरथ कैकेयी से किए गए वचन से बंधे थे और मना नहीं कर सकते थे। यह समाचार सुनकर राम ने सिर झुकाया और कहा, "पिता जी, आपकी आज्ञा मेरे लिए परम धर्म है।" उन्होंने राजसी वस्त्र उतार दिए, वल्कल धारण किया और वन जाने की तैयारी की। सीता ने उनके साथ चलने पर ज़ोर दिया और लक्ष्मण पीछे रहने को तैयार नहीं थे। अयोध्या के लोग रोते हुए अपने प्रिय राजकुमार को जाते देखते रहे। नदियाँ और वृक्ष भी शोक मनाते प्रतीत होते थे। परंतु राम दृढ़ कदमों से चलते रहे, उनका हृदय शुद्ध और उद्देश्य स्पष्ट था — अपनी प्रसन्नता से ऊपर अपने पिता के सम्मान की रक्षा करना। जो वनवास उन्हें तोड़ने के लिए था, वही उनकी कीर्ति की नींव बना।',
        summary: 'The beginning of Rama\'s journey - leaving the palace for the forest.',
        readingTimeMinutes: 10,
        author: 'DivinePath',
        tags: ['rama', 'ramayan', 'exile', 'dharma'],
      ),
      StoryModel(
        id: '7',
        title: 'Krishna Reveals His Universal Form',
        titleHindi: 'कृष्ण का विश्वरूप दर्शन',
        category: 'Bhagavad Gita',
        content: 'On the battlefield of Kurukshetra, after receiving the teachings of the Gita, Arjuna asked to see Krishna\'s divine form. The Lord then granted him celestial vision. What Arjuna saw was beyond all description. Krishna revealed His universal form containing all of creation within His body — countless suns and moons, all the gods and demons, every living being past and future. Arjuna saw the Pandavas and Kauravas entering Krishna\'s blazing mouths as moths enter a flame. Time itself was devoured. The universe expanded and contracted with each breath. Arjuna trembled and begged Krishna to return to His human form, unable to bear the overwhelming vision. Krishna smiled and withdrew the cosmic sight, resuming His gentle form as Arjuna\'s charioteer and friend. He explained that only pure devotion, not power or knowledge, can truly see the divine.',
        contentHindi: 'कुरुक्षेत्र के युद्धभूमि पर गीता के उपदेश प्राप्त करने के बाद अर्जुन ने कृष्ण का दिव्य रूप देखने का अनुरोध किया। भगवान ने उन्हें दिव्य दृष्टि प्रदान की। अर्जुन ने जो देखा वह वर्णन से परे था। कृष्ण ने अपना विश्वरूप प्रकट किया, जिसमें संपूर्ण सृष्टि समाहित थी — असंख्य सूर्य और चंद्रमा, सभी देवता और असुर, भूत और भविष्य के सभी जीव। अर्जुन ने पांडवों और कौरवों को कृष्ण के प्रज्वलित मुखों में प्रवेश करते देखा, जैसे पतंगे अग्नि में प्रवेश करती हैं। काल स्वयं निगला जा रहा था। प्रत्येक श्वास के साथ ब्रह्मांड फैलता और सिकुड़ता था। अर्जुन काँप उठे और कृष्ण से अपने मानव रूप में लौटने की प्रार्थना की, क्योंकि वे इस अद्भुत दृश्य को सहन नहीं कर सकते थे। कृष्ण मुस्कुराए और ब्रह्मांडीय दृश्य समेट लिया, पुनः अर्जुन के सारथी और मित्र के रूप में प्रकट हुए। उन्होंने समझाया कि केवल शुद्ध भक्ति, न कि शक्ति या ज्ञान, सच्चे रूप में दिव्य को देख सकती है।',
        summary: 'The Vishvarupa Darshana - Krishna shows Arjuna His cosmic form containing all of creation.',
        readingTimeMinutes: 12,
        author: 'DivinePath',
        tags: ['krishna', 'gita', 'vishvarupa', 'arjuna', 'cosmic'],
      ),
      StoryModel(
        id: '8',
        title: 'The Devotion of Mirabai',
        titleHindi: 'मीराबाई की भक्ति',
        category: 'Saints & Sages',
        content: 'Mirabai, the princess of Rajasthan, defied every convention of her time to devote herself completely to Lord Krishna. Born a princess in 16th century Rajasthan, she was married into the royal family of Mewar. But her heart belonged only to Krishna. She refused to worship the family goddess as tradition demanded — she would only worship Krishna. Her in-laws persecuted her. They sent her a basket with a snake, but when she opened it, she found a statue of Krishna. They tried to poison her, but the poison turned to nectar. They sent her to drown in the river, but she floated on the water, singing Krishna\'s name. Through every trial, Mira composed beautiful bhajans that are still sung today. Her love was so pure that Krishna Himself would appear before her, dance with her, and wear the garlands she made. She eventually left the palace forever and wandered as a devotee, finally merging into the idol of Krishna at Dwarka — consumed by her love for the divine.',
        contentHindi: 'राजस्थान की राजकुमारी मीराबाई ने भगवान कृष्ण के प्रति पूर्ण समर्पण के लिए अपने युग की हर रूढ़ि को चुनौती दी। सोलहवीं शताब्दी के राजस्थान में राजकुमारी के रूप में जन्मी मीरा का विवाह मेवाड़ के राजपरिवार में हुआ। परंतु उनका हृदय केवल कृष्ण का था। उन्होंने परिवार की देवी की पूजा करने से इनकार कर दिया — वे केवल कृष्ण की पूजा करेंगी। उनके ससुराल वालों ने उन्हें सताया। उन्होंने उन्हें साँप से भरी टोकरी भेजी, परंतु जब उन्होंने उसे खोला तो उसमें कृष्ण की मूर्ति थी। उन्होंने उन्हें विष देने का प्रयास किया, परंतु विष अमृत बन गया। उन्होंने उन्हें नदी में डुबाने भेजा, परंतु वे कृष्ण का नाम गाते हुए जल पर तैरती रहीं। हर परीक्षा में मीरा ने सुंदर भजनों की रचना की जो आज भी गाए जाते हैं। उनका प्रेम इतना शुद्ध था कि कृष्ण स्वयं उनके सामने प्रकट होते, उनके साथ नृत्य करते और उनके बनाए हार धारण करते। अंततः उन्होंने महल को हमेशा के लिए छोड़ दिया और एक भक्त के रूप में भटकती रहीं, अंत में द्वारका में कृष्ण की मूर्ति में विलीन हो गईं — दिव्य के प्रति अपने प्रेम में समाहित।',
        summary: 'The inspiring story of Mirabai - the saint who lived and breathed devotion to Krishna.',
        readingTimeMinutes: 8,
        author: 'DivinePath',
        tags: ['mirabai', 'saint', 'devotion', 'krishna', 'bhakti'],
      ),
      StoryModel(
        id: '9',
        title: 'The Golden Deer of Panchavati',
        titleHindi: 'पंचवटी का स्वर्ण मृग',
        category: 'Ramayan',
        content: 'In the forest of Panchavati, a beautiful golden deer with silver spots appeared before Sita. Its skin glittered like diamonds, and its eyes sparkled with magic. Mesmerized by its beauty, Sita asked Rama to capture it for her. Rama, sensing something amiss, instructed Lakshmana to guard Sita and went after the deer. The deer led Rama far into the forest — deeper and deeper. Finally, Rama shot an arrow and struck the deer. As it fell, it transformed into the demon Maricha and cried out in Rama\'s voice, "O Lakshmana! O Sita! Save me!" Hearing her husband\'s cry, Sita forced Lakshmana to go help Rama. The forest was now empty, and Ravana, who had been watching from hiding, appeared in the guise of a sage. He abducted Sita and carried her away in his pushpaka chariot. The golden deer was Maya — illusion — and it had set in motion the greatest war of the age.',
        contentHindi: 'पंचवटी के वन में सीता के सामने एक सुंदर स्वर्ण मृग प्रकट हुआ। उसकी त्वचा हीरे की तरह चमकती थी और उसकी आँखें जादुई रूप से झिलमिलाती थीं। उसकी सुंदरता से मुग्ध होकर सीता ने राम से उसे पकड़ने का अनुरोध किया। राम ने कुछ संदेह महसूस किया, लक्ष्मण को सीता की रक्षा करने का निर्देश दिया और मृग के पीछे चल दिए। मृग राम को वन में और गहरा ले गया। अंततः राम ने बाण चलाया और मृग को मार गिराया। गिरते ही वह राक्षस मारीच में बदल गया और राम की आवाज़ में चिल्लाया, "हे लक्ष्मण! हे सीता! मुझे बचाओ!" अपने पति की पुकार सुनकर सीता ने लक्ष्मण को राम की सहायता के लिए जाने को विवश किया। वन अब खाली था, और रावण, जो छिपकर देख रहा था, एक साधु के वेश में प्रकट हुआ। उसने सीता का अपहरण कर लिया और उन्हें अपने पुष्पक विमान में ले गया। स्वर्ण मृग माया थी — और उसने युग के सबसे महान युद्ध की नींव रख दी।',
        summary: 'The magical golden deer that led to the abduction of Sita by Ravana.',
        readingTimeMinutes: 9,
        author: 'DivinePath',
        tags: ['rama', 'sita', 'ramayan', 'golden deer', 'ravana'],
      ),
      StoryModel(
        id: '10',
        title: 'Krishna Lifts Mount Govardhan',
        titleHindi: 'कृष्ण का गोवर्धन पर्वत धारण',
        category: 'Krishna Leela',
        content: 'When the people of Vrindavan prepared to worship Lord Indra, young Krishna convinced them to worship Mount Govardhan instead. "We are farmers and cowherds," Krishna said. "Govardhan provides us grass for our cows, water from its streams, and fertile soil for our crops. Let us honor the mountain who sustains us." The villagers agreed and prepared a grand offering for Govardhan. Lord Indra, king of the gods, grew furious at being neglected. He gathered the mightiest storm clouds and unleashed a torrential downpour on Vrindavan. Rain fell like mountains from the sky. The village began to flood. The cows panicked, and the people ran for shelter. Young Krishna calmly walked to Mount Govardhan, lifted it with one hand, and held it above the village like an umbrella. For seven days and seven nights, the storm raged, and Krishna held the mountain steady and unwavering. Indra finally realized that this was no ordinary boy but the Supreme Lord Himself. He withdrew the storm and bowed to Krishna.',
        contentHindi: 'जब वृंदावन के लोग भगवान इंद्र की पूजा की तैयारी कर रहे थे, बाल कृष्ण ने उन्हें गोवर्धन पर्वत की पूजा करने के लिए मनाया। "हम किसान और ग्वाले हैं," कृष्ण ने कहा। "गोवर्धन हमें गायों के लिए घास, अपनी धाराओं से जल और फसलों के लिए उपजाऊ मिट्टी देता है। आओ, हम उस पर्वत का सम्मान करें जो हमारा पालन करता है।" ग्रामीणों ने सहमति दी और गोवर्धन के लिए एक भव्य भोग तैयार किया। देवराज इंद्र उपेक्षित होने पर अत्यंत क्रोधित हुए। उन्होंने सबसे शक्तिशाली तूफानी बादलों को एकत्र किया और वृंदावन पर मूसलधार वर्षा बरसाई। आकाश से पर्वतों की तरह वर्षा हुई। गाँव में बाढ़ आने लगी। गायें घबरा गईं और लोग शरण की तलाश में भागे। बाल कृष्ण शांतिपूर्वक गोवर्धन पर्वत के पास गए, उसे एक हाथ से उठाया और छतरी की तरह गाँव के ऊपर धारण किया। सात दिन और सात रात तूफान चलता रहा और कृष्ण ने पर्वत को स्थिर और अडिग धारण किए रखा। इंद्र अंततः समझ गए कि यह कोई साधारण बालक नहीं बल्कि स्वयं सर्वोच्च भगवान हैं। उन्होंने तूफान वापस ले लिया और कृष्ण को प्रणाम किया।',
        summary: 'The story of how Krishna lifted an entire mountain on his little finger to protect the cowherds.',
        readingTimeMinutes: 7,
        author: 'DivinePath',
        tags: ['krishna', 'govardhan', 'indra', 'vrindavan', 'leela'],
      ),
      StoryModel(
        id: '11',
        title: 'Draupadi\'s Honor',
        titleHindi: 'द्रौपदी की रक्षा',
        category: 'Mahabharat',
        content: 'In the court of the Kauravas, Draupadi was humiliated after Yudhishthira lost her in a game of dice. Duryodhana ordered his brother Dushasana to drag her by the hair and disrobe her before the entire assembly. The court fell silent. Bhima burned with rage but was bound by his elder brother\'s word. Draupadi stood alone, her dignity stripped away. Dushasana laughed as he began to pull at her sari. But as he pulled, a miracle unfolded. Layer after layer of cloth appeared, the sari became longer and longer, yards turned into miles. Dushasana pulled and pulled, but the endless fabric kept flowing. His arms grew tired, his laughter faded, and the court watched in stunned amazement. Draupadi had prayed to Krishna with her hands raised, and He had answered. In that moment, the seeds of the Mahabharata war were sown — the humiliation of Draupadi would never be forgotten or forgiven.',
        contentHindi: 'कौरवों की सभा में युधिष्ठिर द्वारा द्युत क्रीड़ा में द्रौपदी को हारने के बाद उनका अपमान किया गया। दुर्योधन ने अपने भाई दुःशासन को आदेश दिया कि वे द्रौपदी को बालों से खींचकर पूरी सभा के सामने निर्वस्त्र करें। सभा मौन हो गई। भीम क्रोध से जल उठे परंतु अपने बड़े भाई के वचन से बंधे थे। द्रौपदी अकेली खड़ी थीं, उनकी गरिमा छीनी जा चुकी थी। दुःशासन हँसते हुए उनकी साड़ी खींचने लगा। परंतु जैसे ही उसने खींचा, एक चमत्कार हुआ। कपड़े की परत के बाद परत प्रकट होती गई, साड़ी लंबी और लंबी होती गई, गज मीलों में बदल गए। दुःशासन खींचता रहा, परंतु अंतहीन वस्त्र बहता रहा। उसकी भुजाएँ थक गईं, उसकी हँसी समाप्त हो गई और सभा अचंभित होकर देखती रही। द्रौपदी ने हाथ उठाकर कृष्ण से प्रार्थना की थी और उन्होंने उत्तर दिया। उसी क्षण महाभारत युद्ध के बीज बोए गए — द्रौपदी का अपमान कभी भुलाया या माफ नहीं किया जाएगा।',
        summary: 'The divine intervention of Krishna when Draupadi was dishonored in the Kaurava court.',
        readingTimeMinutes: 11,
        author: 'DivinePath',
        tags: ['draupadi', 'mahabharat', 'krishna', 'honor', 'divine'],
      ),
      StoryModel(
        id: '12',
        title: 'Hanuman Finds the Sanjivani Herb',
        titleHindi: 'हनुमान की संजीवनी बूटी',
        category: 'Hanuman Stories',
        content: 'When Lakshmana fell unconscious in battle, struck by a devastating weapon from the demon Meghnad, the only cure was the Sanjivani herb from the Himalayas. The herb grew on the distant Mount Dronagiri and could bring the dead back to life. With no time to lose, Hanuman was dispatched immediately. He expanded to his colossal form and leaped into the sky, flying northward with the speed of the wind. When he reached the Himalayas, he faced a problem — the herb was one among millions, and he could not identify it. With characteristic wisdom, Hanuman decided to uproot the entire mountain and carry it back. He placed Mount Dronagiri on his palm and turned back. On his return, Ravana sent the demon Kalanemi to delay him, but Hanuman crushed him effortlessly. When he reached Lanka, the sun was setting — the herb needed sunlight. Hanuman expanded further and swallowed the sun itself to keep it in the sky. He delivered the mountain to Sushena, the physician, who immediately applied the herb to Lakshmana, and life returned to the fallen prince.',
        contentHindi: 'जब राक्षस मेघनाद के घातक अस्त्र से लक्ष्मण युद्ध में अचेत हो गए, तो एकमात्र उपाय हिमालय की संजीवनी बूटी थी। यह बूटी दूरस्थ द्रोणगिरि पर्वत पर उगती थी और मृतकों को जीवन वापस दे सकती थी। समय बिल्कुल नहीं था, इसलिए हनुमान को तुरंत भेजा गया। उन्होंने अपने विशाल रूप का विस्तार किया और आकाश में छलांग लगाई, पवन की गति से उत्तर की ओर उड़ते हुए। जब वे हिमालय पहुँचे, तो उनके सामने एक समस्या थी — बूटी लाखों में से एक थी और वे उसे पहचान नहीं सकते थे। अपनी विशिष्ट बुद्धि से हनुमान ने पूरे पर्वत को ही उखाड़कर वापस ले जाने का निर्णय लिया। उन्होंने द्रोणगिरि पर्वत को अपनी हथेली पर रखा और वापस चल दिए। वापसी में रावण ने उन्हें विलंबित करने के लिए राक्षस कालनेमि को भेजा, परंतु हनुमान ने उसे सहजता से नष्ट कर दिया। जब वे लंका पहुँचे, सूर्य अस्त हो रहा था — बूटी को सूर्य के प्रकाश की आवश्यकता थी। हनुमान ने और विस्तार किया और सूर्य को ही निगल लिया ताकि वह आकाश में बना रहे। उन्होंने पर्वत वैद्य सुषेण को सौंप दिया, जिन्होंने तुरंत लक्ष्मण पर बूटी लगाई और राजकुमार में जीवन लौट आया।',
        summary: 'Hanuman\'s daring flight to the Himalayas to bring the life-restoring Sanjivani herb.',
        readingTimeMinutes: 10,
        author: 'DivinePath',
        tags: ['hanuman', 'sanjivani', 'lakshmana', 'ramayan', 'devotion'],
      ),
    ];
  }
}

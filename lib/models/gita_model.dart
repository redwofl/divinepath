class GitaChapter {
  final int number;
  final String name;
  final String nameHindi;
  final String? summary;
  final int totalVerses;
  final String? imageUrl;

  GitaChapter({
    required this.number,
    required this.name,
    required this.nameHindi,
    this.summary,
    required this.totalVerses,
    this.imageUrl,
  });

  factory GitaChapter.fromMap(Map<String, dynamic> map) {
    return GitaChapter(
      number: map['number'] ?? 0,
      name: map['name'] ?? '',
      nameHindi: map['nameHindi'] ?? '',
      summary: map['summary'],
      totalVerses: map['totalVerses'] ?? 0,
      imageUrl: map['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'number': number,
      'name': name,
      'nameHindi': nameHindi,
      'summary': summary,
      'totalVerses': totalVerses,
      'imageUrl': imageUrl,
    };
  }
}

class GitaVerse {
  final String id;
  final int chapterNumber;
  final int verseNumber;
  final String? shloka;
  final String? transliteration;
  final String? wordMeanings;
  final String? translationEnglish;
  final String? translationHindi;
  final String? commentary;
  final String? audioUrl;
  final List<String>? tags;

  GitaVerse({
    required this.id,
    required this.chapterNumber,
    required this.verseNumber,
    this.shloka,
    this.transliteration,
    this.wordMeanings,
    this.translationEnglish,
    this.translationHindi,
    this.commentary,
    this.audioUrl,
    this.tags,
  });

  factory GitaVerse.fromMap(Map<String, dynamic> map, String id) {
    return GitaVerse(
      id: id,
      chapterNumber: map['chapterNumber'] ?? 0,
      verseNumber: map['verseNumber'] ?? 0,
      shloka: map['shloka'],
      transliteration: map['transliteration'],
      wordMeanings: map['wordMeanings'],
      translationEnglish: map['translationEnglish'],
      translationHindi: map['translationHindi'],
      commentary: map['commentary'],
      audioUrl: map['audioUrl'],
      tags: map['tags'] != null ? List<String>.from(map['tags']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chapterNumber': chapterNumber,
      'verseNumber': verseNumber,
      'shloka': shloka,
      'transliteration': transliteration,
      'wordMeanings': wordMeanings,
      'translationEnglish': translationEnglish,
      'translationHindi': translationHindi,
      'commentary': commentary,
      'audioUrl': audioUrl,
      'tags': tags,
    };
  }
}

class VerseBookmark {
  final String verseId;
  final int chapterNumber;
  final int verseNumber;
  final String? shloka;
  final String? translation;
  final DateTime bookmarkedAt;
  final String? notes;

  VerseBookmark({
    required this.verseId,
    required this.chapterNumber,
    required this.verseNumber,
    this.shloka,
    this.translation,
    DateTime? bookmarkedAt,
    this.notes,
  }) : bookmarkedAt = bookmarkedAt ?? DateTime.now();

  factory VerseBookmark.fromMap(Map<String, dynamic> map) {
    return VerseBookmark(
      verseId: map['verseId'] ?? '',
      chapterNumber: map['chapterNumber'] ?? 0,
      verseNumber: map['verseNumber'] ?? 0,
      shloka: map['shloka'],
      translation: map['translation'],
      bookmarkedAt: map['bookmarkedAt'] != null
          ? DateTime.tryParse(map['bookmarkedAt']) ?? DateTime.now()
          : DateTime.now(),
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'verseId': verseId,
      'chapterNumber': chapterNumber,
      'verseNumber': verseNumber,
      'shloka': shloka,
      'translation': translation,
      'bookmarkedAt': bookmarkedAt.toIso8601String(),
      'notes': notes,
    };
  }
}

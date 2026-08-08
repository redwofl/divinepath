class StoryModel {
  final String id;
  final String title;
  final String? titleHindi;
  final String category;
  final String content;
  final String? contentHindi;
  final String? summary;
  final String? imageUrl;
  final String? audioUrl;
  final int readingTimeMinutes;
  final String? author;
  final String? source;
  final List<String> tags;
  final bool isPremium;
  final int likes;
  final int reads;
  final DateTime createdAt;
  final DateTime updatedAt;

  StoryModel({
    required this.id,
    required this.title,
    this.titleHindi,
    required this.category,
    required this.content,
    this.contentHindi,
    this.summary,
    this.imageUrl,
    this.audioUrl,
    this.readingTimeMinutes = 5,
    this.author,
    this.source,
    this.tags = const [],
    this.isPremium = false,
    this.likes = 0,
    this.reads = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory StoryModel.fromMap(Map<String, dynamic> map, String id) {
    return StoryModel(
      id: id,
      title: map['title'] ?? '',
      titleHindi: map['titleHindi'],
      category: map['category'] ?? '',
      content: map['content'] ?? '',
      contentHindi: map['contentHindi'],
      summary: map['summary'],
      imageUrl: map['imageUrl'],
      audioUrl: map['audioUrl'],
      readingTimeMinutes: map['readingTimeMinutes'] ?? 5,
      author: map['author'],
      source: map['source'],
      tags: List<String>.from(map['tags'] ?? []),
      isPremium: map['isPremium'] ?? false,
      likes: map['likes'] ?? 0,
      reads: map['reads'] ?? 0,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'titleHindi': titleHindi,
      'category': category,
      'content': content,
      'contentHindi': contentHindi,
      'summary': summary,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
      'readingTimeMinutes': readingTimeMinutes,
      'author': author,
      'source': source,
      'tags': tags,
      'isPremium': isPremium,
      'likes': likes,
      'reads': reads,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class StoryBookmark {
  final String storyId;
  final String title;
  final String? imageUrl;
  final String category;
  final DateTime bookmarkedAt;

  StoryBookmark({
    required this.storyId,
    required this.title,
    this.imageUrl,
    required this.category,
    DateTime? bookmarkedAt,
  }) : bookmarkedAt = bookmarkedAt ?? DateTime.now();

  factory StoryBookmark.fromMap(Map<String, dynamic> map) {
    return StoryBookmark(
      storyId: map['storyId'] ?? '',
      title: map['title'] ?? '',
      imageUrl: map['imageUrl'],
      category: map['category'] ?? '',
      bookmarkedAt: map['bookmarkedAt'] != null
          ? DateTime.tryParse(map['bookmarkedAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'storyId': storyId,
      'title': title,
      'imageUrl': imageUrl,
      'category': category,
      'bookmarkedAt': bookmarkedAt.toIso8601String(),
    };
  }
}

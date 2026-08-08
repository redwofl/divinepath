class MantraModel {
  final String id;
  final String name;
  final String? translation;
  final String? description;
  final String? deity;
  final String? language;
  final bool isCustom;
  final int count;
  final DateTime? lastChanted;
  final String? audioUrl;
  final String? imageUrl;

  MantraModel({
    required this.id,
    required this.name,
    this.translation,
    this.description,
    this.deity,
    this.language,
    this.isCustom = false,
    this.count = 0,
    this.lastChanted,
    this.audioUrl,
    this.imageUrl,
  });

  factory MantraModel.fromMap(Map<String, dynamic> map, String id) {
    return MantraModel(
      id: id,
      name: map['name'] ?? '',
      translation: map['translation'],
      description: map['description'],
      deity: map['deity'],
      language: map['language'],
      isCustom: map['isCustom'] ?? false,
      count: map['count'] ?? 0,
      lastChanted: map['lastChanted'] != null
          ? DateTime.tryParse(map['lastChanted'])
          : null,
      audioUrl: map['audioUrl'],
      imageUrl: map['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'translation': translation,
      'description': description,
      'deity': deity,
      'language': language,
      'isCustom': isCustom,
      'count': count,
      'lastChanted': lastChanted?.toIso8601String(),
      'audioUrl': audioUrl,
      'imageUrl': imageUrl,
    };
  }

  MantraModel copyWith({
    String? name,
    String? translation,
    String? description,
    String? deity,
    String? language,
    bool? isCustom,
    int? count,
    DateTime? lastChanted,
    String? audioUrl,
    String? imageUrl,
  }) {
    return MantraModel(
      id: id,
      name: name ?? this.name,
      translation: translation ?? this.translation,
      description: description ?? this.description,
      deity: deity ?? this.deity,
      language: language ?? this.language,
      isCustom: isCustom ?? this.isCustom,
      count: count ?? this.count,
      lastChanted: lastChanted ?? this.lastChanted,
      audioUrl: audioUrl ?? this.audioUrl,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

class MantraSession {
  final String id;
  final String mantraId;
  final String mantraName;
  final int count;
  final int durationSeconds;
  final DateTime timestamp;
  final bool isMalaComplete;

  MantraSession({
    required this.id,
    required this.mantraId,
    required this.mantraName,
    required this.count,
    required this.durationSeconds,
    required this.timestamp,
    this.isMalaComplete = false,
  });

  factory MantraSession.fromMap(Map<String, dynamic> map, String id) {
    return MantraSession(
      id: id,
      mantraId: map['mantraId'] ?? '',
      mantraName: map['mantraName'] ?? '',
      count: map['count'] ?? 0,
      durationSeconds: map['durationSeconds'] ?? 0,
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      isMalaComplete: map['isMalaComplete'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'mantraId': mantraId,
      'mantraName': mantraName,
      'count': count,
      'durationSeconds': durationSeconds,
      'timestamp': timestamp.toIso8601String(),
      'isMalaComplete': isMalaComplete,
    };
  }
}

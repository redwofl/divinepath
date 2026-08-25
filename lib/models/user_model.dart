class UserModel {
  final String uid;
  final String email;
  final String name;
  final String? photoUrl;
  final String? phone;
  final String language;
  final String? favoriteDeity;
  final String? preferredMantra;
  final List<String> spiritualInterests;
  final int dailyGoal;
  final int streak;
  final int longestStreak;
  final int totalChants;
  final int totalMalas;
  final int totalMeditationMinutes;
  final int totalStoriesRead;
  final int totalVersesRead;
  final int xp;
  final int coins;
  final bool isPremium;
  final bool isAdmin;
  final DateTime? premiumExpiry;
  final DateTime createdAt;
  final DateTime lastActive;
  final List<String> achievements;
  final List<String> completedChallenges;
  final Map<String, dynamic>? settings;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.photoUrl,
    this.phone,
    this.language = 'en',
    this.favoriteDeity,
    this.preferredMantra,
    this.spiritualInterests = const [],
    this.dailyGoal = 108,
    this.streak = 0,
    this.longestStreak = 0,
    this.totalChants = 0,
    this.totalMalas = 0,
    this.totalMeditationMinutes = 0,
    this.totalStoriesRead = 0,
    this.totalVersesRead = 0,
    this.xp = 0,
    this.coins = 0,
    this.isPremium = false,
    this.isAdmin = false,
    this.premiumExpiry,
    DateTime? createdAt,
    DateTime? lastActive,
    this.achievements = const [],
    this.completedChallenges = const [],
    this.settings,
  })  : createdAt = createdAt ?? DateTime.now(),
        lastActive = lastActive ?? DateTime.now();

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      photoUrl: map['photoUrl'],
      phone: map['phone'],
      language: map['language'] ?? 'en',
      favoriteDeity: map['favoriteDeity'],
      preferredMantra: map['preferredMantra'],
      spiritualInterests: List<String>.from(map['spiritualInterests'] ?? []),
      dailyGoal: map['dailyGoal'] ?? 108,
      streak: map['streak'] ?? 0,
      longestStreak: map['longestStreak'] ?? 0,
      totalChants: map['totalChants'] ?? 0,
      totalMalas: map['totalMalas'] ?? 0,
      totalMeditationMinutes: map['totalMeditationMinutes'] ?? 0,
      totalStoriesRead: map['totalStoriesRead'] ?? 0,
      totalVersesRead: map['totalVersesRead'] ?? 0,
      xp: map['xp'] ?? 0,
      coins: map['coins'] ?? 0,
      isPremium: map['isPremium'] ?? false,
      isAdmin: map['isAdmin'] ?? false,
      premiumExpiry: map['premiumExpiry'] != null
          ? DateTime.tryParse(map['premiumExpiry'])
          : null,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      lastActive: map['lastActive'] != null
          ? DateTime.tryParse(map['lastActive']) ?? DateTime.now()
          : DateTime.now(),
      achievements: List<String>.from(map['achievements'] ?? []),
      completedChallenges: List<String>.from(map['completedChallenges'] ?? []),
      settings: map['settings'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'phone': phone,
      'language': language,
      'favoriteDeity': favoriteDeity,
      'preferredMantra': preferredMantra,
      'spiritualInterests': spiritualInterests,
      'dailyGoal': dailyGoal,
      'streak': streak,
      'longestStreak': longestStreak,
      'totalChants': totalChants,
      'totalMalas': totalMalas,
      'totalMeditationMinutes': totalMeditationMinutes,
      'totalStoriesRead': totalStoriesRead,
      'totalVersesRead': totalVersesRead,
      'xp': xp,
      'coins': coins,
      'isPremium': isPremium,
      'isAdmin': isAdmin,
      'premiumExpiry': premiumExpiry?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'lastActive': lastActive.toIso8601String(),
      'achievements': achievements,
      'completedChallenges': completedChallenges,
      'settings': settings,
    };
  }

  UserModel copyWith({
    String? email,
    String? name,
    String? photoUrl,
    String? phone,
    String? language,
    String? favoriteDeity,
    String? preferredMantra,
    List<String>? spiritualInterests,
    int? dailyGoal,
    int? streak,
    int? longestStreak,
    int? totalChants,
    int? totalMalas,
    int? totalMeditationMinutes,
    int? totalStoriesRead,
    int? totalVersesRead,
    int? xp,
    int? coins,
    bool? isPremium,
    bool? isAdmin,
    DateTime? premiumExpiry,
    DateTime? lastActive,
    List<String>? achievements,
    List<String>? completedChallenges,
    Map<String, dynamic>? settings,
  }) {
    return UserModel(
      uid: uid,
      email: email ?? this.email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      phone: phone ?? this.phone,
      language: language ?? this.language,
      favoriteDeity: favoriteDeity ?? this.favoriteDeity,
      preferredMantra: preferredMantra ?? this.preferredMantra,
      spiritualInterests: spiritualInterests ?? this.spiritualInterests,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      streak: streak ?? this.streak,
      longestStreak: longestStreak ?? this.longestStreak,
      totalChants: totalChants ?? this.totalChants,
      totalMalas: totalMalas ?? this.totalMalas,
      totalMeditationMinutes: totalMeditationMinutes ?? this.totalMeditationMinutes,
      totalStoriesRead: totalStoriesRead ?? this.totalStoriesRead,
      totalVersesRead: totalVersesRead ?? this.totalVersesRead,
      xp: xp ?? this.xp,
      coins: coins ?? this.coins,
      isPremium: isPremium ?? this.isPremium,
      isAdmin: isAdmin ?? this.isAdmin,
      premiumExpiry: premiumExpiry ?? this.premiumExpiry,
      createdAt: createdAt,
      lastActive: lastActive ?? this.lastActive,
      achievements: achievements ?? this.achievements,
      completedChallenges: completedChallenges ?? this.completedChallenges,
      settings: settings ?? this.settings,
    );
  }
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final String category;
  final int requiredValue;
  final int xpReward;
  final int coinReward;
  final bool isHidden;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.category,
    this.requiredValue = 1,
    this.xpReward = 50,
    this.coinReward = 10,
    this.isHidden = false,
  });

  factory Achievement.fromMap(Map<String, dynamic> map, String id) {
    return Achievement(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      icon: map['icon'] ?? '🏆',
      category: map['category'] ?? '',
      requiredValue: map['requiredValue'] ?? 1,
      xpReward: map['xpReward'] ?? 50,
      coinReward: map['coinReward'] ?? 10,
      isHidden: map['isHidden'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'icon': icon,
      'category': category,
      'requiredValue': requiredValue,
      'xpReward': xpReward,
      'coinReward': coinReward,
      'isHidden': isHidden,
    };
  }

  static final List<Achievement> defaultAchievements = [
    const Achievement(
      id: 'first_chant',
      title: 'First Chant',
      description: 'Complete your first mantra chant',
      icon: '🔮',
      category: 'Mantra',
      requiredValue: 1,
      xpReward: 10,
      coinReward: 5,
    ),
    const Achievement(
      id: 'first_mala',
      title: 'First Mala',
      description: 'Complete one full mala (108 chants)',
      icon: '📿',
      category: 'Mantra',
      requiredValue: 108,
      xpReward: 50,
      coinReward: 20,
    ),
    const Achievement(
      id: 'streak_7',
      title: 'Weekly Warrior',
      description: 'Maintain a 7-day streak',
      icon: '🔥',
      category: 'Streak',
      requiredValue: 7,
      xpReward: 100,
      coinReward: 50,
    ),
    const Achievement(
      id: 'streak_30',
      title: 'Monthly Master',
      description: 'Maintain a 30-day streak',
      icon: '💫',
      category: 'Streak',
      requiredValue: 30,
      xpReward: 500,
      coinReward: 200,
    ),
    const Achievement(
      id: 'streak_100',
      title: 'Century Streak',
      description: 'Maintain a 100-day streak',
      icon: '🌟',
      category: 'Streak',
      requiredValue: 100,
      xpReward: 1000,
      coinReward: 500,
    ),
    const Achievement(
      id: 'meditation_10',
      title: 'Meditation Beginner',
      description: 'Meditate for 10 minutes total',
      icon: '🧘',
      category: 'Meditation',
      requiredValue: 10,
      xpReward: 50,
      coinReward: 20,
    ),
    const Achievement(
      id: 'meditation_100',
      title: 'Meditation Seeker',
      description: 'Meditate for 100 minutes total',
      icon: '🧘‍♀️',
      category: 'Meditation',
      requiredValue: 100,
      xpReward: 200,
      coinReward: 100,
    ),
    const Achievement(
      id: 'story_5',
      title: 'Story Lover',
      description: 'Read 5 sacred stories',
      icon: '📚',
      category: 'Stories',
      requiredValue: 5,
      xpReward: 50,
      coinReward: 20,
    ),
    const Achievement(
      id: 'gita_10',
      title: 'Gita Scholar',
      description: 'Read 10 Gita verses',
      icon: '📖',
      category: 'Gita',
      requiredValue: 10,
      xpReward: 100,
      coinReward: 50,
    ),
    const Achievement(
      id: 'challenge_5',
      title: 'Challenge Taker',
      description: 'Complete 5 daily challenges',
      icon: '🎯',
      category: 'Challenges',
      requiredValue: 5,
      xpReward: 100,
      coinReward: 50,
    ),
    const Achievement(
      id: 'chants_1000',
      title: 'Chant Master',
      description: 'Complete 1000 total chants',
      icon: '🕉️',
      category: 'Mantra',
      requiredValue: 1000,
      xpReward: 500,
      coinReward: 200,
    ),
    const Achievement(
      id: 'chants_10000',
      title: 'Mantra Sage',
      description: 'Complete 10,000 total chants',
      icon: '✨',
      category: 'Mantra',
      requiredValue: 10000,
      xpReward: 2000,
      coinReward: 1000,
    ),
  ];
}

class DailyChallenge {
  final String id;
  final String title;
  final String description;
  final String type;
  final int requiredValue;
  final int xpReward;
  final int coinReward;
  final String? icon;
  final DateTime? date;
  final bool isActive;

  DailyChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.requiredValue,
    this.xpReward = 50,
    this.coinReward = 20,
    this.icon,
    this.date,
    this.isActive = true,
  });

  factory DailyChallenge.fromMap(Map<String, dynamic> map, String id) {
    return DailyChallenge(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      type: map['type'] ?? '',
      requiredValue: map['requiredValue'] ?? 1,
      xpReward: map['xpReward'] ?? 50,
      coinReward: map['coinReward'] ?? 20,
      icon: map['icon'],
      date: map['date'] != null ? DateTime.tryParse(map['date']) : null,
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'type': type,
      'requiredValue': requiredValue,
      'xpReward': xpReward,
      'coinReward': coinReward,
      'icon': icon,
      'date': date?.toIso8601String(),
      'isActive': isActive,
    };
  }

  static final List<DailyChallenge> defaultChallenges = [
    DailyChallenge(
      id: 'chant_108',
      title: 'Complete 1 Mala',
      description: 'Chant 108 times to complete one full mala',
      type: 'chant',
      requiredValue: 108,
      xpReward: 50,
      coinReward: 20,
      icon: '📿',
    ),
    DailyChallenge(
      id: 'chant_21',
      title: '21 Chants',
      description: 'Chant 21 times with devotion',
      type: 'chant',
      requiredValue: 21,
      xpReward: 10,
      coinReward: 5,
      icon: '🔮',
    ),
    DailyChallenge(
      id: 'meditate_5',
      title: '5 Min Meditation',
      description: 'Meditate for 5 minutes',
      type: 'meditation',
      requiredValue: 5,
      xpReward: 30,
      coinReward: 15,
      icon: '🧘',
    ),
    DailyChallenge(
      id: 'meditate_10',
      title: '10 Min Meditation',
      description: 'Meditate for 10 minutes',
      type: 'meditation',
      requiredValue: 10,
      xpReward: 50,
      coinReward: 25,
      icon: '🧘‍♀️',
    ),
    DailyChallenge(
      id: 'read_story',
      title: 'Read a Story',
      description: 'Read one sacred story',
      type: 'story',
      requiredValue: 1,
      xpReward: 20,
      coinReward: 10,
      icon: '📚',
    ),
    DailyChallenge(
      id: 'read_verse',
      title: 'Read Gita Verse',
      description: 'Read one verse from Bhagavad Gita',
      type: 'verse',
      requiredValue: 1,
      xpReward: 15,
      coinReward: 5,
      icon: '📖',
    ),
    DailyChallenge(
      id: 'morning_prayer',
      title: 'Morning Prayer',
      description: 'Start your day with prayer',
      type: 'prayer',
      requiredValue: 1,
      xpReward: 25,
      coinReward: 10,
      icon: '🌅',
    ),
    DailyChallenge(
      id: 'evening_prayer',
      title: 'Evening Prayer',
      description: 'End your day with gratitude',
      type: 'prayer',
      requiredValue: 1,
      xpReward: 25,
      coinReward: 10,
      icon: '🌇',
    ),
  ];
}

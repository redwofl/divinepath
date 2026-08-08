class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final bool isSaved;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    DateTime? timestamp,
    this.isSaved = false,
  }) : timestamp = timestamp ?? DateTime.now();

  factory ChatMessage.fromMap(Map<String, dynamic> map, String id) {
    return ChatMessage(
      id: id,
      content: map['content'] ?? '',
      isUser: map['isUser'] ?? true,
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      isSaved: map['isSaved'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'isSaved': isSaved,
    };
  }
}

class ChatConversation {
  final String id;
  final String title;
  final List<ChatMessage> messages;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? topic;

  ChatConversation({
    required this.id,
    required this.title,
    this.messages = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
    this.topic,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory ChatConversation.fromMap(Map<String, dynamic> map, String id) {
    return ChatConversation(
      id: id,
      title: map['title'] ?? 'Spiritual Chat',
      messages: (map['messages'] as List<dynamic>?)
              ?.map((m) => ChatMessage.fromMap(
                  m as Map<String, dynamic>, m['id'] ?? ''))
              .toList() ??
          [],
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt'] ?? '') ?? DateTime.now(),
      topic: map['topic'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'messages': messages.map((m) => m.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'topic': topic,
    };
  }
}

class SuggestedQuestion {
  final String question;
  final String category;
  final String? icon;

  const SuggestedQuestion({
    required this.question,
    required this.category,
    this.icon,
  });

  static const List<SuggestedQuestion> spiritualQuestions = [
    SuggestedQuestion(
      question: 'What is the purpose of life according to Bhagavad Gita?',
      category: 'Philosophy',
      icon: '🕉️',
    ),
    SuggestedQuestion(
      question: 'How can I find inner peace?',
      category: 'Meditation',
      icon: '🧘',
    ),
    SuggestedQuestion(
      question: 'How to deal with anxiety and stress?',
      category: 'Wellness',
      icon: '💆',
    ),
    SuggestedQuestion(
      question: 'What is the meaning of karma?',
      category: 'Philosophy',
      icon: '🔄',
    ),
    SuggestedQuestion(
      question: 'How to practice mindfulness daily?',
      category: 'Meditation',
      icon: '🎯',
    ),
    SuggestedQuestion(
      question: 'What does Gita say about success?',
      category: 'Bhagavad Gita',
      icon: '📖',
    ),
    SuggestedQuestion(
      question: 'How to develop a meditation habit?',
      category: 'Meditation',
      icon: '⏰',
    ),
    SuggestedQuestion(
      question: 'What is the power of mantra chanting?',
      category: 'Mantra',
      icon: '🔮',
    ),
    SuggestedQuestion(
      question: 'How to overcome fear and doubt?',
      category: 'Motivation',
      icon: '💪',
    ),
    SuggestedQuestion(
      question: 'What is dharma and how to follow it?',
      category: 'Philosophy',
      icon: '⚖️',
    ),
  ];
}

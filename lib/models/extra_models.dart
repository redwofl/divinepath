class MeditationSession {
  final String id;
  final String type; // guided, breath, focus, custom
  final int durationMinutes;
  final int secondsMeditated;
  final String? ambientSound;
  final DateTime timestamp;
  final String? notes;
  final bool isCompleted;

  MeditationSession({
    required this.id,
    required this.type,
    required this.durationMinutes,
    this.secondsMeditated = 0,
    this.ambientSound,
    DateTime? timestamp,
    this.notes,
    this.isCompleted = false,
  }) : timestamp = timestamp ?? DateTime.now();

  factory MeditationSession.fromMap(Map<String, dynamic> map, String id) {
    return MeditationSession(
      id: id,
      type: map['type'] ?? 'focus',
      durationMinutes: map['durationMinutes'] ?? 5,
      secondsMeditated: map['secondsMeditated'] ?? 0,
      ambientSound: map['ambientSound'],
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      notes: map['notes'],
      isCompleted: map['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'durationMinutes': durationMinutes,
      'secondsMeditated': secondsMeditated,
      'ambientSound': ambientSound,
      'timestamp': timestamp.toIso8601String(),
      'notes': notes,
      'isCompleted': isCompleted,
    };
  }
}

class CommunityPost {
  final String id;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String content;
  final String? imageUrl;
  final String? category;
  final List<String> tags;
  final int likes;
  final int comments;
  final DateTime timestamp;
  final bool isPrayerRequest;

  CommunityPost({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.content,
    this.imageUrl,
    this.category,
    this.tags = const [],
    this.likes = 0,
    this.comments = 0,
    DateTime? timestamp,
    this.isPrayerRequest = false,
  }) : timestamp = timestamp ?? DateTime.now();

  factory CommunityPost.fromMap(Map<String, dynamic> map, String id) {
    return CommunityPost(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userPhotoUrl: map['userPhotoUrl'],
      content: map['content'] ?? '',
      imageUrl: map['imageUrl'],
      category: map['category'],
      tags: List<String>.from(map['tags'] ?? []),
      likes: map['likes'] ?? 0,
      comments: map['comments'] ?? 0,
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      isPrayerRequest: map['isPrayerRequest'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'content': content,
      'imageUrl': imageUrl,
      'category': category,
      'tags': tags,
      'likes': likes,
      'comments': comments,
      'timestamp': timestamp.toIso8601String(),
      'isPrayerRequest': isPrayerRequest,
    };
  }
}

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String? type;
  final String? data;
  final bool isRead;
  final DateTime timestamp;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    this.type,
    this.data,
    this.isRead = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: map['type'],
      data: map['data'],
      isRead: map['isRead'] ?? false,
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'type': type,
      'data': data,
      'isRead': isRead,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

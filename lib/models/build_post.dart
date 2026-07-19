import 'package:cloud_firestore/cloud_firestore.dart';

/// A community build post. Stored under: buildPosts/{postId}
class BuildPost {
  final String id;
  final String userId;
  final String username;
  final String title;
  final String description;
  final String imageUrl;
  final List<String> taggedPartIds; // Links to parts collection in marketplace
  final DateTime createdAt;
  final int likeCount;

  BuildPost({
    required this.id,
    required this.userId,
    required this.username,
    required this.title,
    required this.description,
    required this.imageUrl,
    this.taggedPartIds = const [],
    required this.createdAt,
    this.likeCount = 0,
  });

  factory BuildPost.fromJson(Map<String, dynamic> json, String documentId) {
    return BuildPost(
      id: documentId,
      userId: json['userId'] as String? ?? '',
      username: json['username'] as String? ?? 'Rider',
      title: json['title'] as String? ?? 'My Build',
      description: json['description'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      taggedPartIds: List<String>.from(json['taggedPartIds'] ?? []),
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'taggedPartIds': taggedPartIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'likeCount': likeCount,
    };
  }
}

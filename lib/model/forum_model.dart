// lib/model/forum_model.dart

class ForumPost {
  final String id;
  final String userId;
  final String authorName;
  final String content;
  final String imageUrl;
  final DateTime createdAt;
  final int likeCount;
  final int commentCount;
  final bool likedByMe;

  const ForumPost({
    required this.id,
    required this.userId,
    required this.authorName,
    required this.content,
    required this.imageUrl,
    required this.createdAt,
    required this.likeCount,
    required this.commentCount,
    required this.likedByMe,
  });

  ForumPost copyWith({
    int? likeCount,
    int? commentCount,
    bool? likedByMe,
  }) {
    return ForumPost(
      id: id,
      userId: userId,
      authorName: authorName,
      content: content,
      imageUrl: imageUrl,
      createdAt: createdAt,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      likedByMe: likedByMe ?? this.likedByMe,
    );
  }

  factory ForumPost.fromMap(Map<String, dynamic> map) {
    final createdRaw = map['created_at']?.toString() ?? '';
    final createdAt = DateTime.tryParse(createdRaw) ?? DateTime.now();
    return ForumPost(
      id: (map['id'] ?? '').toString(),
      userId: (map['user_id'] ?? '').toString(),
      authorName: (map['author_name'] ?? 'Anonymous').toString(),
      content: (map['content'] ?? '').toString(),
      imageUrl: (map['image_url'] ?? '').toString(),
      createdAt: createdAt,
      likeCount: 0,
      commentCount: 0,
      likedByMe: false,
    );
  }
}

class ForumComment {
  final String id;
  final String postId;
  final String userId;
  final String authorName;
  final String content;
  final DateTime createdAt;

  const ForumComment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.authorName,
    required this.content,
    required this.createdAt,
  });

  factory ForumComment.fromMap(Map<String, dynamic> map) {
    final createdRaw = map['created_at']?.toString() ?? '';
    final createdAt = DateTime.tryParse(createdRaw) ?? DateTime.now();
    return ForumComment(
      id: (map['id'] ?? '').toString(),
      postId: (map['post_id'] ?? '').toString(),
      userId: (map['user_id'] ?? '').toString(),
      authorName: (map['author_name'] ?? 'Anonymous').toString(),
      content: (map['content'] ?? '').toString(),
      createdAt: createdAt,
    );
  }
}

// lib/controller/forum_controller.dart
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../model/forum_model.dart';

class ForumState {
  final List<ForumPost> posts;
  final Map<String, List<ForumComment>> commentsByPost;
  final bool isLoading;
  final String error;
  final bool isPosting;
  final Set<String> loadingComments;

  const ForumState({
    this.posts = const [],
    this.commentsByPost = const {},
    this.isLoading = true,
    this.error = '',
    this.isPosting = false,
    this.loadingComments = const {},
  });

  ForumState copyWith({
    List<ForumPost>? posts,
    Map<String, List<ForumComment>>? commentsByPost,
    bool? isLoading,
    String? error,
    bool? isPosting,
    Set<String>? loadingComments,
  }) {
    return ForumState(
      posts: posts ?? this.posts,
      commentsByPost: commentsByPost ?? this.commentsByPost,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isPosting: isPosting ?? this.isPosting,
      loadingComments: loadingComments ?? this.loadingComments,
    );
  }
}

class ForumController extends StateNotifier<ForumState> {
  ForumController() : super(const ForumState()) {
    loadPosts();
  }

  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String?> _resolveUserId() async {
    final authId = _supabase.auth.currentUser?.id;
    if (authId != null && authId.isNotEmpty) return authId;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('survey_session_id');
  }

  String _resolveAuthorName() {
    final user = _supabase.auth.currentUser;
    final meta = user?.userMetadata;
    final name = meta?['full_name']?.toString().trim();
    if (name != null && name.isNotEmpty) return name;
    final email = user?.email?.split('@').first;
    if (email != null && email.isNotEmpty) return email;
    return 'Anonymous';
  }

  Future<void> loadPosts() async {
    state = state.copyWith(isLoading: true, error: '');
    try {
      final postsRaw = await _supabase
          .from('forum_posts')
          .select()
          .order('created_at', ascending: false)
          .limit(50);

      final userId = await _resolveUserId();
      final posts = <ForumPost>[];

      for (final row in postsRaw) {
        final post = ForumPost.fromMap(Map<String, dynamic>.from(row));
        final likeCount = await _countForPost('forum_likes', post.id);
        final commentCount = await _countForPost('forum_comments', post.id);
        final likedByMe = userId == null
            ? false
            : await _isLikedByUser(post.id, userId);
        posts.add(post.copyWith(
          likeCount: likeCount,
          commentCount: commentCount,
          likedByMe: likedByMe,
        ));
      }

      state = state.copyWith(posts: posts, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Unable to load forum posts: $e',
      );
    }
  }

  Future<int> _countForPost(String table, String postId) async {
    final rows = await _supabase
        .from(table)
        .select('id')
        .eq('post_id', postId);
    return rows.length;
  }

  Future<bool> _isLikedByUser(String postId, String userId) async {
    final res = await _supabase
        .from('forum_likes')
        .select()
        .eq('post_id', postId)
        .eq('user_id', userId)
        .maybeSingle();
    return res != null;
  }

  Future<void> createPost({
    required String content,
    String imageUrl = '',
    File? imageFile,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return;
    final userId = await _resolveUserId();
    if (userId == null || userId.isEmpty) {
      state = state.copyWith(error: 'Please sign in to post.');
      return;
    }
    state = state.copyWith(isPosting: true, error: '');
    try {
      String finalImageUrl = imageUrl.trim();
      if (imageFile != null) {
        final uploadUrl = await _uploadImage(userId, imageFile);
        if (uploadUrl != null && uploadUrl.isNotEmpty) {
          finalImageUrl = uploadUrl;
        }
      }
      await _supabase.from('forum_posts').insert({
        'user_id': userId,
        'author_name': _resolveAuthorName(),
        'content': trimmed,
        'image_url': finalImageUrl,
      });
      await loadPosts();
    } catch (e) {
      state = state.copyWith(error: 'Unable to post: $e');
    } finally {
      state = state.copyWith(isPosting: false);
    }
  }

  Future<String?> _uploadImage(String userId, File file) async {
    try {
      final ext = file.path.split('.').last.toLowerCase();
      final filename = '${const Uuid().v4()}.$ext';
      final path = '$userId/$filename';
      await _supabase.storage.from('forum-images').upload(
            path,
            file,
            fileOptions: const FileOptions(upsert: false),
          );
      return _supabase.storage.from('forum-images').getPublicUrl(path);
    } catch (_) {
      return null;
    }
  }

  Future<void> toggleLike(ForumPost post) async {
    final userId = await _resolveUserId();
    if (userId == null || userId.isEmpty) return;
    try {
      if (post.likedByMe) {
        await _supabase
            .from('forum_likes')
            .delete()
            .eq('post_id', post.id)
            .eq('user_id', userId);
      } else {
        await _supabase.from('forum_likes').insert({
          'post_id': post.id,
          'user_id': userId,
        });
      }
      final updated = state.posts.map((p) {
        if (p.id != post.id) return p;
        final newLiked = !post.likedByMe;
        final newCount = post.likeCount + (newLiked ? 1 : -1);
        return p.copyWith(likedByMe: newLiked, likeCount: newCount.clamp(0, 999999));
      }).toList();
      state = state.copyWith(posts: updated);
    } catch (_) {
      // Ignore like failure; keep UI state
    }
  }

  Future<void> loadComments(String postId) async {
    if (state.loadingComments.contains(postId)) return;
    final loading = Set<String>.from(state.loadingComments)..add(postId);
    state = state.copyWith(loadingComments: loading);
    try {
      final rows = await _supabase
          .from('forum_comments')
          .select('id,post_id,user_id,author_name,content,created_at')
          .eq('post_id', postId)
          .order('created_at', ascending: true)
          .limit(200)
          .timeout(const Duration(seconds: 8));
      final comments = rows
          .map((e) => ForumComment.fromMap(Map<String, dynamic>.from(e)))
          .toList();
      final map = Map<String, List<ForumComment>>.from(state.commentsByPost);
      map[postId] = comments;
      state = state.copyWith(commentsByPost: map);
    } catch (e) {
      final map = Map<String, List<ForumComment>>.from(state.commentsByPost);
      map[postId] = map[postId] ?? [];
      state = state.copyWith(
        commentsByPost: map,
        error: 'Unable to load comments. Please try again.',
      );
    } finally {
      final loadingDone = Set<String>.from(state.loadingComments)..remove(postId);
      state = state.copyWith(loadingComments: loadingDone);
    }
  }

  Future<void> addComment(String postId, String content) async {
    final text = content.trim();
    if (text.isEmpty) return;
    final userId = await _resolveUserId();
    if (userId == null || userId.isEmpty) return;
    try {
      await _supabase.from('forum_comments').insert({
        'post_id': postId,
        'user_id': userId,
        'author_name': _resolveAuthorName(),
        'content': text,
      });
      await loadComments(postId);
      final updated = state.posts.map((p) {
        if (p.id != postId) return p;
        return p.copyWith(commentCount: p.commentCount + 1);
      }).toList();
      state = state.copyWith(posts: updated);
    } catch (_) {
      // ignore for now
    }
  }
}

final forumControllerProvider =
    StateNotifierProvider<ForumController, ForumState>(
  (_) => ForumController(),
);

// lib/view/forum_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

import 'package:image_picker/image_picker.dart';

import '../controller/forum_controller.dart';
import '../model/app_theme.dart';
import '../model/forum_model.dart';

class ForumScreen extends ConsumerStatefulWidget {
  const ForumScreen({super.key});

  @override
  ConsumerState<ForumScreen> createState() => _ForumScreenState();
}

class _ForumScreenState extends ConsumerState<ForumScreen> {
  final _postCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();
  final _picker = ImagePicker();
  File? _selectedImage;

  @override
  void dispose() {
    _postCtrl.dispose();
    _imageCtrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  void _showComments(BuildContext context, ForumPost post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CommentsSheet(post: post),
    );
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    setState(() {
      _selectedImage = File(picked.path);
    });
  }

  void _showCreatePostSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _ComposerModal(
          postCtrl: _postCtrl,
          imageCtrl: _imageCtrl,
          selectedImage: _selectedImage,
          onPickImage: _pickImage,
          onClearImage: () => setState(() => _selectedImage = null),
          onPost: () {
            final text = _postCtrl.text;
            final image = _imageCtrl.text;
            final imageFile = _selectedImage;
            _postCtrl.clear();
            _imageCtrl.clear();
            setState(() => _selectedImage = null);
            ref.read(forumControllerProvider.notifier).createPost(
                  content: text,
                  imageUrl: image,
                  imageFile: imageFile,
                );
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forumControllerProvider);
    final ctrl = ref.read(forumControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreatePostSheet(context),
        backgroundColor: AppTheme.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.white,
            floating: true,
            expandedHeight: 140,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                padding: const EdgeInsets.fromLTRB(20, 48, 20, 12),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: const [
                    Text(
                      'Community Forum',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Share updates, ask questions, and help other founders.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _InfoBanner(isPosting: state.isPosting),
                const SizedBox(height: 12),
                if (state.isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (state.error.isNotEmpty)
                  Text(state.error, style: const TextStyle(color: AppTheme.error))
                else if (state.posts.isEmpty)
                  const Text(
                    'No posts yet. Be the first to share an update.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  )
                else
                  ...state.posts.map((p) => _PostCard(
                        post: p,
                        dateLabel: _formatDate(p.createdAt),
                        onLike: () => ctrl.toggleLike(p),
                        onComment: () => _showComments(context, p),
                      )),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComposerModal extends StatelessWidget {
  const _ComposerModal({
    required this.postCtrl,
    required this.imageCtrl,
    required this.selectedImage,
    required this.onPickImage,
    required this.onClearImage,
    required this.onPost,
  });

  final TextEditingController postCtrl;
  final TextEditingController imageCtrl;
  final File? selectedImage;
  final VoidCallback onPickImage;
  final VoidCallback onClearImage;
  final VoidCallback onPost;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 80, 16, 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.radiusXl,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Create Post',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: postCtrl,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Share an update or question...',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: imageCtrl,
            decoration: const InputDecoration(
              hintText: 'Image URL (optional)',
            ),
          ),
          const SizedBox(height: 10),
          if (selectedImage != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                selectedImage!,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: onPickImage,
                icon: const Icon(Icons.photo_library_outlined, size: 18),
                label: const Text('Add Photo'),
              ),
              const SizedBox(width: 8),
              if (selectedImage != null)
                TextButton(
                  onPressed: onClearImage,
                  child: const Text('Remove'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: onPost,
              child: const Text('Make Post'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.isPosting});

  final bool isPosting;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.radiusXl,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.bluePale,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.add_comment_outlined, color: AppTheme.blue),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Share updates or questions with the community.',
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
          ),
          const SizedBox(width: 8),
          if (isPosting)
            const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.post,
    required this.dateLabel,
    required this.onLike,
    required this.onComment,
  });

  final ForumPost post;
  final String dateLabel;
  final VoidCallback onLike;
  final VoidCallback onComment;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.radiusXl,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.greenPale,
                child: Text(
                  post.authorName.isNotEmpty ? post.authorName[0].toUpperCase() : 'U',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.green),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.authorName,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      dateLabel,
                      style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            post.content,
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
          if (post.imageUrl.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                post.imageUrl,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 120,
                  color: AppTheme.background,
                  alignment: Alignment.center,
                  child: const Text('Image failed to load',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton.icon(
                onPressed: onLike,
                icon: Icon(
                  post.likedByMe ? Icons.favorite : Icons.favorite_border,
                  color: post.likedByMe ? AppTheme.green : AppTheme.textMuted,
                  size: 18,
                ),
                label: Text(
                  '${post.likeCount}',
                  style: TextStyle(
                    color: post.likedByMe ? AppTheme.green : AppTheme.textMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              TextButton.icon(
                onPressed: onComment,
                icon: const Icon(Icons.chat_bubble_outline, size: 18, color: AppTheme.textMuted),
                label: Text(
                  '${post.commentCount}',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CommentsSheet extends ConsumerStatefulWidget {
  const _CommentsSheet({required this.post});

  final ForumPost post;

  @override
  ConsumerState<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<_CommentsSheet> {
  final _commentCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    ref.read(forumControllerProvider.notifier).loadComments(widget.post.id);
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forumControllerProvider);
    final ctrl = ref.read(forumControllerProvider.notifier);
    final comments = state.commentsByPost[widget.post.id] ?? [];
    final isLoading = state.loadingComments.contains(widget.post.id);
    final error = state.error;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 80, 16, 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.radiusXl,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Comments',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: AppTheme.textMuted),
              ),
            ],
          ),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : error.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              error,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppTheme.error, fontSize: 12),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton(
                              onPressed: () => ctrl.loadComments(widget.post.id),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : comments.isEmpty
                        ? const Center(
                            child: Text(
                              'No comments yet. Start the conversation.',
                              style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                            ),
                          )
                        : ListView.separated(
                        itemCount: comments.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final c = comments[i];
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: AppTheme.bluePale,
                                child: Text(
                                  c.authorName.isNotEmpty ? c.authorName[0].toUpperCase() : 'U',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.blue,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.background,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              c.authorName,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            _formatTime(c.createdAt),
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: AppTheme.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        c.content,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Write a comment...',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  final text = _commentCtrl.text;
                  _commentCtrl.clear();
                  ctrl.addComment(widget.post.id, text);
                },
                child: const Text('Send'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

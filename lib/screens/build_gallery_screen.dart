import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/build_post.dart';
import '../models/part.dart';
import '../services/database_service.dart';

class BuildGalleryScreen extends StatefulWidget {
  const BuildGalleryScreen({super.key});

  @override
  State<BuildGalleryScreen> createState() => _BuildGalleryScreenState();
}

class _BuildGalleryScreenState extends State<BuildGalleryScreen> {
  final _db = DatabaseService();
  final _scrollController = ScrollController();
  final List<BuildPost> _posts = [];
  DocumentSnapshot? _lastDoc;
  bool _isLoading = false;
  bool _hasMore = true;
  static const int _limit = 10;

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 300) {
        _loadPosts();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);
    try {
      final result = await _db.getBuildPostsPaginated(
          limit: _limit, lastDocument: _lastDoc);
      if (result.posts.isEmpty) {
        setState(() { _hasMore = false; _isLoading = false; });
        return;
      }
      setState(() {
        _posts.addAll(result.posts);
        _lastDoc = result.lastDoc;
        if (result.posts.length < _limit) _hasMore = false;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Gallery load error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refresh() async {
    setState(() { _posts.clear(); _lastDoc = null; _hasMore = true; });
    await _loadPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12121A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Build Gallery',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate_rounded, color: Colors.deepPurpleAccent),
            onPressed: () => _showCreatePostSheet(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreatePostSheet(context),
        backgroundColor: Colors.deepPurpleAccent,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('Share Build',
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: Colors.deepPurpleAccent,
        child: _posts.isEmpty && !_isLoading
            ? _buildEmptyState(context)
            : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                itemCount: _posts.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, i) {
                  if (i == _posts.length) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator(color: Colors.deepPurpleAccent)),
                    );
                  }
                  return _BuildPostCard(
                    post: _posts[i],
                    onDeleted: _refresh,
                  );
                },
              ),
      ),
    );
  }

  void _showCreatePostSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A24),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _CreatePostSheet(onPosted: _refresh),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_rounded, size: 72, color: Colors.white.withValues(alpha: 0.15)),
            const SizedBox(height: 24),
            Text('No builds yet',
                style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            Text('Be the first to showcase your ride!',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showCreatePostSheet(context),
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: Text('Share Your Build', style: GoogleFonts.outfit(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurpleAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Build Post Card ───────────────────────────────────────────────────────────

class _BuildPostCard extends StatefulWidget {
  final BuildPost post;
  final VoidCallback onDeleted;
  const _BuildPostCard({required this.post, required this.onDeleted});

  @override
  State<_BuildPostCard> createState() => _BuildPostCardState();
}

class _BuildPostCardState extends State<_BuildPostCard> {
  bool _isLiked = false;
  bool _showParts = false;
  List<Part> _taggedParts = [];
  bool _loadingParts = false;
  final _db = DatabaseService();

  @override
  void initState() {
    super.initState();
    _db.hasLiked(widget.post.id).then((v) { if (mounted) setState(() => _isLiked = v); });
  }

  Future<void> _toggleLike() async {
    setState(() => _isLiked = !_isLiked);
    await _db.toggleLike(widget.post.id, _isLiked);
  }

  Future<void> _loadTaggedParts() async {
    if (_taggedParts.isNotEmpty || widget.post.taggedPartIds.isEmpty) return;
    setState(() => _loadingParts = true);
    final parts = await _db.getPartsByIds(widget.post.taggedPartIds);
    if (mounted) setState(() { _taggedParts = parts; _loadingParts = false; });
  }

  void _toggleParts() {
    setState(() => _showParts = !_showParts);
    if (_showParts) _loadTaggedParts();
  }

  bool get _isOwner => FirebaseAuth.instance.currentUser?.uid == widget.post.userId;

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final dateStr = '${post.createdAt.day}/${post.createdAt.month}/${post.createdAt.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A24),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: CachedNetworkImage(
                imageUrl: post.imageUrl,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                    height: 220,
                    color: const Color(0xFF252538),
                    child: const Center(child: CircularProgressIndicator(color: Colors.deepPurpleAccent))),
                errorWidget: (_, __, ___) => Container(
                    height: 220,
                    color: const Color(0xFF252538),
                    child: const Icon(Icons.two_wheeler, size: 60, color: Colors.white24)),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.deepPurpleAccent.withValues(alpha: 0.2),
                      child: Text(
                        post.username.isNotEmpty ? post.username[0].toUpperCase() : 'R',
                        style: GoogleFonts.outfit(color: Colors.deepPurpleAccent, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(post.username, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                          Text(dateStr, style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
                        ],
                      ),
                    ),
                    if (_isOwner)
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              backgroundColor: const Color(0xFF1A1A24),
                              title: Text('Delete Post?', style: GoogleFonts.outfit(color: Colors.white)),
                              content: Text('This cannot be undone.', style: GoogleFonts.inter(color: Colors.white70)),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white54))),
                                ElevatedButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                    child: Text('Delete', style: GoogleFonts.inter(color: Colors.white))),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await _db.deleteBuildPost(post.id);
                            widget.onDeleted();
                          }
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(post.title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                if (post.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(post.description, style: GoogleFonts.inter(color: Colors.white70, fontSize: 14)),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    GestureDetector(
                      onTap: _toggleLike,
                      child: Row(
                        children: [
                          Icon(
                            _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: _isLiked ? Colors.redAccent : Colors.white38,
                            size: 22,
                          ),
                          const SizedBox(width: 5),
                          Text('${post.likeCount}', style: GoogleFonts.inter(color: Colors.white54, fontSize: 14)),
                        ],
                      ),
                    ),
                    if (post.taggedPartIds.isNotEmpty) ...[
                      const SizedBox(width: 20),
                      GestureDetector(
                        onTap: _toggleParts,
                        child: Row(
                          children: [
                            Icon(Icons.build_rounded,
                                color: _showParts ? Colors.deepPurpleAccent : Colors.white38, size: 20),
                            const SizedBox(width: 5),
                            Text(
                              '${post.taggedPartIds.length} Part${post.taggedPartIds.length == 1 ? '' : 's'}',
                              style: GoogleFonts.inter(
                                  color: _showParts ? Colors.deepPurpleAccent : Colors.white54, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                if (_showParts) ...[
                  const SizedBox(height: 14),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 8),
                  if (_loadingParts)
                    const Center(child: CircularProgressIndicator(color: Colors.deepPurpleAccent))
                  else
                    ..._taggedParts.map((part) => _TaggedPartRow(part: part)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tagged Part Row ───────────────────────────────────────────────────────────

class _TaggedPartRow extends StatelessWidget {
  final Part part;
  const _TaggedPartRow({required this.part});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: part.image,
              width: 48, height: 48, fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(
                  width: 48, height: 48, color: Colors.white10,
                  child: const Icon(Icons.build_rounded, color: Colors.white38, size: 20)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(part.name,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('₱${part.price.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(color: Colors.greenAccent, fontSize: 12)),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              final uri = Uri.parse(part.affiliateUrl);
              if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: const Color(0xFFFF5722),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            child: Text('Buy', style: GoogleFonts.inter(fontSize: 12, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Create Post Sheet ─────────────────────────────────────────────────────────

class _CreatePostSheet extends StatefulWidget {
  final VoidCallback onPosted;
  const _CreatePostSheet({required this.onPosted});

  @override
  State<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<_CreatePostSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _imageUrlController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final imageUrl = _imageUrlController.text.trim();
    if (title.isEmpty || imageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Title and image URL are required.'),
          backgroundColor: Colors.redAccent));
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Must be logged in');
      final post = BuildPost(
        id: '', userId: user.uid,
        username: user.displayName ?? user.email?.split('@').first ?? 'Rider',
        title: title, description: _descController.text.trim(),
        imageUrl: imageUrl, taggedPartIds: const [],
        createdAt: DateTime.now(), likeCount: 0,
      );
      await DatabaseService().createBuildPost(post);
      if (mounted) {
        Navigator.pop(context);
        widget.onPosted();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Build posted! 🏍️', style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 32),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('Share Your Build', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 20),
            _field(_titleController, 'Build title (e.g. My Winner X Track Setup)', maxLines: 1),
            const SizedBox(height: 14),
            _field(_imageUrlController, 'Image URL', maxLines: 1),
            const SizedBox(height: 14),
            _field(_descController, 'Description / mods done (optional)', maxLines: 4),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurpleAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmitting
                  ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Post Build', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: GoogleFonts.inter(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        alignLabelWithHint: maxLines > 1,
      ),
    );
  }
}

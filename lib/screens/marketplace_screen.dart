import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/part.dart';
import '../services/database_service.dart';
import '../widgets/part_card.dart';
import 'package:google_fonts/google_fonts.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final DatabaseService _db = DatabaseService();
  final ScrollController _scrollController = ScrollController();

  final List<Part> _parts = [];
  DocumentSnapshot? _lastDoc;
  bool _isLoading = false;
  bool _hasMore = true;
  final int _limit = 8;

  @override
  void initState() {
    super.initState();
    _loadParts();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _loadParts();
      }
    });
  }

  Future<void> _loadParts() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final snap =
          await _db.getRawPartDocuments(limit: _limit, lastDocument: _lastDoc);

      if (snap.docs.isEmpty) {
        setState(() {
          _hasMore = false;
          _isLoading = false;
        });
        return;
      }

      final newParts = snap.docs
          .map((doc) =>
              Part.fromJson(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      setState(() {
        _lastDoc = snap.docs.last;
        _parts.addAll(newParts);
        if (snap.docs.length < _limit) _hasMore = false;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading parts: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12121A), // Premium dark theme
      appBar: AppBar(
        title: Text(
          'Part Market',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _parts.isEmpty && _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.deepPurpleAccent))
          : GridView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.65,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _parts.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _parts.length) {
                  // Loading indicator at the bottom
                  return const Center(
                    child: CircularProgressIndicator(
                        color: Colors.deepPurpleAccent),
                  );
                }
                final part = _parts[index];
                return PartCard(part: part);
              },
            ),
    );
  }
}

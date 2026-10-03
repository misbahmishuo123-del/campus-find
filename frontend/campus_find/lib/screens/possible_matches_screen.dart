import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/item.dart';
import '../models/match_result.dart';
import '../providers/item_provider.dart';
import '../widgets/item_card.dart';
import '../widgets/common_views.dart';
import 'item_details_screen.dart';

/// Shows ranked possible matches for a given item, with an explicit reminder
/// that a match is only a signal — never proof of ownership.
class PossibleMatchesScreen extends StatefulWidget {
  final Item item;
  const PossibleMatchesScreen({super.key, required this.item});

  @override
  State<PossibleMatchesScreen> createState() => _PossibleMatchesScreenState();
}

class _PossibleMatchesScreenState extends State<PossibleMatchesScreen> {
  List<MatchResult> _matches = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final provider = context.read<ItemProvider>();
    final matches = await provider.fetchMatches(widget.item.id);
    if (!mounted) return;
    setState(() {
      _matches = matches;
      _error = provider.error;
      _loading = false;
    });
  }

  Color _scoreColor(int total) {
    if (total >= 80) return const Color(0xFF1B5E20);
    if (total >= 60) return const Color(0xFF283593);
    return const Color(0xFFEF6C00);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Possible Matches')),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF283593).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              color: Color(0xFF283593)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'These are possible matches for "${widget.item.title}", ranked by similarity. A match never confirms ownership — final verification is done by university security.',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_matches.isEmpty)
                      const EmptyState(
                        icon: Icons.compare_arrows,
                        title: 'No possible matches',
                        subtitle:
                            'No similar items were found yet. Try again later.',
                      )
                    else
                      ..._matches.map((m) => Card(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) => ItemDetailsScreen(
                                          itemId: m.item.id))),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  children: [
                                    ItemCard(item: m.item, matchScore: m.score),
                                    const SizedBox(height: 4),
                                    _ScoreBar(
                                        score: m.score,
                                        color: _scoreColor(m.score.total)),
                                  ],
                                ),
                              ),
                            ),
                          )),
                  ],
                ),
    );
  }
}

class _ScoreBar extends StatelessWidget {
  final MatchScore score;
  final Color color;
  const _ScoreBar({required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: score.total / 100,
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _pill('Category ${score.category}/25'),
            _pill('Location ${score.location}/25'),
            _pill('Date/time ${score.dateTime}/20'),
            _pill('Description ${score.description}/20'),
            _pill('Color/brand ${score.colorBrand}/10'),
          ],
        ),
      ],
    );
  }

  Widget _pill(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(text, style: const TextStyle(fontSize: 11)),
      );
}

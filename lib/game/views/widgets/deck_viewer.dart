// lib/game/views/widgets/deck_viewer.dart

import 'package:flutter/material.dart';

import '../../models/game_state.dart';
import '../../models/playing_card.dart';

class DeckViewer extends StatelessWidget {
  const DeckViewer({super.key, required this.state, required this.onClose});

  final GameState state;
  final VoidCallback onClose;

  static const _suitOrder = [
    Suit.spades,
    Suit.hearts,
    Suit.clubs,
    Suit.diamonds,
  ];

  @override
  Widget build(BuildContext context) {
    final remaining = state.roundDeck.length - state.spentCards.length;

    return Material(
      color: Colors.black.withValues(alpha: 0.82),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Text(
                    'DECK',
                    style: TextStyle(
                      color: Color(0xFFE8A838),
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$remaining / ${state.roundDeck.length} left',
                    style: const TextStyle(
                      color: Color(0xFF9BB0C5),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close, color: Color(0xFFD5E2EF)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Gray cards have already been played or discarded.',
                style: TextStyle(color: Color(0xFF9BB0C5), fontSize: 12),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    for (final suit in _suitOrder)
                      _SuitSection(
                        suit: suit,
                        cards: state.cardsForSuit(suit),
                        remainingCount: state.remainingCountForSuit(suit),
                        spentIds: state.spentCardIds,
                        handIds: state.handCardIds,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: onClose,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE8A838),
                  foregroundColor: const Color(0xFF1B2430),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'CLOSE',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuitSection extends StatelessWidget {
  const _SuitSection({
    required this.suit,
    required this.cards,
    required this.remainingCount,
    required this.spentIds,
    required this.handIds,
  });

  final Suit suit;
  final List<PlayingCard> cards;
  final int remainingCount;
  final Set<String> spentIds;
  final Set<String> handIds;

  @override
  Widget build(BuildContext context) {
    final color = Color(suit.colorValue);

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(suit.symbol, style: TextStyle(color: color, fontSize: 22)),
              const SizedBox(width: 8),
              Text(
                '${suit.name[0].toUpperCase()}${suit.name.substring(1)}',
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF243447),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$remainingCount left',
                  style: const TextStyle(
                    color: Color(0xFFD5E2EF),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final card in cards)
                _DeckCardThumb(
                  card: card,
                  spent: spentIds.contains(card.id),
                  inHand: handIds.contains(card.id),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DeckCardThumb extends StatelessWidget {
  const _DeckCardThumb({
    required this.card,
    required this.spent,
    required this.inHand,
  });

  final PlayingCard card;
  final bool spent;
  final bool inHand;

  @override
  Widget build(BuildContext context) {
    final suitColor = Color(card.suit.colorValue);
    final color = spent ? suitColor.withValues(alpha: 0.28) : suitColor;
    final bg = spent
        ? const Color(0xFF2A3140)
        : (inHand ? const Color(0xFFFFF3D6) : Colors.white);
    final border = spent
        ? const Color(0xFF3A4454)
        : (inHand ? const Color(0xFFE8A838) : const Color(0xFF2C2C3A));

    return Opacity(
      opacity: spent ? 0.55 : 1,
      child: Container(
        width: 42,
        height: 58,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: border, width: inHand ? 2 : 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              card.rank.shortLabel,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
            Text(
              card.suit.symbol,
              style: TextStyle(color: color, fontSize: 14, height: 1.1),
            ),
          ],
        ),
      ),
    );
  }
}

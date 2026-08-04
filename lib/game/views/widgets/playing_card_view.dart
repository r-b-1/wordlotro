// lib/game/views/widgets/playing_card_view.dart

import 'package:flutter/material.dart';

import '../../models/playing_card.dart';

class PlayingCardView extends StatelessWidget {
  const PlayingCardView({
    super.key,
    required this.card,
    required this.onTap,
    this.width = 64,
    this.height = 96,
  });

  final PlayingCard card;
  final VoidCallback onTap;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final selected = card.isSelected;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        width: width,
        height: height,
        transform: Matrix4.translationValues(0, selected ? -12 : 0, 0),
        decoration: BoxDecoration(
          color: card.isFaceDown
              ? const Color(0xFF2A1F5E)
              : (selected ? const Color(0xFFFFF8E7) : Colors.white),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? const Color(0xFFE8A838)
                : (card.isFaceDown
                      ? const Color(0xFF6B5B95)
                      : const Color(0xFF2C2C3A)),
            width: selected ? 2.5 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: selected ? 0.35 : 0.2),
              blurRadius: selected ? 10 : 4,
              offset: Offset(0, selected ? 6 : 2),
            ),
          ],
          gradient: card.isFaceDown
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF3D2A7A), Color(0xFF1B1438)],
                )
              : null,
        ),
        child: card.isFaceDown
            ? Center(
                child: Text(
                  '?',
                  style: TextStyle(
                    color: const Color(0xFFB8A4E8),
                    fontSize: width * 0.42,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              )
            : _FaceUpContent(card: card, width: width),
      ),
    );
  }
}

class _FaceUpContent extends StatelessWidget {
  const _FaceUpContent({required this.card, required this.width});

  final PlayingCard card;
  final double width;

  @override
  Widget build(BuildContext context) {
    final color = Color(card.suit.colorValue);

    return Padding(
      padding: const EdgeInsets.all(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            card.rank.shortLabel,
            style: TextStyle(
              color: color,
              fontSize: width * 0.28,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          Text(
            card.suit.symbol,
            style: TextStyle(color: color, fontSize: width * 0.22, height: 1.1),
          ),
          const Spacer(),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              card.suit.symbol,
              style: TextStyle(color: color, fontSize: width * 0.36, height: 1),
            ),
          ),
        ],
      ),
    );
  }
}

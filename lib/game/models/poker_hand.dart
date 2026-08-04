// lib/game/models/poker_hand.dart

import 'playing_card.dart';

enum PokerHandType {
  highCard,
  pair,
  twoPair,
  threeOfAKind,
  straight,
  flush,
  fullHouse,
  fourOfAKind,
  straightFlush,
}

class PokerHandResult {
  const PokerHandResult({
    required this.type,
    required this.baseChips,
    required this.baseMultiplier,
    required this.scoringCards,
  });

  final PokerHandType type;
  final int baseChips;
  final int baseMultiplier;
  final List<PlayingCard> scoringCards;

  String get displayName {
    switch (type) {
      case PokerHandType.highCard:
        return 'High Card';
      case PokerHandType.pair:
        return 'Pair';
      case PokerHandType.twoPair:
        return 'Two Pair';
      case PokerHandType.threeOfAKind:
        return 'Three of a Kind';
      case PokerHandType.straight:
        return 'Straight';
      case PokerHandType.flush:
        return 'Flush';
      case PokerHandType.fullHouse:
        return 'Full House';
      case PokerHandType.fourOfAKind:
        return 'Four of a Kind';
      case PokerHandType.straightFlush:
        return 'Straight Flush';
    }
  }
}

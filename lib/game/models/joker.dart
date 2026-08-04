// lib/game/models/joker.dart

import 'playing_card.dart';
import 'poker_hand.dart';

enum JokerEffectType {
  /// Add a flat amount to Mult.
  flatMult,

  /// Add a flat amount to Chips.
  flatChips,

  /// Add [value] Mult for each scored card of [suit].
  multPerScoredSuit,

  /// Add [value] Mult if the poker hand contains a pair-family.
  multIfContainsPair,
}

class Joker {
  const Joker({
    required this.id,
    required this.name,
    required this.description,
    required this.cost,
    required this.effectType,
    required this.value,
    this.suit,
  });

  final String id;
  final String name;
  final String description;
  final int cost;
  final JokerEffectType effectType;
  final int value;
  final Suit? suit;

  static const Joker joker = Joker(
    id: 'joker',
    name: 'Joker',
    description: '+4 Mult',
    cost: 4,
    effectType: JokerEffectType.flatMult,
    value: 4,
  );

  static const Joker greedyJoker = Joker(
    id: 'greedy_joker',
    name: 'Greedy Joker',
    description: '+3 Mult per scored Diamond',
    cost: 5,
    effectType: JokerEffectType.multPerScoredSuit,
    value: 3,
    suit: Suit.diamonds,
  );

  static const Joker jollyJoker = Joker(
    id: 'jolly_joker',
    name: 'Jolly Joker',
    description: '+8 Mult if hand contains a Pair',
    cost: 4,
    effectType: JokerEffectType.multIfContainsPair,
    value: 8,
  );

  static const Joker chippy = Joker(
    id: 'chippy',
    name: 'Chippy',
    description: '+30 Chips',
    cost: 4,
    effectType: JokerEffectType.flatChips,
    value: 30,
  );

  static const List<Joker> starterPool = [
    joker,
    greedyJoker,
    jollyJoker,
    chippy,
  ];

  static bool handContainsPair(PokerHandType type) {
    switch (type) {
      case PokerHandType.pair:
      case PokerHandType.twoPair:
      case PokerHandType.threeOfAKind:
      case PokerHandType.fullHouse:
      case PokerHandType.fourOfAKind:
        return true;
      case PokerHandType.highCard:
      case PokerHandType.straight:
      case PokerHandType.flush:
      case PokerHandType.straightFlush:
        return false;
    }
  }
}

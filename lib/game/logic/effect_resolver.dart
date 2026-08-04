// lib/game/logic/effect_resolver.dart

import '../models/joker.dart';
import '../models/playing_card.dart';
import '../models/poker_hand.dart';
import 'score_calculator.dart';

class EffectResolver {
  const EffectResolver();

  ScoreResult resolve({
    required ScoreResult base,
    required PokerHandResult hand,
    required List<PlayingCard> scoringCards,
    required List<Joker> jokers,
  }) {
    var chips = base.chips;
    var mult = base.multiplier;

    for (final joker in jokers) {
      switch (joker.effectType) {
        case JokerEffectType.flatMult:
          mult += joker.value;
        case JokerEffectType.flatChips:
          chips += joker.value;
        case JokerEffectType.multPerScoredSuit:
          final suit = joker.suit;
          if (suit != null) {
            final count = scoringCards
                .where((card) => card.suit == suit)
                .length;
            mult += count * joker.value;
          }
        case JokerEffectType.multIfContainsPair:
          if (Joker.handContainsPair(hand.type)) {
            mult += joker.value;
          }
        case JokerEffectType.chipsIfContainsPair:
          if (Joker.handContainsPair(hand.type)) {
            chips += joker.value;
          }
      }
    }

    return ScoreResult(
      chips: chips,
      multiplier: mult,
      scoringCards: scoringCards,
    );
  }
}

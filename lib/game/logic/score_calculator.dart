// lib/game/logic/score_calculator.dart

import '../models/boss_blind.dart';
import '../models/playing_card.dart';
import '../models/poker_hand.dart';

class ScoreResult {
  const ScoreResult({
    required this.chips,
    required this.multiplier,
    required this.scoringCards,
  });

  final int chips;
  final int multiplier;
  final List<PlayingCard> scoringCards;

  int get total => chips * multiplier;
}

class ScoreCalculator {
  const ScoreCalculator();

  ScoreResult calculate({
    required List<PlayingCard> playedCards,
    required PokerHandResult hand,
    BossBlindEffect? bossEffect,
  }) {
    final scoringCards = hand.scoringCards;
    final zeroDiamonds = bossEffect?.type == BossBlindEffectType.diamondTax;

    final cardChips = scoringCards.fold<int>(0, (sum, card) {
      if (zeroDiamonds && card.suit == Suit.diamonds) {
        return sum;
      }
      return sum + card.rank.chipValue;
    });

    return ScoreResult(
      chips: hand.baseChips + cardChips,
      multiplier: hand.baseMultiplier,
      scoringCards: scoringCards,
    );
  }
}

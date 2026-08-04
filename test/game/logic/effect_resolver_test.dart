// test/game/logic/effect_resolver_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:wordlotro/game/logic/effect_resolver.dart';
import 'package:wordlotro/game/logic/score_calculator.dart';
import 'package:wordlotro/game/models/joker.dart';
import 'package:wordlotro/game/models/playing_card.dart';
import 'package:wordlotro/game/models/poker_hand.dart';

PlayingCard c(Suit suit, Rank rank) =>
    PlayingCard(id: '${suit.name}_${rank.name}', suit: suit, rank: rank);

void main() {
  const resolver = EffectResolver();

  final pairHand = PokerHandResult(
    type: PokerHandType.pair,
    baseChips: 10,
    baseMultiplier: 2,
    scoringCards: [c(Suit.diamonds, Rank.nine), c(Suit.hearts, Rank.nine)],
  );

  final base = ScoreResult(
    chips: 28,
    multiplier: 2,
    scoringCards: pairHand.scoringCards,
  );

  test('flat mult joker adds to multiplier', () {
    final result = resolver.resolve(
      base: base,
      hand: pairHand,
      scoringCards: pairHand.scoringCards,
      jokers: const [Joker.joker],
    );

    expect(result.chips, 28);
    expect(result.multiplier, 6);
    expect(result.total, 168);
  });

  test('flat chips joker adds to chips', () {
    final result = resolver.resolve(
      base: base,
      hand: pairHand,
      scoringCards: pairHand.scoringCards,
      jokers: const [Joker.chippy],
    );

    expect(result.chips, 58);
    expect(result.multiplier, 2);
    expect(result.total, 116);
  });

  test('greedy joker adds mult per scored diamond', () {
    final result = resolver.resolve(
      base: base,
      hand: pairHand,
      scoringCards: pairHand.scoringCards,
      jokers: const [Joker.greedyJoker],
    );

    expect(result.multiplier, 5); // 2 + 3 for one diamond
  });

  test('jolly joker adds mult for pair-family hands', () {
    final result = resolver.resolve(
      base: base,
      hand: pairHand,
      scoringCards: pairHand.scoringCards,
      jokers: const [Joker.jollyJoker],
    );

    expect(result.multiplier, 10);
  });

  test('jolly joker does not trigger on high card', () {
    final highCard = PokerHandResult(
      type: PokerHandType.highCard,
      baseChips: 5,
      baseMultiplier: 1,
      scoringCards: [c(Suit.spades, Rank.ace)],
    );
    final highBase = ScoreResult(
      chips: 16,
      multiplier: 1,
      scoringCards: highCard.scoringCards,
    );

    final result = resolver.resolve(
      base: highBase,
      hand: highCard,
      scoringCards: highCard.scoringCards,
      jokers: const [Joker.jollyJoker],
    );

    expect(result.multiplier, 1);
  });
}

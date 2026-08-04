// test/game/logic/score_calculator_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:wordlotro/game/logic/hand_evaluator.dart';
import 'package:wordlotro/game/logic/score_calculator.dart';
import 'package:wordlotro/game/models/playing_card.dart';
import 'package:wordlotro/game/models/poker_hand.dart';

PlayingCard c(Suit suit, Rank rank) =>
    PlayingCard(id: '${suit.name}_${rank.name}', suit: suit, rank: rank);

void main() {
  const evaluator = HandEvaluator();
  const calculator = ScoreCalculator();

  test('pair scores only pair card chips', () {
    final played = [
      c(Suit.hearts, Rank.nine),
      c(Suit.clubs, Rank.nine),
      c(Suit.diamonds, Rank.ace), // should not contribute chips
    ];
    final hand = evaluator.evaluate(played);
    final score = calculator.calculate(playedCards: played, hand: hand);

    // base 10 + 9 + 9 = 28 chips × 2 = 56
    expect(hand.type, PokerHandType.pair);
    expect(score.chips, 28);
    expect(score.multiplier, 2);
    expect(score.total, 56);
  });

  test('high card scores only highest card chips', () {
    final played = [c(Suit.hearts, Rank.two), c(Suit.clubs, Rank.king)];
    final hand = evaluator.evaluate(played);
    final score = calculator.calculate(playedCards: played, hand: hand);

    // base 5 + 10 = 15 × 1 = 15
    expect(score.chips, 15);
    expect(score.multiplier, 1);
    expect(score.total, 15);
  });

  test('flush scores all five card chips', () {
    final played = [
      c(Suit.hearts, Rank.two),
      c(Suit.hearts, Rank.five),
      c(Suit.hearts, Rank.nine),
      c(Suit.hearts, Rank.jack),
      c(Suit.hearts, Rank.king),
    ];
    final hand = evaluator.evaluate(played);
    final score = calculator.calculate(playedCards: played, hand: hand);

    // base 35 + 2+5+9+10+10 = 71 × 4 = 284
    expect(hand.type, PokerHandType.flush);
    expect(score.chips, 71);
    expect(score.multiplier, 4);
    expect(score.total, 284);
  });
}

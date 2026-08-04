// test/game/logic/hand_evaluator_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:wordlotro/game/logic/hand_evaluator.dart';
import 'package:wordlotro/game/models/playing_card.dart';
import 'package:wordlotro/game/models/poker_hand.dart';

PlayingCard c(Suit suit, Rank rank) =>
    PlayingCard(id: '${suit.name}_${rank.name}', suit: suit, rank: rank);

void main() {
  const evaluator = HandEvaluator();

  group('HandEvaluator', () {
    test('throws on empty input', () {
      expect(() => evaluator.evaluate([]), throwsArgumentError);
    });

    test('high card scores only the highest card', () {
      final cards = [
        c(Suit.hearts, Rank.two),
        c(Suit.clubs, Rank.king),
        c(Suit.diamonds, Rank.five),
      ];
      final result = evaluator.evaluate(cards);

      expect(result.type, PokerHandType.highCard);
      expect(result.baseChips, 5);
      expect(result.baseMultiplier, 1);
      expect(result.scoringCards.single.rank, Rank.king);
    });

    test('pair scores only the pair cards', () {
      final cards = [
        c(Suit.hearts, Rank.nine),
        c(Suit.clubs, Rank.nine),
        c(Suit.diamonds, Rank.ace),
      ];
      final result = evaluator.evaluate(cards);

      expect(result.type, PokerHandType.pair);
      expect(result.scoringCards, hasLength(2));
      expect(
        result.scoringCards.every((card) => card.rank == Rank.nine),
        isTrue,
      );
    });

    test('two pair', () {
      final cards = [
        c(Suit.hearts, Rank.three),
        c(Suit.clubs, Rank.three),
        c(Suit.diamonds, Rank.seven),
        c(Suit.spades, Rank.seven),
        c(Suit.hearts, Rank.ace),
      ];
      final result = evaluator.evaluate(cards);

      expect(result.type, PokerHandType.twoPair);
      expect(result.scoringCards, hasLength(4));
      expect(result.scoringCards.map((card) => card.rank).toSet(), {
        Rank.three,
        Rank.seven,
      });
    });

    test('three of a kind', () {
      final cards = [
        c(Suit.hearts, Rank.queen),
        c(Suit.clubs, Rank.queen),
        c(Suit.diamonds, Rank.queen),
        c(Suit.spades, Rank.two),
      ];
      final result = evaluator.evaluate(cards);

      expect(result.type, PokerHandType.threeOfAKind);
      expect(result.scoringCards, hasLength(3));
      expect(
        result.scoringCards.every((card) => card.rank == Rank.queen),
        isTrue,
      );
    });

    test('straight ace-high', () {
      final cards = [
        c(Suit.hearts, Rank.ten),
        c(Suit.clubs, Rank.jack),
        c(Suit.diamonds, Rank.queen),
        c(Suit.spades, Rank.king),
        c(Suit.hearts, Rank.ace),
      ];
      final result = evaluator.evaluate(cards);

      expect(result.type, PokerHandType.straight);
      expect(result.scoringCards, hasLength(5));
    });

    test('straight ace-low wheel', () {
      final cards = [
        c(Suit.hearts, Rank.ace),
        c(Suit.clubs, Rank.two),
        c(Suit.diamonds, Rank.three),
        c(Suit.spades, Rank.four),
        c(Suit.hearts, Rank.five),
      ];
      final result = evaluator.evaluate(cards);

      expect(result.type, PokerHandType.straight);
      expect(result.scoringCards, hasLength(5));
    });

    test('flush', () {
      final cards = [
        c(Suit.hearts, Rank.two),
        c(Suit.hearts, Rank.five),
        c(Suit.hearts, Rank.nine),
        c(Suit.hearts, Rank.jack),
        c(Suit.hearts, Rank.king),
      ];
      final result = evaluator.evaluate(cards);

      expect(result.type, PokerHandType.flush);
      expect(result.scoringCards, hasLength(5));
    });

    test('full house', () {
      final cards = [
        c(Suit.hearts, Rank.six),
        c(Suit.clubs, Rank.six),
        c(Suit.diamonds, Rank.six),
        c(Suit.spades, Rank.king),
        c(Suit.hearts, Rank.king),
      ];
      final result = evaluator.evaluate(cards);

      expect(result.type, PokerHandType.fullHouse);
      expect(result.scoringCards, hasLength(5));
    });

    test('four of a kind', () {
      final cards = [
        c(Suit.hearts, Rank.eight),
        c(Suit.clubs, Rank.eight),
        c(Suit.diamonds, Rank.eight),
        c(Suit.spades, Rank.eight),
        c(Suit.hearts, Rank.ace),
      ];
      final result = evaluator.evaluate(cards);

      expect(result.type, PokerHandType.fourOfAKind);
      expect(result.scoringCards, hasLength(4));
      expect(
        result.scoringCards.every((card) => card.rank == Rank.eight),
        isTrue,
      );
    });

    test('straight flush beats flush and straight', () {
      final cards = [
        c(Suit.spades, Rank.nine),
        c(Suit.spades, Rank.ten),
        c(Suit.spades, Rank.jack),
        c(Suit.spades, Rank.queen),
        c(Suit.spades, Rank.king),
      ];
      final result = evaluator.evaluate(cards);

      expect(result.type, PokerHandType.straightFlush);
      expect(result.baseChips, 100);
      expect(result.baseMultiplier, 8);
    });

    test('full house beats three of a kind and pair', () {
      final cards = [
        c(Suit.hearts, Rank.four),
        c(Suit.clubs, Rank.four),
        c(Suit.diamonds, Rank.four),
        c(Suit.spades, Rank.nine),
        c(Suit.hearts, Rank.nine),
      ];
      expect(evaluator.evaluate(cards).type, PokerHandType.fullHouse);
    });

    test('four of a kind beats full house components', () {
      final cards = [
        c(Suit.hearts, Rank.two),
        c(Suit.clubs, Rank.two),
        c(Suit.diamonds, Rank.two),
        c(Suit.spades, Rank.two),
        c(Suit.hearts, Rank.three),
      ];
      expect(evaluator.evaluate(cards).type, PokerHandType.fourOfAKind);
    });
  });
}

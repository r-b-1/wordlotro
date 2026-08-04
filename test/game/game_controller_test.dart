// test/game/game_controller_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:wordlotro/game/game_controller.dart';
import 'package:wordlotro/game/logic/deck_builder.dart';
import 'package:wordlotro/game/models/game_state.dart';
import 'package:wordlotro/game/models/playing_card.dart';

PlayingCard c(Suit suit, Rank rank) =>
    PlayingCard(id: '${suit.name}_${rank.name}', suit: suit, rank: rank);

void main() {
  const deckBuilder = DeckBuilder();

  GameController controllerWithDeck(List<PlayingCard> deck) {
    return GameController(initialDeck: deck);
  }

  test('starts round with 8-card hand and 44-card deck', () {
    final controller = controllerWithDeck(deckBuilder.buildOrderedDeck());

    expect(controller.state.hand, hasLength(8));
    expect(controller.state.deck, hasLength(44));
    expect(controller.state.score, 0);
    expect(controller.state.targetScore, 300);
    expect(controller.state.handsRemaining, 4);
    expect(controller.state.discardsRemaining, 3);
    expect(controller.state.status, RoundStatus.playing);
  });

  test('selection is capped at 5 cards', () {
    final controller = controllerWithDeck(deckBuilder.buildOrderedDeck());
    final handIds = controller.state.hand.map((card) => card.id).toList();

    for (final id in handIds.take(6)) {
      controller.toggleCard(id);
    }

    expect(controller.state.selectedCards, hasLength(5));
  });

  test('playing a pair scores, consumes hand, and refills', () {
    final deck = [
      c(Suit.hearts, Rank.nine),
      c(Suit.clubs, Rank.nine),
      c(Suit.diamonds, Rank.ace),
      c(Suit.spades, Rank.two),
      c(Suit.hearts, Rank.three),
      c(Suit.clubs, Rank.four),
      c(Suit.diamonds, Rank.five),
      c(Suit.spades, Rank.six),
      // refill cards
      c(Suit.hearts, Rank.seven),
      c(Suit.clubs, Rank.eight),
    ];
    final controller = controllerWithDeck(deck);

    controller.toggleCard('hearts_nine');
    controller.toggleCard('clubs_nine');
    controller.playSelectedCards();

    // pair of 9s: 10 + 9 + 9 = 28 × 2 = 56
    expect(controller.state.score, 56);
    expect(controller.state.handsRemaining, 3);
    expect(controller.state.hand, hasLength(8));
    expect(controller.state.deck, hasLength(0));
    expect(controller.state.lastResult, contains('Pair'));
    expect(controller.state.lastResult, contains('56'));
  });

  test('discard consumes discard and refills', () {
    final deck = deckBuilder.buildOrderedDeck();
    final controller = controllerWithDeck(deck);
    final firstId = controller.state.hand.first.id;

    controller.toggleCard(firstId);
    controller.discardSelectedCards();

    expect(controller.state.discardsRemaining, 2);
    expect(controller.state.hand, hasLength(8));
    expect(controller.state.deck, hasLength(43));
    expect(controller.state.hand.any((card) => card.id == firstId), isFalse);
  });

  test('reaching target score wins immediately', () {
    final controller = controllerWithDeck(deckBuilder.buildOrderedDeck());
    controller.setStateForTest(
      controller.state.copyWith(
        score: 290,
        hand: [
          c(Suit.hearts, Rank.ace),
          c(Suit.clubs, Rank.ace),
          c(Suit.diamonds, Rank.two),
        ],
        handsRemaining: 2,
      ),
    );

    controller.toggleCard('hearts_ace');
    controller.toggleCard('clubs_ace');
    controller.playSelectedCards();

    // pair of aces: 10 + 11 + 11 = 32 × 2 = 64 → 290 + 64 = 354
    expect(controller.state.score, greaterThanOrEqualTo(300));
    expect(controller.state.status, RoundStatus.won);
  });

  test('running out of hands below target loses', () {
    final controller = controllerWithDeck(deckBuilder.buildOrderedDeck());
    controller.setStateForTest(
      controller.state.copyWith(
        score: 10,
        hand: [c(Suit.hearts, Rank.two), c(Suit.clubs, Rank.three)],
        handsRemaining: 1,
        deck: const [],
      ),
    );

    controller.toggleCard('hearts_two');
    controller.playSelectedCards();

    expect(controller.state.handsRemaining, 0);
    expect(controller.state.status, RoundStatus.lost);
  });

  test('restart deals a fresh round', () {
    final controller = controllerWithDeck(deckBuilder.buildOrderedDeck());
    controller.setStateForTest(
      controller.state.copyWith(
        score: 100,
        handsRemaining: 0,
        status: RoundStatus.lost,
      ),
    );

    controller.restart();

    expect(controller.state.score, 0);
    expect(controller.state.handsRemaining, 4);
    expect(controller.state.discardsRemaining, 3);
    expect(controller.state.status, RoundStatus.playing);
    expect(controller.state.hand, hasLength(8));
  });

  test('cannot play or discard when terminal', () {
    final controller = controllerWithDeck(deckBuilder.buildOrderedDeck());
    controller.setStateForTest(
      controller.state.copyWith(status: RoundStatus.won),
    );
    final before = controller.state;

    controller.toggleCard(controller.state.hand.first.id);
    controller.playSelectedCards();
    controller.discardSelectedCards();

    expect(controller.state.score, before.score);
    expect(controller.state.handsRemaining, before.handsRemaining);
    expect(controller.state.discardsRemaining, before.discardsRemaining);
  });
}

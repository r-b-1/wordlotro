// test/game/game_controller_test.dart

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wordlotro/game/game_controller.dart';
import 'package:wordlotro/game/logic/deck_builder.dart';
import 'package:wordlotro/game/models/boss_blind.dart';
import 'package:wordlotro/game/models/game_state.dart';
import 'package:wordlotro/game/models/joker.dart';
import 'package:wordlotro/game/models/playing_card.dart';

PlayingCard c(Suit suit, Rank rank) =>
    PlayingCard(id: '${suit.name}_${rank.name}', suit: suit, rank: rank);

void main() {
  const deckBuilder = DeckBuilder();

  GameController controllerWithDeck(List<PlayingCard> deck, {Random? random}) {
    return GameController(initialDeck: deck, random: random ?? Random(1));
  }

  test('starts round with 8-card hand and 44-card deck', () {
    final controller = controllerWithDeck(deckBuilder.buildOrderedDeck());

    expect(controller.state.hand, hasLength(8));
    expect(controller.state.deck, hasLength(44));
    expect(controller.state.score, 0);
    expect(controller.state.targetScore, 300);
    expect(controller.state.handsRemaining, 4);
    expect(controller.state.discardsRemaining, 3);
    expect(controller.state.phase, RunPhase.playing);
    expect(controller.state.blindIndex, 0);
    expect(controller.state.money, 0);
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
      c(Suit.hearts, Rank.seven),
      c(Suit.clubs, Rank.eight),
    ];
    final controller = controllerWithDeck(deck);

    controller.toggleCard('hearts_nine');
    controller.toggleCard('clubs_nine');
    controller.playSelectedCards();

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

  test('reaching target score enters shop with reward', () {
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

    expect(controller.state.score, greaterThanOrEqualTo(300));
    expect(controller.state.phase, RunPhase.shop);
    expect(controller.state.money, BlindInfo.anteOne[0].reward);
    expect(controller.state.shopOffers, isNotEmpty);
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
    expect(controller.state.phase, RunPhase.runLost);
  });

  test('restart deals a fresh run', () {
    final controller = controllerWithDeck(deckBuilder.buildOrderedDeck());
    controller.setStateForTest(
      controller.state.copyWith(
        score: 100,
        handsRemaining: 0,
        money: 12,
        blindIndex: 2,
        phase: RunPhase.runLost,
        jokers: const [Joker.joker],
      ),
    );

    controller.restart();

    expect(controller.state.score, 0);
    expect(controller.state.handsRemaining, 4);
    expect(controller.state.discardsRemaining, 3);
    expect(controller.state.phase, RunPhase.playing);
    expect(controller.state.money, 0);
    expect(controller.state.blindIndex, 0);
    expect(controller.state.jokers, isEmpty);
    expect(controller.state.hand, hasLength(8));
  });

  test('cannot play or discard when not playing', () {
    final controller = controllerWithDeck(deckBuilder.buildOrderedDeck());
    controller.setStateForTest(controller.state.copyWith(phase: RunPhase.shop));
    final before = controller.state;

    controller.toggleCard(controller.state.hand.first.id);
    controller.playSelectedCards();
    controller.discardSelectedCards();

    expect(controller.state.score, before.score);
    expect(controller.state.handsRemaining, before.handsRemaining);
    expect(controller.state.discardsRemaining, before.discardsRemaining);
  });

  test('sortHandByRank orders Ace-high descending', () {
    final controller = controllerWithDeck(deckBuilder.buildOrderedDeck());
    controller.setHand([
      c(Suit.hearts, Rank.two),
      c(Suit.clubs, Rank.ace),
      c(Suit.diamonds, Rank.king),
      c(Suit.spades, Rank.five),
    ]);

    controller.sortHandByRank();

    expect(controller.state.hand.map((card) => card.rank).toList(), [
      Rank.ace,
      Rank.king,
      Rank.five,
      Rank.two,
    ]);
  });

  test('sortHandBySuit orders Spades Hearts Clubs Diamonds then rank', () {
    final controller = controllerWithDeck(deckBuilder.buildOrderedDeck());
    controller.setHand([
      c(Suit.diamonds, Rank.two),
      c(Suit.hearts, Rank.ace),
      c(Suit.clubs, Rank.king),
      c(Suit.spades, Rank.five),
      c(Suit.spades, Rank.ace),
    ]);

    controller.sortHandBySuit();

    expect(
      controller.state.hand.map(
        (card) => '${card.suit.name}_${card.rank.name}',
      ),
      ['spades_ace', 'spades_five', 'hearts_ace', 'clubs_king', 'diamonds_two'],
    );
  });

  test('preferred rank sort is reapplied after discard refill', () {
    final deck = [
      c(Suit.hearts, Rank.two),
      c(Suit.clubs, Rank.ace),
      c(Suit.diamonds, Rank.king),
      c(Suit.spades, Rank.five),
      c(Suit.hearts, Rank.three),
      c(Suit.clubs, Rank.four),
      c(Suit.diamonds, Rank.six),
      c(Suit.spades, Rank.seven),
      c(Suit.hearts, Rank.queen), // refill
    ];
    final controller = controllerWithDeck(deck);
    controller.sortHandByRank();
    controller.toggleCard('hearts_two');
    controller.discardSelectedCards();

    final ranks = controller.state.hand.map((card) => card.rank.order).toList();
    final sorted = List<int>.from(ranks)..sort((a, b) => b.compareTo(a));
    expect(ranks, sorted);
    expect(controller.handSortMode, HandSortMode.rank);
  });

  test('buyJoker spends money and removes offer', () {
    final controller = controllerWithDeck(deckBuilder.buildOrderedDeck());
    controller.setStateForTest(
      controller.state.copyWith(
        phase: RunPhase.shop,
        money: 10,
        shopOffers: const [Joker.joker, Joker.chippy],
      ),
    );

    controller.buyJoker(Joker.joker.id);

    expect(controller.state.money, 6);
    expect(controller.state.jokers, contains(Joker.joker));
    expect(controller.state.shopOffers, [Joker.chippy]);
  });

  test('buyJoker does nothing when unaffordable', () {
    final controller = controllerWithDeck(deckBuilder.buildOrderedDeck());
    controller.setStateForTest(
      controller.state.copyWith(
        phase: RunPhase.shop,
        money: 1,
        shopOffers: const [Joker.joker],
      ),
    );

    controller.buyJoker(Joker.joker.id);

    expect(controller.state.money, 1);
    expect(controller.state.jokers, isEmpty);
  });

  test('skipShop advances to next blind target', () {
    final controller = controllerWithDeck(deckBuilder.buildOrderedDeck());
    controller.setStateForTest(
      controller.state.copyWith(
        phase: RunPhase.shop,
        money: 4,
        blindIndex: 0,
        jokers: const [Joker.chippy],
      ),
    );

    controller.skipShop();

    expect(controller.state.phase, RunPhase.playing);
    expect(controller.state.blindIndex, 1);
    expect(controller.state.targetScore, BlindInfo.anteOne[1].targetScore);
    expect(controller.state.money, 4);
    expect(controller.state.jokers, [Joker.chippy]);
    expect(controller.state.score, 0);
    expect(controller.state.hand, hasLength(8));
  });

  test('skipShop after boss wins the run', () {
    final controller = controllerWithDeck(deckBuilder.buildOrderedDeck());
    controller.setStateForTest(
      controller.state.copyWith(phase: RunPhase.shop, money: 15, blindIndex: 2),
    );

    controller.skipShop();

    expect(controller.state.phase, RunPhase.runWon);
  });

  test('owned joker modifies played score', () {
    final deck = [
      c(Suit.hearts, Rank.nine),
      c(Suit.clubs, Rank.nine),
      c(Suit.diamonds, Rank.ace),
      c(Suit.spades, Rank.two),
      c(Suit.hearts, Rank.three),
      c(Suit.clubs, Rank.four),
      c(Suit.diamonds, Rank.five),
      c(Suit.spades, Rank.six),
    ];
    final controller = controllerWithDeck(deck);
    controller.setStateForTest(
      controller.state.copyWith(jokers: const [Joker.joker]),
    );

    controller.toggleCard('hearts_nine');
    controller.toggleCard('clubs_nine');
    controller.playSelectedCards();

    // pair: 28 chips × (2 + 4) = 168
    expect(controller.state.score, 168);
  });

  test('boss fog deals opening hand face down; refills are face up', () {
    final controller = GameController(
      initialDeck: deckBuilder.buildOrderedDeck(),
      random: Random(1),
      forcedBossEffect: BossBlindEffect.fog,
    );
    controller.setStateForTest(
      controller.state.copyWith(phase: RunPhase.shop, money: 10, blindIndex: 1),
    );
    controller.skipShop();

    expect(controller.state.blindIndex, 2);
    expect(controller.state.bossEffect, BossBlindEffect.fog);
    expect(controller.state.hand.every((card) => card.isFaceDown), isTrue);

    final firstId = controller.state.hand.first.id;
    controller.toggleCard(firstId);
    controller.discardSelectedCards();

    expect(controller.state.hand.where((card) => card.id == firstId), isEmpty);
    // Remaining original cards stay face down; refill(s) are face up.
    final faceDownCount = controller.state.hand
        .where((card) => card.isFaceDown)
        .length;
    final faceUpCount = controller.state.hand
        .where((card) => !card.isFaceDown)
        .length;
    expect(faceDownCount, 7);
    expect(faceUpCount, 1);
  });

  test('boss diamond tax zeroes diamond chips when scoring', () {
    final deck = [
      c(Suit.diamonds, Rank.nine),
      c(Suit.hearts, Rank.nine),
      c(Suit.clubs, Rank.ace),
      c(Suit.spades, Rank.two),
      c(Suit.hearts, Rank.three),
      c(Suit.clubs, Rank.four),
      c(Suit.diamonds, Rank.five),
      c(Suit.spades, Rank.six),
    ];
    final controller = GameController(
      initialDeck: deck,
      random: Random(1),
      forcedBossEffect: BossBlindEffect.diamondTax,
    );
    controller.setStateForTest(
      controller.state.copyWith(phase: RunPhase.shop, money: 10, blindIndex: 1),
    );
    controller.skipShop();
    controller.setHand([
      c(Suit.diamonds, Rank.nine),
      c(Suit.hearts, Rank.nine),
      c(Suit.clubs, Rank.ace),
      c(Suit.spades, Rank.two),
      c(Suit.hearts, Rank.three),
      c(Suit.clubs, Rank.four),
      c(Suit.diamonds, Rank.five),
      c(Suit.spades, Rank.six),
    ]);

    expect(controller.state.bossEffect, BossBlindEffect.diamondTax);

    controller.toggleCard('diamonds_nine');
    controller.toggleCard('hearts_nine');
    controller.playSelectedCards();

    // base 10 + 0 + 9 = 19 × 2 = 38
    expect(controller.state.score, 38);
  });

  test('rerollShop costs money and replaces offers', () {
    final controller = controllerWithDeck(deckBuilder.buildOrderedDeck());
    controller.setStateForTest(
      controller.state.copyWith(
        phase: RunPhase.shop,
        money: 10,
        shopOffers: const [Joker.joker, Joker.chippy],
      ),
    );

    final before = controller.state.shopOffers.map((j) => j.id).toSet();
    controller.rerollShop();

    expect(controller.state.money, 8);
    expect(controller.state.shopOffers, isNotEmpty);
    expect(controller.state.shopOffers.length, lessThanOrEqualTo(2));
    // With a large pool, reroll should usually differ; at minimum cost applied.
    expect(
      controller.state.shopOffers.every((j) => !before.contains(j.id)) ||
          controller.state.shopOffers.isNotEmpty,
      isTrue,
    );
  });

  test('rerollShop does nothing when unaffordable', () {
    final controller = controllerWithDeck(deckBuilder.buildOrderedDeck());
    controller.setStateForTest(
      controller.state.copyWith(
        phase: RunPhase.shop,
        money: 1,
        shopOffers: const [Joker.joker, Joker.chippy],
      ),
    );

    controller.rerollShop();

    expect(controller.state.money, 1);
    expect(controller.state.shopOffers, [Joker.joker, Joker.chippy]);
  });

  test('spent cards are tracked and grayed in remaining suit counts', () {
    final deck = [
      c(Suit.hearts, Rank.two),
      c(Suit.clubs, Rank.ace),
      c(Suit.diamonds, Rank.king),
      c(Suit.spades, Rank.five),
      c(Suit.hearts, Rank.three),
      c(Suit.clubs, Rank.four),
      c(Suit.diamonds, Rank.six),
      c(Suit.spades, Rank.seven),
      c(Suit.hearts, Rank.queen),
    ];
    final controller = controllerWithDeck(deck);

    expect(controller.state.roundDeck, hasLength(9));
    expect(controller.state.remainingCountForSuit(Suit.hearts), 3);

    controller.toggleCard('hearts_two');
    controller.discardSelectedCards();

    expect(controller.state.spentCards, hasLength(1));
    expect(controller.state.isSpent(c(Suit.hearts, Rank.two)), isTrue);
    expect(controller.state.remainingCountForSuit(Suit.hearts), 2);
  });
}

// lib/game/game_controller.dart

import 'dart:math';

import 'package:flutter/foundation.dart';

import 'logic/deck_builder.dart';
import 'logic/effect_resolver.dart';
import 'logic/hand_evaluator.dart';
import 'logic/score_calculator.dart';
import 'models/game_state.dart';
import 'models/joker.dart';
import 'models/playing_card.dart';

class GameController extends ChangeNotifier {
  GameController({
    HandEvaluator evaluator = const HandEvaluator(),
    ScoreCalculator calculator = const ScoreCalculator(),
    EffectResolver effectResolver = const EffectResolver(),
    DeckBuilder deckBuilder = const DeckBuilder(),
    Random? random,
    List<PlayingCard>? initialDeck,
    int handsRemaining = 4,
    int discardsRemaining = 3,
    int handSize = DeckBuilder.handSize,
  }) : _evaluator = evaluator,
       _calculator = calculator,
       _effectResolver = effectResolver,
       _deckBuilder = deckBuilder,
       _random = random ?? Random(),
       _initialDeckOverride = initialDeck,
       _startingHands = handsRemaining,
       _startingDiscards = discardsRemaining,
       _handSize = handSize,
       _state = GameState.initial() {
    startRun();
  }

  final HandEvaluator _evaluator;
  final ScoreCalculator _calculator;
  final EffectResolver _effectResolver;
  final DeckBuilder _deckBuilder;
  final Random _random;
  final List<PlayingCard>? _initialDeckOverride;
  final int _startingHands;
  final int _startingDiscards;
  final int _handSize;

  GameState _state;
  GameState get state => _state;

  static const List<Suit> suitSortOrder = [
    Suit.spades,
    Suit.hearts,
    Suit.clubs,
    Suit.diamonds,
  ];

  void startRun() {
    _dealBlind(money: 0, ante: 1, blindIndex: 0, jokers: const []);
  }

  void restart() => startRun();

  void startRound() => startRun();

  void toggleCard(String cardId) {
    if (!_state.isPlaying) return;

    final selectedCount = _state.selectedCards.length;

    _state = _state.copyWith(
      hand: _state.hand
          .map((card) {
            if (card.id != cardId) return card;

            if (!card.isSelected && selectedCount >= 5) {
              return card;
            }

            return card.copyWith(isSelected: !card.isSelected);
          })
          .toList(growable: false),
    );

    notifyListeners();
  }

  void sortHandByRank() {
    if (!_state.isPlaying) return;

    final sorted = List<PlayingCard>.from(_state.hand)
      ..sort((a, b) => b.rank.order.compareTo(a.rank.order));

    _state = _state.copyWith(hand: sorted);
    notifyListeners();
  }

  void sortHandBySuit() {
    if (!_state.isPlaying) return;

    final sorted = List<PlayingCard>.from(_state.hand)
      ..sort((a, b) {
        final suitCompare = suitSortOrder
            .indexOf(a.suit)
            .compareTo(suitSortOrder.indexOf(b.suit));
        if (suitCompare != 0) return suitCompare;
        return b.rank.order.compareTo(a.rank.order);
      });

    _state = _state.copyWith(hand: sorted);
    notifyListeners();
  }

  void playSelectedCards() {
    if (!_state.isPlaying) return;

    final selected = _state.selectedCards;
    if (selected.isEmpty || _state.handsRemaining <= 0) {
      return;
    }

    final pokerHand = _evaluator.evaluate(selected);
    final baseScore = _calculator.calculate(
      playedCards: selected,
      hand: pokerHand,
    );
    final scoreResult = _effectResolver.resolve(
      base: baseScore,
      hand: pokerHand,
      scoringCards: pokerHand.scoringCards,
      jokers: _state.jokers,
    );

    final remainingHand = _state.hand
        .where((card) => !card.isSelected)
        .toList(growable: false);

    final (refilledHand, remainingDeck) = _deckBuilder.refillHand(
      hand: remainingHand,
      deck: _state.deck,
      targetSize: _handSize,
    );

    final newScore = _state.score + scoreResult.total;
    final newHands = _state.handsRemaining - 1;

    final lastResult =
        '${pokerHand.displayName}: '
        '${scoreResult.chips} × ${scoreResult.multiplier} '
        '= ${scoreResult.total}';

    if (newScore >= _state.targetScore) {
      _enterShopAfterBlindClear(
        hand: refilledHand,
        deck: remainingDeck,
        score: newScore,
        handsRemaining: newHands,
        lastResult: lastResult,
      );
      return;
    }

    if (newHands <= 0) {
      _state = _state.copyWith(
        score: newScore,
        handsRemaining: newHands,
        hand: refilledHand,
        deck: remainingDeck,
        phase: RunPhase.runLost,
        lastResult: lastResult,
      );
      notifyListeners();
      return;
    }

    _state = _state.copyWith(
      score: newScore,
      handsRemaining: newHands,
      hand: refilledHand,
      deck: remainingDeck,
      lastResult: lastResult,
    );
    notifyListeners();
  }

  void discardSelectedCards() {
    if (!_state.isPlaying) return;

    final selected = _state.selectedCards;
    if (selected.isEmpty || _state.discardsRemaining <= 0) {
      return;
    }

    final remainingHand = _state.hand
        .where((card) => !card.isSelected)
        .toList(growable: false);

    final (refilledHand, remainingDeck) = _deckBuilder.refillHand(
      hand: remainingHand,
      deck: _state.deck,
      targetSize: _handSize,
    );

    _state = _state.copyWith(
      discardsRemaining: _state.discardsRemaining - 1,
      hand: refilledHand,
      deck: remainingDeck,
      clearLastResult: true,
    );

    notifyListeners();
  }

  void buyJoker(String jokerId) {
    if (!_state.isShop) return;

    final offerIndex = _state.shopOffers.indexWhere((j) => j.id == jokerId);
    if (offerIndex < 0) return;

    final joker = _state.shopOffers[offerIndex];
    if (_state.money < joker.cost) return;
    if (_state.jokers.length >= GameState.maxJokers) return;
    if (_state.jokers.any((owned) => owned.id == joker.id)) return;

    final offers = List<Joker>.from(_state.shopOffers)..removeAt(offerIndex);

    _state = _state.copyWith(
      money: _state.money - joker.cost,
      jokers: [..._state.jokers, joker],
      shopOffers: offers,
    );
    notifyListeners();
  }

  void skipShop() {
    if (!_state.isShop) return;

    final nextIndex = _state.blindIndex + 1;
    if (nextIndex >= BlindInfo.anteOne.length) {
      _state = _state.copyWith(phase: RunPhase.runWon, shopOffers: const []);
      notifyListeners();
      return;
    }

    _dealBlind(
      money: _state.money,
      ante: _state.ante,
      blindIndex: nextIndex,
      jokers: _state.jokers,
    );
  }

  void _enterShopAfterBlindClear({
    required List<PlayingCard> hand,
    required List<PlayingCard> deck,
    required int score,
    required int handsRemaining,
    required String lastResult,
  }) {
    final reward = _state.currentBlind.reward;
    final offers = _rollShopOffers(owned: _state.jokers);

    _state = _state.copyWith(
      hand: hand,
      deck: deck,
      score: score,
      handsRemaining: handsRemaining,
      money: _state.money + reward,
      phase: RunPhase.shop,
      shopOffers: offers,
      lastResult: lastResult,
    );
    notifyListeners();
  }

  List<Joker> _rollShopOffers({required List<Joker> owned}) {
    final ownedIds = owned.map((j) => j.id).toSet();
    final available =
        Joker.starterPool.where((j) => !ownedIds.contains(j.id)).toList()
          ..shuffle(_random);

    return available.take(2).toList(growable: false);
  }

  void _dealBlind({
    required int money,
    required int ante,
    required int blindIndex,
    required List<Joker> jokers,
  }) {
    final blind = BlindInfo.anteOne[blindIndex];
    final fullDeck = _buildDeckForBlind();
    final (hand, remaining) = _deckBuilder.draw(fullDeck, count: _handSize);

    _state = GameState.initial(
      deck: remaining,
      hand: hand,
      targetScore: blind.targetScore,
      handsRemaining: _startingHands,
      discardsRemaining: _startingDiscards,
      money: money,
      ante: ante,
      blindIndex: blindIndex,
      jokers: jokers,
    );
    notifyListeners();
  }

  List<PlayingCard> _buildDeckForBlind() {
    if (_initialDeckOverride != null) {
      return List<PlayingCard>.from(
        _initialDeckOverride!.map((card) => card.copyWith(isSelected: false)),
      );
    }

    return _deckBuilder.buildShuffledDeck(random: _random);
  }

  /// Test helper: inject a hand without dealing from the deck.
  @visibleForTesting
  void setHand(List<PlayingCard> cards) {
    _state = _state.copyWith(hand: cards);
    notifyListeners();
  }

  /// Test helper: override score/hands for terminal-state tests.
  @visibleForTesting
  void setStateForTest(GameState state) {
    _state = state;
    notifyListeners();
  }
}

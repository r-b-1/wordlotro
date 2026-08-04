// lib/game/game_controller.dart

import 'dart:math';

import 'package:flutter/foundation.dart';

import 'logic/deck_builder.dart';
import 'logic/effect_resolver.dart';
import 'logic/hand_evaluator.dart';
import 'logic/score_calculator.dart';
import 'models/boss_blind.dart';
import 'models/game_state.dart';
import 'models/joker.dart';
import 'models/playing_card.dart';

enum HandSortMode { none, rank, suit }

class GameController extends ChangeNotifier {
  GameController({
    HandEvaluator evaluator = const HandEvaluator(),
    ScoreCalculator calculator = const ScoreCalculator(),
    EffectResolver effectResolver = const EffectResolver(),
    DeckBuilder deckBuilder = const DeckBuilder(),
    Random? random,
    List<PlayingCard>? initialDeck,
    BossBlindEffect? forcedBossEffect,
    int handsRemaining = 4,
    int discardsRemaining = 3,
    int handSize = DeckBuilder.handSize,
  }) : _evaluator = evaluator,
       _calculator = calculator,
       _effectResolver = effectResolver,
       _deckBuilder = deckBuilder,
       _random = random ?? Random(),
       _initialDeckOverride = initialDeck,
       _forcedBossEffect = forcedBossEffect,
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
  final BossBlindEffect? _forcedBossEffect;
  final int _startingHands;
  final int _startingDiscards;
  final int _handSize;

  GameState _state;
  GameState get state => _state;

  HandSortMode _handSortMode = HandSortMode.none;
  HandSortMode get handSortMode => _handSortMode;

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
    _handSortMode = HandSortMode.rank;
    _state = _state.copyWith(hand: _sortedHand(_state.hand));
    notifyListeners();
  }

  void sortHandBySuit() {
    if (!_state.isPlaying) return;
    _handSortMode = HandSortMode.suit;
    _state = _state.copyWith(hand: _sortedHand(_state.hand));
    notifyListeners();
  }

  List<PlayingCard> _sortedHand(List<PlayingCard> hand) {
    if (_handSortMode == HandSortMode.none) {
      return List<PlayingCard>.from(hand);
    }

    final sorted = List<PlayingCard>.from(hand);
    switch (_handSortMode) {
      case HandSortMode.none:
        break;
      case HandSortMode.rank:
        sorted.sort((a, b) => b.rank.order.compareTo(a.rank.order));
      case HandSortMode.suit:
        sorted.sort((a, b) {
          final suitCompare = suitSortOrder
              .indexOf(a.suit)
              .compareTo(suitSortOrder.indexOf(b.suit));
          if (suitCompare != 0) return suitCompare;
          return b.rank.order.compareTo(a.rank.order);
        });
    }
    return sorted;
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
      bossEffect: _state.bossEffect,
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

    final spent = [
      ..._state.spentCards,
      ...selected.map(
        (card) => card.copyWith(isSelected: false, isFaceDown: false),
      ),
    ];

    final (refilledHand, remainingDeck) = _deckBuilder.refillHand(
      hand: remainingHand,
      deck: _state.deck,
      targetSize: _handSize,
    );
    final nextHand = _sortedHand(refilledHand);

    final newScore = _state.score + scoreResult.total;
    final newHands = _state.handsRemaining - 1;

    final lastResult =
        '${pokerHand.displayName}: '
        '${scoreResult.chips} × ${scoreResult.multiplier} '
        '= ${scoreResult.total}';

    if (newScore >= _state.targetScore) {
      _enterShopAfterBlindClear(
        hand: nextHand,
        deck: remainingDeck,
        spentCards: spent,
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
        hand: nextHand,
        deck: remainingDeck,
        spentCards: spent,
        phase: RunPhase.runLost,
        lastResult: lastResult,
      );
      notifyListeners();
      return;
    }

    _state = _state.copyWith(
      score: newScore,
      handsRemaining: newHands,
      hand: nextHand,
      deck: remainingDeck,
      spentCards: spent,
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

    final spent = [
      ..._state.spentCards,
      ...selected.map(
        (card) => card.copyWith(isSelected: false, isFaceDown: false),
      ),
    ];

    final (refilledHand, remainingDeck) = _deckBuilder.refillHand(
      hand: remainingHand,
      deck: _state.deck,
      targetSize: _handSize,
    );

    _state = _state.copyWith(
      discardsRemaining: _state.discardsRemaining - 1,
      hand: _sortedHand(refilledHand),
      deck: remainingDeck,
      spentCards: spent,
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

  void rerollShop() {
    if (!canRerollShop) return;

    final offers = _rollShopOffers(
      owned: _state.jokers,
      excludeIds: _state.shopOffers.map((j) => j.id).toSet(),
    );
    if (offers.isEmpty) return;

    _state = _state.copyWith(
      money: _state.money - GameState.shopRerollCost,
      shopOffers: offers,
    );
    notifyListeners();
  }

  bool get canRerollShop {
    if (!_state.isShop) return false;
    if (_state.money < GameState.shopRerollCost) return false;
    final ownedIds = _state.jokers.map((j) => j.id).toSet();
    final remaining = Joker.starterPool
        .where((j) => !ownedIds.contains(j.id))
        .length;
    return remaining > 0;
  }

  void skipShop() {
    if (!_state.isShop) return;

    final nextIndex = _state.blindIndex + 1;
    if (nextIndex >= BlindInfo.anteOne.length) {
      _state = _state.copyWith(
        phase: RunPhase.runWon,
        shopOffers: const [],
        clearBossEffect: true,
      );
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
    required List<PlayingCard> spentCards,
    required int score,
    required int handsRemaining,
    required String lastResult,
  }) {
    final reward = _state.currentBlind.reward;
    final offers = _rollShopOffers(owned: _state.jokers);

    _state = _state.copyWith(
      hand: hand,
      deck: deck,
      spentCards: spentCards,
      score: score,
      handsRemaining: handsRemaining,
      money: _state.money + reward,
      phase: RunPhase.shop,
      shopOffers: offers,
      lastResult: lastResult,
    );
    notifyListeners();
  }

  List<Joker> _rollShopOffers({
    required List<Joker> owned,
    Set<String> excludeIds = const {},
  }) {
    final ownedIds = owned.map((j) => j.id).toSet();
    var available = Joker.starterPool
        .where((j) => !ownedIds.contains(j.id) && !excludeIds.contains(j.id))
        .toList();

    if (available.isEmpty) {
      available = Joker.starterPool
          .where((j) => !ownedIds.contains(j.id))
          .toList();
    }

    available.shuffle(_random);
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
    final roundDeck = fullDeck
        .map((card) => card.copyWith(isSelected: false, isFaceDown: false))
        .toList(growable: false);
    final (drawn, remaining) = _deckBuilder.draw(fullDeck, count: _handSize);

    final isBoss = blindIndex == BlindInfo.anteOne.length - 1;
    final bossEffect = isBoss ? _pickBossEffect() : null;

    final hand = bossEffect?.type == BossBlindEffectType.fog
        ? drawn
              .map((card) => card.copyWith(isFaceDown: true, isSelected: false))
              .toList(growable: false)
        : drawn
              .map(
                (card) => card.copyWith(isFaceDown: false, isSelected: false),
              )
              .toList(growable: false);

    _state = GameState.initial(
      deck: remaining,
      hand: _sortedHand(hand),
      roundDeck: roundDeck,
      spentCards: const [],
      targetScore: blind.targetScore,
      handsRemaining: _startingHands,
      discardsRemaining: _startingDiscards,
      money: money,
      ante: ante,
      blindIndex: blindIndex,
      jokers: jokers,
      bossEffect: bossEffect,
    );
    notifyListeners();
  }

  BossBlindEffect _pickBossEffect() {
    return _forcedBossEffect ??
        BossBlindEffect.pool[_random.nextInt(BossBlindEffect.pool.length)];
  }

  List<PlayingCard> _buildDeckForBlind() {
    if (_initialDeckOverride != null) {
      return List<PlayingCard>.from(
        _initialDeckOverride!.map(
          (card) => card.copyWith(isSelected: false, isFaceDown: false),
        ),
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

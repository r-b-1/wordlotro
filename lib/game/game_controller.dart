// lib/game/game_controller.dart

import 'dart:math';

import 'package:flutter/foundation.dart';

import 'logic/deck_builder.dart';
import 'logic/hand_evaluator.dart';
import 'logic/score_calculator.dart';
import 'models/game_state.dart';
import 'models/playing_card.dart';

class GameController extends ChangeNotifier {
  GameController({
    HandEvaluator evaluator = const HandEvaluator(),
    ScoreCalculator calculator = const ScoreCalculator(),
    DeckBuilder deckBuilder = const DeckBuilder(),
    Random? random,
    List<PlayingCard>? initialDeck,
    int targetScore = 300,
    int handsRemaining = 4,
    int discardsRemaining = 3,
    int handSize = DeckBuilder.handSize,
  }) : _evaluator = evaluator,
       _calculator = calculator,
       _deckBuilder = deckBuilder,
       _random = random,
       _initialDeckOverride = initialDeck,
       _targetScore = targetScore,
       _startingHands = handsRemaining,
       _startingDiscards = discardsRemaining,
       _handSize = handSize,
       _state = GameState.initial(
         targetScore: targetScore,
         handsRemaining: handsRemaining,
         discardsRemaining: discardsRemaining,
       ) {
    startRound();
  }

  final HandEvaluator _evaluator;
  final ScoreCalculator _calculator;
  final DeckBuilder _deckBuilder;
  final Random? _random;
  final List<PlayingCard>? _initialDeckOverride;
  final int _targetScore;
  final int _startingHands;
  final int _startingDiscards;
  final int _handSize;

  GameState _state;
  GameState get state => _state;

  void startRound() {
    final fullDeck = _initialDeckOverride != null
        ? List<PlayingCard>.from(_initialDeckOverride!)
        : _deckBuilder.buildShuffledDeck(random: _random);

    final (hand, remaining) = _deckBuilder.draw(fullDeck, count: _handSize);

    _state = GameState.initial(
      deck: remaining,
      hand: hand,
      targetScore: _targetScore,
      handsRemaining: _startingHands,
      discardsRemaining: _startingDiscards,
    );
    notifyListeners();
  }

  void restart() => startRound();

  void toggleCard(String cardId) {
    if (_state.isTerminal) return;

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

  void playSelectedCards() {
    if (_state.isTerminal) return;

    final selected = _state.selectedCards;
    if (selected.isEmpty || _state.handsRemaining <= 0) {
      return;
    }

    final pokerHand = _evaluator.evaluate(selected);
    final scoreResult = _calculator.calculate(
      playedCards: selected,
      hand: pokerHand,
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

    final status = _resolveStatus(score: newScore, handsRemaining: newHands);

    _state = _state.copyWith(
      score: newScore,
      handsRemaining: newHands,
      hand: refilledHand,
      deck: remainingDeck,
      status: status,
      lastResult:
          '${pokerHand.displayName}: '
          '${scoreResult.chips} × ${scoreResult.multiplier} '
          '= ${scoreResult.total}',
    );

    notifyListeners();
  }

  void discardSelectedCards() {
    if (_state.isTerminal) return;

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

  RoundStatus _resolveStatus({
    required int score,
    required int handsRemaining,
  }) {
    if (score >= _state.targetScore) {
      return RoundStatus.won;
    }
    if (handsRemaining <= 0) {
      return RoundStatus.lost;
    }
    return RoundStatus.playing;
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

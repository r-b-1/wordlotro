// lib/game/models/game_state.dart

import 'playing_card.dart';

enum RoundStatus { playing, won, lost }

class GameState {
  const GameState({
    required this.deck,
    required this.hand,
    required this.score,
    required this.targetScore,
    required this.handsRemaining,
    required this.discardsRemaining,
    required this.status,
    this.lastResult,
  });

  factory GameState.initial({
    List<PlayingCard> deck = const [],
    List<PlayingCard> hand = const [],
    int targetScore = 300,
    int handsRemaining = 4,
    int discardsRemaining = 3,
  }) {
    return GameState(
      deck: deck,
      hand: hand,
      score: 0,
      targetScore: targetScore,
      handsRemaining: handsRemaining,
      discardsRemaining: discardsRemaining,
      status: RoundStatus.playing,
    );
  }

  final List<PlayingCard> deck;
  final List<PlayingCard> hand;
  final int score;
  final int targetScore;
  final int handsRemaining;
  final int discardsRemaining;
  final RoundStatus status;
  final String? lastResult;

  List<PlayingCard> get selectedCards =>
      hand.where((card) => card.isSelected).toList(growable: false);

  bool get isTerminal =>
      status == RoundStatus.won || status == RoundStatus.lost;

  GameState copyWith({
    List<PlayingCard>? deck,
    List<PlayingCard>? hand,
    int? score,
    int? targetScore,
    int? handsRemaining,
    int? discardsRemaining,
    RoundStatus? status,
    String? lastResult,
    bool clearLastResult = false,
  }) {
    return GameState(
      deck: deck ?? this.deck,
      hand: hand ?? this.hand,
      score: score ?? this.score,
      targetScore: targetScore ?? this.targetScore,
      handsRemaining: handsRemaining ?? this.handsRemaining,
      discardsRemaining: discardsRemaining ?? this.discardsRemaining,
      status: status ?? this.status,
      lastResult: clearLastResult ? null : (lastResult ?? this.lastResult),
    );
  }
}

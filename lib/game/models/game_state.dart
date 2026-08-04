// lib/game/models/game_state.dart

import 'boss_blind.dart';
import 'joker.dart';
import 'playing_card.dart';

enum RunPhase { playing, shop, runWon, runLost }

/// Kept for older call sites / readability around blind outcomes.
enum RoundStatus { playing, won, lost }

class BlindInfo {
  const BlindInfo({
    required this.name,
    required this.targetScore,
    required this.reward,
  });

  final String name;
  final int targetScore;
  final int reward;

  static const List<BlindInfo> anteOne = [
    BlindInfo(name: 'Small Blind', targetScore: 300, reward: 4),
    BlindInfo(name: 'Big Blind', targetScore: 450, reward: 5),
    BlindInfo(name: 'Boss Blind', targetScore: 600, reward: 6),
  ];
}

class GameState {
  const GameState({
    required this.deck,
    required this.hand,
    required this.roundDeck,
    required this.spentCards,
    required this.score,
    required this.targetScore,
    required this.handsRemaining,
    required this.discardsRemaining,
    required this.phase,
    required this.money,
    required this.ante,
    required this.blindIndex,
    required this.jokers,
    required this.shopOffers,
    this.bossEffect,
    this.lastResult,
  });

  factory GameState.initial({
    List<PlayingCard> deck = const [],
    List<PlayingCard> hand = const [],
    List<PlayingCard> roundDeck = const [],
    List<PlayingCard> spentCards = const [],
    int targetScore = 300,
    int handsRemaining = 4,
    int discardsRemaining = 3,
    int money = 0,
    int ante = 1,
    int blindIndex = 0,
    List<Joker> jokers = const [],
    BossBlindEffect? bossEffect,
  }) {
    return GameState(
      deck: deck,
      hand: hand,
      roundDeck: roundDeck,
      spentCards: spentCards,
      score: 0,
      targetScore: targetScore,
      handsRemaining: handsRemaining,
      discardsRemaining: discardsRemaining,
      phase: RunPhase.playing,
      money: money,
      ante: ante,
      blindIndex: blindIndex,
      jokers: jokers,
      shopOffers: const [],
      bossEffect: bossEffect,
    );
  }

  final List<PlayingCard> deck;
  final List<PlayingCard> hand;

  /// Full card list for the current blind (draw pile + hand + spent).
  final List<PlayingCard> roundDeck;

  /// Cards played or discarded this blind.
  final List<PlayingCard> spentCards;

  final int score;
  final int targetScore;
  final int handsRemaining;
  final int discardsRemaining;
  final RunPhase phase;
  final int money;
  final int ante;
  final int blindIndex;
  final List<Joker> jokers;
  final List<Joker> shopOffers;
  final BossBlindEffect? bossEffect;
  final String? lastResult;

  static const int maxJokers = 5;
  static const int shopRerollCost = 2;

  BlindInfo get currentBlind =>
      BlindInfo.anteOne[blindIndex.clamp(0, BlindInfo.anteOne.length - 1)];

  String get blindName => currentBlind.name;

  bool get isBossBlind => blindIndex == BlindInfo.anteOne.length - 1;

  List<PlayingCard> get selectedCards =>
      hand.where((card) => card.isSelected).toList(growable: false);

  Set<String> get spentCardIds => spentCards.map((card) => card.id).toSet();

  Set<String> get handCardIds => hand.map((card) => card.id).toSet();

  bool isSpent(PlayingCard card) => spentCardIds.contains(card.id);

  bool isInHand(PlayingCard card) => handCardIds.contains(card.id);

  /// Cards still available this blind (draw pile + hand).
  int remainingCountForSuit(Suit suit) {
    return roundDeck
        .where((card) => card.suit == suit && !isSpent(card))
        .length;
  }

  Map<Suit, int> get remainingSuitCounts => {
    for (final suit in Suit.values) suit: remainingCountForSuit(suit),
  };

  List<PlayingCard> cardsForSuit(Suit suit) {
    final cards = roundDeck.where((card) => card.suit == suit).toList()
      ..sort((a, b) => b.rank.order.compareTo(a.rank.order));
    return cards;
  }

  bool get isPlaying => phase == RunPhase.playing;

  bool get isShop => phase == RunPhase.shop;

  bool get isTerminal => phase == RunPhase.runWon || phase == RunPhase.runLost;

  /// Maps run phase onto the older round status used by some UI/tests.
  RoundStatus get status {
    switch (phase) {
      case RunPhase.playing:
        return RoundStatus.playing;
      case RunPhase.shop:
        return RoundStatus.won;
      case RunPhase.runWon:
        return RoundStatus.won;
      case RunPhase.runLost:
        return RoundStatus.lost;
    }
  }

  GameState copyWith({
    List<PlayingCard>? deck,
    List<PlayingCard>? hand,
    List<PlayingCard>? roundDeck,
    List<PlayingCard>? spentCards,
    int? score,
    int? targetScore,
    int? handsRemaining,
    int? discardsRemaining,
    RunPhase? phase,
    int? money,
    int? ante,
    int? blindIndex,
    List<Joker>? jokers,
    List<Joker>? shopOffers,
    BossBlindEffect? bossEffect,
    bool clearBossEffect = false,
    String? lastResult,
    bool clearLastResult = false,
  }) {
    return GameState(
      deck: deck ?? this.deck,
      hand: hand ?? this.hand,
      roundDeck: roundDeck ?? this.roundDeck,
      spentCards: spentCards ?? this.spentCards,
      score: score ?? this.score,
      targetScore: targetScore ?? this.targetScore,
      handsRemaining: handsRemaining ?? this.handsRemaining,
      discardsRemaining: discardsRemaining ?? this.discardsRemaining,
      phase: phase ?? this.phase,
      money: money ?? this.money,
      ante: ante ?? this.ante,
      blindIndex: blindIndex ?? this.blindIndex,
      jokers: jokers ?? this.jokers,
      shopOffers: shopOffers ?? this.shopOffers,
      bossEffect: clearBossEffect ? null : (bossEffect ?? this.bossEffect),
      lastResult: clearLastResult ? null : (lastResult ?? this.lastResult),
    );
  }
}

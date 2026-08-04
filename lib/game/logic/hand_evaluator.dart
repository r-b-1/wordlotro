// lib/game/logic/hand_evaluator.dart

import '../models/playing_card.dart';
import '../models/poker_hand.dart';

/// Balatro-like base chips and multipliers for each poker hand type.
class HandBaseValues {
  static const Map<PokerHandType, (int chips, int mult)> values = {
    PokerHandType.highCard: (5, 1),
    PokerHandType.pair: (10, 2),
    PokerHandType.twoPair: (20, 2),
    PokerHandType.threeOfAKind: (30, 3),
    PokerHandType.straight: (30, 4),
    PokerHandType.flush: (35, 4),
    PokerHandType.fullHouse: (40, 4),
    PokerHandType.fourOfAKind: (60, 7),
    PokerHandType.straightFlush: (100, 8),
  };
}

class HandEvaluator {
  const HandEvaluator();

  PokerHandResult evaluate(List<PlayingCard> cards) {
    if (cards.isEmpty) {
      throw ArgumentError('At least one card must be played.');
    }
    if (cards.length > 5) {
      throw ArgumentError('At most five cards can be played.');
    }

    final sorted = List<PlayingCard>.from(cards)
      ..sort((a, b) => b.rank.order.compareTo(a.rank.order));

    final rankGroups = _groupByRank(sorted);
    final isFlush = _isFlush(sorted);
    final straightRanks = _straightRanks(sorted);
    final isStraight = straightRanks != null;

    if (isStraight && isFlush && sorted.length == 5) {
      return _result(
        PokerHandType.straightFlush,
        _cardsMatchingRanks(sorted, straightRanks),
      );
    }

    final fourOfAKind = _firstRankWithCount(rankGroups, 4);
    if (fourOfAKind != null) {
      return _result(
        PokerHandType.fourOfAKind,
        _cardsOfRank(sorted, fourOfAKind),
      );
    }

    final threeOfAKind = _firstRankWithCount(rankGroups, 3);
    final pair = _firstRankWithCount(rankGroups, 2);
    if (threeOfAKind != null && pair != null) {
      return _result(PokerHandType.fullHouse, [
        ..._cardsOfRank(sorted, threeOfAKind),
        ..._cardsOfRank(sorted, pair),
      ]);
    }

    if (isFlush && sorted.length == 5) {
      return _result(PokerHandType.flush, sorted);
    }

    if (isStraight && sorted.length == 5) {
      return _result(
        PokerHandType.straight,
        _cardsMatchingRanks(sorted, straightRanks),
      );
    }

    if (threeOfAKind != null) {
      return _result(
        PokerHandType.threeOfAKind,
        _cardsOfRank(sorted, threeOfAKind),
      );
    }

    final pairs =
        rankGroups.entries
            .where((entry) => entry.value.length >= 2)
            .map((entry) => entry.key)
            .toList()
          ..sort((a, b) => b.order.compareTo(a.order));

    if (pairs.length >= 2) {
      return _result(PokerHandType.twoPair, [
        ..._cardsOfRank(sorted, pairs[0]),
        ..._cardsOfRank(sorted, pairs[1]),
      ]);
    }

    if (pairs.length == 1) {
      return _result(PokerHandType.pair, _cardsOfRank(sorted, pairs[0]));
    }

    return _result(PokerHandType.highCard, [sorted.first]);
  }

  PokerHandResult _result(PokerHandType type, List<PlayingCard> scoringCards) {
    final (chips, mult) = HandBaseValues.values[type]!;
    return PokerHandResult(
      type: type,
      baseChips: chips,
      baseMultiplier: mult,
      scoringCards: List<PlayingCard>.unmodifiable(scoringCards),
    );
  }

  Map<Rank, List<PlayingCard>> _groupByRank(List<PlayingCard> cards) {
    final groups = <Rank, List<PlayingCard>>{};
    for (final card in cards) {
      groups.putIfAbsent(card.rank, () => []).add(card);
    }
    return groups;
  }

  bool _isFlush(List<PlayingCard> cards) {
    if (cards.length < 5) return false;
    final suit = cards.first.suit;
    return cards.every((card) => card.suit == suit);
  }

  /// Returns the ordered ranks that form the straight, or null.
  /// Supports ace-high (A-K-Q-J-10) and ace-low (A-2-3-4-5).
  List<Rank>? _straightRanks(List<PlayingCard> cards) {
    if (cards.length != 5) return null;

    final uniqueRanks = cards.map((c) => c.rank).toSet();
    if (uniqueRanks.length != 5) return null;

    final orders = uniqueRanks.map((r) => r.order).toList()..sort();

    // Ace-high or normal consecutive
    var isConsecutive = true;
    for (var i = 1; i < orders.length; i++) {
      if (orders[i] != orders[i - 1] + 1) {
        isConsecutive = false;
        break;
      }
    }
    if (isConsecutive) {
      return uniqueRanks.toList()..sort((a, b) => b.order.compareTo(a.order));
    }

    // Ace-low wheel: A, 2, 3, 4, 5
    const wheel = {Rank.ace, Rank.two, Rank.three, Rank.four, Rank.five};
    if (uniqueRanks.containsAll(wheel)) {
      return const [Rank.five, Rank.four, Rank.three, Rank.two, Rank.ace];
    }

    return null;
  }

  Rank? _firstRankWithCount(Map<Rank, List<PlayingCard>> groups, int count) {
    final matches =
        groups.entries
            .where((entry) => entry.value.length == count)
            .map((entry) => entry.key)
            .toList()
          ..sort((a, b) => b.order.compareTo(a.order));
    return matches.isEmpty ? null : matches.first;
  }

  List<PlayingCard> _cardsOfRank(List<PlayingCard> cards, Rank rank) {
    return cards.where((card) => card.rank == rank).toList(growable: false);
  }

  List<PlayingCard> _cardsMatchingRanks(
    List<PlayingCard> cards,
    List<Rank> ranks,
  ) {
    final rankSet = ranks.toSet();
    return cards
        .where((card) => rankSet.contains(card.rank))
        .toList(growable: false);
  }
}

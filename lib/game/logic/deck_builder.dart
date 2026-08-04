// lib/game/logic/deck_builder.dart

import 'dart:math';

import '../models/playing_card.dart';

class DeckBuilder {
  const DeckBuilder();

  static const int handSize = 8;

  /// Builds a standard 52-card deck. Optionally shuffles with [random].
  List<PlayingCard> buildShuffledDeck({Random? random}) {
    final deck = buildOrderedDeck();
    if (random != null) {
      deck.shuffle(random);
    } else {
      deck.shuffle();
    }
    return deck;
  }

  /// Builds an unshuffled 52-card deck (useful for tests).
  List<PlayingCard> buildOrderedDeck() {
    final cards = <PlayingCard>[];
    for (final suit in Suit.values) {
      for (final rank in Rank.values) {
        cards.add(
          PlayingCard(id: '${suit.name}_${rank.name}', suit: suit, rank: rank),
        );
      }
    }
    return cards;
  }

  /// Draws up to [count] cards from the front of [deck].
  /// Returns (drawn cards, remaining deck).
  (List<PlayingCard>, List<PlayingCard>) draw(
    List<PlayingCard> deck, {
    required int count,
  }) {
    if (count <= 0 || deck.isEmpty) {
      return (const [], List<PlayingCard>.from(deck));
    }

    final drawCount = count > deck.length ? deck.length : count;
    final drawn = deck.sublist(0, drawCount);
    final remaining = deck.sublist(drawCount);
    return (drawn, remaining);
  }

  /// Refills [hand] from [deck] until hand has [handSize] cards or deck is empty.
  (List<PlayingCard>, List<PlayingCard>) refillHand({
    required List<PlayingCard> hand,
    required List<PlayingCard> deck,
    int targetSize = handSize,
  }) {
    final needed = targetSize - hand.length;
    if (needed <= 0 || deck.isEmpty) {
      return (List<PlayingCard>.from(hand), List<PlayingCard>.from(deck));
    }

    final (drawn, remaining) = draw(deck, count: needed);
    return ([...hand, ...drawn], remaining);
  }
}

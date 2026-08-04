// test/game/logic/deck_builder_test.dart

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wordlotro/game/logic/deck_builder.dart';
import 'package:wordlotro/game/models/playing_card.dart';

void main() {
  const builder = DeckBuilder();

  test('ordered deck has 52 unique cards', () {
    final deck = builder.buildOrderedDeck();

    expect(deck, hasLength(52));
    expect(deck.map((card) => card.id).toSet(), hasLength(52));
    expect(deck.where((card) => card.suit == Suit.hearts), hasLength(13));
  });

  test('shuffled deck with seed is deterministic', () {
    final a = builder.buildShuffledDeck(random: Random(42));
    final b = builder.buildShuffledDeck(random: Random(42));

    expect(a.map((card) => card.id), b.map((card) => card.id));
  });

  test('draw takes from front of deck', () {
    final deck = builder.buildOrderedDeck();
    final (drawn, remaining) = builder.draw(deck, count: 8);

    expect(drawn, hasLength(8));
    expect(remaining, hasLength(44));
    expect(drawn.first.id, deck.first.id);
    expect(remaining.first.id, deck[8].id);
  });

  test('refillHand fills up to hand size', () {
    final deck = builder.buildOrderedDeck();
    final hand = deck.take(3).toList();
    final remaining = deck.skip(3).toList();

    final (refilled, after) = builder.refillHand(hand: hand, deck: remaining);

    expect(refilled, hasLength(8));
    expect(after, hasLength(44));
  });
}

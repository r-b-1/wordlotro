import 'playing_card.dart';

class GameState {
    const GameState ({
        required this.deck,
        required this.hand,
        required this.score,
        required this.handsRemaining,
        required this.discardsRemaining,
        required this.lastResult,
    });

    factory GameState.initial() {
        return const GameState(deck: [],
        hand: [],
        score: 0,
        handsRemaining: 4,
        discardsRemaining: 3,
        );
    }

    final List<PlayingCard> deck;
    final List<PlayingCard> hand;
    final int score;
    final int handsRemaining;
    final int discardsRemaining;
    final String? lastResult;

    List<PlayingCard> get selectedCards =>
    hand.where((card) => card.isSelected).toList(growable: false);
}
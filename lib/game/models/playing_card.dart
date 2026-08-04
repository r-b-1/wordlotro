enum Suit { clubs, diamonds, hearts, spades }

enum Rank {
  two(2, 2),
  three(3, 3),
  four(4, 4),
  five(5, 5),
  six(6, 6),
  seven(7, 7),
  eight(8, 8),
  nine(9, 9),
  ten(10, 10),
  jack(11, 10),
  queen(12, 10),
  king(13, 10),
  ace(14, 11);

  const Rank(this.order, this.chipValue);

  final int order;
  final int chipValue;

  String get shortLabel {
    switch (this) {
      case Rank.two:
        return '2';
      case Rank.three:
        return '3';
      case Rank.four:
        return '4';
      case Rank.five:
        return '5';
      case Rank.six:
        return '6';
      case Rank.seven:
        return '7';
      case Rank.eight:
        return '8';
      case Rank.nine:
        return '9';
      case Rank.ten:
        return '10';
      case Rank.jack:
        return 'J';
      case Rank.queen:
        return 'Q';
      case Rank.king:
        return 'K';
      case Rank.ace:
        return 'A';
    }
  }
}

extension SuitVisual on Suit {
  String get symbol {
    switch (this) {
      case Suit.clubs:
        return '♣';
      case Suit.diamonds:
        return '♦';
      case Suit.hearts:
        return '♥';
      case Suit.spades:
        return '♠';
    }
  }

  /// Balatro-style suit colors (high-contrast):
  /// Spades blue, Hearts red, Clubs green, Diamonds orange.
  int get colorValue {
    switch (this) {
      case Suit.spades:
        return 0xFF2F6FED;
      case Suit.hearts:
        return 0xFFE03A3A;
      case Suit.clubs:
        return 0xFF2E9B57;
      case Suit.diamonds:
        return 0xFFE08A2B;
    }
  }
}

class PlayingCard {
  const PlayingCard({
    required this.id,
    required this.suit,
    required this.rank,
    this.isSelected = false,
    this.isFaceDown = false,
  });

  final String id;
  final Suit suit;
  final Rank rank;
  final bool isSelected;
  final bool isFaceDown;

  PlayingCard copyWith({bool? isSelected, bool? isFaceDown}) {
    return PlayingCard(
      id: id,
      suit: suit,
      rank: rank,
      isSelected: isSelected ?? this.isSelected,
      isFaceDown: isFaceDown ?? this.isFaceDown,
    );
  }

  @override
  String toString() => '${rank.shortLabel}${suit.symbol}';
}

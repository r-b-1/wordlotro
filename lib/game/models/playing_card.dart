
enum Suit {
    clubs,
    diamonds,
    hearts,
    spades,
  }

enum Rank {
    two(2),
    three(3),
    four(4),
    five(5),
    six(6),
    seven(7),
    eight(8),
    nine(9),
    ten(10),
    jack(10),
    queen(10),
    king(10),
    ace(11);

    const Rank(this.chipValue);

    final int chipValue;
  }

class PlayingCard {
    const PlayingCard({
        required this.id,
        required this.suit,
        required this.rank,
        this.isSelected = false,
      });

    final String id;
    final Suit suit;
    final Rank rank;
    final bool isSelected;

    PlayingCard copyWith({
        bool? isSelected,
      }) {
        return PlayingCard(
        id: id,
        suit: suit,
        rank: rank,
        isSelected: isSelected ?? this.isSelected,
        );
      }

  }

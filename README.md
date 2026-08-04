# Wordlotro

A Balatro-inspired poker roguelike built in Flutter.

## Current vertical slice

One playable Small Blind round:

- Shuffled 52-card deck
- 8-card hand, select up to 5
- 4 hands and 3 discards
- 300-chip target score
- Poker hands from High Card through Straight Flush
- Win / lose overlay and restart

## Scoring pipeline

1. **HandEvaluator** — What poker hand is this, and which cards score?
2. **ScoreCalculator** — How many chips and mult does it produce?
3. **EffectResolver** — (deferred) How do Jokers, editions, seals and enhancements modify it?

## Run

```bash
flutter run
flutter test
```

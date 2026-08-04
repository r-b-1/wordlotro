# Wordlotro

A Balatro-inspired poker roguelike built in Flutter.

## Current vertical slice

One ante run:

- Small Blind (300) → Big Blind (450) → Boss Blind (600)
- Shuffled 52-card deck, 8-card hand, select up to 5
- 4 hands and 3 discards per blind
- Sort hand by rank or suit
- Shop after each cleared blind with starter jokers
- Bust / ante-clear overlays with restart

## Scoring pipeline

1. **HandEvaluator** — What poker hand is this, and which cards score?
2. **ScoreCalculator** — How many chips and mult does it produce?
3. **EffectResolver** — How do owned Jokers modify chips/mult?

## Run

```bash
flutter run
flutter test
```

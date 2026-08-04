// lib/game/models/boss_blind.dart

enum BossBlindEffectType {
  /// Scored diamond cards contribute 0 rank chips.
  diamondTax,

  /// Opening hand is dealt face-down until cards leave the hand.
  fog,
}

class BossBlindEffect {
  const BossBlindEffect({
    required this.type,
    required this.name,
    required this.description,
  });

  final BossBlindEffectType type;
  final String name;
  final String description;

  static const BossBlindEffect diamondTax = BossBlindEffect(
    type: BossBlindEffectType.diamondTax,
    name: 'The Diamond Tax',
    description: 'Scored Diamonds give 0 chips',
  );

  static const BossBlindEffect fog = BossBlindEffect(
    type: BossBlindEffectType.fog,
    name: 'The Fog',
    description: 'Opening hand is face down',
  );

  static const List<BossBlindEffect> pool = [diamondTax, fog];
}

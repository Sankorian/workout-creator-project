import 'muscle_rules.dart';

class Muscle {
  String name;
  double growthLevel; // 0 to 100
  double recoveryTime; // in days
  double decayStartTime; // in days
  double decayInterval; //in days
  DateTime? lastTrained;
  DateTime? lastDecayed;
  Set<GrowthRule> growthRules;
  Set<DecayRule> decayRules;

  Muscle({
    required this.name,
    this.growthLevel = 0,
    this.recoveryTime = 2,
    this.decayStartTime = 10,
    this.decayInterval = 5,
    Set<GrowthRule>? growthRules,
    Set<DecayRule>? decayRules,
  })  : growthRules = growthRules ?? {},
        decayRules = decayRules ?? {};

  // Getters to calculate end times based on lastTrained
  DateTime? get tRecoveryEnd =>
      lastTrained?.add(Duration(hours: (recoveryTime * 24).toInt()));

  DateTime? get tDecayStart =>
      lastTrained?.add(Duration(hours: (decayStartTime * 24).toInt()));

  /// Called when the muscle is trained. Applies all growth rules.
  void train({
    required DateTime timestamp,
    required double intensity,
    required double volume,
    required int effectiveReps,
    required double involvementFactor, 
  }) {
    double totalGrowth = 0;
    
    // Scale input metrics by involvementFactor
    double adjustedIntensity = intensity * involvementFactor;
    double adjustedVolume = volume * involvementFactor;
    double adjustedEffectiveReps = effectiveReps * involvementFactor;

    for (var rule in growthRules) {
      totalGrowth += rule.calculateGrowth(
        muscle: this,
        intensity: adjustedIntensity,
        volume: adjustedVolume,
        effectiveReps: adjustedEffectiveReps,
      );
    }
    
    // Diminishing returns: growth is harder when closer to 100.
    growthLevel += totalGrowth * (1 - (growthLevel / 100));
    
    lastTrained = timestamp;
  }

  /// Called to check for decay. Applies all decay rules.
  void applyDecay(DateTime currentTime) {
    double totalDecay = 0;
    for (var rule in decayRules) {
      totalDecay += rule.calculateDecay(this, currentTime);
    }

    // Faster decay at the top, slower close to 0.
    growthLevel -= totalDecay * (growthLevel / 100);
    
    lastDecayed = currentTime;
  }

  static List<Muscle> getDefaultMuscles() {
    final defaultGrowthRules = <GrowthRule>{
      const SimpleGrowthRule(),
      const IntensityGrowthRule(),
      const EffectiveRepsGrowthRule(),
      const TimingGrowthRule(),
    };

    final defaultDecayRules = <DecayRule>{
      const PassiveDecayRule(),
      const InactivityDecayRule(),
    };

    return [
      Muscle(name: 'Biceps', growthRules: defaultGrowthRules, decayRules: defaultDecayRules),
      Muscle(name: 'Triceps', growthRules: defaultGrowthRules, decayRules: defaultDecayRules),
      Muscle(name: 'Chest', growthRules: defaultGrowthRules, decayRules: defaultDecayRules),
      Muscle(name: 'Shoulders', growthRules: defaultGrowthRules, decayRules: defaultDecayRules),
      Muscle(name: 'Upper Back', growthRules: defaultGrowthRules, decayRules: defaultDecayRules),
      Muscle(name: 'Lower Back', growthRules: defaultGrowthRules, decayRules: defaultDecayRules),
      Muscle(name: 'Quadriceps', growthRules: defaultGrowthRules, decayRules: defaultDecayRules),
      Muscle(name: 'Glutes', growthRules: defaultGrowthRules, decayRules: defaultDecayRules),
      Muscle(name: 'Hamstrings', growthRules: defaultGrowthRules, decayRules: defaultDecayRules),
      Muscle(name: 'Calves', growthRules: defaultGrowthRules, decayRules: defaultDecayRules),
      Muscle(name: 'Abs', growthRules: defaultGrowthRules, decayRules: defaultDecayRules),
      Muscle(name: 'Forearms', growthRules: defaultGrowthRules, decayRules: defaultDecayRules),
    ];
  }
}

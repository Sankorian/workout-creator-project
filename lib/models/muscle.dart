import 'muscle_rules.dart';

class Muscle {
  final String id; // Unique ID for storage
  String name;
  double growthLevel;
  double recoveryTime;
  double decayStartTime;
  double decayInterval;
  DateTime? lastTrained;
  DateTime? lastDecayed;
  Set<GrowthRule> growthRules;
  Set<DecayRule> decayRules;

  Muscle({
    String? id,
    required this.name,
    this.growthLevel = 0,
    this.recoveryTime = 2,
    this.decayStartTime = 10,
    this.decayInterval = 5,
    this.lastTrained,
    this.lastDecayed,
    Set<GrowthRule>? growthRules,
    Set<DecayRule>? decayRules,
  })  : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        growthRules = growthRules ?? {},
        decayRules = decayRules ?? {};

  // JSON Serialization
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'growthLevel': growthLevel,
    'recoveryTime': recoveryTime,
    'decayStartTime': decayStartTime,
    'decayInterval': decayInterval,
    'lastTrained': lastTrained?.toIso8601String(),
    'lastDecayed': lastDecayed?.toIso8601String(),
    'growthRules': growthRules.map((r) => r.name).toList(),
    'decayRules': decayRules.map((r) => r.name).toList(),
  };

  factory Muscle.fromJson(Map<String, dynamic> json) {
    return Muscle(
      id: json['id'],
      name: json['name'],
      growthLevel: json['growthLevel'].toDouble(),
      recoveryTime: json['recoveryTime'].toDouble(),
      decayStartTime: json['decayStartTime'].toDouble(),
      decayInterval: json['decayInterval'].toDouble(),
      lastTrained: json['lastTrained'] != null ? DateTime.parse(json['lastTrained']) : null,
      lastDecayed: json['lastDecayed'] != null ? DateTime.parse(json['lastDecayed']) : null,
      growthRules: (json['growthRules'] as List).map((n) => GrowthRule.fromName(n)!).toSet(),
      decayRules: (json['decayRules'] as List).map((n) => DecayRule.fromName(n)!).toSet(),
    );
  }

  // Getters to calculate end times
  DateTime? get tRecoveryEnd => lastTrained?.add(Duration(hours: (recoveryTime * 24).toInt()));
  DateTime? get tDecayStart => lastTrained?.add(Duration(hours: (decayStartTime * 24).toInt()));

  void train({
    required DateTime timestamp,
    required double intensity,
    required double volume,
    required int effectiveReps,
    required double involvementFactor, 
  }) {
    double totalGrowth = 0;
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
    growthLevel += totalGrowth * (1 - (growthLevel / 100));
    lastTrained = timestamp;
  }

  void applyDecay(DateTime currentTime) {
    double totalDecay = 0;
    for (var rule in decayRules) {
      totalDecay += rule.calculateDecay(this, currentTime);
    }
    growthLevel -= totalDecay * (growthLevel / 100);
    lastDecayed = currentTime;
  }

  static List<Muscle> getDefaultMuscles() {
    final defaultGrowthRules = <GrowthRule>{
      const IntensityGrowthRule(),
      const EffectiveRepsGrowthRule(),
      const TimingGrowthRule(),
    };
    final defaultDecayRules = <DecayRule>{
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
    ];
  }
}

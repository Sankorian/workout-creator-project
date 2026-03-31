import 'muscle_rules.dart';

/// Represents one trainable muscle with growth/decay state and rule sets. But
/// this code object could also be used for other entities like memory, or
/// languages - "The brain is like a muscle"...
class Muscle {
  /// Stable identifier used for persistence.
  final String id;

  /// Display name (for example "Biceps").
  String name;

  /// Current modeled growth value (should be in the 0..100 range). This is just
  /// a range to make progress (and regress) visible. A suitable start value
  /// would consider 0 being the muscle state without working out for a long
  /// time and 100 for the (never reachable) genetic maximum.
  double growthLevel;

  /// Recovery duration in days after a training event.
  double recoveryTime;

  /// Time in days after training when inactivity decay can begin.
  double decayStartTime;

  /// Last timestamp when this muscle was trained.
  DateTime? lastTrained;

  /// Last timestamp when decay was applied.
  DateTime? lastDecayed;

  /// Growth rules that contribute positive adaptation during training. User can
  /// choose which apply - giving meaning to the growthLevel as well.
  Set<GrowthRule> growthRules;

  /// Decay rules that reduce growth over time.
  Set<DecayRule> decayRules;

  /// Creates a [Muscle] with optional persisted ID and custom rule sets.
  Muscle({
    String? id,
    required this.name,
    this.growthLevel = 0,
    this.recoveryTime = 2,
    this.decayStartTime = 10,
    this.lastTrained,
    this.lastDecayed,
    Set<GrowthRule>? growthRules,
    Set<DecayRule>? decayRules,
  })  : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        growthRules = growthRules ?? {},
        decayRules = decayRules ?? {};

  /// Serializes the muscle model to JSON for local storage.
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'growthLevel': growthLevel,
    'recoveryTime': recoveryTime,
    'decayStartTime': decayStartTime,
    'lastTrained': lastTrained?.toIso8601String(),
    'lastDecayed': lastDecayed?.toIso8601String(),
    'growthRules': growthRules.map((r) => r.name).toList(),
    'decayRules': decayRules.map((r) => r.name).toList(),
  };

  /// Rebuilds a [Muscle] from previously serialized JSON data.
  factory Muscle.fromJson(Map<String, dynamic> json) {
    return Muscle(
      id: json['id'],
      name: json['name'],
      growthLevel: json['growthLevel'].toDouble(),
      recoveryTime: json['recoveryTime'].toDouble(),
      decayStartTime: json['decayStartTime'].toDouble(),
      lastTrained: json['lastTrained'] != null ? DateTime.parse(json['lastTrained']) : null,
      lastDecayed: json['lastDecayed'] != null ? DateTime.parse(json['lastDecayed']) : null,
      growthRules: (json['growthRules'] as List).map((n) => GrowthRule.fromName(n)!).toSet(),
      decayRules: (json['decayRules'] as List).map((n) => DecayRule.fromName(n)!).toSet(),
    );
  }

  /// Time when the recovery phase is considered complete.
  DateTime? get tRecoveryEnd => lastTrained?.add(Duration(hours: (recoveryTime * 24).toInt()));

  /// Time when inactivity decay may start.
  DateTime? get tDecayStart => lastTrained?.add(Duration(hours: (decayStartTime * 24).toInt()));

  /// Applies one training stimulus and updates growth using all growth rules.
  void train({
    required DateTime timestamp,
    required double intensity,
    required double involvementFactor, 
  }) {
    double totalGrowth = 0;
    double adjustedIntensity = intensity * involvementFactor;

    for (var rule in growthRules) {
      totalGrowth += rule.calculateGrowth(
        muscle: this,
        intensity: adjustedIntensity,
      );
    }

    // Diminishing returns as growth approaches 100.
    growthLevel += totalGrowth * (1 - (growthLevel / 100));
    lastTrained = timestamp;
  }

  /// Applies accumulated decay at [currentTime] using all decay rules.
  void applyDecay(DateTime currentTime) {
    double totalDecay = 0;
    for (var rule in decayRules) {
      totalDecay += rule.calculateDecay(this, currentTime);
    }

    // Decay scales with current growth level.
    growthLevel -= totalDecay * (growthLevel / 100);
    lastDecayed = currentTime;
  }
}

import 'muscle.dart';

/// Abstract base class for muscle growth calculation rules.
/// Each rule defines how much growth a muscle gains during training.
abstract class GrowthRule {
  final String name;
  const GrowthRule(this.name);

  /// Calculates growth contribution based on training intensity and muscle state.
  double calculateGrowth({
    required Muscle muscle,
    required double intensity,
  });

  /// Factory method to instantiate a GrowthRule from its name string.
  /// Used for deserialization from JSON/storage.
  static GrowthRule? fromName(String name) {
    return switch (name) {
      'Simple' => const SimpleGrowthRule(),
      'Intensity' => const IntensityGrowthRule(),
      'Timing' => const TimingGrowthRule(),
      _ => null,
    };
  }
}

/// Abstract base class for muscle decay/loss calculation rules.
/// Each rule defines how much growth a muscle loses over time.
abstract class DecayRule {
  final String name;
  const DecayRule(this.name);

  /// Calculates decay amount based on time elapsed and muscle state.
  double calculateDecay(Muscle muscle, DateTime currentTime);

  /// Factory method to instantiate a DecayRule from its name string.
  /// Used for deserialization from JSON/storage.
  static DecayRule? fromName(String name) {
    return switch (name) {
      'Passive Decay' => const PassiveDecayRule(),
      'Inactivity Decay' => const InactivityDecayRule(),
      _ => null,
    };
  }
}
/// Baseline growth rule that always returns a fixed gain.
class SimpleGrowthRule extends GrowthRule {
  const SimpleGrowthRule() : super('Simple');
  @override
  double calculateGrowth({required Muscle muscle, required double intensity}) => 1.0;
}

/// Growth rule that scales linearly with training intensity.
class IntensityGrowthRule extends GrowthRule {
  const IntensityGrowthRule() : super('Intensity');
  @override
  double calculateGrowth({required Muscle muscle, required double intensity}) => intensity;
}

/// Growth rule based on when training occurs in the recovery/decay cycle.
class TimingGrowthRule extends GrowthRule {
  const TimingGrowthRule() : super('Timing');
  @override
  double calculateGrowth({required Muscle muscle, required double intensity}) {
    // No prior training history gets baseline timing growth.
    if (muscle.lastTrained == null) return 1.0;
    
    final now = DateTime.now();
    final recoveryEnd = muscle.tRecoveryEnd!;
    final decayStart = muscle.tDecayStart!;
    
    // No gain while still recovering.
    if (now.isBefore(recoveryEnd)) return 0.0;
    
    // Reduced gain after inactivity window starts.
    if (now.isAfter(decayStart)) return 0.1;
    
    // Interpolate between 1.0 and 0.1 across the optimal window.
    final totalWindow = decayStart.difference(recoveryEnd).inSeconds;
    if (totalWindow <= 0) return 1.0;
    
    final secondsSinceRecovery = now.difference(recoveryEnd).inSeconds;
    double closenessFactor = 1.0 - (secondsSinceRecovery / totalWindow);
    return 0.1 + (closenessFactor * 0.9);
  }
}

/// Decay rule that applies continuously over elapsed time.
class PassiveDecayRule extends DecayRule {
  final double decayRatePerDay;
  const PassiveDecayRule({this.decayRatePerDay = 0.1}) : super('Passive Decay');

  @override
  double calculateDecay(Muscle muscle, DateTime currentTime) {
    // Continue decay from the last decay checkpoint or last training time.
    final lastReferencePoint = muscle.lastDecayed ?? muscle.lastTrained ?? currentTime;
    
    // Convert elapsed time to fractional days.
    final daysPassed = currentTime.difference(lastReferencePoint).inSeconds / (24 * 3600);
    
    return daysPassed * decayRatePerDay;
  }
}

/// Decay rule that starts only after the muscle's inactivity threshold.
class InactivityDecayRule extends DecayRule {
  final double decayRatePerDay;
  const InactivityDecayRule({this.decayRatePerDay = 0.5}) : super('Inactivity Decay');

  @override
  double calculateDecay(Muscle muscle, DateTime currentTime) {
    // No inactivity decay before first training stimulus.
    if (muscle.lastTrained == null) return 0.0;
    
    final decayStart = muscle.tDecayStart!;
    
    // No decay while still before inactivity threshold.
    if (currentTime.isBefore(decayStart)) return 0.0;
    
    // Continue from the last decay checkpoint, but never before decayStart.
    final lastCheck = muscle.lastDecayed ?? decayStart;
    final effectiveStart = lastCheck.isBefore(decayStart) ? decayStart : lastCheck;
    
    // Convert elapsed time to fractional days.
    final daysPassed = currentTime.difference(effectiveStart).inSeconds / (24 * 3600);
    
    return daysPassed * decayRatePerDay;
  }
}

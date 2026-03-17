import 'muscle.dart';

/// Base class for growth logic
abstract class GrowthRule {
  final String name;
  const GrowthRule(this.name);

  /// Calculates the growth increment based on muscle state and workout data
  double calculateGrowth({
    required Muscle muscle,
    required double intensity,      // weight / 1RM (0.0 to 1.0+)
    required double volume,         // reps * weight
    required double effectiveReps,  // reps close to failure (scaled)
  });
}

/// Base class for decay logic
abstract class DecayRule {
  final String name;
  const DecayRule(this.name);

  /// Calculates the growth decrement based on muscle state and time
  double calculateDecay(Muscle muscle, DateTime currentTime);
}

// --- Growth Rule Implementations ---

class SimpleGrowthRule extends GrowthRule {
  const SimpleGrowthRule() : super('Simple');

  @override
  double calculateGrowth({
    required Muscle muscle,
    required double intensity,
    required double volume,
    required double effectiveReps,
  }) {
    return 1.0; 
  }
}

class IntensityGrowthRule extends GrowthRule {
  const IntensityGrowthRule() : super('Intensity');

  @override
  double calculateGrowth({
    required Muscle muscle,
    required double intensity,
    required double volume,
    required double effectiveReps,
  }) {
    return intensity; 
  }
}

class EffectiveRepsGrowthRule extends GrowthRule {
  const EffectiveRepsGrowthRule() : super('Effective Reps');

  @override
  double calculateGrowth({
    required Muscle muscle,
    required double intensity,
    required double volume,
    required double effectiveReps,
  }) {
    if (intensity < 0.5) return 0.0;
    return effectiveReps * 0.2;
  }
}

class TimingGrowthRule extends GrowthRule {
  const TimingGrowthRule() : super('Timing');

  @override
  double calculateGrowth({
    required Muscle muscle,
    required double intensity,
    required double volume,
    required double effectiveReps,
  }) {
    if (muscle.lastTrained == null) return 1.0; // First training is always optimal

    final now = DateTime.now();
    final recoveryEnd = muscle.tRecoveryEnd!;
    final decayStart = muscle.tDecayStart!;

    // If trained before recovery is finished, return a small penalty or base value
    if (now.isBefore(recoveryEnd)) {
      return 0.2; 
    }

    // If trained after decay has already started, return minimum stimulus
    if (now.isAfter(decayStart)) {
      return 0.1;
    }

    // Linear interpolation between RecoveryEnd (1.0) and DecayStart (0.1)
    // Formula: value = max - (time_passed / total_window) * (max - min)
    final totalWindowSeconds = decayStart.difference(recoveryEnd).inSeconds;
    if (totalWindowSeconds <= 0) return 1.0;

    final secondsSinceRecovery = now.difference(recoveryEnd).inSeconds;
    double closenessFactor = 1.0 - (secondsSinceRecovery / totalWindowSeconds);
    
    // Scale closenessFactor to stay between 0.1 and 1.0
    return 0.1 + (closenessFactor * 0.9);
  }
}

// --- Decay Rule Implementations ---

class PassiveDecayRule extends DecayRule {
  final double decayRatePerDay;

  const PassiveDecayRule({this.decayRatePerDay = 0.1}) : super('Passive Decay');

  @override
  double calculateDecay(Muscle muscle, DateTime currentTime) {
    final lastReferencePoint = muscle.lastDecayed ?? muscle.lastTrained ?? currentTime;
    final timePassed = currentTime.difference(lastReferencePoint);
    final daysPassed = timePassed.inSeconds / (24 * 3600);
    
    return daysPassed * decayRatePerDay;
  }
}

class InactivityDecayRule extends DecayRule {
  final double decayRatePerDay;

  const InactivityDecayRule({this.decayRatePerDay = 0.5}) : super('Inactivity Decay');

  @override
  double calculateDecay(Muscle muscle, DateTime currentTime) {
    if (muscle.lastTrained == null) return 0.0;

    final decayStart = muscle.tDecayStart!;
    if (currentTime.isBefore(decayStart)) return 0.0;

    final lastCheck = muscle.lastDecayed ?? decayStart;
    final effectiveStart = lastCheck.isBefore(decayStart) ? decayStart : lastCheck;
    
    final timePassed = currentTime.difference(effectiveStart);
    final daysPassed = timePassed.inSeconds / (24 * 3600);

    return daysPassed * decayRatePerDay;
  }
}

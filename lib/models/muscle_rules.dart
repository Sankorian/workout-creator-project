import 'muscle.dart';

abstract class GrowthRule {
  final String name;
  const GrowthRule(this.name);

  double calculateGrowth({
    required Muscle muscle,
    required double intensity,
  });

  static GrowthRule? fromName(String name) {
    switch (name) {
      case 'Simple': return const SimpleGrowthRule();
      case 'Intensity': return const IntensityGrowthRule();
      case 'Timing': return const TimingGrowthRule();
      default: return null;
    }
  }
}

abstract class DecayRule {
  final String name;
  const DecayRule(this.name);

  double calculateDecay(Muscle muscle, DateTime currentTime);

  static DecayRule? fromName(String name) {
    switch (name) {
      case 'Passive Decay': return const PassiveDecayRule();
      case 'Inactivity Decay': return const InactivityDecayRule();
      default: return null;
    }
  }
}

// --- Growth Rule Implementations ---

class SimpleGrowthRule extends GrowthRule {
  const SimpleGrowthRule() : super('Simple');
  @override
  double calculateGrowth({required Muscle muscle, required double intensity}) => 1.0;
}

class IntensityGrowthRule extends GrowthRule {
  const IntensityGrowthRule() : super('Intensity');
  @override
  double calculateGrowth({required Muscle muscle, required double intensity}) => intensity;
}

class TimingGrowthRule extends GrowthRule {
  const TimingGrowthRule() : super('Timing');
  @override
  double calculateGrowth({required Muscle muscle, required double intensity}) {
    if (muscle.lastTrained == null) return 1.0;
    final now = DateTime.now();
    final recoveryEnd = muscle.tRecoveryEnd!;
    final decayStart = muscle.tDecayStart!;
    if (now.isBefore(recoveryEnd)) return 0.2; 
    if (now.isAfter(decayStart)) return 0.1;
    final totalWindow = decayStart.difference(recoveryEnd).inSeconds;
    if (totalWindow <= 0) return 1.0;
    final secondsSinceRecovery = now.difference(recoveryEnd).inSeconds;
    double closenessFactor = 1.0 - (secondsSinceRecovery / totalWindow);
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
    final daysPassed = currentTime.difference(lastReferencePoint).inSeconds / (24 * 3600);
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
    final daysPassed = currentTime.difference(effectiveStart).inSeconds / (24 * 3600);
    return daysPassed * decayRatePerDay;
  }
}

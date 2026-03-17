import 'dart:math';
import 'muscle.dart';

/// Represents how much a specific muscle is involved in an exercise.
class MuscleInvolvement {
  final Muscle muscle;
  final double weight; // 0.0 to 1.0 (involvement factor)

  const MuscleInvolvement({
    required this.muscle,
    required this.weight,
  });
}

/// Represents a single set within an exercise configuration.
class ExerciseSet {
  int repetitions;
  double weight; // in kg
  /// Reps in Reserve (RIR): How many more reps the user thinks they could have done.
  /// 0 = failure, 1 = 1 rep left, ..., 5 = 5 reps left, 6 = >5 reps left.
  int repsInReserve;

  ExerciseSet({
    required this.repetitions,
    required this.weight,
    this.repsInReserve = 6,
  });
}

class Exercise {
  String name;
  List<MuscleInvolvement> involvedMuscles;
  double oneRepetitionMax; // in kg (All-time best)
  List<ExerciseSet> sets;
  int pauseTimeSeconds;

  Exercise({
    required this.name,
    required this.involvedMuscles,
    required this.oneRepetitionMax,
    required this.sets,
    this.pauseTimeSeconds = 60,
  });

  /// Total volume calculated for this exercise configuration.
  double get totalVolume => sets.fold(0, (sum, set) => sum + (set.repetitions * set.weight));

  /// Calculates the estimated 1RM using the Epley formula.
  double calculateEpley1RM(int reps, double weight) {
    if (reps <= 0) return 0;
    if (reps == 1) return weight;
    return weight * (1 + reps / 30.0);
  }

  /// Processes a completed set: Updates 1RM and notifies all involved muscles.
  void completeSet(int setIndex, DateTime timestamp) {
    if (setIndex < 0 || setIndex >= sets.length) return;
    
    final completedSet = sets[setIndex];
    
    // 1. Update 1RM record
    update1RMFromSet(completedSet.repetitions, completedSet.weight);

    // 2. Calculate metrics for this specific set
    double setIntensity = oneRepetitionMax > 0 ? (completedSet.weight / oneRepetitionMax) : 0;
    double setVolume = completedSet.repetitions * completedSet.weight;
    
    // effectiveReps = 6 - repsInReserve (clamped to 0-6)
    int effectiveReps = max(0, 6 - completedSet.repsInReserve);

    // 3. Pass data to each involved muscle
    for (var involvement in involvedMuscles) {
      involvement.muscle.train(
        timestamp: timestamp,
        intensity: setIntensity,
        volume: setVolume,
        effectiveReps: effectiveReps,
        involvementFactor: involvement.weight,
      );
    }
  }

  void update1RMFromSet(int reps, double weight) {
    double newEstimate = calculateEpley1RM(reps, weight);
    if (newEstimate > oneRepetitionMax) {
      oneRepetitionMax = newEstimate;
    }
  }
}

import 'dart:math';
import 'muscle.dart';

/// Represents how much a specific muscle is involved in an exercise.
class Inv {
  final Muscle muscle;
  final double weight; // 0.0 to 1.0 (involvement factor)

  const Inv({
    required this.muscle,
    required this.weight,
  });

  Map<String, dynamic> toJson() => {
    'muscleId': muscle.id,
    'weight': weight,
  };

  static Inv fromJson(Map<String, dynamic> json, List<Muscle> availableMuscles) {
    return Inv(
      muscle: availableMuscles.firstWhere((m) => m.id == json['muscleId']),
      weight: json['weight'].toDouble(),
    );
  }
}

/// Represents a single set within an exercise configuration.
class ExerciseSet {
  int repetitions;
  double weight; // in kg

  ExerciseSet({
    required this.repetitions,
    required this.weight,
  });

  Map<String, dynamic> toJson() => {
    'repetitions': repetitions,
    'weight': weight,
  };

  factory ExerciseSet.fromJson(Map<String, dynamic> json) {
    return ExerciseSet(
      repetitions: json['repetitions'],
      weight: json['weight'].toDouble(),
    );
  }
}

class Exercise {
  final String id;
  String name;
  String description;
  List<Inv> involvedMuscles;
  double oneRepetitionMax; // in kg (All-time best)
  List<ExerciseSet> sets;
  int pauseDuration; // in seconds
  int exerciseDuration; // in seconds

  Exercise({
    String? id,
    required this.name,
    this.description = '',
    required this.involvedMuscles,
    required this.oneRepetitionMax,
    required this.sets,
    this.pauseDuration = 60,
    this.exerciseDuration = 0,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'involvedMuscles': involvedMuscles.map((i) => i.toJson()).toList(),
    'oneRepetitionMax': oneRepetitionMax,
    'sets': sets.map((s) => s.toJson()).toList(),
    'pauseDuration': pauseDuration,
    'exerciseDuration': exerciseDuration,
  };

  factory Exercise.fromJson(Map<String, dynamic> json, List<Muscle> availableMuscles) {
    final hasNewPauseField = json.containsKey('pauseDuration');
    final pauseDuration =
        ((json['pauseDuration'] ?? json['pauseTimeSeconds'] ?? 60) as num).toInt();
    final rawExerciseDuration = (json['exerciseDuration'] ?? 0) as num;

    // Legacy entries used minutes; new entries store seconds.
    final exerciseDuration = hasNewPauseField
        ? rawExerciseDuration.round()
        : (rawExerciseDuration * 60).round();

    return Exercise(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      involvedMuscles: (json['involvedMuscles'] as List)
          .map((i) => Inv.fromJson(i, availableMuscles))
          .toList(),
      oneRepetitionMax: json['oneRepetitionMax'].toDouble(),
      sets: (json['sets'] as List)
          .map((s) => ExerciseSet.fromJson(s))
          .toList(),
      pauseDuration: pauseDuration,
      exerciseDuration: exerciseDuration,
    );
  }

  /// Total volume calculated for this exercise configuration.
  double get totalVolume => sets.fold(0, (sum, set) => sum + (set.repetitions * set.weight));

  /// Calculates the estimated 1RM using the Epley formula.
  double calculateEpley1RM(int reps, double weight) {
    if (reps <= 0) return 0;
    if (reps == 1) return weight;
    return weight * (1 + reps / 30.0);
  }

  /// Processes a completed set: Updates 1RM and notifies all involved muscles.
  /// [repsInReserve] is provided by the user during execution:
  /// 0 = failure, 1 = 1 rep left, ..., 5 = 5 reps left, 6 = >5 reps left.
  void completeSet(int setIndex, DateTime timestamp, int repsInReserve) {
    if (setIndex < 0 || setIndex >= sets.length) return;
    
    final completedSet = sets[setIndex];
    
    // 1. Update 1RM record
    update1RMFromSet(completedSet.repetitions, completedSet.weight);

    // 2. Calculate metrics for this specific set
    double setIntensity = oneRepetitionMax > 0 ? (completedSet.weight / oneRepetitionMax) : 0;
    double setVolume = completedSet.repetitions * completedSet.weight;
    
    // effectiveReps = 6 - repsInReserve (clamped to 0-6)
    int effectiveReps = max(0, 6 - repsInReserve);

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

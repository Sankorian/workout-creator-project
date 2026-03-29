import 'muscle.dart';

/// Connects a muscle to an exercise with an involvement factor.
class Inv {
  /// Referenced muscle.
  final Muscle muscle;

  /// Relative contribution in the 0..1 range.
  final double weight;

  const Inv({
    required this.muscle,
    required this.weight,
  });

  /// Serializes this involvement reference.
  Map<String, dynamic> toJson() => {
    'muscleId': muscle.id,
    'weight': weight,
  };

  /// Rebuilds an involvement reference from JSON.
  static Inv fromJson(Map<String, dynamic> json, List<Muscle> availableMuscles) {
    return Inv(
      muscle: availableMuscles.firstWhere((m) => m.id == json['muscleId']),
      weight: json['weight'].toDouble(),
    );
  }
}

/// Defines one configured training set.
class ExerciseSet {
  /// Planned repetitions for the set.
  int repetitions;

  /// Planned load in kilograms.
  double weight;

  ExerciseSet({
    required this.repetitions,
    required this.weight,
  });

  /// Serializes this set.
  Map<String, dynamic> toJson() => {
    'repetitions': repetitions,
    'weight': weight,
  };

  /// Rebuilds a set from JSON.
  factory ExerciseSet.fromJson(Map<String, dynamic> json) {
    return ExerciseSet(
      repetitions: json['repetitions'],
      weight: json['weight'].toDouble(),
    );
  }
}

/// Represents a trainable exercise definition and its execution settings.
class Exercise {
  /// Stable identifier used for persistence.
  final String id;

  /// Display name.
  String name;

  /// Optional user-facing notes.
  String description;

  /// Muscles involved in this exercise.
  List<Inv> involvedMuscles;

  /// Best known one-repetition maximum in kilograms.
  double oneRepetitionMax;

  /// Ordered set plan for this exercise.
  List<ExerciseSet> sets;

  /// Planned pause between sets in seconds.
  int pauseDuration;

  /// Planned duration in seconds for time-based execution.
  int exerciseDuration;

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

  /// Serializes this exercise.
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

  /// Rebuilds an exercise from JSON, including legacy field compatibility.
  factory Exercise.fromJson(Map<String, dynamic> json, List<Muscle> availableMuscles) {
    final hasNewPauseField = json.containsKey('pauseDuration');
    final pauseDuration =
        ((json['pauseDuration'] ?? json['pauseTimeSeconds'] ?? 60) as num).toInt();
    final rawExerciseDuration = (json['exerciseDuration'] ?? 0) as num;

    // Legacy entries stored minutes; current entries store seconds.
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

  /// Estimates 1RM from reps and load using the Epley formula.
  double calculateEpley1RM(int reps, double weight) {
    if (reps <= 0) return 0;
    if (reps == 1) return weight;
    return weight * (1 + reps / 30.0);
  }

  /// Processes a completed set, updates 1RM, and trains involved muscles.
  void completeSet(int setIndex, DateTime timestamp, int repsInReserve) {
    if (setIndex < 0 || setIndex >= sets.length) return;

    // Reserved for future fatigue/effective-rep modeling.
    final _ = repsInReserve;

    final completedSet = sets[setIndex];
    update1RMFromSet(completedSet.repetitions, completedSet.weight);

    final setIntensity = oneRepetitionMax > 0 ? (completedSet.weight / oneRepetitionMax) : 0.0;

    for (var involvement in involvedMuscles) {
      involvement.muscle.train(
        timestamp: timestamp,
        intensity: setIntensity,
        involvementFactor: involvement.weight,
      );
    }
  }

  /// Completes time-based exercises that have no configured sets.
  void completeExercise(DateTime timestamp) {
    if (sets.isEmpty) {
      for (var involvement in involvedMuscles) {
        involvement.muscle.train(
          timestamp: timestamp,
          intensity: 0,
          involvementFactor: involvement.weight,
        );
      }
    }
  }

  /// Updates stored 1RM only when the new estimate is higher.
  void update1RMFromSet(int reps, double weight) {
    final newEstimate = calculateEpley1RM(reps, weight);
    if (newEstimate > oneRepetitionMax) {
      oneRepetitionMax = newEstimate;
    }
  }
}

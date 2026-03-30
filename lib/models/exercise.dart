import 'muscle.dart';

/// Connects a muscle to an exercise with an involvement factor. Involvement of
/// 1 means the muscle is completely exerted during this exercise while 0.1
/// would mean the muscle is only slightly involved.
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

/// Defines one configured training set which consists of a certain amount of
/// repetitions and a load in kilograms that are executed without a pause.
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
/// Examples for an exercise would be bench press or pull ups.
class Exercise {
  /// Stable identifier used for persistence.
  final String id;

  /// Display name (for example "Plank")
  String name;

  /// Optional text that is shown during execution mode below the name - can
  /// be used to provide a description or instruction of the exercise.
  String description;

  /// Muscles involved in this exercise.
  List<Inv> involvedMuscles;

  /// Best known one-repetition maximum in kilograms. Can be left empty or set
  /// to zero and will then be calculated during exercising.
  double oneRepetitionMax;

  /// Ordered set plan for this exercise. If none are added the exercise has no
  /// sets and can be finished via the endExercise-button
  List<ExerciseSet> sets;

  /// Planned pause between sets in seconds. Last set will also evoke one last
  /// pause.
  int pauseDuration;

  /// Planned duration in seconds for time-based execution. Exercise cant be
  /// finished before the timer is started and reached zero - even if all sets
  /// have been finished. Set to zero allows the user to finish the exercise
  /// as soon as all sets are done.
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

  /// Estimates 1RM from reps and load using the Epley formula - a formula
  /// commonly used in sports science.
  double calculate1RM(int reps, double weight) {
    if (reps <= 0) return 0;
    if (reps == 1) return weight;
    return weight * (1 + reps / 30.0);
  }

  /// Processes a completed set, updates 1RM, and trains involved muscles. So
  /// every involved muscle will already be updated directly after exerting
  ///  - not just after ending an exercise or the whole workout.
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

  /// Completes exercises that have no configured sets
  /// (for example a time based exercise)
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
    final newEstimate = calculate1RM(reps, weight);
    if (newEstimate > oneRepetitionMax) {
      oneRepetitionMax = newEstimate;
    }
  }
}

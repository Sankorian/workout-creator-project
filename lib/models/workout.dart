import 'exercise.dart';
import 'muscle.dart';

enum BatchType {
  alternating,
  choice,
  randomPick,
}

class Workout {
  final String id;
  String name;

  /// A workout consists of a list of batches.
  /// Each batch is a list of exercises.
  /// - alternating: Exercises in the batch alternate after workout.
  /// - choice: The user chooses one exercise from the current batch.
  /// - randomPick: The system picks one exercise from the current batch.
  List<List<Exercise>> batches;

  bool randomBatchOrder;
  BatchType batchType;
  bool allowExerciseSelection;

  Workout({
    String? id,
    required this.name,
    required this.batches,
    this.randomBatchOrder = false,
    this.batchType = BatchType.alternating,
    this.allowExerciseSelection = true,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'batches': batches
        .map((batch) => batch.map((e) => e.toJson()).toList())
        .toList(),
    'randomOrder': randomBatchOrder,
    'batchType': batchType.name,
    'allowExerciseSelection': allowExerciseSelection,
  };

  factory Workout.fromJson(Map<String, dynamic> json, List<Muscle> availableMuscles) {
    final legacyModus = (json['modus'] ?? '').toString();
    final rawBatchType = (json['batchType'] ?? '').toString();

    // Keep compatibility with old saved values after removing superset.
    if (rawBatchType == 'superset' || legacyModus == 'supersets') {
      return Workout(
        id: json['id'],
        name: json['name'],
        batches: (json['batches'] as List)
            .map((batch) => (batch as List)
                .map((e) => Exercise.fromJson(e, availableMuscles))
                .toList())
            .toList(),
        randomBatchOrder: json['randomOrder'] ?? false,
        batchType: BatchType.alternating,
        allowExerciseSelection: json.containsKey('allowExerciseSelection')
            ? (json['allowExerciseSelection'] ?? false)
            : (legacyModus == 'choice' || legacyModus == 'pool'),
      );
    }

    final batchType = BatchType.values.firstWhere(
      (type) => type.name == rawBatchType,
      orElse: () {
        switch (legacyModus) {
          case 'alternate':
            return BatchType.alternating;
          case 'pool':
            return BatchType.randomPick;
          case 'choice':
          case 'strict':
          default:
            return BatchType.choice;
        }
      },
    );

    final allowExerciseSelection = json.containsKey('allowExerciseSelection')
        ? (json['allowExerciseSelection'] ?? false)
        : (legacyModus == 'choice' || legacyModus == 'pool');

    return Workout(
      id: json['id'],
      name: json['name'],
      batches: (json['batches'] as List)
          .map((batch) => (batch as List)
              .map((e) => Exercise.fromJson(e, availableMuscles))
              .toList())
          .toList(),
      randomBatchOrder: json['randomOrder'] ?? false,
      batchType: batchType,
      allowExerciseSelection: allowExerciseSelection,
    );
  }
}

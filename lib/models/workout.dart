import 'exercise.dart';
import 'muscle.dart';

enum BatchType {
  choice,
  randomPick,
  alternating,
  superset,
}

class Workout {
  final String id;
  String name;
  String description;

  /// A workout consists of a list of batches.
  /// Each batch is a list of exercises.
  /// - choice: The user chooses one exercise from the current batch.
  /// - randomPick: The system picks one exercise from the current batch.
  /// - alternating: Exercises in the batch alternate after workout.
  /// - superset: Exercises in the batch are performed back-to-back with no rest between them.
  List<List<Exercise>> batches;

  bool randomBatchOrder;
  BatchType batchType;
  bool allowExerciseSelection;

  Workout({
    String? id,
    required this.name,
    this.description = '',
    required this.batches,
    this.randomBatchOrder = false,
    this.batchType = BatchType.choice,
    this.allowExerciseSelection = true,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
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

    final batchType = BatchType.values.firstWhere(
      (type) => type.name == rawBatchType,
      orElse: () {
        switch (legacyModus) {
          case 'alternate':
            return BatchType.alternating;
          case 'supersets':
            return BatchType.superset;
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
      description: json['description'] ?? '',
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

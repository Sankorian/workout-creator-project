import 'exercise.dart';
import 'muscle.dart';

/// How exercises in workout batches are selected.
enum BatchType {
  /// Rotate through exercises across workout runs.
  alternating,

  /// Let the user pick an exercise from each batch.
  choice,

  /// Pick one exercise from each batch automatically.
  randomPick,
}

/// Represents a workout composed of ordered batches of exercises.
class Workout {
  /// Stable identifier used for persistence.
  final String id;

  /// Display name.
  String name;

  /// Two-dimensional list where each inner list is one batch.
  List<List<Exercise>> batches;

  /// Whether the batch order is shuffled at execution time.
  bool randomBatchOrder;

  /// Selection behavior used within each batch.
  BatchType batchType;

  /// Whether the UI allows manual exercise choice during execution.
  bool allowExerciseSelection;

  Workout({
    String? id,
    required this.name,
    required this.batches,
    this.randomBatchOrder = false,
    this.batchType = BatchType.alternating,
    this.allowExerciseSelection = true,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  /// Serializes this workout.
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

  /// Rebuilds a workout from JSON, including legacy value compatibility.
  factory Workout.fromJson(Map<String, dynamic> json, List<Muscle> availableMuscles) {
    final legacyModus = (json['modus'] ?? '').toString();
    final rawBatchType = (json['batchType'] ?? '').toString();
    final parsedBatches = (json['batches'] as List)
        .map((batch) => (batch as List)
            .map((e) => Exercise.fromJson(e, availableMuscles))
            .toList())
        .toList();

    // Keep compatibility with old saved values after removing superset.
    if (rawBatchType == 'superset' || legacyModus == 'supersets') {
      return Workout(
        id: json['id'],
        name: json['name'],
        batches: parsedBatches,
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
      batches: parsedBatches,
      randomBatchOrder: json['randomOrder'] ?? false,
      batchType: batchType,
      allowExerciseSelection: allowExerciseSelection,
    );
  }
}

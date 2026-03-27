import 'exercise.dart';
import 'muscle.dart';

enum WorkoutModus {
  pool,
  strict,
  choice,
  alternate,
  supersets,
}

class Workout {
  final String id;
  String name;

  /// A workout consists of a list of batches.
  /// Each batch is a list of exercises.
  /// - pool: All exercises across all batches are available.
  /// - strict: One exercise per batch. Selection not yet decided.... TODO
  /// - choice: The user chooses one exercise from the current batch.
  /// - alternate: Exercises in the batch alternate after workout.
  /// - supersets: Exercises in the batch are performed back-to-back with no rest between them.
  List<List<Exercise>> batches;

  bool randomBatchOrder;
  WorkoutModus modus;

  Workout({
    String? id,
    required this.name,
    required this.batches,
    this.randomBatchOrder = false,
    this.modus = WorkoutModus.strict,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'batches': batches
        .map((batch) => batch.map((e) => e.toJson()).toList())
        .toList(),
    'randomOrder': randomBatchOrder,
    'modus': modus.name,
  };

  factory Workout.fromJson(Map<String, dynamic> json, List<Muscle> availableMuscles) {
    return Workout(
      id: json['id'],
      name: json['name'],
      batches: (json['batches'] as List)
          .map((batch) => (batch as List)
              .map((e) => Exercise.fromJson(e, availableMuscles))
              .toList())
          .toList(),
      randomBatchOrder: json['randomOrder'] ?? false,
      modus: WorkoutModus.values.firstWhere(
        (m) => m.name == json['modus'],
        orElse: () => WorkoutModus.strict,
      ),
    );
  }
}

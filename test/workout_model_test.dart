import 'package:flutter_test/flutter_test.dart';

import 'package:workout_creator/models/workout.dart';

void main() {
  test('Workout default batch type is alternating', () {
    final workout = Workout(
      name: 'W',
      batches: const [],
    );

    expect(workout.batchType, BatchType.alternating);
  });

  test('fromJson maps legacy batchType superset to alternating', () {
    final workout = Workout.fromJson(
      {
        'id': '1',
        'name': 'Legacy Superset',
        'batchType': 'superset',
        'batches': [],
      },
      const [],
    );

    expect(workout.batchType, BatchType.alternating);
  });

  test('fromJson maps legacy modus supersets to alternating', () {
    final workout = Workout.fromJson(
      {
        'id': '2',
        'name': 'Legacy Modus',
        'modus': 'supersets',
        'batches': [],
      },
      const [],
    );

    expect(workout.batchType, BatchType.alternating);
  });
}


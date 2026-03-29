import 'package:flutter_test/flutter_test.dart';

import 'package:workout_creator/models/exercise.dart';
import 'package:workout_creator/models/muscle.dart';
import 'package:workout_creator/models/muscle_rules.dart';

void main() {
  test('completeSet trains involved muscle and increases growthLevel', () {
    final muscle = Muscle(
      name: 'Test Muscle',
      growthLevel: 0,
      growthRules: {const SimpleGrowthRule()},
      decayRules: {const InactivityDecayRule()},
    );

    final exercise = Exercise(
      name: 'Test Exercise',
      involvedMuscles: [Inv(muscle: muscle, weight: 1.0)],
      oneRepetitionMax: 100,
      sets: [ExerciseSet(repetitions: 10, weight: 50)],
      pauseDuration: 60,
      exerciseDuration: 0,
    );

    expect(muscle.growthLevel, 0);
    expect(muscle.lastTrained, isNull);

    exercise.completeSet(0, DateTime.now(), 2);

    expect(muscle.growthLevel, greaterThan(0));
    expect(muscle.lastTrained, isNotNull);
  });

  test('completeExercise trains set-less exercise muscles once with zero metrics', () {
    final muscle = Muscle(
      name: 'Timed Muscle',
      growthLevel: 0,
      growthRules: {const SimpleGrowthRule()},
      decayRules: {const InactivityDecayRule()},
    );

    final exercise = Exercise(
      name: 'Timed Exercise',
      involvedMuscles: [Inv(muscle: muscle, weight: 1.0)],
      oneRepetitionMax: 100,
      sets: const [],
      pauseDuration: 60,
      exerciseDuration: 30,
    );

    expect(muscle.lastTrained, isNull);

    exercise.completeExercise(DateTime.now());

    expect(muscle.growthLevel, greaterThan(0));
    expect(muscle.lastTrained, isNotNull);
  });
}


import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:workout_creator/models/exercise.dart';
import 'package:workout_creator/models/muscle.dart';
import 'package:workout_creator/models/workout.dart';
import 'package:workout_creator/screens/workout_execution_screen.dart';

void main() {
  Exercise createExercise(String name, {int exerciseDuration = 0, int pauseDuration = 30}) {
    final muscle = Muscle(name: 'Chest');
    return Exercise(
      name: name,
      description: '',
      involvedMuscles: [Inv(muscle: muscle, weight: 1.0)],
      oneRepetitionMax: 100,
      sets: [
        ExerciseSet(repetitions: 10, weight: 40),
      ],
      pauseDuration: pauseDuration,
      exerciseDuration: exerciseDuration,
    );
  }

  bool isActionButtonEnabled(WidgetTester tester, String label) {
    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, label),
    );
    return button.onPressed != null;
  }

  testWidgets('choice mode shows buttons and allows immediate back-to-reselect', (tester) async {
    final workout = Workout(
      name: 'Choice Workout',
      batches: [
        [createExercise('PushUp'), createExercise('BenchPress')],
      ],
      batchType: BatchType.choice,
      allowExerciseSelection: true,
    );

    await tester.pumpWidget(
      MaterialApp(home: WorkoutExecutionScreen(workout: workout)),
    );
    await tester.pumpAndSettle();

    expect(find.text('chooseExercise();'), findsOneWidget);
    expect(find.text('PushUp'), findsOneWidget);
    expect(find.text('BenchPress'), findsOneWidget);

    await tester.tap(find.text('PushUp'));
    await tester.pumpAndSettle();

    expect(find.text('chooseExercise();'), findsNothing);
    expect(find.text('PushUp'), findsWidgets);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('chooseExercise();'), findsOneWidget);
    expect(find.text('BenchPress'), findsOneWidget);
  });

  testWidgets('choice mode auto-selects single exercise batch', (tester) async {
    final workout = Workout(
      name: 'Single Choice Workout',
      batches: [
        [createExercise('OnlyExercise')],
      ],
      batchType: BatchType.choice,
      allowExerciseSelection: true,
    );

    await tester.pumpWidget(
      MaterialApp(home: WorkoutExecutionScreen(workout: workout)),
    );
    await tester.pumpAndSettle();

    expect(find.text('chooseExercise();'), findsNothing);
    expect(find.text('OnlyExercise'), findsWidgets);
  });

  testWidgets(
    'timed exercise with sets enables end only after sets are done and timer ended',
    (tester) async {
      final workout = Workout(
        name: 'Timed Workout',
        batches: [
          [createExercise('Burpees', exerciseDuration: 5, pauseDuration: 3)],
        ],
        batchType: BatchType.choice,
        allowExerciseSelection: false,
      );

      await tester.pumpWidget(
        MaterialApp(home: WorkoutExecutionScreen(workout: workout)),
      );
      await tester.pumpAndSettle();

      if (find.text('startExercise();').evaluate().isNotEmpty) {
        await tester.tap(find.text('startExercise();'));
        await tester.pump();
      }

      await tester.tap(find.text('false'));
      await tester.pump();

      expect(isActionButtonEnabled(tester, 'endExercise();'), isFalse);

      await tester.pump(const Duration(seconds: 2));
      expect(isActionButtonEnabled(tester, 'endExercise();'), isFalse);

      await tester.pump(const Duration(seconds: 4));
      expect(isActionButtonEnabled(tester, 'endExercise();'), isTrue);
    },
  );
}


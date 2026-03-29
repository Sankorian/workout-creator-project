import 'package:flutter/material.dart';
import '../models/muscle.dart';
import '../models/exercise.dart';
import '../models/workout.dart';
import 'create_muscle_screen.dart';
import 'create_exercise_screen.dart';
import 'create_workout_screen.dart';

/// Generic list manager for muscles, exercises, and workouts.
class ItemManagementScreen<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final String Function(T) labelBuilder;
  final List<Muscle>? availableMuscles;
  final List<Exercise>? availableExercises;
  final VoidCallback? onSave; 

  const ItemManagementScreen({
    super.key,
    required this.title,
    required this.items,
    required this.labelBuilder,
    this.availableMuscles,
    this.availableExercises,
    this.onSave,
  });

  @override
  State<ItemManagementScreen<T>> createState() => _ItemManagementScreenState<T>();
}

class _ItemManagementScreenState<T> extends State<ItemManagementScreen<T>> {
  List<Muscle> get _availableMuscles => widget.availableMuscles ?? const [];
  List<Exercise> get _availableExercises => widget.availableExercises ?? const [];

  bool get _isMuscleMode => T == Muscle;
  bool get _isExerciseMode => T == Exercise;
  bool get _isWorkoutMode => T == Workout;

  void _mutateAndSave(VoidCallback mutation) {
    setState(mutation);
    widget.onSave?.call();
  }

  Future<dynamic> _pushCreateScreen() {
    if (_isMuscleMode) {
      return Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CreateMuscleScreen()),
      );
    }
    if (_isExerciseMode) {
      return Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreateExerciseScreen(availableMuscles: _availableMuscles),
        ),
      );
    }
    if (_isWorkoutMode) {
      return Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreateWorkoutScreen(availableExercises: _availableExercises),
        ),
      );
    }
    return Future.value(null);
  }

  void _pushViewScreen(Object item) {
    if (item is Muscle) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreateMuscleScreen(muscleToEdit: item, isViewOnly: true),
        ),
      );
      return;
    }
    if (item is Exercise) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreateExerciseScreen(
            exerciseToEdit: item,
            availableMuscles: _availableMuscles,
            isViewOnly: true,
          ),
        ),
      );
      return;
    }
    if (item is Workout) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreateWorkoutScreen(
            workoutToEdit: item,
            availableExercises: _availableExercises,
            isViewOnly: true,
          ),
        ),
      );
    }
  }

  Future<dynamic> _pushEditScreen(Object item) {
    if (item is Muscle) {
      return Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CreateMuscleScreen(muscleToEdit: item)),
      );
    }
    if (item is Exercise) {
      return Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreateExerciseScreen(
            exerciseToEdit: item,
            availableMuscles: _availableMuscles,
          ),
        ),
      );
    }
    if (item is Workout) {
      return Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreateWorkoutScreen(
            workoutToEdit: item,
            availableExercises: _availableExercises,
          ),
        ),
      );
    }
    return Future.value(null);
  }

  T? _cloneItem(T original) {
    if (original is Muscle) {
      return Muscle(
        name: original.name,
        growthLevel: original.growthLevel,
        recoveryTime: original.recoveryTime,
        decayStartTime: original.decayStartTime,
        growthRules: Set.from(original.growthRules),
        decayRules: Set.from(original.decayRules),
      ) as T;
    }
    if (original is Exercise) {
      return Exercise(
        name: original.name,
        involvedMuscles: List.from(original.involvedMuscles),
        oneRepetitionMax: original.oneRepetitionMax,
        sets: original.sets
            .map((s) => ExerciseSet(repetitions: s.repetitions, weight: s.weight))
            .toList(),
        pauseDuration: original.pauseDuration,
        exerciseDuration: original.exerciseDuration,
      ) as T;
    }
    if (original is Workout) {
      return Workout(
        name: original.name,
        batchType: original.batchType,
        allowExerciseSelection: original.allowExerciseSelection,
        randomBatchOrder: original.randomBatchOrder,
        batches: original.batches.map((b) => List<Exercise>.from(b)).toList(),
      ) as T;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: ListView.builder(
          itemCount: widget.items.length + 1,
          itemBuilder: (context, index) {
            if (index == widget.items.length) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80.0),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final result = await _pushCreateScreen();
                    if (result is T) _mutateAndSave(() => widget.items.add(result));
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('create new'),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                ),
              );
            }

            final item = widget.items[index];

            return ListTile(
              title: Text(widget.labelBuilder(item)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility),
                    onPressed: () => _pushViewScreen(item as Object),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () async {
                      final result = await _pushEditScreen(item as Object);
                      if (result is T) _mutateAndSave(() => widget.items[index] = result);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _showDeleteConfirmation(index),
                  ),
                  IconButton(
                    icon: const Icon(Icons.content_copy),
                    onPressed: () {
                      final original = widget.items[index];
                      final copy = _cloneItem(original);
                      if (copy != null) _mutateAndSave(() => widget.items.add(copy));
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Shows a destructive-action confirmation before removing an item.
  void _showDeleteConfirmation(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete Item"),
          content: const Text("Are you sure? This action cannot be undone."),
          actions: [
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    _mutateAndSave(() => widget.items.removeAt(index));
                    Navigator.of(context).pop();
                  },
                  child: const Text("DELETE", style: TextStyle(color: Colors.red)),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("CANCEL"),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

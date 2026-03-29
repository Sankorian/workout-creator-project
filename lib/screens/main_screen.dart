import 'package:flutter/material.dart';
import '../models/muscle.dart';
import '../models/exercise.dart';
import '../models/workout.dart';
import '../services/storage_service.dart';
import 'workout_creator_screen.dart';
import 'workout_selection_screen.dart';

/// Entry screen that loads persisted data and routes to app flows.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final StorageService _storageService = StorageService();
  List<Muscle> _myMuscles = [];
  List<Exercise> _myExercises = [];
  List<Workout> _myWorkouts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Loads muscles first, then exercises/workouts that depend on them.
  Future<void> _loadData() async {
    final muscles = await _storageService.loadMuscles();
    final exercises = await _storageService.loadExercises(muscles);
    final workouts = await _storageService.loadWorkouts(muscles);
    _syncWorkoutExercises(workouts: workouts, exercises: exercises);

    if (!mounted) return;
    setState(() {
      _myMuscles = muscles;
      _myExercises = exercises;
      _myWorkouts = workouts;
      _isLoading = false;
    });
  }

  /// Re-links workout exercise references to the latest in-memory exercise objects.
  void _syncWorkoutExercises({
    required List<Workout> workouts,
    required List<Exercise> exercises,
  }) {
    final exerciseById = {for (final exercise in exercises) exercise.id: exercise};

    for (final workout in workouts) {
      for (final batch in workout.batches) {
        for (int i = 0; i < batch.length; i++) {
          final latestExercise = exerciseById[batch[i].id];
          if (latestExercise != null) {
            batch[i] = latestExercise;
          }
        }
      }
    }
  }

  /// Persists all collections after re-linking workout exercise references.
  Future<void> _saveData() async {
    _syncWorkoutExercises(workouts: _myWorkouts, exercises: _myExercises);
    await _storageService.saveMuscles(_myMuscles);
    await _storageService.saveExercises(_myExercises);
    await _storageService.saveWorkouts(_myWorkouts);
  }

  /// Navigates to a screen and persists any mutations when returning.
  Future<void> _navigateTo(Widget screen) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );

    _syncWorkoutExercises(workouts: _myWorkouts, exercises: _myExercises);
    await _saveData();
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final hasWorkouts = _myWorkouts.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Creator'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _navigateTo(WorkoutCreatorScreen(
                muscles: _myMuscles,
                exercises: _myExercises,
                workouts: _myWorkouts,
                onSave: _saveData,
              )),
              style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
              child: const Text('Workout Creator'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: hasWorkouts 
                  ? () => _navigateTo(WorkoutSelectionScreen(workouts: _myWorkouts))
                  : null,
              style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
              child: const Text('Start Workout'),
            ),
          ],
        ),
      ),
    );
  }
}

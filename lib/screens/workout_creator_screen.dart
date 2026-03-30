import 'package:flutter/material.dart';
import '../models/muscle.dart';
import '../models/exercise.dart';
import '../models/workout.dart';
import 'item_management_screen.dart';

/// Hub screen for managing muscles, exercises, and workouts.
class WorkoutCreatorScreen extends StatefulWidget {
  final List<Muscle> muscles;
  final List<Exercise> exercises;
  final List<Workout> workouts;
  final VoidCallback onSave;

  const WorkoutCreatorScreen({
    super.key,
    required this.muscles,
    required this.exercises,
    required this.workouts,
    required this.onSave,
  });

  @override
  State<WorkoutCreatorScreen> createState() => _WorkoutCreatorScreenState();
}

class _WorkoutCreatorScreenState extends State<WorkoutCreatorScreen> {
  // Opens a manager screen and refreshes local button states on return.
  Future<void> _openManager(Widget screen) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
    if (!mounted) return;
    setState(() {});
  }

  Widget _buildMenuButton({
    required String label,
    required VoidCallback? onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
      child: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Workout Creator')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildMenuButton(
              label: 'My Muscles',
              onPressed: () => _openManager(
                ItemManagementScreen<Muscle>(
                  title: 'My Muscles',
                  items: widget.muscles,
                  labelBuilder: (muscle) => muscle.name,
                  onSave: widget.onSave,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildMenuButton(
              label: 'My Exercises',
              // Exercises require at least one muscle to link involvement.
              onPressed: widget.muscles.isNotEmpty
                  ? () => _openManager(
                        ItemManagementScreen<Exercise>(
                          title: 'My Exercises',
                          items: widget.exercises,
                          labelBuilder: (exercise) => exercise.name,
                          availableMuscles: widget.muscles,
                          onSave: widget.onSave,
                        ),
                      )
                  : null,
            ),
            const SizedBox(height: 20),
            _buildMenuButton(
              label: 'My Workouts',
              // Workouts require at least one exercise to compose batches.
              onPressed: widget.exercises.isNotEmpty
                  ? () => _openManager(
                        ItemManagementScreen<Workout>(
                          title: 'My Workouts',
                          items: widget.workouts,
                          labelBuilder: (workout) => workout.name,
                          availableExercises: widget.exercises,
                          onSave: widget.onSave,
                        ),
                      )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

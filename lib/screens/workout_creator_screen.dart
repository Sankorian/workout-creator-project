import 'package:flutter/material.dart';
import '../models/muscle.dart';
import '../models/exercise.dart';
import '../models/workout.dart';
import 'item_management_screen.dart';

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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Workout Creator')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ItemManagementScreen<Muscle>(
                      title: 'My Muscles',
                      items: widget.muscles,
                      labelBuilder: (muscle) => muscle.name,
                      onSave: widget.onSave,
                    ),
                  ),
                ).then((_) => setState(() {}));
              },
              style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
              child: const Text('My Muscles'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: widget.muscles.isNotEmpty
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ItemManagementScreen<Exercise>(
                            title: 'My Exercises',
                            items: widget.exercises,
                            labelBuilder: (exercise) => exercise.name,
                            availableMuscles: widget.muscles,
                            onSave: widget.onSave,
                          ),
                        ),
                      ).then((_) => setState(() {}));
                    }
                  : null,
              style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
              child: const Text('My Exercises'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: widget.exercises.isNotEmpty
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ItemManagementScreen<Workout>(
                            title: 'My Workouts',
                            items: widget.workouts,
                            labelBuilder: (workout) => workout.name,
                            availableExercises: widget.exercises,
                            onSave: widget.onSave,
                          ),
                        ),
                      ).then((_) => setState(() {}));
                    }
                  : null,
              style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
              child: const Text('My Workouts'),
            ),
          ],
        ),
      ),
    );
  }
}

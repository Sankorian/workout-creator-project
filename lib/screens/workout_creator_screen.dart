import 'package:flutter/material.dart';
import '../models/muscle.dart';
import '../models/exercise.dart';
import 'item_management_screen.dart';

class WorkoutCreatorScreen extends StatelessWidget {
  final List<Muscle> muscles;
  final List<Exercise> exercises;

  const WorkoutCreatorScreen({
    super.key,
    required this.muscles,
    required this.exercises,
  });

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
                      items: muscles,
                      labelBuilder: (muscle) => muscle.name,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
              child: const Text('My Muscles'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ItemManagementScreen<Exercise>(
                      title: 'My Exercises',
                      items: exercises,
                      labelBuilder: (exercise) => exercise.name,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
              child: const Text('My Exercises'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: exercises.isNotEmpty
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ItemManagementScreen<String>(
                            title: 'My Workouts',
                            items: [],
                            labelBuilder: (item) => item,
                          ),
                        ),
                      );
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

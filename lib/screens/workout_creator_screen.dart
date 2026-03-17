import 'package:flutter/material.dart';
import '../models/muscle.dart';
import 'item_management_screen.dart';

class WorkoutCreatorScreen extends StatelessWidget {
  final bool hasExercises;

  const WorkoutCreatorScreen({super.key, required this.hasExercises});

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
                      items: [
                        Muscle(name: 'Shoulder'),
                        Muscle(name: 'Chest'),
                        Muscle(name: 'Biceps'),
                      ],
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
                    builder: (context) => ItemManagementScreen<String>(
                      title: 'My Exercises',
                      items: [],
                      labelBuilder: (item) => item,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
              child: const Text('My Exercises'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: hasExercises
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

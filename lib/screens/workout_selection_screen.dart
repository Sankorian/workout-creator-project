import 'package:flutter/material.dart';
import '../models/workout.dart';
import 'workout_execution_screen.dart';

class WorkoutSelectionScreen extends StatelessWidget {
  final List<Workout> workouts;

  const WorkoutSelectionScreen({
    super.key,
    required this.workouts,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Workout'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: workouts.map((workout) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WorkoutExecutionScreen(workout: workout),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(200, 50),
                  ),
                  child: Text(workout.name),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

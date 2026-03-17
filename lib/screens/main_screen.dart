import 'package:flutter/material.dart';
import '../models/muscle.dart';
import '../models/exercise.dart';
import 'workout_creator_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final List<Muscle> _myMuscles = [];
  final List<Exercise> _myExercises = [];

  void _navigateTo(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    ).then((_) {
      // Refresh the main screen state when returning, 
      // in case exercises were added to enable "Start Workout"
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    bool hasExercises = _myExercises.isNotEmpty;

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
              )),
              style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
              child: const Text('Workout Creator'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: hasExercises ? () {} : null,
              style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
              child: const Text('Start Workout'),
            ),
          ],
        ),
      ),
    );
  }
}

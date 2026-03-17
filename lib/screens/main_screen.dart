import 'package:flutter/material.dart';
import 'workout_creator_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool _hasExercises = false;

  void _navigateTo(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              onPressed: () => _navigateTo(WorkoutCreatorScreen(hasExercises: _hasExercises)),
              style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
              child: const Text('Workout Creator'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _hasExercises ? () {} : null,
              style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
              child: const Text('Start Workout'),
            ),
            const SizedBox(height: 40),
            TextButton(
              onPressed: () => setState(() => _hasExercises = !_hasExercises),
              child: Text(_hasExercises ? "Simulate: No Exercises" : "Simulate: Has Exercises"),
            ),
          ],
        ),
      ),
    );
  }
}

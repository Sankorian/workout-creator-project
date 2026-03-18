import 'package:flutter/material.dart';
import '../models/muscle.dart';
import '../models/exercise.dart';
import '../services/storage_service.dart';
import 'workout_creator_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final StorageService _storageService = StorageService();
  List<Muscle> _myMuscles = [];
  List<Exercise> _myExercises = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final muscles = await _storageService.loadMuscles();
    final exercises = await _storageService.loadExercises(muscles);
    setState(() {
      _myMuscles = muscles;
      _myExercises = exercises;
      _isLoading = false;
    });
  }

  Future<void> _saveData() async {
    await _storageService.saveMuscles(_myMuscles);
    await _storageService.saveExercises(_myExercises);
  }

  void _navigateTo(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    ).then((_) {
      _saveData();
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
                onSave: _saveData, // Pass the save callback
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

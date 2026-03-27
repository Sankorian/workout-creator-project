import 'dart:async';
import 'package:flutter/material.dart';
import '../models/workout.dart';
import '../models/exercise.dart';

class WorkoutExecutionScreen extends StatefulWidget {
  final Workout workout;

  const WorkoutExecutionScreen({super.key, required this.workout});

  @override
  State<WorkoutExecutionScreen> createState() => _WorkoutExecutionScreenState();
}

class _WorkoutExecutionScreenState extends State<WorkoutExecutionScreen> {
  late List<Exercise> _flatExercises;
  int _currentExerciseIndex = 0;
  int _currentSetIndex = 0;
  
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isTimerRunning = false;
  bool _isFinished = false;

  final Map<int, TextEditingController> _weightControllers = {};
  final Map<int, TextEditingController> _repsControllers = {};

  @override
  void initState() {
    super.initState();
    _flatExercises = widget.workout.batches.expand((batch) => batch).toList();
    if (widget.workout.randomBatchOrder) {
      _flatExercises.shuffle();
    }
    _initControllers();
  }

  void _initControllers() {
    _disposeControllers();
    if (_flatExercises.isEmpty || _currentExerciseIndex >= _flatExercises.length) return;
    
    final exercise = _flatExercises[_currentExerciseIndex];
    for (int i = 0; i < exercise.sets.length; i++) {
      _weightControllers[i] = TextEditingController(text: exercise.sets[i].weight.toString());
      _repsControllers[i] = TextEditingController(text: exercise.sets[i].repetitions.toString());
    }
  }

  void _disposeControllers() {
    _weightControllers.forEach((_, c) => c.dispose());
    _repsControllers.forEach((_, c) => c.dispose());
    _weightControllers.clear();
    _repsControllers.clear();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _disposeControllers();
    super.dispose();
  }

  void _startTimer(int seconds) {
    _timer?.cancel();
    setState(() {
      _remainingSeconds = seconds;
      _isTimerRunning = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _timer?.cancel();
          _isTimerRunning = false;
        }
      });
    });
  }

  void _moveToNextSet() {
    final currentExercise = _flatExercises[_currentExerciseIndex];
    if (_currentSetIndex < currentExercise.sets.length - 1) {
      setState(() {
        _currentSetIndex++;
      });
    } else {
      if (_currentExerciseIndex < _flatExercises.length - 1) {
        setState(() {
          _currentExerciseIndex++;
          _currentSetIndex = 0;
          _initControllers();
        });
      } else {
        setState(() {
          _isFinished = true;
        });
      }
    }
  }

  void _completeSet() {
    final exercise = _flatExercises[_currentExerciseIndex];
    final set = exercise.sets[_currentSetIndex];
    
    // Update model with current controller values before completing
    set.weight = double.tryParse(_weightControllers[_currentSetIndex]?.text ?? '') ?? set.weight;
    set.repetitions = int.tryParse(_repsControllers[_currentSetIndex]?.text ?? '') ?? set.repetitions;
    
    exercise.completeSet(_currentSetIndex, DateTime.now(), 2);
    _startTimer(exercise.pauseTimeSeconds);
    _moveToNextSet();
  }

  @override
  Widget build(BuildContext context) {
    if (_isFinished) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Workout.complete();', style: TextStyle(fontFamily: 'monospace', fontSize: 20, color: Colors.green)),
              const SizedBox(height: 20),
              const Text('Congratulations!', style: TextStyle(fontSize: 24)),
              const SizedBox(height: 40),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('RETURN TO MAIN', style: TextStyle(fontFamily: 'monospace')),
              ),
            ],
          ),
        ),
      );
    }

    if (_flatExercises.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Workout')),
        body: const Center(child: Text('Error: No exercises found.', style: TextStyle(fontFamily: 'monospace'))),
      );
    }

    final exercise = _flatExercises[_currentExerciseIndex];
    const headerStyle = TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, color: Colors.grey);
    const cellStyle = TextStyle(fontFamily: 'monospace', fontSize: 16);

    return Scaffold(
      appBar: AppBar(title: Text(widget.workout.name)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(exercise.name, 
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 18)),
              const SizedBox(height: 30),
              
              // Lineless Table Header
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: const [
                    SizedBox(width: 30),
                    SizedBox(width: 50, child: Text('Set', style: headerStyle)),
                    SizedBox(width: 80, child: Text('Kg', style: headerStyle)),
                    SizedBox(width: 80, child: Text('Reps', style: headerStyle)),
                    SizedBox(width: 60, child: Text('Done', style: headerStyle)),
                  ],
                ),
              ),
              const Divider(height: 1),
              
              Expanded(
                child: ListView.builder(
                  itemCount: exercise.sets.length,
                  itemBuilder: (context, index) {
                    final isCurrent = index == _currentSetIndex;
                    final isDone = index < _currentSetIndex;
                    
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 30,
                              child: Text(
                                isCurrent ? '> ' : '  ',
                                style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, color: Colors.blue),
                              ),
                            ),
                            SizedBox(
                              width: 50,
                              child: Text('${index + 1}', style: cellStyle),
                            ),
                            SizedBox(
                              width: 80,
                              child: isCurrent
                                  ? TextField(
                                      controller: _weightControllers[index],
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                                      style: cellStyle.copyWith(color: Colors.blue),
                                    )
                                  : Text(
                                      _weightControllers[index]?.text ?? '',
                                      style: cellStyle.copyWith(color: isDone ? Colors.grey : Colors.black),
                                    ),
                            ),
                            SizedBox(
                              width: 80,
                              child: isCurrent
                                  ? TextField(
                                      controller: _repsControllers[index],
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                                      style: cellStyle.copyWith(color: Colors.blue),
                                    )
                                  : Text(
                                      _repsControllers[index]?.text ?? '',
                                      style: cellStyle.copyWith(color: isDone ? Colors.grey : Colors.black),
                                    ),
                            ),
                            SizedBox(
                              width: 60,
                              child: IconButton(
                                icon: Icon(
                                  Icons.check_circle,
                                  color: isDone
                                      ? Colors.green
                                      : (isCurrent ? Colors.grey : Colors.grey.withOpacity(0.3)),
                                ),
                                onPressed: isCurrent ? _completeSet : null,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              if (_isTimerRunning)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Text('pauseTimeSeconds: $_remainingSeconds;', 
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 24, color: Colors.green)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

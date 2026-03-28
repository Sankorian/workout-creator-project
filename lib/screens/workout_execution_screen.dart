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
  
  Timer? _pauseDurationTimer;
  Timer? _exerciseDurationCountdownTimer;
  int _remainingPauseDurationSeconds = 0;
  int _remainingExerciseDurationSeconds = 0;
  bool _isPauseDurationTimerRunning = false;
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
    _startExerciseDurationCountdown();
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
    _pauseDurationTimer?.cancel();
    _exerciseDurationCountdownTimer?.cancel();
    _disposeControllers();
    super.dispose();
  }

  void _startExerciseDurationCountdown() {
    _exerciseDurationCountdownTimer?.cancel();
    if (_flatExercises.isEmpty || _currentExerciseIndex >= _flatExercises.length) {
      _remainingExerciseDurationSeconds = 0;
      return;
    }

    final exercise = _flatExercises[_currentExerciseIndex];
    _remainingExerciseDurationSeconds = exercise.exerciseDuration;

    if (_remainingExerciseDurationSeconds <= 0) return;

    _exerciseDurationCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_remainingExerciseDurationSeconds > 0) {
        setState(() {
          _remainingExerciseDurationSeconds--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final mm = minutes.toString().padLeft(2, '0');
    final ss = seconds.toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  bool _areAllSetsDone(Exercise exercise) => _currentSetIndex >= exercise.sets.length;

  bool _isExerciseDurationDone(Exercise exercise) {
    if (exercise.exerciseDuration <= 0) return true;
    return _remainingExerciseDurationSeconds <= 0;
  }

  bool _canProceedToNextExercise(Exercise exercise) {
    return _areAllSetsDone(exercise) && _isExerciseDurationDone(exercise);
  }

  void _nextExercise() {
    if (_currentExerciseIndex >= _flatExercises.length - 1) return;
    setState(() {
      _currentExerciseIndex++;
      _currentSetIndex = 0;
      _startExerciseDurationCountdown();
      _initControllers();
    });
  }

  void _endExercise() {
    _pauseDurationTimer?.cancel();
    _exerciseDurationCountdownTimer?.cancel();
    setState(() {
      _isFinished = true;
    });
  }

  void _completeExerciseAction() {
    if (_currentExerciseIndex == _flatExercises.length - 1) {
      _endExercise();
      return;
    }
    _nextExercise();
  }

  void _startPauseDurationTimer(int seconds) {
    _pauseDurationTimer?.cancel();
    if (seconds <= 0) {
      setState(() {
        _remainingPauseDurationSeconds = 0;
        _isPauseDurationTimerRunning = false;
      });
      return;
    }

    setState(() {
      _remainingPauseDurationSeconds = seconds;
      _isPauseDurationTimerRunning = true;
    });
    _pauseDurationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_remainingPauseDurationSeconds > 0) {
          _remainingPauseDurationSeconds--;
        } else {
          _pauseDurationTimer?.cancel();
          _isPauseDurationTimerRunning = false;
        }
      });
    });
  }

  void _completeSet() {
    if (_flatExercises.isEmpty || _currentExerciseIndex >= _flatExercises.length) return;
    final exercise = _flatExercises[_currentExerciseIndex];
    if (_currentSetIndex >= exercise.sets.length) return;

    final set = exercise.sets[_currentSetIndex];
    
    // Update model with current controller values before completing
    set.weight = double.tryParse(_weightControllers[_currentSetIndex]?.text ?? '') ?? set.weight;
    set.repetitions = int.tryParse(_repsControllers[_currentSetIndex]?.text ?? '') ?? set.repetitions;
    
    exercise.completeSet(_currentSetIndex, DateTime.now(), 2);
    _startPauseDurationTimer(exercise.pauseDuration);
    setState(() {
      _currentSetIndex++;
    });
  }

  bool _hasDescription(Exercise exercise) => exercise.description.trim().isNotEmpty;

  bool _hasSets(Exercise exercise) => exercise.sets.isNotEmpty;

  bool _showPauseDurationTimer(Exercise exercise) {
    return exercise.pauseDuration > 0 && _isPauseDurationTimerRunning;
  }

  bool _showExerciseDurationTimer(Exercise exercise) {
    return exercise.exerciseDuration > 0 && _remainingExerciseDurationSeconds > 0;
  }

  Widget _buildExerciseTitleAndDescription(Exercise exercise) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          exercise.name,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 18),
        ),
        if (_hasDescription(exercise)) ...[
          const SizedBox(height: 8),
          Text(
            exercise.description,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildExerciseProgressOverview() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = _flatExercises.length;
        if (count == 0) return const SizedBox.shrink();

        const minBlockWidth = 32.0;
        const gap = 8.0;

        final availableWidth = constraints.maxWidth;
        final stretchedBlockWidth =
            (availableWidth - (count - 1) * gap) / count;

        // Stretch when possible; once blocks would get too small, keep min width and scroll.
        final shouldScroll = stretchedBlockWidth < minBlockWidth;
        final blockWidth = shouldScroll ? minBlockWidth : stretchedBlockWidth;
        final contentWidth = count * blockWidth + (count - 1) * gap;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: availableWidth),
            child: SizedBox(
              width: contentWidth,
              child: Row(
                children: List.generate(count, (index) {
                  final isActive = index == _currentExerciseIndex;
                  final isCompleted = index < _currentExerciseIndex;

                  final backgroundColor = isActive
                      ? Colors.blue
                      : (isCompleted ? Colors.green : Colors.grey.withValues(alpha: 0.35));

                  final textColor = isActive || isCompleted ? Colors.white : Colors.black54;

                  return Padding(
                    padding: EdgeInsets.only(right: index == count - 1 ? 0 : gap),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: blockWidth,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${index + 1}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSetHeader() {
    const headerStyle = TextStyle(
      fontFamily: 'monospace',
      fontWeight: FontWeight.bold,
      color: Colors.grey,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              SizedBox(width: 30),
              SizedBox(width: 50, child: Text('Set', style: headerStyle)),
              SizedBox(width: 80, child: Text('Kg', style: headerStyle)),
              SizedBox(width: 80, child: Text('Reps', style: headerStyle)),
              SizedBox(width: 60, child: Text('Done', style: headerStyle)),
            ],
          ),
        ),
        Divider(height: 1),
      ],
    );
  }

  Widget _buildSetRow(Exercise exercise, int index) {
    const cellStyle = TextStyle(fontFamily: 'monospace', fontSize: 16);
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
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
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
              child: GestureDetector(
                onTap: isCurrent && !isDone ? _completeSet : null,
                child: Text(
                  isDone ? 'true' : 'false',
                  style: cellStyle.copyWith(
                    color: isDone ? Colors.green : (isCurrent ? Colors.blue : Colors.grey),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetTableSection(Exercise exercise) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSetHeader(),
          Expanded(
            child: ListView.builder(
              itemCount: exercise.sets.length,
              itemBuilder: (context, index) => _buildSetRow(exercise, index),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPauseTimerSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          'pauseDuration: $_remainingPauseDurationSeconds;',
          style: const TextStyle(fontFamily: 'monospace', fontSize: 18, color: Colors.green),
        ),
      ),
    );
  }

  Widget _buildExerciseDurationSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      width: double.infinity,
      child: Center(
        child: Text(
          'exerciseDuration: ${_formatDuration(_remainingExerciseDurationSeconds)};',
          style: const TextStyle(fontFamily: 'monospace', fontSize: 18, color: Colors.deepPurple),
        ),
      ),
    );
  }

  Widget _buildExerciseActionButton({
    required bool canProceedToNextExercise,
    required String exerciseActionLabel,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canProceedToNextExercise ? _completeExerciseAction : null,
        child: Text(exerciseActionLabel, style: const TextStyle(fontFamily: 'monospace')),
      ),
    );
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
    final canProceedToNextExercise = _canProceedToNextExercise(exercise);
    final isLastExercise = _currentExerciseIndex == _flatExercises.length - 1;
    final exerciseActionLabel = isLastExercise ? 'endExercise();' : 'nextExercise();';
    final hasSets = _hasSets(exercise);

    return Scaffold(
      appBar: AppBar(title: Text(widget.workout.name)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildExerciseProgressOverview(),
              const SizedBox(height: 16),
              _buildExerciseTitleAndDescription(exercise),
              const SizedBox(height: 30),

              if (hasSets) _buildSetTableSection(exercise) else const Spacer(),

              if (_showPauseDurationTimer(exercise)) _buildPauseTimerSection(),
              if (_showExerciseDurationTimer(exercise)) _buildExerciseDurationSection(),
              _buildExerciseActionButton(
                canProceedToNextExercise: canProceedToNextExercise,
                exerciseActionLabel: exerciseActionLabel,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

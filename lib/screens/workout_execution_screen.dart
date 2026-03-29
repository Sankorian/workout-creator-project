import 'dart:async';
import 'dart:math';
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
  late List<Exercise?> _flatExercises;
  final List<int> _batchIndexByExercise = [];
  final Set<int> _resolvedBatchIndices = {};
  final Set<int> _navigatedAwayAfterChoice = {};
  int _currentExerciseIndex = 0;
  int _currentSetIndex = 0;
  
  Timer? _pauseDurationTimer;
  Timer? _exerciseDurationCountdownTimer;
  int _remainingPauseDurationSeconds = 0;
  int _remainingExerciseDurationSeconds = 0;
  bool _isPauseDurationTimerRunning = false;
  bool _isExerciseDurationCountdownRunning = false;
  bool _isFinished = false;
  bool _isBackDialogOpen = false;

  final Map<int, int> _setIndexByExercise = {};
  final Map<int, int> _remainingExerciseDurationByExercise = {};
  final Set<int> _startedExerciseIndices = {};

  final Map<int, TextEditingController> _weightControllers = {};
  final Map<int, TextEditingController> _repsControllers = {};

  @override
  void initState() {
    super.initState();
    _initializeExecutionExercises();

    for (int i = 0; i < _flatExercises.length; i++) {
      _initializeExerciseStateForIndex(i);
    }

    _restoreCurrentExerciseState();
    _initControllers();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _autoStartCurrentExerciseIfEligible();
    });
  }

  bool get _usesSingleExercisePerBatch {
    if (widget.workout.batchType == BatchType.choice) return true;
    return widget.workout.batchType == BatchType.randomPick ||
        widget.workout.batchType == BatchType.alternating;
  }

  bool get _isChoiceBatchMode => widget.workout.batchType == BatchType.choice;

  List<Exercise> _batchForExecutionIndex(int executionIndex) {
    final batchIndex = _batchIndexByExercise[executionIndex];
    return widget.workout.batches[batchIndex];
  }

  Exercise? _exerciseAt(int executionIndex) {
    if (executionIndex < 0 || executionIndex >= _flatExercises.length) return null;
    return _flatExercises[executionIndex];
  }

  Exercise? get _currentExercise => _exerciseAt(_currentExerciseIndex);

  bool _requiresChoiceSelectionAt(int executionIndex) {
    if (!_isChoiceBatchMode) return false;
    if (executionIndex < 0 || executionIndex >= _flatExercises.length) return false;
    final batch = _batchForExecutionIndex(executionIndex);
    return batch.length > 1 && _flatExercises[executionIndex] == null;
  }

  void _initializeExerciseStateForIndex(int executionIndex) {
    final exercise = _exerciseAt(executionIndex);
    _setIndexByExercise[executionIndex] = 0;
    _remainingExerciseDurationByExercise[executionIndex] = exercise?.exerciseDuration ?? 0;
    if (exercise != null && exercise.exerciseDuration <= 0) {
      _startedExerciseIndices.add(executionIndex);
    } else {
      _startedExerciseIndices.remove(executionIndex);
    }
  }

  void _initializeExecutionExercises() {
    _batchIndexByExercise.clear();
    _resolvedBatchIndices.clear();

    if (_usesSingleExercisePerBatch) {
      final batchOrder = List<int>.generate(widget.workout.batches.length, (i) => i)
          .where((batchIndex) => widget.workout.batches[batchIndex].isNotEmpty)
          .toList();

      if (widget.workout.randomBatchOrder) {
        batchOrder.shuffle();
      }

      _batchIndexByExercise.addAll(batchOrder);
      if (_isChoiceBatchMode) {
        _flatExercises = [
          for (final batchIndex in batchOrder)
            widget.workout.batches[batchIndex].length == 1
                ? widget.workout.batches[batchIndex].first
                : null,
        ];

        for (int i = 0; i < _flatExercises.length; i++) {
          if (_flatExercises[i] != null) {
            _resolvedBatchIndices.add(_batchIndexByExercise[i]);
          }
        }
      } else {
        _flatExercises = [
          for (final batchIndex in batchOrder) widget.workout.batches[batchIndex].first,
        ];

        if (_flatExercises.isNotEmpty) {
          _resolveExerciseForExecutionIndex(0);
        }
      }
      return;
    }

    final entries = <MapEntry<int, Exercise>>[];
    for (int batchIndex = 0; batchIndex < widget.workout.batches.length; batchIndex++) {
      for (final exercise in widget.workout.batches[batchIndex]) {
        entries.add(MapEntry(batchIndex, exercise));
      }
    }

    if (widget.workout.randomBatchOrder) {
      entries.shuffle();
    }

    _batchIndexByExercise.addAll(entries.map((entry) => entry.key));
    _flatExercises = entries.map((entry) => entry.value).toList();
  }

  void _resolveExerciseForExecutionIndex(int exerciseIndex) {
    if (!_usesSingleExercisePerBatch) return;
    if (exerciseIndex < 0 || exerciseIndex >= _flatExercises.length) return;
    if (_isChoiceBatchMode) return;

    final batchIndex = _batchIndexByExercise[exerciseIndex];
    if (_resolvedBatchIndices.contains(batchIndex)) return;

    final batch = widget.workout.batches[batchIndex];
    if (batch.isEmpty) return;

    final selectedExercise = switch (widget.workout.batchType) {
      BatchType.randomPick => batch[Random().nextInt(batch.length)],
      BatchType.alternating => batch.first,
      _ => batch.first,
    };

    if (widget.workout.batchType == BatchType.alternating && batch.length > 1) {
      final rotated = batch.removeAt(0);
      batch.add(rotated);
    }

    _flatExercises[exerciseIndex] = selectedExercise;
    _initializeExerciseStateForIndex(exerciseIndex);

    _resolvedBatchIndices.add(batchIndex);
  }

  void _initControllers() {
    _disposeControllers();
    if (_flatExercises.isEmpty || _currentExerciseIndex >= _flatExercises.length) return;

    final exercise = _currentExercise;
    if (exercise == null) return;
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

  void _persistCurrentExerciseState() {
    _setIndexByExercise[_currentExerciseIndex] = _currentSetIndex;
    _remainingExerciseDurationByExercise[_currentExerciseIndex] = _remainingExerciseDurationSeconds;
  }

  void _restoreCurrentExerciseState() {
    if (_flatExercises.isEmpty || _currentExerciseIndex >= _flatExercises.length) return;

    _currentSetIndex = _setIndexByExercise[_currentExerciseIndex] ?? 0;
    final exercise = _currentExercise;
    _remainingExerciseDurationSeconds =
        _remainingExerciseDurationByExercise[_currentExerciseIndex] ??
            (exercise?.exerciseDuration ?? 0);
  }

  bool _isCurrentExerciseStarted() {
    return _startedExerciseIndices.contains(_currentExerciseIndex);
  }

  bool _canStartExerciseDurationCountdown() {
    if (_currentExercise == null) return false;
    return _isCurrentExerciseStarted() &&
        !_isPauseDurationTimerRunning &&
        _remainingExerciseDurationSeconds > 0 &&
        !_isExerciseDurationCountdownRunning;
  }

  bool _shouldShowStartExerciseButton(Exercise exercise) {
    return exercise.exerciseDuration > 0 &&
        !_isCurrentExerciseStarted() &&
        _remainingExerciseDurationSeconds > 0;
  }

  void _autoStartCurrentExerciseIfEligible() {
    if (widget.workout.allowExerciseSelection) return;
    if (_flatExercises.isEmpty || _currentExerciseIndex >= _flatExercises.length) return;

    final exercise = _currentExercise;
    if (exercise == null) return;
    if (!_shouldShowStartExerciseButton(exercise)) return;
    if (_isPauseDurationTimerRunning) return;

    _startCurrentExercise();
  }

  bool _isExerciseFullyCompleted(int exerciseIndex) {
    if (exerciseIndex < 0 || exerciseIndex >= _flatExercises.length) return false;

    final exercise = _exerciseAt(exerciseIndex);
    if (exercise == null) return false;
    final setIndex = _setIndexByExercise[exerciseIndex] ?? 0;
    final allSetsDone = setIndex >= exercise.sets.length;
    final durationDone = (exercise.exerciseDuration <= 0) ||
        ((_remainingExerciseDurationByExercise[exerciseIndex] ?? exercise.exerciseDuration) <= 0);

    return allSetsDone && durationDone;
  }

  bool _canSwipeExercises() {
    return widget.workout.allowExerciseSelection && !_isExerciseDurationCountdownRunning;
  }

  void _goToExercise(int index) {
    if (index < 0 || index >= _flatExercises.length || index == _currentExerciseIndex) return;
    if (!_canSwipeExercises()) return;

    if (_isChoiceBatchMode && _currentExercise != null) {
      _navigatedAwayAfterChoice.add(_currentExerciseIndex);
    }

    _persistCurrentExerciseState();
    _resolveExerciseForExecutionIndex(index);
    setState(() {
      _currentExerciseIndex = index;
      _restoreCurrentExerciseState();
      _initControllers();
    });
  }

  void _startCurrentExercise() {
    if (_flatExercises.isEmpty || _currentExerciseIndex >= _flatExercises.length) return;
    final exercise = _currentExercise;
    if (exercise == null) return;

    setState(() {
      if (_isPauseDurationTimerRunning) {
        _pauseDurationTimer?.cancel();
        _isPauseDurationTimerRunning = false;
        _remainingPauseDurationSeconds = 0;
      }

      _startedExerciseIndices.add(_currentExerciseIndex);
    });

    if (exercise.exerciseDuration > 0 && _remainingExerciseDurationSeconds > 0) {
      _startExerciseDurationCountdown();
    }
  }

  void _startExerciseDurationCountdown() {
    _exerciseDurationCountdownTimer?.cancel();
    _isExerciseDurationCountdownRunning = false;
    if (_flatExercises.isEmpty || _currentExerciseIndex >= _flatExercises.length) {
      _remainingExerciseDurationSeconds = 0;
      return;
    }

    if (_remainingExerciseDurationSeconds <= 0) return;
    if (_currentExercise == null) return;

    if (mounted) {
      setState(() {
        _isExerciseDurationCountdownRunning = true;
      });
    } else {
      _isExerciseDurationCountdownRunning = true;
    }

    _exerciseDurationCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        _isExerciseDurationCountdownRunning = false;
        return;
      }

      if (_remainingExerciseDurationSeconds > 0) {
        setState(() {
          _remainingExerciseDurationSeconds--;
          _remainingExerciseDurationByExercise[_currentExerciseIndex] = _remainingExerciseDurationSeconds;
        });
      } else {
        timer.cancel();
        _isExerciseDurationCountdownRunning = false;
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

  bool _areAllSetsDone(Exercise? exercise) {
    if (exercise == null) return false;
    return _currentSetIndex >= exercise.sets.length;
  }

  bool _isExerciseDurationDone(Exercise? exercise) {
    if (exercise == null) return false;
    if (exercise.exerciseDuration <= 0) return true;
    return _remainingExerciseDurationSeconds <= 0;
  }

  bool _canProceedToNextExercise(Exercise? exercise) {
    return _areAllSetsDone(exercise) && _isExerciseDurationDone(exercise);
  }

  void _nextExercise() {
    if (_currentExerciseIndex >= _flatExercises.length - 1) return;
    final nextIndex = _currentExerciseIndex + 1;
    _persistCurrentExerciseState();
    _resolveExerciseForExecutionIndex(nextIndex);
    setState(() {
      _currentExerciseIndex = nextIndex;
      _restoreCurrentExerciseState();
      _initControllers();
    });

    _autoStartCurrentExerciseIfEligible();
  }

  void _endExercise() {
    _pauseDurationTimer?.cancel();
    _exerciseDurationCountdownTimer?.cancel();
    setState(() {
      _isFinished = true;
    });
  }

  Future<void> _handleBackPressedDuringWorkout() async {
    if (_tryResetChoiceSelectionOnBack()) return;
    if (_isBackDialogOpen) return;

    _isBackDialogOpen = true;
    final shouldFinish = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finish workout?'),
        content: const Text('Do you want to finish this workout now?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    _isBackDialogOpen = false;

    if (!mounted || shouldFinish != true) return;
    _endExercise();
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
      _autoStartCurrentExerciseIfEligible();
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
          _autoStartCurrentExerciseIfEligible();
        }
      });
    });
  }

  void _completeSet() {
    if (_flatExercises.isEmpty || _currentExerciseIndex >= _flatExercises.length) return;
    if (!_isCurrentExerciseStarted()) return;
    final exercise = _currentExercise;
    if (exercise == null) return;
    if (_currentSetIndex >= exercise.sets.length) return;

    final set = exercise.sets[_currentSetIndex];
    
    // Update model with current controller values before completing
    set.weight = double.tryParse(_weightControllers[_currentSetIndex]?.text ?? '') ?? set.weight;
    set.repetitions = int.tryParse(_repsControllers[_currentSetIndex]?.text ?? '') ?? set.repetitions;
    
    exercise.completeSet(_currentSetIndex, DateTime.now(), 2);
    _startPauseDurationTimer(exercise.pauseDuration);
    setState(() {
      _currentSetIndex++;
      _setIndexByExercise[_currentExerciseIndex] = _currentSetIndex;
    });
  }

  bool _hasDescription(Exercise exercise) => exercise.description.trim().isNotEmpty;

  void _selectChoiceExercise(int executionIndex, Exercise exercise) {
    if (executionIndex < 0 || executionIndex >= _flatExercises.length) return;

    setState(() {
      _flatExercises[executionIndex] = exercise;
      _resolvedBatchIndices.add(_batchIndexByExercise[executionIndex]);
      _navigatedAwayAfterChoice.remove(executionIndex);
      _initializeExerciseStateForIndex(executionIndex);

      if (executionIndex == _currentExerciseIndex) {
        _restoreCurrentExerciseState();
      }
    });

    if (executionIndex == _currentExerciseIndex) {
      _initControllers();
      _autoStartCurrentExerciseIfEligible();
    }
  }

  bool _tryResetChoiceSelectionOnBack() {
    if (!_isChoiceBatchMode) return false;
    if (_currentExerciseIndex < 0 || _currentExerciseIndex >= _flatExercises.length) return false;

    final currentExercise = _currentExercise;
    if (currentExercise == null) return false;

    final batch = _batchForExecutionIndex(_currentExerciseIndex);
    if (batch.length <= 1) return false;
    if (_navigatedAwayAfterChoice.contains(_currentExerciseIndex)) return false;
    if ((_setIndexByExercise[_currentExerciseIndex] ?? 0) > 0) return false;

    final hasStartedDurationTimer =
        currentExercise.exerciseDuration > 0 && _startedExerciseIndices.contains(_currentExerciseIndex);
    if (hasStartedDurationTimer || _isExerciseDurationCountdownRunning) return false;

    setState(() {
      _flatExercises[_currentExerciseIndex] = null;
      _resolvedBatchIndices.remove(_batchIndexByExercise[_currentExerciseIndex]);
      _navigatedAwayAfterChoice.remove(_currentExerciseIndex);

      _setIndexByExercise[_currentExerciseIndex] = 0;
      _remainingExerciseDurationByExercise[_currentExerciseIndex] = 0;
      _startedExerciseIndices.remove(_currentExerciseIndex);
      _currentSetIndex = 0;
      _remainingExerciseDurationSeconds = 0;
    });

    _initControllers();
    return true;
  }

  bool _hasSets(Exercise exercise) => exercise.sets.isNotEmpty;

  bool _showPauseDurationTimer(Exercise exercise) {
    return exercise.pauseDuration > 0 && _isPauseDurationTimerRunning;
  }

  bool _showExerciseDurationTimer(Exercise exercise) {
    return _isCurrentExerciseStarted() &&
        exercise.exerciseDuration > 0 &&
        _isExerciseDurationCountdownRunning &&
        _remainingExerciseDurationSeconds > 0;
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

  Widget _buildExerciseProgressOverview({bool highlightCurrent = true}) {
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
                  final isActive = highlightCurrent && index == _currentExerciseIndex;
                  final isCompleted = _isExerciseFullyCompleted(index);
                  final exercise = _exerciseAt(index);
                  final label = exercise?.name ?? '${index + 1}';

                  final backgroundColor = isActive
                      ? Colors.blue
                      : (isCompleted ? Colors.green : Colors.grey.withValues(alpha: 0.35));

                  final textColor = isActive || isCompleted ? Colors.white : Colors.black54;

                  return Padding(
                    padding: EdgeInsets.only(right: index == count - 1 ? 0 : gap),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: blockWidth,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                          label,
                        textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
    final isCurrent = _isCurrentExerciseStarted() && index == _currentSetIndex;
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

  Widget _buildStartExerciseButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _startCurrentExercise,
        child: const Text(
          'startExercise();',
          style: TextStyle(fontFamily: 'monospace'),
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

  Widget _buildChoiceButtonsSection(int executionIndex) {
    final batch = _batchForExecutionIndex(executionIndex);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'chooseExercise();',
          style: TextStyle(fontFamily: 'monospace', fontSize: 18),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        for (int i = 0; i < batch.length; i++) ...[
          ElevatedButton(
            onPressed: () => _selectChoiceExercise(executionIndex, batch[i]),
            child: Text(
              batch[i].name,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
          if (i < batch.length - 1)
            const SizedBox(height: 8),
        ],
      ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isFinished) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.workout.name)),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildExerciseProgressOverview(highlightCurrent: false),
                const SizedBox(height: 24),
                const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Workout.complete();',
                          style: TextStyle(fontFamily: 'monospace', fontSize: 20, color: Colors.green),
                        ),
                        SizedBox(height: 20),
                        Text('Congratulations!', style: TextStyle(fontSize: 24)),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'returnToMain();',
                      style: TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                ),
              ],
            ),
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

    final exercise = _currentExercise;
    final needsChoiceSelection = _requiresChoiceSelectionAt(_currentExerciseIndex);
    final isLastExercise = _currentExerciseIndex == _flatExercises.length - 1;
    final canProceedToNextExercise = _canProceedToNextExercise(exercise) ||
        (_isPauseDurationTimerRunning &&
            _areAllSetsDone(exercise) &&
            ((exercise?.exerciseDuration ?? 0) <= 0));
    final exerciseActionLabel = isLastExercise ? 'endExercise();' : 'nextExercise();';
    final hasSets = exercise != null && _hasSets(exercise);
    final showStartExerciseButton = exercise != null && _shouldShowStartExerciseButton(exercise);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBackPressedDuringWorkout();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(widget.workout.name)),
        body: SafeArea(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragEnd: (details) {
              if (!_canSwipeExercises()) return;

              final velocity = details.primaryVelocity ?? 0;
              if (velocity.abs() < 200) return;

              if (velocity < 0) {
                _goToExercise(_currentExerciseIndex + 1);
              } else {
                _goToExercise(_currentExerciseIndex - 1);
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildExerciseProgressOverview(),
                  const SizedBox(height: 16),
                  if (needsChoiceSelection)
                    _buildChoiceButtonsSection(_currentExerciseIndex)
                  else if (exercise != null) ...[
                    _buildExerciseTitleAndDescription(exercise),
                    const SizedBox(height: 30),
                  ],

                  if (hasSets) _buildSetTableSection(exercise) else const Spacer(),

                  if (exercise != null && _showPauseDurationTimer(exercise)) _buildPauseTimerSection(),
                  if (showStartExerciseButton) _buildStartExerciseButton(),
                  if (exercise != null && _showExerciseDurationTimer(exercise)) _buildExerciseDurationSection(),
                  _buildExerciseActionButton(
                    canProceedToNextExercise: canProceedToNextExercise,
                    exerciseActionLabel: exerciseActionLabel,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

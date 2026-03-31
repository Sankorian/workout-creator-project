import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/workout.dart';
import '../models/exercise.dart';

/// Executes a workout across batches, sets, pauses, and timed exercises.
class WorkoutExecutionScreen extends StatefulWidget {
  final Workout workout;

  const WorkoutExecutionScreen({super.key, required this.workout});

  @override
  State<WorkoutExecutionScreen> createState() => _WorkoutExecutionScreenState();
}

class _WorkoutExecutionScreenState extends State<WorkoutExecutionScreen> {
  // Flattened execution lane. Index == UI card index.
  // In choice mode, unresolved multi-exercise batches are represented as null entries.
  late List<Exercise?> _flatExercises;
  // Maps execution index -> original workout batch index.
  final List<int> _batchIndexByExercise = [];
  // Tracks which batches already resolved to a concrete exercise for single-slot modes.
  final Set<int> _resolvedBatchIndices = {};
  // Remembers choice cards the user already left, so back no longer resets that choice.
  final Set<int> _navigatedAwayAfterChoice = {};
  // Active card index in _flatExercises.
  int _currentExerciseIndex = 0;
  // Active set pointer for the currently visible exercise.
  int _currentSetIndex = 0;
  
  // Pause timer between sets.
  Timer? _pauseDurationTimer;
  // Countdown timer for time-based exercises.
  Timer? _exerciseDurationCountdownTimer;
  // Live pause countdown value shown in UI.
  int _remainingPauseDurationSeconds = 0;
  // Live exercise countdown value shown in UI.
  int _remainingExerciseDurationSeconds = 0;
  // Whether pause timer is currently ticking.
  bool _isPauseDurationTimerRunning = false;
  // Whether exercise countdown is currently ticking.
  bool _isExerciseDurationCountdownRunning = false;
  // Toggles finish screen.
  bool _isFinished = false;
  // Dialog reentrancy guard for repeated back presses.
  bool _isBackDialogOpen = false;

  // Per-exercise persisted runtime state (used when navigating away and back).
  final Map<int, int> _setIndexByExercise = {};
  final Map<int, int> _remainingExerciseDurationByExercise = {};
  // Exercises that were explicitly started (relevant for timed execution).
  final Set<int> _startedExerciseIndices = {};

  // Controllers for editable table cells of current exercise.
  final Map<int, TextEditingController> _weightControllers = {};
  final Map<int, TextEditingController> _repsControllers = {};

  @override
  void initState() {
    super.initState();
    // 1) Build execution order and placeholders depending on workout mode.
    _initializeExecutionExercises();

    // 2) Seed runtime state for every execution slot.
    for (int i = 0; i < _flatExercises.length; i++) {
      _initializeExerciseStateForIndex(i);
    }

    // 3) Sync state + controllers for initially visible card.
    _restoreCurrentExerciseState();
    _initControllers();

    // 4) Run auto-start after first frame to avoid init-time setState/timer edge cases.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _autoStartCurrentExerciseIfEligible();
    });
  }

  bool get _usesSingleExercisePerBatch {
    // Choice always shows one slot per batch, resolved by user selection.
    if (widget.workout.batchType == BatchType.choice) return true;
    // randomPick/alternating also keep one active slot per batch.
    return widget.workout.batchType == BatchType.randomPick ||
        widget.workout.batchType == BatchType.alternating;
  }

  bool get _isChoiceBatchMode => widget.workout.batchType == BatchType.choice;

  List<Exercise> _batchForExecutionIndex(int executionIndex) {
    // Resolve back from execution lane index to source batch.
    final batchIndex = _batchIndexByExercise[executionIndex];
    return widget.workout.batches[batchIndex];
  }

  Exercise? _exerciseAt(int executionIndex) {
    // Safe index access helper.
    if (executionIndex < 0 || executionIndex >= _flatExercises.length) return null;
    return _flatExercises[executionIndex];
  }

  Exercise? get _currentExercise => _exerciseAt(_currentExerciseIndex);

  bool _requiresChoiceSelectionAt(int executionIndex) {
    // Only choice mode can have unresolved placeholders.
    if (!_isChoiceBatchMode) return false;
    if (executionIndex < 0 || executionIndex >= _flatExercises.length) return false;
    final batch = _batchForExecutionIndex(executionIndex);
    // A batch with multiple options requires a selection while current slot is null.
    return batch.length > 1 && _flatExercises[executionIndex] == null;
  }

  void _initializeExerciseStateForIndex(int executionIndex) {
    final exercise = _exerciseAt(executionIndex);
    // Every exercise starts from the first set.
    _setIndexByExercise[executionIndex] = 0;
    // Timed exercises start with their configured duration.
    _remainingExerciseDurationByExercise[executionIndex] = exercise?.exerciseDuration ?? 0;
    // Non-timed exercises are effectively "started" immediately.
    if (exercise != null && exercise.exerciseDuration <= 0) {
      _startedExerciseIndices.add(executionIndex);
    } else {
      _startedExerciseIndices.remove(executionIndex);
    }
  }

  void _initializeExecutionExercises() {
    // Rebuild lane from workout model from scratch.
    _batchIndexByExercise.clear();
    _resolvedBatchIndices.clear();

    // Single-exercise modes resolve one slot per batch (choice may stay unresolved initially).
    if (_usesSingleExercisePerBatch) {
      // Build batch order and drop empty batches from execution.
      final batchOrder = List<int>.generate(widget.workout.batches.length, (i) => i)
          .where((batchIndex) => widget.workout.batches[batchIndex].isNotEmpty)
          .toList();

      // Optional batch order randomization happens before slot creation.
      if (widget.workout.randomBatchOrder) {
        batchOrder.shuffle();
      }

      _batchIndexByExercise.addAll(batchOrder);
      if (_isChoiceBatchMode) {
        // Multi-exercise choice batches start unresolved until user chooses.
        _flatExercises = [
          for (final batchIndex in batchOrder)
            // Single-option choice batch can be auto-resolved immediately.
            widget.workout.batches[batchIndex].length == 1
                ? widget.workout.batches[batchIndex].first
                : null,
        ];

        // Pre-mark batches that were already resolved above.
        for (int i = 0; i < _flatExercises.length; i++) {
          if (_flatExercises[i] != null) {
            _resolvedBatchIndices.add(_batchIndexByExercise[i]);
          }
        }
      } else {
        // randomPick/alternating initialize with first entries; resolution refines per mode.
        _flatExercises = [
          for (final batchIndex in batchOrder) widget.workout.batches[batchIndex].first,
        ];

        // Resolve first slot up-front so mode-specific selection logic is applied immediately.
        if (_flatExercises.isNotEmpty) {
          _resolveExerciseForExecutionIndex(0);
        }
      }
      return;
    }

    final entries = <MapEntry<int, Exercise>>[];
    // Multi-exercise mode flattens all exercises into one execution lane.
    for (int batchIndex = 0; batchIndex < widget.workout.batches.length; batchIndex++) {
      for (final exercise in widget.workout.batches[batchIndex]) {
        entries.add(MapEntry(batchIndex, exercise));
      }
    }

    if (widget.workout.randomBatchOrder) {
      // In multi-exercise mode this shuffles all flattened entries, not just batch groups.
      entries.shuffle();
    }

    _batchIndexByExercise.addAll(entries.map((entry) => entry.key));
    _flatExercises = entries.map((entry) => entry.value).toList();
  }

  void _resolveExerciseForExecutionIndex(int exerciseIndex) {
    // Only relevant in single-slot non-choice modes.
    if (!_usesSingleExercisePerBatch) return;
    if (exerciseIndex < 0 || exerciseIndex >= _flatExercises.length) return;
    if (_isChoiceBatchMode) return;

    final batchIndex = _batchIndexByExercise[exerciseIndex];
    if (_resolvedBatchIndices.contains(batchIndex)) return;

    final batch = widget.workout.batches[batchIndex];
    if (batch.isEmpty) return;

    // Pick exercise according to mode semantics.
    final selectedExercise = switch (widget.workout.batchType) {
      BatchType.randomPick => batch[Random().nextInt(batch.length)],
      BatchType.alternating => batch.first,
      _ => batch.first,
    };

    // Alternating mode rotates the source batch so the next visit starts at a new exercise.
    if (widget.workout.batchType == BatchType.alternating && batch.length > 1) {
      final rotated = batch.removeAt(0);
      batch.add(rotated);
    }

    _flatExercises[exerciseIndex] = selectedExercise;
    // Reset state against resolved exercise because sets/duration may differ.
    _initializeExerciseStateForIndex(exerciseIndex);

    _resolvedBatchIndices.add(batchIndex);
  }

  void _initControllers() {
    // Recreate controllers whenever visible exercise changes.
    _disposeControllers();
    if (_flatExercises.isEmpty || _currentExerciseIndex >= _flatExercises.length) return;

    final exercise = _currentExercise;
    if (exercise == null) return;
    // Controllers are keyed by set index for inline editing.
    for (int i = 0; i < exercise.sets.length; i++) {
      _weightControllers[i] = TextEditingController(text: exercise.sets[i].weight.toString());
      _repsControllers[i] = TextEditingController(text: exercise.sets[i].repetitions.toString());
    }
  }

  void _disposeControllers() {
    // Prevent leaks by disposing stale text controllers before rebuilding.
    _weightControllers.forEach((_, c) => c.dispose());
    _repsControllers.forEach((_, c) => c.dispose());
    _weightControllers.clear();
    _repsControllers.clear();
  }

  @override
  void dispose() {
    // Clean up timers/controllers owned by this screen.
    _pauseDurationTimer?.cancel();
    _exerciseDurationCountdownTimer?.cancel();
    _disposeControllers();
    super.dispose();
  }

  void _persistCurrentExerciseState() {
    // Persist progress so navigation away/back restores the same point.
    _setIndexByExercise[_currentExerciseIndex] = _currentSetIndex;
    _remainingExerciseDurationByExercise[_currentExerciseIndex] = _remainingExerciseDurationSeconds;
  }

  void _restoreCurrentExerciseState() {
    if (_flatExercises.isEmpty || _currentExerciseIndex >= _flatExercises.length) return;

    // Read previously persisted set pointer for this execution slot.
    _currentSetIndex = _setIndexByExercise[_currentExerciseIndex] ?? 0;
    final exercise = _currentExercise;
    // Fall back to exercise defaults when nothing was persisted yet.
    _remainingExerciseDurationSeconds =
        _remainingExerciseDurationByExercise[_currentExerciseIndex] ??
            (exercise?.exerciseDuration ?? 0);
  }

  bool _isCurrentExerciseStarted() {
    // "Started" means user explicitly started the timed exercise (or exercise is non-timed).
    return _startedExerciseIndices.contains(_currentExerciseIndex);
  }

  bool _shouldShowStartExerciseButton(Exercise exercise) {
    // Start button is only for timed exercises that still have remaining duration.
    return exercise.exerciseDuration > 0 &&
        !_isCurrentExerciseStarted() &&
        _remainingExerciseDurationSeconds > 0;
  }

  void _autoStartCurrentExerciseIfEligible() {
    // Never auto-start if user can freely navigate/select exercises.
    if (widget.workout.allowExerciseSelection) return;
    if (_flatExercises.isEmpty || _currentExerciseIndex >= _flatExercises.length) return;

    final exercise = _currentExercise;
    if (exercise == null) return;
    if (!_shouldShowStartExerciseButton(exercise)) return;
    // Also block auto-start while resting between sets.
    if (_isPauseDurationTimerRunning) return;

    _startCurrentExercise();
  }

  bool _isExerciseFullyCompleted(int exerciseIndex) {
    if (exerciseIndex < 0 || exerciseIndex >= _flatExercises.length) return false;

    final exercise = _exerciseAt(exerciseIndex);
    if (exercise == null) return false;
    final setIndex = _setIndexByExercise[exerciseIndex] ?? 0;
    final allSetsDone = setIndex >= exercise.sets.length;
    // Timed part is complete if no duration exists or countdown reached zero.
    final durationDone = (exercise.exerciseDuration <= 0) ||
        ((_remainingExerciseDurationByExercise[exerciseIndex] ?? exercise.exerciseDuration) <= 0);

    // Completion is the conjunction of set progression and timer progression.
    return allSetsDone && durationDone;
  }

  bool _canSwipeExercises() {
    // Swiping is intentionally blocked while timed countdown is active.
    return widget.workout.allowExerciseSelection && !_isExerciseDurationCountdownRunning;
  }

  // Shared exercise transition path used by both swipe navigation and auto-next flow.
  void _switchToExercise(
    int index, {
    bool enforceSwipePermission = false,
    bool autoStartOnArrival = false,
  }) {
    if (index < 0 || index >= _flatExercises.length || index == _currentExerciseIndex) return;
    // For gesture navigation, enforce explicit swipe permission checks.
    if (enforceSwipePermission && !_canSwipeExercises()) return;

    // Track that we left a selected choice exercise (used by back-reset behavior).
    if (_isChoiceBatchMode && _currentExercise != null) {
      _navigatedAwayAfterChoice.add(_currentExerciseIndex);
    }

    // Persist old slot first, then resolve/restore new slot.
    _persistCurrentExerciseState();
    _resolveExerciseForExecutionIndex(index);
    setState(() {
      _currentExerciseIndex = index;
      _restoreCurrentExerciseState();
      _initControllers();
    });

    // Auto-start is used by programmatic transitions (e.g. after completion), not manual swipe.
    if (autoStartOnArrival) {
      _autoStartCurrentExerciseIfEligible();
    }
  }

  void _goToExercise(int index) {
    _switchToExercise(index, enforceSwipePermission: true);
  }

  void _startCurrentExercise() {
    if (_flatExercises.isEmpty || _currentExerciseIndex >= _flatExercises.length) return;
    final exercise = _currentExercise;
    if (exercise == null) return;

    setState(() {
      if (_isPauseDurationTimerRunning) {
        // Starting an exercise cancels any active pause countdown.
        _pauseDurationTimer?.cancel();
        _isPauseDurationTimerRunning = false;
        _remainingPauseDurationSeconds = 0;
      }

      // Mark this exercise as started (required for timed execution UI).
      _startedExerciseIndices.add(_currentExerciseIndex);
    });

    // Non-timed exercises have no countdown; timed ones start ticking now.
    if (exercise.exerciseDuration > 0 && _remainingExerciseDurationSeconds > 0) {
      _startExerciseDurationCountdown();
    }
  }

  void _startExerciseDurationCountdown() {
    // Restart countdown cleanly for current exercise.
    _exerciseDurationCountdownTimer?.cancel();
    _isExerciseDurationCountdownRunning = false;
    if (_flatExercises.isEmpty || _currentExerciseIndex >= _flatExercises.length) {
      _remainingExerciseDurationSeconds = 0;
      return;
    }

    // Nothing to tick if already finished or exercise unresolved.
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
        // Stop timer on disposal to avoid orphan callbacks.
        timer.cancel();
        _isExerciseDurationCountdownRunning = false;
        return;
      }

      if (_remainingExerciseDurationSeconds > 0) {
        setState(() {
          // Tick down and persist per-exercise remaining duration.
          _remainingExerciseDurationSeconds--;
          _remainingExerciseDurationByExercise[_currentExerciseIndex] = _remainingExerciseDurationSeconds;
        });
      } else {
        // Countdown finished for this exercise.
        timer.cancel();
        _isExerciseDurationCountdownRunning = false;
      }
    });
  }

  String _formatDuration(int totalSeconds) {
    // Render mm:ss for exercise timer text.
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final mm = minutes.toString().padLeft(2, '0');
    final ss = seconds.toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  bool _areAllSetsDone(Exercise? exercise) {
    // Set progression is complete when pointer moved past last configured set.
    if (exercise == null) return false;
    return _currentSetIndex >= exercise.sets.length;
  }

  bool _isExerciseDurationDone(Exercise? exercise) {
    // Untimed exercises are duration-complete by definition.
    if (exercise == null) return false;
    if (exercise.exerciseDuration <= 0) return true;
    return _remainingExerciseDurationSeconds <= 0;
  }

  bool _canProceedToNextExercise(Exercise? exercise) {
    // Proceed only after both dimensions are complete: sets + duration.
    return _areAllSetsDone(exercise) && _isExerciseDurationDone(exercise);
  }

  bool _hasMeaningfulProgress() {
    // Used on finish screen to decide whether to show encouragement text.
    for (int i = 0; i < _flatExercises.length; i++) {
      final exercise = _exerciseAt(i);
      if (exercise == null) continue;

      // Any completed set counts as progress.
      if ((_setIndexByExercise[i] ?? 0) > 0) return true;

      if (exercise.exerciseDuration > 0) {
        // Timed exercises count as progress once timer moved from its initial value.
        final remaining = _remainingExerciseDurationByExercise[i] ?? exercise.exerciseDuration;
        if (remaining < exercise.exerciseDuration) return true;
      }
    }
    return false;
  }

  int? _findNextUnfinishedExerciseIndex({required int fromIndex}) {
    // No next item exists in empty/single-item lanes.
    if (_flatExercises.isEmpty) return null;
    if (_flatExercises.length == 1) return null;

    for (int step = 1; step < _flatExercises.length; step++) {
      // Wrap around in circular order until an unfinished exercise is found.
      final candidateIndex = (fromIndex + step) % _flatExercises.length;
      if (!_isExerciseFullyCompleted(candidateIndex)) {
        return candidateIndex;
      }
    }

    return null;
  }

  void _moveToExercise(int nextIndex) {
    // Completion flow transitions should auto-start if workout rules allow it.
    _switchToExercise(nextIndex, autoStartOnArrival: true);
  }

  void _endExercise() {
    // Freeze all time-based side effects before showing completion UI.
    _pauseDurationTimer?.cancel();
    _exerciseDurationCountdownTimer?.cancel();
    setState(() {
      _isFinished = true;
    });
  }

  Future<void> _handleBackPressedDuringWorkout() async {
    // In choice mode, first try soft-undo of a fresh selection.
    if (_tryResetChoiceSelectionOnBack()) return;
    // Prevent stacked dialogs when back is tapped repeatedly.
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
    final exercise = _currentExercise;
    if (exercise != null) {
      // Finalize exercise-level effects (important for set-less/timed exercises).
      exercise.completeExercise(DateTime.now());
    }

    // Completion flows in circular order to support "finish later" selection patterns.
    final nextUnfinishedIndex = _findNextUnfinishedExerciseIndex(fromIndex: _currentExerciseIndex);
    if (nextUnfinishedIndex == null) {
      // No unfinished exercises remain.
      _endExercise();
      return;
    }
    // Jump to next unfinished card instead of forcing linear order.
    _moveToExercise(nextUnfinishedIndex);
  }

  void _startPauseDurationTimer(int seconds) {
    // Pause timer is single-instance; replace any previous one.
    _pauseDurationTimer?.cancel();
    if (seconds <= 0) {
      // Zero/negative pause means immediate continuation.
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
    // Pause timer gates progression and optional auto-start behavior.
    _pauseDurationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_remainingPauseDurationSeconds > 0) {
          _remainingPauseDurationSeconds--;
        } else {
          // Pause ended: unlock flow and auto-start if selection is fixed.
          _pauseDurationTimer?.cancel();
          _isPauseDurationTimerRunning = false;
          _autoStartCurrentExerciseIfEligible();
        }
      });
    });
  }

  void _completeSet() {
    // Guard all invalid states (no exercise, not started, or out-of-range pointer).
    if (_flatExercises.isEmpty || _currentExerciseIndex >= _flatExercises.length) return;
    if (!_isCurrentExerciseStarted()) return;
    final exercise = _currentExercise;
    if (exercise == null) return;
    if (_currentSetIndex >= exercise.sets.length) return;

    final set = exercise.sets[_currentSetIndex];
    
    // Persist edited set inputs before applying training effects.
    set.weight = double.tryParse(_weightControllers[_currentSetIndex]?.text ?? '') ?? set.weight;
    set.repetitions = int.tryParse(_repsControllers[_currentSetIndex]?.text ?? '') ?? set.repetitions;
    
    // Persist set completion into domain model and trigger configured rest phase.
    exercise.completeSet(_currentSetIndex, DateTime.now(), 2);
    _startPauseDurationTimer(exercise.pauseDuration);
    setState(() {
      // Advance set pointer and persist for cross-card navigation restore.
      _currentSetIndex++;
      _setIndexByExercise[_currentExerciseIndex] = _currentSetIndex;
    });
  }

  // Empty descriptions are suppressed to keep card layout compact.
  bool _hasDescription(Exercise exercise) => exercise.description.trim().isNotEmpty;

  void _selectChoiceExercise(int executionIndex, Exercise exercise) {
    // Ignore stale/out-of-range UI callbacks.
    if (executionIndex < 0 || executionIndex >= _flatExercises.length) return;

    setState(() {
      // Resolve this slot from null -> selected exercise.
      _flatExercises[executionIndex] = exercise;
      _resolvedBatchIndices.add(_batchIndexByExercise[executionIndex]);
      _navigatedAwayAfterChoice.remove(executionIndex);
      _initializeExerciseStateForIndex(executionIndex);

      if (executionIndex == _currentExerciseIndex) {
        // If current card changed, sync pointer/timer state immediately.
        _restoreCurrentExerciseState();
      }
    });

    if (executionIndex == _currentExerciseIndex) {
      // Current card changed from null->exercise; rebuild set inputs and possibly auto-start.
      _initControllers();
      _autoStartCurrentExerciseIfEligible();
    }
  }

  bool _tryResetChoiceSelectionOnBack() {
    // Reset-on-back is strictly limited to unresolved-progress choice cards.
    if (!_isChoiceBatchMode) return false;
    if (_currentExerciseIndex < 0 || _currentExerciseIndex >= _flatExercises.length) return false;

    final currentExercise = _currentExercise;
    if (currentExercise == null) return false;

    final batch = _batchForExecutionIndex(_currentExerciseIndex);
    // Only multi-option batches are reversible.
    if (batch.length <= 1) return false;
    // Once user navigated away, treat selection as committed.
    if (_navigatedAwayAfterChoice.contains(_currentExerciseIndex)) return false;
    // Any completed set makes selection durable.
    if ((_setIndexByExercise[_currentExerciseIndex] ?? 0) > 0) return false;

    final hasStartedDurationTimer =
        currentExercise.exerciseDuration > 0 && _startedExerciseIndices.contains(_currentExerciseIndex);
    // Active/started timed execution also makes selection durable.
    if (hasStartedDurationTimer || _isExerciseDurationCountdownRunning) return false;

    // Allow one-step undo of a fresh choice before any durable progress exists.
    // This keeps back behavior predictable in choice mode without losing completed work.
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

  // Set table is only rendered for exercises that actually define sets.
  bool _hasSets(Exercise exercise) => exercise.sets.isNotEmpty;

  bool _showPauseDurationTimer(Exercise exercise) {
    // Show pause timer only while actively counting down.
    return exercise.pauseDuration > 0 && _isPauseDurationTimerRunning;
  }

  bool _showExerciseDurationTimer(Exercise exercise) {
    // Show duration timer only during active countdown.
    return _isCurrentExerciseStarted() &&
        exercise.exerciseDuration > 0 &&
        _isExerciseDurationCountdownRunning &&
        _remainingExerciseDurationSeconds > 0;
  }

  Widget _buildExerciseTitleAndDescription(Exercise exercise) {
    // Header block for name + optional description text.
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
    // Responsive horizontal progress strip of all execution slots.
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = _flatExercises.length;
        if (count == 0) return const SizedBox.shrink();

        const minBlockWidth = 32.0;
        const gap = 8.0;

        final availableWidth = constraints.maxWidth;
        final stretchedBlockWidth =
            (availableWidth - (count - 1) * gap) / count;

        // Stretch when possible; once blocks get too small, keep min width and enable scrolling.
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
                  // Show exercise name when resolved, otherwise fallback ordinal label.
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
    // Column headers for the editable set table.
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
    // Current row is editable; previous rows are read-only and styled as done.
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
                      // Current set allows inline editing right before confirmation.
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
                // Tap to complete only on the active pending row.
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
    // Set table takes remaining vertical space between header and bottom action area.
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
    // Visual rest-state block shown between sets.
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
    // Active countdown block for timed exercises.
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
    // Explicit start gate for timed exercises before countdown begins.
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
    // Main bottom CTA; disabled until progression criteria are met.
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canProceedToNextExercise ? _completeExerciseAction : null,
        child: Text(exerciseActionLabel, style: const TextStyle(fontFamily: 'monospace')),
      ),
    );
  }

  Widget _buildChoiceButtonsSection(int executionIndex) {
    // Choice-mode selector shown when current card has not been resolved yet.
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
              // Resolve slot with selected candidate from this batch.
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
    // Branch 1: terminal state after user finished (or all exercises completed).
    if (_isFinished) {
      final didMakeProgress = _hasMeaningfulProgress();
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
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Workout complete',
                          style: TextStyle(fontFamily: 'monospace', fontSize: 20, color: Colors.green),
                        ),
                        // Only show encouragement when some measurable progress was made.
                        if (didMakeProgress) ...[
                          SizedBox(height: 20),
                          Text('Great work!', style: TextStyle(fontSize: 24)),
                        ],
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

    // Branch 2: defensive fallback for malformed/empty workouts.
    if (_flatExercises.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Workout')),
        body: const Center(child: Text('Error: No exercises found.', style: TextStyle(fontFamily: 'monospace'))),
      );
    }

    // Branch 3: active workout execution screen.
    final exercise = _currentExercise;
    // In choice mode, unresolved slot shows chooser instead of exercise details.
    final needsChoiceSelection = _requiresChoiceSelectionAt(_currentExerciseIndex);
    // Allow CTA during pause only if all sets are done for untimed exercises.
    final canProceedToNextExercise = _canProceedToNextExercise(exercise) ||
        (_isPauseDurationTimerRunning &&
            _areAllSetsDone(exercise) &&
            ((exercise?.exerciseDuration ?? 0) <= 0));
    // Keep action copy consistent; handler still decides whether to advance or finish.
    const exerciseActionLabel = 'endExercise();';
    // Layout decisions for middle content and timer/start controls.
    final hasSets = exercise != null && _hasSets(exercise);
    final showStartExerciseButton = exercise != null && _shouldShowStartExerciseButton(exercise);

    return PopScope(
      // Back is handled manually to support reset-choice and confirm-finish logic.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        // Intercept system back to preserve custom finish/choice-reset handling.
        _handleBackPressedDuringWorkout();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(widget.workout.name)),
        body: SafeArea(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragEnd: (details) {
              // Horizontal card navigation is available only under swipe-safe conditions.
              if (!_canSwipeExercises()) return;

              final velocity = details.primaryVelocity ?? 0;
              // Ignore slow drags so horizontal scroll gestures in set rows do not navigate cards.
              if (velocity.abs() < 200) return;

              if (velocity < 0) {
                // Left swipe -> next card.
                _goToExercise(_currentExerciseIndex + 1);
              } else {
                // Right swipe -> previous card.
                _goToExercise(_currentExerciseIndex - 1);
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Always show global progress across all execution slots.
                  _buildExerciseProgressOverview(),
                  const SizedBox(height: 16),
                  if (needsChoiceSelection)
                    _buildChoiceButtonsSection(_currentExerciseIndex)
                  else if (exercise != null) ...[
                    // Exercise detail header is hidden only when slot is unresolved.
                    _buildExerciseTitleAndDescription(exercise),
                    const SizedBox(height: 30),
                  ],

                  // Main middle area: either set table or flexible spacer for no-set exercises.
                  if (hasSets) _buildSetTableSection(exercise) else const Spacer(),

                  // Bottom stack: pause timer, optional start gate, exercise timer, final CTA.
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


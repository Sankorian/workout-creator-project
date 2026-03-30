import 'package:flutter/material.dart';
import '../models/muscle.dart';
import '../models/workout.dart';
import 'workout_execution_screen.dart';

enum _MuscleState {
  decaying,
  recovered,
  regenerating,
}

enum _DisplayMetric {
  recovered,
  decaying,
}

class _WorkoutMuscleStats {
  final int decayingCount;
  final int recoveredCount;
  final int regeneratingCount;

  const _WorkoutMuscleStats({
    required this.decayingCount,
    required this.recoveredCount,
    required this.regeneratingCount,
  });
}

/// Displays workouts ranked by selected muscle-readiness metric.
class WorkoutSelectionScreen extends StatefulWidget {
  final List<Workout> workouts;

  const WorkoutSelectionScreen({
    super.key,
    required this.workouts,
  });

  @override
  State<WorkoutSelectionScreen> createState() => _WorkoutSelectionScreenState();
}

class _WorkoutSelectionScreenState extends State<WorkoutSelectionScreen> {
  _DisplayMetric _displayMetric = _DisplayMetric.recovered;

  String get _metricHeaderText =>
      _displayMetric == _DisplayMetric.recovered ? 'Muscles ready' : 'Muscles decaying';

  // Sort ratio switches between recovered and decaying counts.
  double _ratioForMetric(_WorkoutMuscleStats stats, int totalMuscles) {
    if (totalMuscles <= 0) return 0.0;
    return _displayMetric == _DisplayMetric.recovered
        ? stats.recoveredCount / totalMuscles
        : stats.decayingCount / totalMuscles;
  }

  // Displayed counter mirrors the active header metric.
  int _countForMetric(_WorkoutMuscleStats stats) {
    return _displayMetric == _DisplayMetric.recovered
        ? stats.recoveredCount
        : stats.decayingCount;
  }

  void _toggleMetric() {
    setState(() {
      _displayMetric = _displayMetric == _DisplayMetric.recovered
          ? _DisplayMetric.decaying
          : _DisplayMetric.recovered;
    });
  }

  // Classifies each muscle into one lifecycle phase for summary counts.
  _MuscleState _classifyMuscleState(Muscle muscle, DateTime now) {
    if (muscle.lastTrained == null) {
      // Never trained muscles are shown as ready/recovered.
      return _MuscleState.recovered;
    }

    final recoveryEnd = muscle.tRecoveryEnd;
    if (recoveryEnd != null && now.isBefore(recoveryEnd)) {
      return _MuscleState.regenerating;
    }

    final decayStart = muscle.tDecayStart;
    if (decayStart != null && !now.isBefore(decayStart)) {
      return _MuscleState.decaying;
    }

    return _MuscleState.recovered;
  }

  _WorkoutMuscleStats _buildWorkoutMuscleStats(Workout workout, DateTime now) {
    final musclesById = <String, Muscle>{};

    for (final batch in workout.batches) {
      for (final exercise in batch) {
        for (final involvement in exercise.involvedMuscles) {
          musclesById[involvement.muscle.id] = involvement.muscle;
        }
      }
    }

    int decayingCount = 0;
    int recoveredCount = 0;
    int regeneratingCount = 0;

    for (final muscle in musclesById.values) {
      switch (_classifyMuscleState(muscle, now)) {
        case _MuscleState.decaying:
          decayingCount++;
          break;
        case _MuscleState.recovered:
          recoveredCount++;
          break;
        case _MuscleState.regenerating:
          regeneratingCount++;
          break;
      }
    }

    return _WorkoutMuscleStats(
      decayingCount: decayingCount,
      recoveredCount: recoveredCount,
      regeneratingCount: regeneratingCount,
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    // Build stats for each workout and sort by the active metric (highest first).
    final workoutStatsEntries = widget.workouts.map((workout) {
      final stats = _buildWorkoutMuscleStats(workout, now);
      final totalMuscles = stats.decayingCount + stats.recoveredCount + stats.regeneratingCount;
      return (
        workout: workout,
        stats: stats,
        totalMuscles: totalMuscles,
        metricRatio: _ratioForMetric(stats, totalMuscles),
      );
    }).toList();

    workoutStatsEntries.sort((a, b) => b.metricRatio.compareTo(a.metricRatio));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Workout'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Workout',
                    style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                  ),
                ),
                SizedBox(
                  width: 160,
                  child: GestureDetector(
                    onTap: _toggleMetric,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Text(
                        _metricHeaderText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            for (final entry in workoutStatsEntries) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: ElevatedButton(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => WorkoutExecutionScreen(workout: entry.workout),
                              ),
                            );
                            // Workout execution mutates muscle/exercise state; refresh rankings.
                            if (!mounted) return;
                            setState(() {});
                          },
                          style: ElevatedButton.styleFrom(
                            alignment: Alignment.centerLeft,
                          ),
                          child: Text(entry.workout.name, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 160,
                      child: Text(
                        '${_countForMetric(entry.stats)}/${entry.totalMuscles > 0 ? entry.totalMuscles : 0}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
            ],
          ],
        ),
      ),
    );
  }
}

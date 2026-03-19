import 'package:flutter/material.dart';
import '../models/muscle.dart';
import '../models/exercise.dart';
import 'create_muscle_screen.dart';
import 'create_exercise_screen.dart';

class ItemManagementScreen<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final String Function(T) labelBuilder;
  final List<Muscle>? availableMuscles;
  final VoidCallback? onSave; 

  const ItemManagementScreen({
    super.key,
    required this.title,
    required this.items,
    required this.labelBuilder,
    this.availableMuscles,
    this.onSave,
  });

  @override
  State<ItemManagementScreen<T>> createState() => _ItemManagementScreenState<T>();
}

class _ItemManagementScreenState<T> extends State<ItemManagementScreen<T>> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: ListView.builder(
          itemCount: widget.items.length + 1,
          itemBuilder: (context, index) {
            if (index == widget.items.length) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80.0),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    dynamic result;
                    if (widget.title == 'My Muscles') {
                      result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CreateMuscleScreen()),
                      );
                    } else if (widget.title == 'My Exercises') {
                      result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreateExerciseScreen(
                            availableMuscles: widget.availableMuscles ?? [],
                          ),
                        ),
                      );
                    }

                    if (result != null && result is T) {
                      setState(() => widget.items.add(result));
                      if (widget.onSave != null) widget.onSave!();
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('create new'),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                ),
              );
            }

            final item = widget.items[index];

            return ListTile(
              title: Text(widget.labelBuilder(item)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility),
                    onPressed: () {
                      if (item is Muscle) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreateMuscleScreen(
                              muscleToEdit: item,
                              isViewOnly: true,
                            ),
                          ),
                        );
                      } else if (item is Exercise) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreateExerciseScreen(
                              exerciseToEdit: item,
                              availableMuscles: widget.availableMuscles ?? [],
                              isViewOnly: true,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () async {
                      dynamic result;
                      if (item is Muscle) {
                        result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => CreateMuscleScreen(muscleToEdit: item)),
                        );
                      } else if (item is Exercise) {
                        result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreateExerciseScreen(
                              exerciseToEdit: item,
                              availableMuscles: widget.availableMuscles ?? [],
                            ),
                          ),
                        );
                      }

                      if (result != null && result is T) {
                        setState(() => widget.items[index] = result);
                        if (widget.onSave != null) widget.onSave!();
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _showDeleteConfirmation(context, index),
                  ),
                  IconButton(
                    icon: const Icon(Icons.content_copy),
                    onPressed: () {
                      final original = widget.items[index];
                      dynamic copy;
                      if (original is Muscle) {
                        copy = Muscle(
                          name: original.name,
                          growthLevel: original.growthLevel,
                          recoveryTime: original.recoveryTime,
                          decayStartTime: original.decayStartTime,
                          decayInterval: original.decayInterval,
                          growthRules: Set.from(original.growthRules),
                          decayRules: Set.from(original.decayRules),
                        );
                      } else if (original is Exercise) {
                        copy = Exercise(
                          name: original.name,
                          involvedMuscles: List.from(original.involvedMuscles),
                          oneRepetitionMax: original.oneRepetitionMax,
                          sets: original.sets.map((s) => ExerciseSet(
                            repetitions: s.repetitions,
                            weight: s.weight,
                          )).toList(),
                          pauseTimeSeconds: original.pauseTimeSeconds,
                        );
                      }
                      
                      if (copy != null && copy is T) {
                        setState(() => widget.items.add(copy));
                        if (widget.onSave != null) widget.onSave!();
                      }
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete Item"),
          content: const Text("Are you sure? This action cannot be undone."),
          actions: [
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    setState(() => widget.items.removeAt(index));
                    if (widget.onSave != null) widget.onSave!();
                    Navigator.of(context).pop();
                  },
                  child: const Text("DELETE", style: TextStyle(color: Colors.red)),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("CANCEL"),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

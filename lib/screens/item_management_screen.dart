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
  final VoidCallback? onSave; // Callback to trigger save

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
                      setState(() {
                        widget.items.add(result);
                      });
                      if (widget.onSave != null) widget.onSave!();
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('create new'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              );
            }

            return ListTile(
              title: Text(widget.labelBuilder(widget.items[index])),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: const Icon(Icons.visibility), onPressed: () {}),
                  IconButton(icon: const Icon(Icons.edit), onPressed: () {}),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      setState(() {
                        widget.items.removeAt(index);
                      });
                      if (widget.onSave != null) widget.onSave!();
                    },
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
                        setState(() {
                          widget.items.add(copy);
                        });
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
}

import 'package:flutter/material.dart';
import '../models/workout.dart';
import '../models/exercise.dart';

class CreateWorkoutScreen extends StatefulWidget {
  final Workout? workoutToEdit;
  final List<Exercise> availableExercises;
  final bool isViewOnly;

  const CreateWorkoutScreen({
    super.key,
    this.workoutToEdit,
    required this.availableExercises,
    this.isViewOnly = false,
  });

  @override
  State<CreateWorkoutScreen> createState() => _CreateWorkoutScreenState();
}

class _CreateWorkoutScreenState extends State<CreateWorkoutScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late WorkoutModus _selectedModus;
  late bool _randomOrder;
  final List<List<Exercise>> _batches = [];

  bool get _isEditing => widget.workoutToEdit != null && !widget.isViewOnly;
  bool get _isViewing => widget.isViewOnly;

  @override
  void initState() {
    super.initState();
    final w = widget.workoutToEdit;
    _nameController = TextEditingController(text: w?.name ?? 'My Workout');
    _descriptionController = TextEditingController(text: w?.description ?? 'Enter description...');
    _selectedModus = w?.modus ?? WorkoutModus.strict;
    _randomOrder = w?.randomBatchOrder ?? false;

    if (w != null) {
      for (var batch in w.batches) {
        _batches.add(List.from(batch));
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Widget _buildCodeLine(String label, Widget input) {
    String prefix = _isEditing ? '  ..$label = ' : '  $label: ';
    if (_isViewing) prefix = '  $label: ';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(prefix, style: const TextStyle(fontFamily: 'monospace', fontSize: 16)),
            input,
            Text(_isEditing || _isViewing ? ' ;' : ' ,', style: const TextStyle(fontFamily: 'monospace', fontSize: 16)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isViewing ? 'View Workout' : (_isEditing ? 'Edit Workout' : 'Create Workout'))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_isViewing ? 'final myWorkout = Workout(' : (_isEditing ? 'workoutToEdit' : 'final newWorkout = Workout('), 
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 16)),
                _buildCodeLine('name', _isViewing 
                  ? Text('"${_nameController.text}"', 
                      style: const TextStyle(color: Colors.brown, fontFamily: 'monospace', fontSize: 16))
                  : SizedBox(
                    width: 200,
                    child: TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                      style: const TextStyle(color: Colors.blue, fontFamily: 'monospace'),
                    ),
                  )),
                _buildCodeLine('description', _isViewing 
                  ? Text('"${_descriptionController.text}"', 
                      style: const TextStyle(color: Colors.brown, fontFamily: 'monospace', fontSize: 16))
                  : SizedBox(
                    width: 200,
                    child: TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                      style: const TextStyle(color: Colors.blue, fontFamily: 'monospace'),
                    ),
                  )),
                _buildCodeLine('modus', _isViewing 
                  ? Text('WorkoutModus.${_selectedModus.name}', 
                      style: const TextStyle(color: Colors.purple, fontFamily: 'monospace', fontSize: 16))
                  : DropdownButtonHideUnderline(
                    child: DropdownButton<WorkoutModus>(
                      value: _selectedModus,
                      isDense: true,
                      style: const TextStyle(color: Colors.purple, fontFamily: 'monospace', fontSize: 16),
                      items: WorkoutModus.values.map((m) => DropdownMenuItem(value: m, child: Text('WorkoutModus.${m.name}'))).toList(),
                      onChanged: (val) => setState(() => _selectedModus = val!),
                    ),
                  )),
                _buildCodeLine('randomBatchOrder', _isViewing 
                  ? Text(_randomOrder.toString(), style: const TextStyle(color: Colors.blue, fontFamily: 'monospace', fontSize: 16))
                  : InkWell(
                      onTap: () => setState(() => _randomOrder = !_randomOrder),
                      child: Text(
                        _randomOrder.toString(),
                        style: const TextStyle(color: Colors.blue, fontFamily: 'monospace', fontSize: 16),
                      ),
                    )),

                Padding(
                  padding: const EdgeInsets.only(left: 8.0, top: 8.0),
                  child: Text(_isEditing ? '  ..batches = [' : '  batches: [', 
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 16)),
                ),
                ..._batches.asMap().entries.map((entry) {
                  int batchIdx = entry.key;
                  List<Exercise> batch = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('[', style: TextStyle(fontFamily: 'monospace', fontSize: 14)),
                        ...batch.asMap().entries.map((eEntry) {
                          int exIdx = eEntry.key;
                          Exercise ex = eEntry.value;
                          return Padding(
                            padding: const EdgeInsets.only(left: 16.0),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  Text('Exercise(name: "${ex.name}"),', 
                                      style: const TextStyle(fontFamily: 'monospace', fontSize: 14, color: Colors.blue)),
                                  if (!_isViewing)
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, size: 16),
                                      onPressed: () => setState(() => batch.removeAt(exIdx)),
                                    )
                                ],
                              ),
                            ),
                          );
                        }),
                        if (!_isViewing)
                          Padding(
                            padding: const EdgeInsets.only(left: 16.0),
                            child: TextButton.icon(
                              onPressed: () => _showAddExerciseToBatchDialog(batchIdx),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add Exercise', style: TextStyle(fontFamily: 'monospace')),
                            ),
                          ),
                        Row(
                          children: [
                            const Text('],', style: TextStyle(fontFamily: 'monospace', fontSize: 14)),
                            if (!_isViewing)
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, size: 20),
                                onPressed: () => setState(() => _batches.removeAt(batchIdx)),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
                if (!_isViewing)
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: TextButton.icon(
                      onPressed: () => setState(() => _batches.add([])),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Batch', style: TextStyle(fontFamily: 'monospace')),
                    ),
                  ),
                const Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: Text('  ],', style: TextStyle(fontFamily: 'monospace', fontSize: 16)),
                ),

                if (_isViewing || !_isEditing)
                  const Text(');', style: TextStyle(fontFamily: 'monospace', fontSize: 16)),
                
                if (!_isEditing && !_isViewing) ...[
                  const SizedBox(height: 20),
                  const Text('myWorkouts.add(newWorkout);', style: TextStyle(fontFamily: 'monospace', fontSize: 16)),
                ],
                
                const SizedBox(height: 40),
                if (!_isViewing)
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          // Validation: Ensure at least one exercise in at least one batch
                          bool hasExercise = _batches.any((batch) => batch.isNotEmpty);
                          if (!hasExercise) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please add at least one exercise to a batch.')),
                            );
                            return;
                          }

                          final workout = Workout(
                            id: widget.workoutToEdit?.id,
                            name: _nameController.text,
                            description: _descriptionController.text,
                            modus: _selectedModus,
                            randomBatchOrder: _randomOrder,
                            batches: _batches,
                          );
                          Navigator.pop(context, workout);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(200, 50),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(_isEditing ? 'SAVE CHANGES' : 'EXECUTE'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddExerciseToBatchDialog(int batchIdx) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Exercise to Batch'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: widget.availableExercises.length,
            itemBuilder: (context, index) {
              final ex = widget.availableExercises[index];
              return ListTile(
                title: Text(ex.name),
                onTap: () {
                  setState(() => _batches[batchIdx].add(ex));
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../models/workout.dart';
import '../models/exercise.dart';

/// Screen for creating, editing, or viewing a [Workout].
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
  late BatchType _selectedBatchType;
  late bool _allowExerciseSelection;
  late bool _randomOrder;
  final List<List<Exercise>> _batches = [];
  final Set<String> _attributesWithComments = {};

  // Mode flags drive the code-like constructor presentation.
  bool get _isEditing => widget.workoutToEdit != null && !widget.isViewOnly;
  bool get _isViewing => widget.isViewOnly;

  String get _screenTitle =>
      _isViewing ? 'View Workout' : (_isEditing ? 'Edit Workout' : 'Create Workout');

  String get _openingLine =>
      _isViewing ? 'final myWorkout = Workout(' : (_isEditing ? 'workoutToEdit' : 'final newWorkout = Workout(');

  @override
  void initState() {
    super.initState();
    final w = widget.workoutToEdit;
    _nameController = TextEditingController(text: w?.name ?? 'My Workout');
    _selectedBatchType = w?.batchType ?? BatchType.alternating;
    _allowExerciseSelection = w?.allowExerciseSelection ?? true;
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
    super.dispose();
  }

  // Displays booleans as code-like values and toggles them in edit/create mode.
  Widget _buildToggleValue(bool value, {VoidCallback? onTap}) {
    final text = Text(
      value.toString(),
      style: const TextStyle(color: Colors.blue, fontFamily: 'monospace', fontSize: 16),
    );
    return _isViewing ? text : InkWell(onTap: onTap, child: text);
  }

  // Renders one constructor-like line in create/edit/view modes with optional comment above.
  Widget _buildCodeLine(String label, Widget input) {
    final prefix = _isEditing && !_isViewing ? '  ..' : '  ';
    final suffix = _isEditing || _isViewing ? ';' : ',';
    final hasComment = _attributesWithComments.contains(label);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Comment line that appears above the attribute
        if (hasComment)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 2.0),
            child: Text(
              '  /// placeholder',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ),
        // Main code line
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(prefix, style: const TextStyle(fontFamily: 'monospace', fontSize: 16)),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_attributesWithComments.contains(label)) {
                          _attributesWithComments.remove(label);
                        } else {
                          _attributesWithComments.add(label);
                        }
                      });
                    },
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                Text(' = ', style: const TextStyle(fontFamily: 'monospace', fontSize: 16)),
                input,
                const SizedBox(width: 4),
                Text(suffix, style: const TextStyle(fontFamily: 'monospace', fontSize: 16)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_screenTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_openingLine,
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
                _buildCodeLine('batchType', _isViewing 
                  ? Text('BatchType.${_selectedBatchType.name}', 
                      style: const TextStyle(color: Colors.purple, fontFamily: 'monospace', fontSize: 16))
                  : DropdownButtonHideUnderline(
                    child: DropdownButton<BatchType>(
                      value: _selectedBatchType,
                      isDense: true,
                      style: const TextStyle(color: Colors.purple, fontFamily: 'monospace', fontSize: 16),
                      items: BatchType.values.map((m) => DropdownMenuItem(value: m, child: Text('BatchType.${m.name}'))).toList(),
                      onChanged: (val) => setState(() => _selectedBatchType = val!),
                    ),
                  )),
                _buildCodeLine('allowExerciseSelection', _isViewing 
                  ? _buildToggleValue(_allowExerciseSelection)
                  : _buildToggleValue(
                      _allowExerciseSelection,
                      onTap: () => setState(() => _allowExerciseSelection = !_allowExerciseSelection),
                    )),
                _buildCodeLine('randomBatchOrder', _isViewing 
                  ? _buildToggleValue(_randomOrder)
                  : _buildToggleValue(
                      _randomOrder,
                      onTap: () => setState(() => _randomOrder = !_randomOrder),
                    )),

                // batches header with optional comment
                if (_attributesWithComments.contains('batches'))
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 2.0),
                    child: Text(
                      '  /// placeholder',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, top: 8.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_isEditing ? '  ..' : '  ', style: const TextStyle(fontFamily: 'monospace', fontSize: 16)),
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                if (_attributesWithComments.contains('batches')) {
                                  _attributesWithComments.remove('batches');
                                } else {
                                  _attributesWithComments.add('batches');
                                }
                              });
                            },
                            child: const Text(
                              'batches',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                        Text(_isEditing ? ' = [' : ': [', style: const TextStyle(fontFamily: 'monospace', fontSize: 16)),
                      ],
                    ),
                  ),
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
                          // Require at least one exercise across all batches.
                          final hasExercise = _batches.any((batch) => batch.isNotEmpty);
                          if (!hasExercise) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please add at least one exercise to a batch.')),
                            );
                            return;
                          }

                          final workout = Workout(
                            id: widget.workoutToEdit?.id,
                            name: _nameController.text,
                            batchType: _selectedBatchType,
                            allowExerciseSelection: _allowExerciseSelection,
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
                  // Add the selected exercise directly into the targeted batch.
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

import 'package:flutter/material.dart';
import '../models/exercise.dart';
import '../models/muscle.dart';

/// Screen for creating, editing, or viewing an [Exercise].
class CreateExerciseScreen extends StatefulWidget {
  final Exercise? exerciseToEdit;
  final List<Muscle> availableMuscles;
  final bool isViewOnly;

  const CreateExerciseScreen({
    super.key, 
    this.exerciseToEdit, 
    required this.availableMuscles,
    this.isViewOnly = false,
  });

  @override
  State<CreateExerciseScreen> createState() => _CreateExerciseScreenState();
}

class _CreateExerciseScreenState extends State<CreateExerciseScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _oneRepMaxController;
  late final TextEditingController _pauseDurationController;
  late final TextEditingController _durationController;

  final List<Inv> _involvedMuscles = [];
  final List<ExerciseSet> _sets = [];
  final Set<String> _attributesWithComments = {};

  // Mode flags drive the code-style layout and editability.
  bool get _isEditing => widget.exerciseToEdit != null && !widget.isViewOnly;
  bool get _isViewing => widget.isViewOnly;

  String get _screenTitle =>
      _isViewing ? 'View Exercise' : (_isEditing ? 'Edit Exercise' : 'Create Exercise');

  String get _openingLine => _isViewing
      ? 'final myExercise = Exercise('
      : (_isEditing ? 'exerciseToEdit' : 'final newExercise = Exercise(');

  String _formatOneRepMax(double value) => value.toStringAsFixed(2);

  // Normalizes numeric text while preserving a predictable cursor position.
  void _normalizeOneRepMaxText() {
    final parsed = double.tryParse(_oneRepMaxController.text);
    if (parsed == null) return;
    final formatted = _formatOneRepMax(parsed);
    _oneRepMaxController.value = _oneRepMaxController.value.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  @override
  void initState() {
    super.initState();
    final e = widget.exerciseToEdit;
    _nameController = TextEditingController(text: e?.name ?? 'My Exercise');
    _descriptionController = TextEditingController(text: e?.description ?? 'My Description');
    _oneRepMaxController = TextEditingController(
      text: _formatOneRepMax(e?.oneRepetitionMax ?? 20.0),
    );
    _pauseDurationController = TextEditingController(text: (e?.pauseDuration ?? 60).toString());
    _durationController = TextEditingController(text: (e?.exerciseDuration ?? 0).toString());
    
    if (e != null) {
      _involvedMuscles.addAll(e.involvedMuscles);
      _sets.addAll(e.sets);
    } else {
      _sets.add(ExerciseSet(repetitions: 10, weight: 10.0));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _oneRepMaxController.dispose();
    _pauseDurationController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required double width,
    TextInputType? keyboardType,
    VoidCallback? onEditingComplete,
    ValueChanged<String>? onFieldSubmitted,
  }) {
    return SizedBox(
      width: width,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        onEditingComplete: onEditingComplete,
        onFieldSubmitted: onFieldSubmitted,
        decoration: const InputDecoration(isDense: true, border: InputBorder.none),
        style: const TextStyle(color: Colors.blue, fontFamily: 'monospace'),
      ),
    );
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
                  ? Text('"${_nameController.text}"', style: const TextStyle(color: Colors.brown, fontFamily: 'monospace', fontSize: 16))
                  : _buildInputField(controller: _nameController, width: 200)),
                _buildCodeLine('description', _isViewing 
                  ? Text('"${_descriptionController.text}"', style: const TextStyle(color: Colors.brown, fontFamily: 'monospace', fontSize: 16))
                  : _buildInputField(controller: _descriptionController, width: 200)),
                _buildCodeLine('oneRepetitionMax', _isViewing 
                  ? Text(_oneRepMaxController.text, style: const TextStyle(color: Colors.blue, fontFamily: 'monospace', fontSize: 16))
                  : _buildInputField(
                      controller: _oneRepMaxController,
                      width: 100,
                      keyboardType: TextInputType.number,
                      onEditingComplete: _normalizeOneRepMaxText,
                      onFieldSubmitted: (_) => _normalizeOneRepMaxText(),
                    )),
                _buildCodeLine('pauseDuration', _isViewing 
                  ? Text(_pauseDurationController.text, style: const TextStyle(color: Colors.blue, fontFamily: 'monospace', fontSize: 16))
                  : _buildInputField(
                      controller: _pauseDurationController,
                      width: 100,
                      keyboardType: TextInputType.number,
                    )),
                _buildCodeLine('exerciseDuration', _isViewing 
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_durationController.text, style: const TextStyle(color: Colors.blue, fontFamily: 'monospace', fontSize: 16)),
                      ],
                    )
                  : _buildInputField(
                      controller: _durationController,
                      width: 180,
                      keyboardType: TextInputType.number,
                    )),
                
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, top: 8.0),
                  child: Text(_isEditing ? '  ..involvedMuscles = [' : '  involvedMuscles: [', 
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 16)),
                ),
                ..._involvedMuscles.asMap().entries.map((entry) {
                  int idx = entry.key;
                  Inv inv = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Text('Inv(muscle: ${inv.muscle.name}, weight: ${inv.weight}),',
                              style: const TextStyle(fontFamily: 'monospace', fontSize: 14)),
                          if (!_isViewing)
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, size: 20),
                              onPressed: () => setState(() => _involvedMuscles.removeAt(idx)),
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
                      onPressed: _showAddMuscleDialog,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Muscle Involvement', style: TextStyle(fontFamily: 'monospace')),
                    ),
                  ),
                const Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: Text('  ],', style: TextStyle(fontFamily: 'monospace', fontSize: 16)),
                ),

                Padding(
                  padding: const EdgeInsets.only(left: 8.0, top: 8.0),
                  child: Text(_isEditing ? '  ..sets = [' : '  sets: [', 
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 16)),
                ),
                ..._sets.asMap().entries.map((entry) {
                  int idx = entry.key;
                  ExerciseSet s = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Text('Set(reps: ${s.repetitions}, weight: ${s.weight}),',
                              style: const TextStyle(fontFamily: 'monospace', fontSize: 14)),
                          if (!_isViewing)
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, size: 20),
                              onPressed: () => setState(() => _sets.removeAt(idx)),
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
                      onPressed: _showAddSetDialog,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Set', style: TextStyle(fontFamily: 'monospace')),
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
                  const Text('myExercises.add(newExercise);', style: TextStyle(fontFamily: 'monospace', fontSize: 16)),
                ],
                
                const SizedBox(height: 40),
                if (!_isViewing)
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          final exercise = Exercise(
                            id: widget.exerciseToEdit?.id,
                            name: _nameController.text,
                            description: _descriptionController.text,
                            oneRepetitionMax: double.tryParse(_oneRepMaxController.text) ?? 0.0,
                            pauseDuration: int.tryParse(_pauseDurationController.text) ?? 60,
                            exerciseDuration: int.tryParse(_durationController.text) ?? 0,
                            involvedMuscles: List.from(_involvedMuscles),
                            sets: List.from(_sets),
                          );
                          Navigator.pop(context, exercise);
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

  void _showAddMuscleDialog() {
    Muscle? selectedMuscle;
    double weight = 1.0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Muscle Involvement'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<Muscle>(
                hint: const Text('Select Muscle'),
                value: selectedMuscle,
                isExpanded: true,
                items: widget.availableMuscles.map((m) => DropdownMenuItem(value: m, child: Text(m.name))).toList(),
                onChanged: (val) => setDialogState(() => selectedMuscle = val),
              ),
              const SizedBox(height: 10),
              Text('Involvement Factor: ${weight.toStringAsFixed(1)}'),
              Slider(
                value: weight,
                min: 0.1,
                max: 1.0,
                divisions: 9,
                onChanged: (val) => setDialogState(() => weight = val),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                if (selectedMuscle != null) {
                  // Persist the current slider value with the selected muscle.
                  setState(() => _involvedMuscles.add(Inv(muscle: selectedMuscle!, weight: weight)));
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSetDialog() {
    final repsController = TextEditingController(text: '10');
    final weightController = TextEditingController(text: '10.0');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Set'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: repsController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Reps')),
            TextField(controller: weightController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Weight (kg)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              // Parse with defaults so partially filled dialogs still add a valid set.
              setState(() => _sets.add(ExerciseSet(
                repetitions: int.tryParse(repsController.text) ?? 10,
                weight: double.tryParse(weightController.text) ?? 10.0,
              )));
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

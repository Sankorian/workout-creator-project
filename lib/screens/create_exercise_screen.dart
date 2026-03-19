import 'package:flutter/material.dart';
import '../models/exercise.dart';
import '../models/muscle.dart';

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
  late final TextEditingController _oneRepMaxController;
  late final TextEditingController _pauseTimeController;

  final List<Inv> _involvedMuscles = [];
  final List<ExerciseSet> _sets = [];

  bool get _isEditing => widget.exerciseToEdit != null && !widget.isViewOnly;
  bool get _isViewing => widget.isViewOnly;

  @override
  void initState() {
    super.initState();
    final e = widget.exerciseToEdit;
    _nameController = TextEditingController(text: e?.name ?? 'Bench Press');
    _oneRepMaxController = TextEditingController(text: (e?.oneRepetitionMax ?? 100.0).toString());
    _pauseTimeController = TextEditingController(text: (e?.pauseTimeSeconds ?? 60).toString());
    
    if (e != null) {
      _involvedMuscles.addAll(e.involvedMuscles);
      _sets.addAll(e.sets);
    } else {
      _sets.add(ExerciseSet(repetitions: 10, weight: 80.0));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _oneRepMaxController.dispose();
    _pauseTimeController.dispose();
    super.dispose();
  }

  Widget _buildCodeLine(String label, Widget input) {
    String prefix = _isEditing ? '  ..$label = ' : '  $label: ';
    if (_isViewing) prefix = '  $label: ';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(prefix, style: const TextStyle(fontFamily: 'monospace', fontSize: 16)),
          Expanded(child: input),
          Text(_isEditing || _isViewing ? ';' : ',', style: const TextStyle(fontFamily: 'monospace', fontSize: 16)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isViewing ? 'View Exercise' : (_isEditing ? 'Edit Exercise' : 'Create Exercise'))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_isViewing ? 'final myExercise = Exercise(' : (_isEditing ? 'exerciseToEdit' : 'final newExercise = Exercise('), 
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 16)),
                _buildCodeLine('name', _isViewing 
                  ? Text('"${_nameController.text}"', style: const TextStyle(color: Colors.brown, fontFamily: 'monospace', fontSize: 16))
                  : TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                    style: const TextStyle(color: Colors.blue, fontFamily: 'monospace'),
                  )),
                _buildCodeLine('oneRepetitionMax', _isViewing 
                  ? Text(_oneRepMaxController.text, style: const TextStyle(color: Colors.blue, fontFamily: 'monospace', fontSize: 16))
                  : TextFormField(
                    controller: _oneRepMaxController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                    style: const TextStyle(color: Colors.blue, fontFamily: 'monospace'),
                  )),
                _buildCodeLine('pauseTimeSeconds', _isViewing 
                  ? Text(_pauseTimeController.text, style: const TextStyle(color: Colors.blue, fontFamily: 'monospace', fontSize: 16))
                  : TextFormField(
                    controller: _pauseTimeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                    style: const TextStyle(color: Colors.blue, fontFamily: 'monospace'),
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
                            oneRepetitionMax: double.tryParse(_oneRepMaxController.text) ?? 0.0,
                            pauseTimeSeconds: int.tryParse(_pauseTimeController.text) ?? 60,
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
    final weightController = TextEditingController(text: '80.0');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
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
                setState(() => _sets.add(ExerciseSet(
                  repetitions: int.tryParse(repsController.text) ?? 10,
                  weight: double.tryParse(weightController.text) ?? 0.0,
                )));
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

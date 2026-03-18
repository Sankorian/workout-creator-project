import 'package:flutter/material.dart';
import '../models/exercise.dart';
import '../models/muscle.dart';

class CreateExerciseScreen extends StatefulWidget {
  final List<Muscle> availableMuscles;

  const CreateExerciseScreen({super.key, required this.availableMuscles});

  @override
  State<CreateExerciseScreen> createState() => _CreateExerciseScreenState();
}

class _CreateExerciseScreenState extends State<CreateExerciseScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController(text: 'Bench Press');
  final _oneRepMaxController = TextEditingController(text: '100.0');
  final _pauseTimeController = TextEditingController(text: '60');

  final List<Inv> _involvedMuscles = [];
  final List<ExerciseSet> _sets = [
    ExerciseSet(repetitions: 10, weight: 80.0)
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _oneRepMaxController.dispose();
    _pauseTimeController.dispose();
    super.dispose();
  }

  Widget _buildCodeLine(String label, Widget input) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text('  $label: ',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 16)),
          Expanded(child: input),
          const Text(',',
              style: TextStyle(fontFamily: 'monospace', fontSize: 16)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Exercise')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('final newExercise = Exercise(',
                    style: TextStyle(fontFamily: 'monospace', fontSize: 16)),
                _buildCodeLine(
                    'name',
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                          isDense: true, border: InputBorder.none),
                      style: const TextStyle(
                          color: Colors.blue, fontFamily: 'monospace'),
                    )),
                _buildCodeLine(
                    'oneRepetitionMax',
                    TextFormField(
                      controller: _oneRepMaxController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          isDense: true, border: InputBorder.none),
                      style: const TextStyle(
                          color: Colors.blue, fontFamily: 'monospace'),
                    )),
                _buildCodeLine(
                    'pauseTimeSeconds',
                    TextFormField(
                      controller: _pauseTimeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          isDense: true, border: InputBorder.none),
                      style: const TextStyle(
                          color: Colors.blue, fontFamily: 'monospace'),
                    )),
                const Padding(
                  padding: EdgeInsets.only(left: 8.0, top: 8.0),
                  child: Text('  involvedMuscles: [',
                      style: TextStyle(fontFamily: 'monospace', fontSize: 16)),
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
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, size: 20),
                            onPressed: () => setState(() => _involvedMuscles.removeAt(idx)),
                          )
                        ],
                      ),
                    ),
                  );
                }),
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
                  child: Text('  ],',
                      style: TextStyle(fontFamily: 'monospace', fontSize: 16)),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 8.0, top: 8.0),
                  child: Text('  sets: [',
                      style: TextStyle(fontFamily: 'monospace', fontSize: 16)),
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
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, size: 20),
                            onPressed: () => setState(() => _sets.removeAt(idx)),
                          )
                        ],
                      ),
                    ),
                  );
                }),
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
                  child: Text('  ],',
                      style: TextStyle(fontFamily: 'monospace', fontSize: 16)),
                ),
                const Text(');',
                    style: TextStyle(fontFamily: 'monospace', fontSize: 16)),
                const SizedBox(height: 20),
                const Text('myExercises.add(newExercise);',
                    style: TextStyle(fontFamily: 'monospace', fontSize: 16)),
                const SizedBox(height: 40),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final exercise = Exercise(
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
                    child: const Text('EXECUTE'),
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

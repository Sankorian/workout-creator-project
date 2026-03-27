import 'package:flutter/material.dart';
import '../models/muscle.dart';
import '../models/muscle_rules.dart';

class CreateMuscleScreen extends StatefulWidget {
  final Muscle? muscleToEdit;
  final bool isViewOnly;

  const CreateMuscleScreen({super.key, this.muscleToEdit, this.isViewOnly = false});

  @override
  State<CreateMuscleScreen> createState() => _CreateMuscleScreenState();
}

class _CreateMuscleScreenState extends State<CreateMuscleScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late final TextEditingController _nameController;
  late final TextEditingController _growthLevelController;
  late final TextEditingController _recoveryTimeController;
  late final TextEditingController _decayStartTimeController;

  final List<GrowthRule> _availableGrowthRules = [
    const SimpleGrowthRule(),
    const IntensityGrowthRule(),
    const EffectiveRepsGrowthRule(),
    const TimingGrowthRule(),
  ];

  final List<DecayRule> _availableDecayRules = [
    const PassiveDecayRule(),
    const InactivityDecayRule(),
  ];

  final Set<GrowthRule> _selectedGrowthRules = {};
  final Set<DecayRule> _selectedDecayRules = {};

  bool get _isEditing => widget.muscleToEdit != null && !widget.isViewOnly;
  bool get _isViewing => widget.isViewOnly;

  @override
  void initState() {
    super.initState();
    final m = widget.muscleToEdit;
    
    if (m != null) {
      _nameController = TextEditingController(text: m.name);
      _growthLevelController = TextEditingController(text: m.growthLevel.toString());
      _recoveryTimeController = TextEditingController(text: m.recoveryTime.toString());
      _decayStartTimeController = TextEditingController(text: m.decayStartTime.toString());
      _selectedGrowthRules.addAll(m.growthRules);
      _selectedDecayRules.addAll(m.decayRules);
    } else {
      _nameController = TextEditingController(text: 'Biceps');
      _growthLevelController = TextEditingController(text: '0.0');
      _recoveryTimeController = TextEditingController(text: '2.0');
      _decayStartTimeController = TextEditingController(text: '10.0');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _growthLevelController.dispose();
    _recoveryTimeController.dispose();
    _decayStartTimeController.dispose();
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
            const SizedBox(width: 4),
            Text(_isEditing || _isViewing ? ';' : ',', style: const TextStyle(fontFamily: 'monospace', fontSize: 16)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isViewing ? 'View Muscle' : (_isEditing ? 'Edit Muscle' : 'Create Muscle'))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_isViewing ? 'final myMuscle = Muscle(' : (_isEditing ? 'muscleToEdit' : 'final newMuscle = Muscle('), 
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 16)),
                _buildCodeLine('name', _isViewing 
                  ? Text('"${_nameController.text}"', style: const TextStyle(color: Colors.brown, fontFamily: 'monospace', fontSize: 16))
                  : SizedBox(
                      width: 200,
                      child: TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                        style: const TextStyle(color: Colors.blue, fontFamily: 'monospace'),
                      ),
                    )),
                _buildCodeLine('growthLevel', _isViewing 
                  ? Text(_growthLevelController.text, style: const TextStyle(color: Colors.blue, fontFamily: 'monospace', fontSize: 16))
                  : SizedBox(
                      width: 100,
                      child: TextFormField(
                        controller: _growthLevelController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                        style: const TextStyle(color: Colors.blue, fontFamily: 'monospace'),
                      ),
                    )),
                _buildCodeLine('recoveryTime', _isViewing 
                  ? Text(_recoveryTimeController.text, style: const TextStyle(color: Colors.blue, fontFamily: 'monospace', fontSize: 16))
                  : SizedBox(
                      width: 100,
                      child: TextFormField(
                        controller: _recoveryTimeController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                        style: const TextStyle(color: Colors.blue, fontFamily: 'monospace'),
                      ),
                    )),
                _buildCodeLine('decayStartTime', _isViewing 
                  ? Text(_decayStartTimeController.text, style: const TextStyle(color: Colors.blue, fontFamily: 'monospace', fontSize: 16))
                  : SizedBox(
                      width: 100,
                      child: TextFormField(
                        controller: _decayStartTimeController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                        style: const TextStyle(color: Colors.blue, fontFamily: 'monospace'),
                      ),
                    )),
                
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, top: 8.0),
                  child: Text(_isEditing ? '  ..growthRules = [' : '  growthRules: [', 
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 16)),
                ),
                if (_isViewing)
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Text(_selectedGrowthRules.map((r) => r.name).join(', '), 
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 16, color: Colors.blue)),
                    ),
                  )
                else
                  ..._availableGrowthRules.map((rule) => CheckboxListTile(
                    title: Text(rule.name, style: const TextStyle(fontFamily: 'monospace')),
                    value: _selectedGrowthRules.any((r) => r.name == rule.name),
                    onChanged: (val) {
                      setState(() {
                        if (val!) {
                          _selectedGrowthRules.add(rule);
                        } else {
                          _selectedGrowthRules.removeWhere((r) => r.name == rule.name);
                        }
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                  )),
                const Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: Text('  ],', style: TextStyle(fontFamily: 'monospace', fontSize: 16)),
                ),

                Padding(
                  padding: const EdgeInsets.only(left: 8.0, top: 8.0),
                  child: Text(_isEditing ? '  ..decayRules = [' : '  decayRules: [', 
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 16)),
                ),
                if (_isViewing)
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Text(_selectedDecayRules.map((r) => r.name).join(', '), 
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 16, color: Colors.blue)),
                    ),
                  )
                else
                  ..._availableDecayRules.map((rule) => CheckboxListTile(
                    title: Text(rule.name, style: const TextStyle(fontFamily: 'monospace')),
                    value: _selectedDecayRules.any((r) => r.name == rule.name),
                    onChanged: (val) {
                      setState(() {
                        if (val!) {
                          _selectedDecayRules.add(rule);
                        } else {
                          _selectedDecayRules.removeWhere((r) => r.name == rule.name);
                        }
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                  )),
                const Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: Text('  ],', style: TextStyle(fontFamily: 'monospace', fontSize: 16)),
                ),

                if (_isViewing || !_isEditing)
                  const Text(');', style: TextStyle(fontFamily: 'monospace', fontSize: 16)),
                
                if (!_isEditing && !_isViewing) ...[
                  const SizedBox(height: 20),
                  const Text('myMuscles.add(newMuscle);', style: TextStyle(fontFamily: 'monospace', fontSize: 16)),
                ],
                
                const SizedBox(height: 40),
                if (!_isViewing)
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          final muscle = Muscle(
                            id: widget.muscleToEdit?.id,
                            name: _nameController.text.isEmpty ? 'New Muscle' : _nameController.text,
                            growthLevel: double.tryParse(_growthLevelController.text) ?? 0.0,
                            recoveryTime: double.tryParse(_recoveryTimeController.text) ?? 2.0,
                            decayStartTime: double.tryParse(_decayStartTimeController.text) ?? 10.0,
                            lastTrained: widget.muscleToEdit?.lastTrained,
                            lastDecayed: widget.muscleToEdit?.lastDecayed,
                            growthRules: Set.from(_selectedGrowthRules),
                            decayRules: Set.from(_selectedDecayRules),
                          );
                          Navigator.pop(context, muscle);
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
}

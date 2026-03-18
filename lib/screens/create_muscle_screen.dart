import 'package:flutter/material.dart';
import '../models/muscle.dart';
import '../models/muscle_rules.dart';

class CreateMuscleScreen extends StatefulWidget {
  const CreateMuscleScreen({super.key});

  @override
  State<CreateMuscleScreen> createState() => _CreateMuscleScreenState();
}

class _CreateMuscleScreenState extends State<CreateMuscleScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController(text: 'Chest');
  final _growthLevelController = TextEditingController(text: '0.0');
  final _recoveryTimeController = TextEditingController(text: '3');
  final _decayStartTimeController = TextEditingController(text: '10');
  final _decayIntervalController = TextEditingController(text: '5');

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

  @override
  void dispose() {
    _nameController.dispose();
    _growthLevelController.dispose();
    _recoveryTimeController.dispose();
    _decayStartTimeController.dispose();
    _decayIntervalController.dispose();
    super.dispose();
  }

  Widget _buildCodeLine(String label, Widget input) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text('  $label: ', style: const TextStyle(fontFamily: 'monospace', fontSize: 16)),
          Expanded(child: input),
          const Text(',', style: TextStyle(fontFamily: 'monospace', fontSize: 16)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use SafeArea to avoid system overlays like the navigation bar
    return Scaffold(
      appBar: AppBar(title: const Text('Create Muscle')),
      body: SafeArea(
        child: SingleChildScrollView(
          // Add extra padding at the bottom to ensure the EXECUTE button is easily reachable
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('final newMuscle = Muscle(', style: TextStyle(fontFamily: 'monospace', fontSize: 16)),
                _buildCodeLine('name', TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                  style: const TextStyle(color: Colors.blue, fontFamily: 'monospace'),
                )),
                _buildCodeLine('growthLevel', TextFormField(
                  controller: _growthLevelController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                  style: const TextStyle(color: Colors.blue, fontFamily: 'monospace'),
                )),
                _buildCodeLine('recoveryTime', TextFormField(
                  controller: _recoveryTimeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                  style: const TextStyle(color: Colors.blue, fontFamily: 'monospace'),
                )),
                _buildCodeLine('decayStartTime', TextFormField(
                  controller: _decayStartTimeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                  style: const TextStyle(color: Colors.blue, fontFamily: 'monospace'),
                )),
                _buildCodeLine('decayInterval', TextFormField(
                  controller: _decayIntervalController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                  style: const TextStyle(color: Colors.blue, fontFamily: 'monospace'),
                )),
                
                const Padding(
                  padding: EdgeInsets.only(left: 8.0, top: 8.0),
                  child: Text('  growthRules: [', style: TextStyle(fontFamily: 'monospace', fontSize: 16)),
                ),
                ..._availableGrowthRules.map((rule) => CheckboxListTile(
                  title: Text(rule.name, style: const TextStyle(fontFamily: 'monospace')),
                  value: _selectedGrowthRules.contains(rule),
                  onChanged: (val) {
                    setState(() {
                      val! ? _selectedGrowthRules.add(rule) : _selectedGrowthRules.remove(rule);
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                )),
                const Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: Text('  ],', style: TextStyle(fontFamily: 'monospace', fontSize: 16)),
                ),

                const Padding(
                  padding: EdgeInsets.only(left: 8.0, top: 8.0),
                  child: Text('  decayRules: [', style: TextStyle(fontFamily: 'monospace', fontSize: 16)),
                ),
                ..._availableDecayRules.map((rule) => CheckboxListTile(
                  title: Text(rule.name, style: const TextStyle(fontFamily: 'monospace')),
                  value: _selectedDecayRules.contains(rule),
                  onChanged: (val) {
                    setState(() {
                      val! ? _selectedDecayRules.add(rule) : _selectedDecayRules.remove(rule);
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                )),
                const Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: Text('  ],', style: TextStyle(fontFamily: 'monospace', fontSize: 16)),
                ),

                const Text(');', style: TextStyle(fontFamily: 'monospace', fontSize: 16)),
                const SizedBox(height: 20),
                const Text('myMuscles.add(newMuscle);', style: TextStyle(fontFamily: 'monospace', fontSize: 16)),
                
                const SizedBox(height: 40),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final muscle = Muscle(
                          name: _nameController.text,
                          growthLevel: double.tryParse(_growthLevelController.text) ?? 0.0,
                          recoveryTime: double.tryParse(_recoveryTimeController.text) ?? 2.0,
                          decayStartTime: double.tryParse(_decayStartTimeController.text) ?? 10.0,
                          decayInterval: double.tryParse(_decayIntervalController.text) ?? 5.0,
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
}

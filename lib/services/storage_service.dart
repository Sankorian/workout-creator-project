import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/muscle.dart';
import '../models/exercise.dart';

class StorageService {
  static const String _muscleFile = 'muscles.json';
  static const String _exerciseFile = 'exercises.json';

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> _getFile(String fileName) async {
    final path = await _localPath;
    return File('$path/$fileName');
  }

  Future<void> saveMuscles(List<Muscle> muscles) async {
    final file = await _getFile(_muscleFile);
    final String jsonString = jsonEncode(muscles.map((m) => m.toJson()).toList());
    await file.writeAsString(jsonString);
  }

  Future<List<Muscle>> loadMuscles() async {
    try {
      final file = await _getFile(_muscleFile);
      if (!await file.exists()) return [];
      final String jsonString = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((j) => Muscle.fromJson(j)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveExercises(List<Exercise> exercises) async {
    final file = await _getFile(_exerciseFile);
    final String jsonString = jsonEncode(exercises.map((e) => e.toJson()).toList());
    await file.writeAsString(jsonString);
  }

  Future<List<Exercise>> loadExercises(List<Muscle> availableMuscles) async {
    try {
      final file = await _getFile(_exerciseFile);
      if (!await file.exists()) return [];
      final String jsonString = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((j) => Exercise.fromJson(j, availableMuscles)).toList();
    } catch (e) {
      return [];
    }
  }
}

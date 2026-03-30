const Map<String, String> kAttributeExplanations = {
  // Shared
  'name': 'Display name shown in the UI and lists.',

  // Muscle
  'growthLevel': 'Current modeled growth value on a 0..100 asymptotic scale: growth uses growthLevel += totalGrowth * (1 - growthLevel / 100), so gains shrink as the value rises and 100 remains a theoretical limit that cannot be reached.',
  'recoveryTime': 'Recovery duration in days after a training event.',
  'decayStartTime': 'Days after training when inactivity decay can begin.',
  'growthRules': 'Rules that add growth during training based on your model.',
  'decayRules': 'Rules that reduce growth over time due to inactivity/decay.',

  // Exercise
  'description': 'Optional instructions shown during exercise execution.',
  'oneRepetitionMax': 'Best known 1RM in kilograms; used to estimate intensity.',
  'pauseDuration': 'Planned rest time in seconds between sets.',
  'exerciseDuration': 'Minimum timer duration in seconds for time-based execution.',
  'involvedMuscles': 'Muscles trained by this exercise with involvement weights.',
  'sets': 'Ordered set plan with reps and load for this exercise.',

  // Workout
  'batchType': 'How exercises are selected within each batch.',
  'allowExerciseSelection': 'Whether users can manually pick exercises in execution.',
  'randomBatchOrder': 'Whether batch order is shuffled at execution time.',
  'batches': 'Two-dimensional exercise groups; each inner list is one batch.',

  // Growth rules
  'growthRule_Simple': 'Baseline growth rule that always returns a fixed gain.',
  'growthRule_Intensity': 'Growth scales linearly with training intensity.',
  'growthRule_Timing': 'Growth depends on whether training timing is optimal.',

  // Decay rules
  'decayRule_Passive Decay': 'Applies continuous decay based on elapsed time.',
  'decayRule_Inactivity Decay': 'Applies decay only after the inactivity threshold.',
};

String attributeExplanationFor(String key) {
  return kAttributeExplanations[key] ?? 'No description available yet.';
}

String formatAttributeComment(String key, {String indent = '  '}) {
  return '$indent/// ${attributeExplanationFor(key)}';
}


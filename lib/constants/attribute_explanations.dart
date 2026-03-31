const Map<String, String> kAttributeExplanations = {
  // Shared
  'name': '(String) Display name shown in the UI and lists.',

  // Muscle
  'growthLevel': '(double) Current modeled growth value on a 0..100 asymptotic scale: growth uses growthLevel += totalGrowth * (1 - growthLevel / 100), so gains shrink as the value rises and 100 remains a theoretical limit that cannot be reached.',
  'recoveryTime': '(double) Recovery duration in days after a training event.',
  'decayStartTime': '(double) Days after training when inactivity decay can begin.',
  'growthRules': '(Set<GrowthRule>) Rules that add growth during training based on your model. Every rule gets this multiplier: (1 - growthLevel / 100). This guarantees that muscle grow gets slower the stronger the muscle is.',
  'decayRules': '(Set<DecayRule>) Rules that reduce growth over time due to inactivity/decay. Every rule gets this multiplier: (growthLevel / 100). This guarantees that muscle decay gets slower the weaker the muscle is.',

  // Exercise
  'description': '(String) Optional instructions shown during exercise execution.',
  'oneRepetitionMax': '(double) Best known 1RM in kilograms; This will be updated during every workout if the new calculated 1RM is higher than the old one via this formula: weight * (1 + reps / 30.0). The 1RM value is used to calculate intensity (intensity = currentWeight/1RM).',
  'pauseDuration': '(int) Planned rest time in seconds between sets. These pauses can be skipped.',
  'exerciseDuration': '(int) Minimum timer duration in seconds for time-based execution. Exercise cannot be finished before this timer runs out.',
  'involvedMuscles': '(List<Inv>) Muscles trained by this exercise with involvement factor. These factors will be used as a further multiplier when growth is calculated (0.5 leading only to half the normal gains)',
  'sets': '(List<ExerciseSet>) Ordered set plan with reps and load in kg for this exercise. If none are added the exercise has no sets and can be finished via the endExercise-button.',

  // Workout
  'batchType': '(WorkoutModus) How exercises are selected within each batch. Alternating rotates through batches, Choice allows the user to choose from all exercises in the batch and RandomPick picks one randomly, ',
  'allowExerciseSelection': '(bool) Whether users slide manually between all exercises and choose which one to do first; if set to false, exercises have to be done in strict order from first to last.',
  'randomBatchOrder': '(bool) Whether batch order is shuffled at execution time. Exercises within a batch stay in their order',
  'batches': '(List<List<Exercise>>) The outer list lists all the batches; the inner lists contain the exercises of these batches. Allows to build a variety of workouts together with the batchType.',

  // Growth rules
  'growthRule_Simple': '(Rule) Baseline growth rule that always returns a fixed gain. growthLevel is increased by 1 for every set the muscle is involved in (other multipliers will be applied too)',
  'growthRule_Intensity': '(Rule) This returns gains based on training intensity for each set. So if the set is done with 80% of the 1RM-load than growthLevel is increased by 0.8',
  'growthRule_Timing': '(Rule) Growth depends on whether timing of the set is optimal. If the set is done immediately after recovery time has passed, muscleGrowth will be increased by 1. This bonus decreases linearly until the decayStartTime is reached. After that only 0.1 will be added.',

  // Decay rules
  'decayRule_Passive Decay': '(Rule) Applies continuous decay based on elapsed time. muscleGrowth decreases by 0.1 per day ',
  'decayRule_Inactivity Decay': '(Rule) Applies decay only after the inactivity threshold defined through decayStartTime. muscleGrowth decreases then by 0.5 per day',
};

String attributeExplanationFor(String key) {
  return kAttributeExplanations[key] ?? 'No description available yet.';
}

String formatAttributeComment(String key, {String indent = '  '}) {
  return '$indent/// ${attributeExplanationFor(key)}';
}

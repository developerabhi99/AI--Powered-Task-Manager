class PeriodReport {
  final String period; // 'week', 'month', 'year'
  final DateTime from;
  final DateTime to;
  final int totalTasks;
  final int completedTasks;
  final int missedTasks;
  final Map<DateTime, int> dailyCompletions; // date → completed count
  final Map<DateTime, int> dailyTotal;       // date → total tasks that day
  final int streakDays;
  double rating;           // 0.0 – 5.0, user-given
  List<String> goodNotes; // "What went well"
  List<String> badNotes;  // "What to improve"

  PeriodReport({
    required this.period,
    required this.from,
    required this.to,
    required this.totalTasks,
    required this.completedTasks,
    required this.missedTasks,
    required this.dailyCompletions,
    required this.dailyTotal,
    required this.streakDays,
    this.rating = 0.0,
    this.goodNotes = const [],
    this.badNotes = const [],
  });

  double get completionRate =>
      totalTasks == 0 ? 0.0 : completedTasks / totalTasks;

  /// Day with the highest completions
  DateTime? get bestDay {
    if (dailyCompletions.isEmpty) return null;
    return dailyCompletions.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
  }

  /// Day with the lowest completions (but had tasks)
  DateTime? get worstDay {
    final withTasks = dailyTotal.entries.where((e) => e.value > 0);
    if (withTasks.isEmpty) return null;
    return withTasks
        .reduce((a, b) {
          final aRate = (dailyCompletions[a.key] ?? 0) / a.value;
          final bRate = (dailyCompletions[b.key] ?? 0) / b.value;
          return aRate <= bRate ? a : b;
        })
        .key;
  }
}

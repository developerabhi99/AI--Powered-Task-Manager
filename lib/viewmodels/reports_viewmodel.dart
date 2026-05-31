import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/report_model.dart';
import '../models/task_model.dart';

class ReportsViewModel extends ChangeNotifier {
  // Ratings & notes keyed by period string e.g. "week_2025_W22"
  final Map<String, double> _ratings = {};
  final Map<String, List<String>> _goodNotes = {};
  final Map<String, List<String>> _badNotes = {};

  List<TaskModel> _allTasks = [];

  ReportsViewModel() {
    _loadFromPrefs();
  }

  /// Called from TaskViewModel whenever tasks change
  void updateTasks(List<TaskModel> tasks) {
    _allTasks = tasks;
    notifyListeners();
  }

  // ── Period Keys ──────────────────────────────────────────────────────────
  String _weekKey(DateTime date) {
    final monday = date.subtract(Duration(days: date.weekday - 1));
    return 'week_${monday.year}_${monday.month}_${monday.day}';
  }

  String _monthKey(DateTime date) => 'month_${date.year}_${date.month}';
  String _yearKey(DateTime date) => 'year_${date.year}';

  // ── Report Generators ────────────────────────────────────────────────────
  PeriodReport getWeeklyReport([DateTime? forDate]) {
    final ref = forDate ?? DateTime.now();
    final monday = ref.subtract(Duration(days: ref.weekday - 1));
    final from = DateTime(monday.year, monday.month, monday.day);
    final to = from.add(const Duration(days: 6, hours: 23, minutes: 59));
    return _buildReport('week', from, to, _weekKey(ref));
  }

  PeriodReport getMonthlyReport([DateTime? forDate]) {
    final ref = forDate ?? DateTime.now();
    final from = DateTime(ref.year, ref.month, 1);
    final to = DateTime(ref.year, ref.month + 1, 0, 23, 59, 59);
    return _buildReport('month', from, to, _monthKey(ref));
  }

  PeriodReport getYearlyReport([DateTime? forDate]) {
    final ref = forDate ?? DateTime.now();
    final from = DateTime(ref.year, 1, 1);
    final to = DateTime(ref.year, 12, 31, 23, 59, 59);
    return _buildReport('year', from, to, _yearKey(ref));
  }

  PeriodReport _buildReport(String period, DateTime from, DateTime to, String key) {
    final tasks = _allTasks.where((t) {
      return t.dueDate.isAfter(from.subtract(const Duration(seconds: 1))) &&
             t.dueDate.isBefore(to.add(const Duration(seconds: 1)));
    }).toList();

    final completed = tasks.where((t) => t.isCompleted).length;
    final missed = tasks.where((t) => !t.isCompleted && t.dueDate.isBefore(DateTime.now())).length;

    // Build daily maps
    final Map<DateTime, int> dailyCompletions = {};
    final Map<DateTime, int> dailyTotal = {};

    for (final task in tasks) {
      final day = DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);
      dailyTotal[day] = (dailyTotal[day] ?? 0) + 1;
      if (task.isCompleted) {
        dailyCompletions[day] = (dailyCompletions[day] ?? 0) + 1;
      }
    }

    return PeriodReport(
      period: period,
      from: from,
      to: to,
      totalTasks: tasks.length,
      completedTasks: completed,
      missedTasks: missed,
      dailyCompletions: dailyCompletions,
      dailyTotal: dailyTotal,
      streakDays: _calculateStreak(),
      rating: _ratings[key] ?? 0.0,
      goodNotes: List.from(_goodNotes[key] ?? []),
      badNotes: List.from(_badNotes[key] ?? []),
    );
  }

  int _calculateStreak() {
    int streak = 0;
    DateTime day = DateTime.now();
    while (true) {
      final dayStart = DateTime(day.year, day.month, day.day);
      final dayEnd = dayStart.add(const Duration(hours: 23, minutes: 59));
      final dayTasks = _allTasks.where((t) =>
          t.dueDate.isAfter(dayStart.subtract(const Duration(seconds: 1))) &&
          t.dueDate.isBefore(dayEnd.add(const Duration(seconds: 1)))).toList();
      if (dayTasks.isEmpty) break;
      final hasCompleted = dayTasks.any((t) => t.isCompleted);
      if (!hasCompleted) break;
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  // ── Monthly bar data (for yearly chart) ──────────────────────────────────
  /// Returns list of 12 completion rates (Jan=0 … Dec=11) for current year
  List<double> getYearlyMonthlyRates([int? year]) {
    final y = year ?? DateTime.now().year;
    return List.generate(12, (month) {
      final from = DateTime(y, month + 1, 1);
      final to = DateTime(y, month + 2, 0, 23, 59);
      final tasks = _allTasks.where((t) =>
          t.dueDate.isAfter(from.subtract(const Duration(seconds: 1))) &&
          t.dueDate.isBefore(to.add(const Duration(seconds: 1)))).toList();
      if (tasks.isEmpty) return 0.0;
      return tasks.where((t) => t.isCompleted).length / tasks.length;
    });
  }

  // ── Rating & Notes Persistence ───────────────────────────────────────────
  Future<void> saveRating(String period, DateTime date, double rating) async {
    final key = _periodKey(period, date);
    _ratings[key] = rating;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('rating_$key', rating);
  }

  Future<void> saveNotes(String period, DateTime date, List<String> good, List<String> bad) async {
    final key = _periodKey(period, date);
    _goodNotes[key] = good;
    _badNotes[key] = bad;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('good_$key', jsonEncode(good));
    await prefs.setString('bad_$key', jsonEncode(bad));
  }

  String _periodKey(String period, DateTime date) {
    if (period == 'week') return _weekKey(date);
    if (period == 'month') return _monthKey(date);
    return _yearKey(date);
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in prefs.getKeys()) {
      if (key.startsWith('rating_')) {
        _ratings[key.substring(7)] = prefs.getDouble(key) ?? 0.0;
      } else if (key.startsWith('good_')) {
        final raw = prefs.getString(key);
        if (raw != null) {
          _goodNotes[key.substring(5)] = List<String>.from(jsonDecode(raw));
        }
      } else if (key.startsWith('bad_')) {
        final raw = prefs.getString(key);
        if (raw != null) {
          _badNotes[key.substring(4)] = List<String>.from(jsonDecode(raw));
        }
      }
    }
    notifyListeners();
  }

  // ── Achievement Badges ───────────────────────────────────────────────────
  List<Map<String, String>> getAchievements() {
    final badges = <Map<String, String>>[];
    final total = _allTasks.length;
    final done = _allTasks.where((t) => t.isCompleted).length;
    final streak = _calculateStreak();
    if (done >= 1) badges.add({'emoji': '🎯', 'label': 'First Task Done'});
    if (done >= 10) badges.add({'emoji': '⚡', 'label': '10 Tasks Crushed'});
    if (done >= 50) badges.add({'emoji': '💪', 'label': '50 Tasks Warrior'});
    if (done >= 100) badges.add({'emoji': '🏆', 'label': 'Century Club'});
    if (streak >= 3) badges.add({'emoji': '🔥', 'label': '$streak Day Streak'});
    if (streak >= 7) badges.add({'emoji': '🌟', 'label': 'Perfect Week'});
    if (total > 0 && done / total >= 0.9) badges.add({'emoji': '💯', 'label': '90%+ Rate'});
    return badges;
  }
}

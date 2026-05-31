import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pedometer/pedometer.dart';
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';
import '../models/fitness_model.dart';

class FitnessViewModel extends ChangeNotifier {
  DailyFitnessModel _dailyData = DailyFitnessModel(
    date: DateTime.now(),
    stepCount: 0,
    meals: [],
    isWorkoutCompleted: false,
  );

  DailyFitnessModel get dailyData => _dailyData;

  Stream<StepCount>? _stepCountStream;
  int _initialSteps = -1;
  bool _isPedometerActive = false;

  int _reminderHour = 8;
  int _reminderMinute = 0;

  int get reminderHour => _reminderHour;
  int get reminderMinute => _reminderMinute;

  FitnessViewModel() {
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    
    final dataStr = prefs.getString('fitness_data_$todayStr');
    if (dataStr != null) {
      _dailyData = DailyFitnessModel.fromJson(json.decode(dataStr));
    } else {
      // If a new day has started, reset daily data but keep the goals
      _dailyData = DailyFitnessModel(
        date: DateTime.now(),
        stepCount: 0,
        meals: [],
        isWorkoutCompleted: false,
        stepGoal: _dailyData.stepGoal,
        calorieGoal: _dailyData.calorieGoal,
      );
    }
    
    _reminderHour = prefs.getInt('fitness_reminder_hour') ?? 8;
    _reminderMinute = prefs.getInt('fitness_reminder_minute') ?? 0;
    
    notifyListeners();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    await prefs.setString('fitness_data_$todayStr', json.encode(_dailyData.toJson()));
  }

  Future<bool> requestPermissions() async {
    PermissionStatus status = await Permission.activityRecognition.request();
    if (status.isGranted) {
      _initPedometer();
      return true;
    }
    return false;
  }

  void _initPedometer() {
    if (_isPedometerActive) return;
    try {
      _stepCountStream = Pedometer.stepCountStream;
      _stepCountStream?.listen((StepCount event) {
        if (_initialSteps == -1) {
          _initialSteps = event.steps;
        }
        final sessionSteps = event.steps - _initialSteps;
        // In a real app we'd combine this with saved steps, but for simplicity:
        _dailyData = _dailyData.copyWith(stepCount: _dailyData.stepCount + sessionSteps);
        _initialSteps = event.steps; // Reset initial steps to only count diffs
        _saveData();
        notifyListeners();
      }, onError: (error) {
        debugPrint("Pedometer error: $error");
      });
      _isPedometerActive = true;
    } catch (e) {
      debugPrint("Could not initialize pedometer: $e");
    }
  }

  void addMeal(MealModel meal) {
    final updatedMeals = List<MealModel>.from(_dailyData.meals)..add(meal);
    _dailyData = _dailyData.copyWith(meals: updatedMeals);
    _saveData();
    notifyListeners();
  }

  void toggleWorkout() {
    _dailyData = _dailyData.copyWith(isWorkoutCompleted: !_dailyData.isWorkoutCompleted);
    _saveData();
    notifyListeners();
  }

  void setGoals(int stepGoal, int calorieGoal) {
    _dailyData = _dailyData.copyWith(stepGoal: stepGoal, calorieGoal: calorieGoal);
    _saveData();
    notifyListeners();
  }

  Future<void> setReminderTime(int hour, int minute) async {
    _reminderHour = hour;
    _reminderMinute = minute;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('fitness_reminder_hour', hour);
    await prefs.setInt('fitness_reminder_minute', minute);
    notifyListeners();
  }
}

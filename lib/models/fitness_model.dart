import 'package:flutter/material.dart';

class MealModel {
  final String id;
  final String name;
  final int calories;
  final DateTime timestamp;

  MealModel({
    required this.id,
    required this.name,
    required this.calories,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'calories': calories,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory MealModel.fromJson(Map<String, dynamic> json) {
    return MealModel(
      id: json['id'],
      name: json['name'],
      calories: json['calories'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class DailyFitnessModel {
  final DateTime date;
  final int stepCount;
  final List<MealModel> meals;
  final bool isWorkoutCompleted;
  final int stepGoal;
  final int calorieGoal;

  DailyFitnessModel({
    required this.date,
    required this.stepCount,
    required this.meals,
    required this.isWorkoutCompleted,
    this.stepGoal = 10000,
    this.calorieGoal = 2000,
  });

  int get totalCalories {
    return meals.fold(0, (sum, meal) => sum + meal.calories);
  }

  DailyFitnessModel copyWith({
    DateTime? date,
    int? stepCount,
    List<MealModel>? meals,
    bool? isWorkoutCompleted,
    int? stepGoal,
    int? calorieGoal,
  }) {
    return DailyFitnessModel(
      date: date ?? this.date,
      stepCount: stepCount ?? this.stepCount,
      meals: meals ?? this.meals,
      isWorkoutCompleted: isWorkoutCompleted ?? this.isWorkoutCompleted,
      stepGoal: stepGoal ?? this.stepGoal,
      calorieGoal: calorieGoal ?? this.calorieGoal,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'stepCount': stepCount,
      'meals': meals.map((m) => m.toJson()).toList(),
      'isWorkoutCompleted': isWorkoutCompleted,
      'stepGoal': stepGoal,
      'calorieGoal': calorieGoal,
    };
  }

  factory DailyFitnessModel.fromJson(Map<String, dynamic> json) {
    return DailyFitnessModel(
      date: DateTime.parse(json['date']),
      stepCount: json['stepCount'],
      meals: (json['meals'] as List).map((m) => MealModel.fromJson(m)).toList(),
      isWorkoutCompleted: json['isWorkoutCompleted'],
      stepGoal: json['stepGoal'] ?? 10000,
      calorieGoal: json['calorieGoal'] ?? 2000,
    );
  }
}

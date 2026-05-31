import 'subtask_model.dart';
import 'category_model.dart';

enum TaskPriority {
  low,
  medium,
  high
}

class TaskModel {
  final String id;
  String title;
  String description;
  DateTime dueDate;
  TaskPriority priority;
  bool isCompleted;
  CategoryModel category;
  List<SubtaskModel> subtasks;
  int duration; // in minutes
  int reminderMinutes; // in minutes (-1 means none)

  TaskModel({
    required this.id,
    required this.title,
    this.description = '',
    required this.dueDate,
    this.priority = TaskPriority.medium,
    this.isCompleted = false,
    required this.category,
    this.subtasks = const [],
    this.duration = 0,
    this.reminderMinutes = -1,
  });

  double get progressPercentage {
    if (subtasks.isEmpty) {
      return isCompleted ? 1.0 : 0.0;
    }
    final completedCount = subtasks.where((s) => s.isCompleted).length;
    return completedCount / subtasks.length;
  }

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    TaskPriority? priority,
    bool? isCompleted,
    CategoryModel? category,
    List<SubtaskModel>? subtasks,
    int? duration,
    int? reminderMinutes,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      category: category ?? this.category,
      subtasks: subtasks ?? this.subtasks,
      duration: duration ?? this.duration,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'priority': priority.name,
      'isCompleted': isCompleted,
      'category': category.toJson(),
      'subtasks': subtasks.map((s) => s.toJson()).toList(),
      'duration': duration,
      'reminderMinutes': reminderMinutes,
    };
  }

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      dueDate: DateTime.parse(json['dueDate'] as String),
      priority: TaskPriority.values.byName(json['priority'] as String? ?? 'medium'),
      isCompleted: json['isCompleted'] as bool? ?? false,
      category: CategoryModel.fromJson(json['category'] as Map<String, dynamic>),
      subtasks: (json['subtasks'] as List<dynamic>?)
              ?.map((e) => SubtaskModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      duration: json['duration'] as int? ?? 0,
      reminderMinutes: json['reminderMinutes'] as int? ?? -1,
    );
  }
}

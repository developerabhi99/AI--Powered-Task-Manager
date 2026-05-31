import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/task_model.dart';
import '../models/category_model.dart';
import '../models/subtask_model.dart';
import '../services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class TaskViewModel extends ChangeNotifier {
  final List<TaskModel> _tasks = [];
  final List<CategoryModel> _categories = List.from(CategoryModel.defaultCategories);
  
  String _selectedCategoryId = 'all';
  String _searchQuery = '';
  String _statusFilter = 'all'; // 'all', 'active', 'completed'
  DateTime? _selectedDate; // null means "All Days"

  TaskViewModel() {
    _loadTasksFromPrefs();
    NotificationService.onNotificationAction = _handleNotificationAction;
  }

  Future<void> _loadTasksFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final String? tasksJson = prefs.getString('saved_tasks');
    
    if (tasksJson != null && tasksJson.isNotEmpty) {
      try {
        final List<dynamic> decodedList = json.decode(tasksJson);
        _tasks.clear();
        _tasks.addAll(decodedList.map((e) => TaskModel.fromJson(e)).toList());
        notifyListeners();
        return;
      } catch (e) {
        debugPrint('Error loading tasks from prefs: $e');
      }
    }
    
    // If no tasks are found or error occurred, load sample tasks once.
    if (!prefs.containsKey('has_loaded_samples')) {
      _loadSampleTasks();
      await prefs.setBool('has_loaded_samples', true);
    }
  }

  Future<void> _saveTasksToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedList = json.encode(_tasks.map((e) => e.toJson()).toList());
    await prefs.setString('saved_tasks', encodedList);
  }

  void _handleNotificationAction(String taskId, String actionId) {
    if (actionId == 'action_complete') {
      final index = _tasks.indexWhere((t) => t.id == taskId);
      if (index != -1 && !_tasks[index].isCompleted) {
        toggleTaskCompletion(taskId);
      }
    } else if (actionId == 'action_add_15m') {
      extendTaskTime(taskId, const Duration(minutes: 15));
    }
  }

  // Getters
  List<TaskModel> get allTasks => List.unmodifiable(_tasks);
  List<TaskModel> get tasks => allTasks;
  List<CategoryModel> get categories => List.unmodifiable(_categories);
  String get selectedCategoryId => _selectedCategoryId;
  String get searchQuery => _searchQuery;
  String get statusFilter => _statusFilter;
  DateTime? get selectedDate => _selectedDate;

  // --- Date helpers ---
  bool get isDateFilterActive => _selectedDate != null;

  /// Returns tasks due on [date] (date-only comparison, ignores time)
  List<TaskModel> tasksForDate(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return _tasks.where((t) {
      final td = DateTime(t.dueDate.year, t.dueDate.month, t.dueDate.day);
      return td == d;
    }).toList();
  }

  /// Tasks due today (active only)
  int get todayTasksCount {
    final today = DateTime.now();
    return tasksForDate(today).where((t) => !t.isCompleted).length;
  }

  /// Tasks due today including completed
  List<TaskModel> get todayTasks => tasksForDate(DateTime.now());

  // Filtered Tasks
  List<TaskModel> get filteredTasks {
    return _tasks.where((task) {
      // Category filter
      final matchesCategory = _selectedCategoryId == 'all' || task.category.id == _selectedCategoryId;
      
      // Status filter
      bool matchesStatus = true;
      if (_statusFilter == 'active') {
        matchesStatus = !task.isCompleted;
      } else if (_statusFilter == 'completed') {
        matchesStatus = task.isCompleted;
      }

      // Search query filter
      final matchesSearch = task.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          task.description.toLowerCase().contains(_searchQuery.toLowerCase());

      // Date filter
      bool matchesDate = true;
      if (_selectedDate != null) {
        final sd = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day);
        final td = DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);
        matchesDate = td == sd;
      }

      return matchesCategory && matchesStatus && matchesSearch && matchesDate;
    }).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate)); // Earliest due first
  }

  // Stats
  int get totalTasksCount => _tasks.length;
  int get completedTasksCount => _tasks.where((t) => t.isCompleted).length;
  int get activeTasksCount => _tasks.where((t) => !t.isCompleted).length;
  int get highPriorityTasksCount => _tasks.where((t) => t.priority == TaskPriority.high && !t.isCompleted).length;

  double get completionRate {
    if (_tasks.isEmpty) return 0.0;
    return completedTasksCount / totalTasksCount;
  }

  // Setters/Filters
  void setCategoryFilter(String categoryId) {
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setStatusFilter(String status) {
    _statusFilter = status;
    notifyListeners();
  }

  void setDateFilter(DateTime date) {
    _selectedDate = DateTime(date.year, date.month, date.day);
    notifyListeners();
  }

  void clearDateFilter() {
    _selectedDate = null;
    notifyListeners();
  }

  // CRUD Operations
  void addTask(TaskModel task) {
    _tasks.add(task);
    _saveTasksToPrefs();
    NotificationService.scheduleTaskNotification(task);
    _refreshMorningBriefing();
    notifyListeners();
  }

  void updateTask(TaskModel updatedTask) {
    final index = _tasks.indexWhere((t) => t.id == updatedTask.id);
    if (index != -1) {
      _tasks[index] = updatedTask;
      _saveTasksToPrefs();
      NotificationService.scheduleTaskNotification(updatedTask);
      _refreshMorningBriefing();
      notifyListeners();
    }
  }

  void deleteTask(String taskId) {
    _tasks.removeWhere((t) => t.id == taskId);
    _saveTasksToPrefs();
    NotificationService.cancelTaskNotification(taskId);
    _refreshMorningBriefing();
    notifyListeners();
  }

  void toggleTaskCompletion(String taskId) {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final task = _tasks[index];
      final newStatus = !task.isCompleted;
      
      // Update task status and also update all subtasks accordingly if needed, 
      // or just mark the task as complete.
      List<SubtaskModel> updatedSubtasks = task.subtasks.map((sub) {
        return sub.copyWith(isCompleted: newStatus);
      }).toList();

      final updatedTask = task.copyWith(
        isCompleted: newStatus,
        subtasks: updatedSubtasks,
      );

      _tasks[index] = updatedTask;
      _saveTasksToPrefs();
      
      if (newStatus) {
        NotificationService.cancelTaskNotification(taskId);
      } else {
        NotificationService.scheduleTaskNotification(updatedTask);
      }
      _refreshMorningBriefing();
      notifyListeners();
    }
  }

  // Extend task time
  void extendTaskTime(String taskId, Duration extension) {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final task = _tasks[index];
      final newDueDate = task.dueDate.isBefore(DateTime.now())
          ? DateTime.now().add(extension)
          : task.dueDate.add(extension);

      final updatedTask = task.copyWith(
        dueDate: newDueDate,
        isCompleted: false, // Re-activate task if extended
      );

      _tasks[index] = updatedTask;
      _saveTasksToPrefs();
      NotificationService.scheduleTaskNotification(updatedTask);
      notifyListeners();
    }
  }

  // Subtask Operations
  void toggleSubtaskCompletion(String taskId, String subtaskId) {
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex != -1) {
      final task = _tasks[taskIndex];
      final subtasks = List<SubtaskModel>.from(task.subtasks);
      final subIndex = subtasks.indexWhere((s) => s.id == subtaskId);
      
      if (subIndex != -1) {
        subtasks[subIndex] = subtasks[subIndex].copyWith(
          isCompleted: !subtasks[subIndex].isCompleted,
        );

        // If all subtasks are now completed, automatically mark the main task as completed
        final allDone = subtasks.isNotEmpty && subtasks.every((s) => s.isCompleted);
        // If any subtask is unchecked and the task was completed, mark task as uncompleted
        final anyActive = subtasks.any((s) => !s.isCompleted);
        
        bool isTaskCompleted = task.isCompleted;
        if (allDone) {
          isTaskCompleted = true;
        } else if (anyActive && task.isCompleted) {
          isTaskCompleted = false;
        }

        final updatedTask = task.copyWith(
          subtasks: subtasks,
          isCompleted: isTaskCompleted,
        );

        _tasks[taskIndex] = updatedTask;
        _saveTasksToPrefs();

        if (isTaskCompleted) {
          NotificationService.cancelTaskNotification(taskId);
        } else {
          NotificationService.scheduleTaskNotification(updatedTask);
        }
        notifyListeners();
      }
    }
  }

  // Add Category
  void addCategory(CategoryModel category) {
    _categories.add(category);
    notifyListeners();
  }

  // Schedule morning briefing whenever task list changes
  void _refreshMorningBriefing() {
    NotificationService.scheduleMorningBriefing(todayTasks);
  }

  // Sample Data Initialization
  void _loadSampleTasks() {
    final uuid = const Uuid();
    final now = DateTime.now();

    // 1. Work task with subtasks (Active, High Priority)
    _tasks.add(TaskModel(
      id: uuid.v4(),
      title: 'Design App Wireframes',
      description: 'Create modern UI layouts for the Personal Task Manager mobile app.',
      dueDate: now.add(const Duration(days: 1)),
      priority: TaskPriority.high,
      category: _categories.firstWhere((c) => c.id == 'work'),
      subtasks: [
        SubtaskModel(id: uuid.v4(), title: 'Sketch dashboard layout', isCompleted: true),
        SubtaskModel(id: uuid.v4(), title: 'Define dark/light color palette', isCompleted: false),
        SubtaskModel(id: uuid.v4(), title: 'Create interactive prototype', isCompleted: false),
      ],
    ));

    // 2. Health task with subtask (Active, Medium Priority) — due today
    _tasks.add(TaskModel(
      id: uuid.v4(),
      title: 'Evening Run & Stretch',
      description: 'Complete a 5km outdoor run followed by a 15-minute full body stretch session.',
      dueDate: DateTime(now.year, now.month, now.day, 18, 0),
      priority: TaskPriority.medium,
      category: _categories.firstWhere((c) => c.id == 'health'),
      subtasks: [
        SubtaskModel(id: uuid.v4(), title: 'Run 5km in under 28 mins', isCompleted: false),
        SubtaskModel(id: uuid.v4(), title: 'Post-run dynamic stretching', isCompleted: false),
      ],
    ));

    // 3. Study task (Active, High Priority) — due today
    _tasks.add(TaskModel(
      id: uuid.v4(),
      title: 'Study Flutter State Management',
      description: 'Read Flutter docs and build a simple reactive application to practice Provider.',
      dueDate: DateTime(now.year, now.month, now.day, 20, 0),
      priority: TaskPriority.high,
      category: _categories.firstWhere((c) => c.id == 'study'),
      subtasks: [],
    ));

    // 4. Shopping task (Completed, Low Priority) — yesterday
    _tasks.add(TaskModel(
      id: uuid.v4(),
      title: 'Buy Weekly Groceries',
      description: 'Get fresh fruits, vegetables, oat milk, and organic eggs.',
      dueDate: now.subtract(const Duration(days: 1)),
      priority: TaskPriority.low,
      isCompleted: true,
      category: _categories.firstWhere((c) => c.id == 'shopping'),
      subtasks: [
        SubtaskModel(id: uuid.v4(), title: 'Spinach & Avocados', isCompleted: true),
        SubtaskModel(id: uuid.v4(), title: 'Oat Milk', isCompleted: true),
      ],
    ));

    // 5. Personal task — tomorrow
    _tasks.add(TaskModel(
      id: uuid.v4(),
      title: 'Read 20 Pages of Book',
      description: 'Continue reading Atomic Habits — focus on chapter 4.',
      dueDate: now.add(const Duration(days: 2)),
      priority: TaskPriority.low,
      category: _categories.firstWhere((c) => c.id == 'personal'),
      subtasks: [],
    ));
    
    _saveTasksToPrefs();
  }
}

import 'package:flutter/material.dart';
import '../viewmodels/task_viewmodel.dart';
import '../models/task_model.dart';
import '../models/category_model.dart';
import '../views/main_scaffold.dart';
import 'package:uuid/uuid.dart';

class ChatMessage {
  final String text;
  final String sender; // 'user' | 'ai'
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.sender,
    required this.timestamp,
  });
}

class AiAssistantService {
  static Future<AiResponse> processMessage(
    String text,
    TaskViewModel viewModel,
    BuildContext context,
  ) async {
    final cleanInput = text.trim();
    if (cleanInput.isEmpty) {
      return AiResponse("Please say something!", success: false);
    }

    final inputLower = cleanInput.toLowerCase();

    // 1. Tab Navigation: "open reports", "go to home", "switch to profile"
    if (RegExp(r'\b(open|go\s+to|show|switch\s+to)\b', caseSensitive: false).hasMatch(inputLower)) {
      if (inputLower.contains('report')) {
        final state = MainScaffold.of(context);
        if (state != null) {
          state.switchTab(1);
          return AiResponse("Sure, I have switched to the Reports tab! 📊");
        }
      } else if (inputLower.contains('profile') || inputLower.contains('user')) {
        final state = MainScaffold.of(context);
        if (state != null) {
          state.switchTab(2);
          return AiResponse("Navigated to your Profile tab. 👤");
        }
      } else if (inputLower.contains('home') || inputLower.contains('task')) {
        final state = MainScaffold.of(context);
        if (state != null) {
          state.switchTab(0);
          return AiResponse("I've opened the Home screen where all your tasks are. 🏠");
        }
      }
    }

    // 2. Complete Task: "complete buy groceries", "done with design UI"
    if (RegExp(r'\b(complete|finish|done\s+with|check\s+off)\b', caseSensitive: false).hasMatch(inputLower)) {
      String query = cleanInput
          .replaceAll(RegExp(r'\b(complete|finish|done\s+with|check\s+off)\b', caseSensitive: false), '')
          .trim();
      if (query.isNotEmpty) {
        final task = _findTaskByTitle(query, viewModel.tasks);
        if (task != null) {
          if (task.isCompleted) {
            return AiResponse('"${task.title}" is already marked completed!');
          }
          viewModel.toggleTaskCompletion(task.id);
          return AiResponse('Awesome! I have marked the task "${task.title}" as completed. 🎉');
        } else {
          return AiResponse('I couldn\'t find any task matching "$query". Could you check the title?', success: false);
        }
      }
    }

    // 3. Delete Task: "delete buy groceries", "remove reading book"
    if (RegExp(r'\b(delete|remove|cancel)\b', caseSensitive: false).hasMatch(inputLower)) {
      String query = cleanInput
          .replaceAll(RegExp(r'\b(delete|remove|cancel)\b', caseSensitive: false), '')
          .trim();
      if (query.isNotEmpty) {
        final task = _findTaskByTitle(query, viewModel.tasks);
        if (task != null) {
          viewModel.deleteTask(task.id);
          return AiResponse('Okay, I have deleted the task "${task.title}". 🗑️');
        } else {
          return AiResponse('I couldn\'t find a task named "$query" to delete.', success: false);
        }
      }
    }

    // 4. Snooze / Postpone Task: "snooze buy groceries for 30 minutes", "postpone check email"
    if (RegExp(r'\b(snooze|postpone|extend|delay)\b', caseSensitive: false).hasMatch(inputLower)) {
      String query = cleanInput
          .replaceAll(RegExp(r'\b(snooze|postpone|extend|delay)\b', caseSensitive: false), '')
          .trim();
      
      int snoozeMins = 15;
      final durMatch = RegExp(r'(?:for\s+)?(\d+)\s*(mins?|minutes?|hours?|hrs?|h)\b', caseSensitive: false).firstMatch(query);
      if (durMatch != null) {
        final value = int.parse(durMatch.group(1)!);
        final unit = durMatch.group(2)!.toLowerCase();
        if (unit.startsWith('h')) {
          snoozeMins = value * 60;
        } else {
          snoozeMins = value;
        }
        query = query.replaceAll(durMatch.group(0)!, '').trim();
      }

      if (query.isNotEmpty) {
        final task = _findTaskByTitle(query, viewModel.tasks);
        if (task != null) {
          final newDueDate = task.dueDate.add(Duration(minutes: snoozeMins));
          final updatedTask = task.copyWith(dueDate: newDueDate);
          viewModel.updateTask(updatedTask);
          return AiResponse('Snoozed! "${task.title}" has been postponed by $snoozeMins minutes to ${TimeOfDay.fromDateTime(newDueDate).format(context)}. ⏰');
        } else {
          return AiResponse('I couldn\'t find any task matching "$query" to snooze.', success: false);
        }
      }
    }

    // 5. List Tasks: "what is due today?", "show high priority tasks", "list completed"
    if (RegExp(r'\b(show|list|what\s+is|get)\b', caseSensitive: false).hasMatch(inputLower)) {
      List<TaskModel> taskList = viewModel.tasks;
      String filterDesc = "all your tasks";
      
      if (inputLower.contains('complete')) {
        taskList = taskList.where((t) => t.isCompleted).toList();
        filterDesc = "completed tasks";
      } else if (inputLower.contains('active') || inputLower.contains('pending') || inputLower.contains('unfinished')) {
        taskList = taskList.where((t) => !t.isCompleted).toList();
        filterDesc = "active tasks";
      }

      if (inputLower.contains('high')) {
        taskList = taskList.where((t) => t.priority == TaskPriority.high).toList();
        filterDesc = "high priority $filterDesc";
      } else if (inputLower.contains('medium')) {
        taskList = taskList.where((t) => t.priority == TaskPriority.medium).toList();
        filterDesc = "medium priority $filterDesc";
      } else if (inputLower.contains('low')) {
        taskList = taskList.where((t) => t.priority == TaskPriority.low).toList();
        filterDesc = "low priority $filterDesc";
      }

      if (inputLower.contains('today')) {
        final today = DateTime.now();
        taskList = taskList.where((t) {
          return t.dueDate.year == today.year &&
                 t.dueDate.month == today.month &&
                 t.dueDate.day == today.day;
        }).toList();
        filterDesc += " due today";
      } else if (inputLower.contains('tomorrow')) {
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        taskList = taskList.where((t) {
          return t.dueDate.year == tomorrow.year &&
                 t.dueDate.month == tomorrow.month &&
                 t.dueDate.day == tomorrow.day;
        }).toList();
        filterDesc += " due tomorrow";
      }

      if (taskList.isEmpty) {
        return AiResponse("You don't have any $filterDesc right now! ✨");
      }

      final buf = StringBuffer("Here are $filterDesc:\n");
      for (int i = 0; i < taskList.length; i++) {
        final t = taskList[i];
        final check = t.isCompleted ? "✅" : "⏳";
        final timeStr = TimeOfDay.fromDateTime(t.dueDate).format(context);
        buf.write("${i + 1}. $check **${t.title}** (due at $timeStr)");
        if (t.priority == TaskPriority.high) buf.write(" 🔥");
        if (i < taskList.length - 1) buf.write("\n");
      }
      return AiResponse(buf.toString());
    }

    // 6. Create Task: "create buy groceries", "add study math tomorrow for 1 hour"
    if (RegExp(r'\b(create|add|new|schedule)\b', caseSensitive: false).hasMatch(inputLower) ||
        (inputLower.contains('today') || inputLower.contains('tomorrow'))) {
      
      String textToParse = cleanInput
          .replaceAll(RegExp(r'\b(create|add|new|schedule)\b', caseSensitive: false), '')
          .trim();

      TaskPriority priority = TaskPriority.medium;
      int duration = 0;
      CategoryModel category = viewModel.categories.first;
      DateTime dueDate = DateTime.now();

      final priorityMatch = RegExp(r'\b(high|medium|low)\s*(?:priority)?\b', caseSensitive: false).firstMatch(textToParse);
      if (priorityMatch != null) {
        final pStr = priorityMatch.group(1)!.toLowerCase();
        if (pStr == 'high') priority = TaskPriority.high;
        if (pStr == 'low') priority = TaskPriority.low;
        textToParse = textToParse.replaceAll(priorityMatch.group(0)!, '').trim();
      }

      final durationMatch = RegExp(r'(?:for\s+)?(\d+)\s*(mins?|minutes?|hours?|hrs?|h)\b', caseSensitive: false).firstMatch(textToParse);
      if (durationMatch != null) {
        final val = int.parse(durationMatch.group(1)!);
        final unit = durationMatch.group(2)!.toLowerCase();
        if (unit.startsWith('h')) {
          duration = val * 60;
        } else {
          duration = val;
        }
        textToParse = textToParse.replaceAll(durationMatch.group(0)!, '').trim();
      }

      for (final cat in viewModel.categories) {
        final catReg = RegExp('\\b${cat.name}\\b', caseSensitive: false);
        if (catReg.hasMatch(textToParse)) {
          category = cat;
          textToParse = textToParse.replaceAll(catReg, '').trim();
          break;
        }
      }

      bool tomorrow = false;
      if (RegExp(r'\btomorrow\b', caseSensitive: false).hasMatch(textToParse)) {
        tomorrow = true;
        textToParse = textToParse.replaceAll(RegExp(r'\btomorrow\b', caseSensitive: false), '').trim();
      } else if (RegExp(r'\btoday\b', caseSensitive: false).hasMatch(textToParse)) {
        textToParse = textToParse.replaceAll(RegExp(r'\btoday\b', caseSensitive: false), '').trim();
      }

      int hour = 18;
      int minute = 0;
      final timeMatch = RegExp(r'\bat\s+(\d+)(?::(\d+))?\s*(am|pm)?\b', caseSensitive: false).firstMatch(textToParse);
      if (timeMatch != null) {
        int h = int.parse(timeMatch.group(1)!);
        int m = timeMatch.group(2) != null ? int.parse(timeMatch.group(2)!) : 0;
        final ampm = timeMatch.group(3)?.toLowerCase();

        if (ampm == 'pm' && h < 12) {
          h += 12;
        } else if (ampm == 'am' && h == 12) {
          h = 0;
        }
        hour = h;
        minute = m;
        textToParse = textToParse.replaceAll(timeMatch.group(0)!, '').trim();
      }

      final now = DateTime.now();
      dueDate = DateTime(
        now.year,
        now.month,
        tomorrow ? now.day + 1 : now.day,
        hour,
        minute,
      );

      String title = textToParse
          .replaceAll(RegExp(r'^(?:task\s+to\s+|task\s+|to\s+|a\s+|an\s+)', caseSensitive: false), '')
          .trim();

      if (title.isNotEmpty) {
        title = title[0].toUpperCase() + title.substring(1);
      } else {
        title = "New Task via AI";
      }

      final task = TaskModel(
        id: const Uuid().v4(),
        title: title,
        dueDate: dueDate,
        priority: priority,
        category: category,
        duration: duration,
        isCompleted: false,
      );

      viewModel.addTask(task);

      final dateStr = tomorrow ? "tomorrow" : "today";
      final timeStr = TimeOfDay.fromDateTime(dueDate).format(context);
      final pStr = priority.name;
      final durStr = duration > 0 ? " for $duration mins" : "";
      
      return AiResponse(
        'I have added the task **"$title"** ($pStr priority, in ${category.name}) due $dateStr at $timeStr$durStr! ✍️',
      );
    }

    return AiResponse(
      "Sorry, I didn't quite catch that. You can ask me to:\n"
      "• **Add task**: *\"Add high priority coding task to code tomorrow for 2 hours at 3 PM\"*\n"
      "• **Complete task**: *\"Complete coding task\"*\n"
      "• **Snooze task**: *\"Snooze coding task for 30 minutes\"*\n"
      "• **Delete task**: *\"Delete coding task\"*\n"
      "• **List tasks**: *\"Show active high priority tasks due today\"*\n"
      "• **Navigate**: *\"Open reports\"* or *\"Go to profile\"*",
      success: false,
    );
  }

  static TaskModel? _findTaskByTitle(String query, List<TaskModel> tasks) {
    final cleanQuery = query.toLowerCase().trim();
    if (cleanQuery.isEmpty) return null;

    for (final task in tasks) {
      if (task.title.toLowerCase() == cleanQuery) {
        return task;
      }
    }

    for (final task in tasks) {
      if (task.title.toLowerCase().contains(cleanQuery)) {
        return task;
      }
    }

    for (final task in tasks) {
      if (cleanQuery.contains(task.title.toLowerCase())) {
        return task;
      }
    }

    return null;
  }
}

class AiResponse {
  final String text;
  final bool success;

  AiResponse(this.text, {this.success = true});
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:personal_task_manager/viewmodels/task_viewmodel.dart';
import 'package:personal_task_manager/services/ai_assistant_service.dart';
import 'package:personal_task_manager/models/task_model.dart';
import 'package:personal_task_manager/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    const MethodChannel localNotificationsChannel =
        MethodChannel('dexterous.com/flutter/local_notifications');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(localNotificationsChannel, (MethodCall methodCall) async {
      return true;
    });

    const MethodChannel timezoneChannel = MethodChannel('flutter_timezone');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(timezoneChannel, (MethodCall methodCall) async {
      return 'UTC';
    });

    await NotificationService.init();
  });

  group('Gravity AI Assistant Parsing tests', () {
    late TaskViewModel viewModel;

    setUp(() {
      viewModel = TaskViewModel();
    });

    testWidgets('Add Task command', (WidgetTester tester) async {
      BuildContext? buildContext;
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) {
          buildContext = context;
          return const SizedBox();
        }),
      ));

      final response = await AiAssistantService.processMessage(
        "add high priority work task code tests today for 45 mins at 2 PM",
        viewModel,
        buildContext!,
      );

      expect(response.success, isTrue);
      expect(response.text, contains("Code tests"));

      final task = viewModel.allTasks.firstWhere((t) => t.title == "Code tests");
      expect(task, isNotNull);
      expect(task.priority, TaskPriority.high);
      expect(task.duration, 45);
      expect(task.category.id, 'work');
    });

    testWidgets('Complete Task command', (WidgetTester tester) async {
      BuildContext? buildContext;
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) {
          buildContext = context;
          return const SizedBox();
        }),
      ));

      expect(viewModel.allTasks.any((t) => t.title == "Design App Wireframes"), isTrue);
      
      final response = await AiAssistantService.processMessage(
        "complete Design App Wireframes",
        viewModel,
        buildContext!,
      );

      expect(response.success, isTrue);
      expect(response.text, contains("completed"));

      final task = viewModel.allTasks.firstWhere((t) => t.title == "Design App Wireframes");
      expect(task.isCompleted, isTrue);
    });

    testWidgets('Delete Task command', (WidgetTester tester) async {
      BuildContext? buildContext;
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) {
          buildContext = context;
          return const SizedBox();
        }),
      ));

      expect(viewModel.allTasks.any((t) => t.title == "Evening Run & Stretch"), isTrue);

      final response = await AiAssistantService.processMessage(
        "delete Evening Run",
        viewModel,
        buildContext!,
      );

      expect(response.success, isTrue);
      expect(response.text, contains("deleted"));
      expect(viewModel.allTasks.any((t) => t.title == "Evening Run & Stretch"), isFalse);
    });

    testWidgets('Snooze Task command', (WidgetTester tester) async {
      BuildContext? buildContext;
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) {
          buildContext = context;
          return const SizedBox();
        }),
      ));

      final originalTask = viewModel.allTasks.firstWhere((t) => t.title == "Study Flutter State Management");
      final originalDueDate = originalTask.dueDate;

      final response = await AiAssistantService.processMessage(
        "snooze Study Flutter State Management for 30 minutes",
        viewModel,
        buildContext!,
      );

      expect(response.success, isTrue);
      expect(response.text, contains("Snoozed"));

      final updatedTask = viewModel.allTasks.firstWhere((t) => t.title == "Study Flutter State Management");
      expect(updatedTask.dueDate, originalDueDate.add(const Duration(minutes: 30)));
    });

    testWidgets('List Tasks command', (WidgetTester tester) async {
      BuildContext? buildContext;
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) {
          buildContext = context;
          return const SizedBox();
        }),
      ));

      final response = await AiAssistantService.processMessage(
        "show all active high priority tasks today",
        viewModel,
        buildContext!,
      );

      expect(response.success, isTrue);
      expect(response.text, contains("Study Flutter State Management"));
    });
  });
}

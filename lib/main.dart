import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'viewmodels/task_viewmodel.dart';
import 'viewmodels/user_profile_viewmodel.dart';
import 'viewmodels/reports_viewmodel.dart';
import 'viewmodels/fitness_viewmodel.dart';
import 'views/main_scaffold.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  await NotificationService.scheduleDailyWorkoutReminder(hour: 8, minute: 0); // Default 8:00 AM
  runApp(const PersonalTaskManagerApp());
}

class PersonalTaskManagerApp extends StatelessWidget {
  const PersonalTaskManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TaskViewModel()),
        ChangeNotifierProvider(create: (_) => UserProfileViewModel()),
        ChangeNotifierProvider(create: (_) => ReportsViewModel()),
        ChangeNotifierProvider(create: (_) => FitnessViewModel()),
      ],
      child: Consumer<UserProfileViewModel>(
        builder: (context, profileVm, child) {
          return MaterialApp(
            title: 'Personal Task Manager',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: profileVm.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const MainScaffold(),
          );
        },
      ),
    );
  }
}

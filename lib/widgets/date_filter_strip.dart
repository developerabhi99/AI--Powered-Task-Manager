import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../viewmodels/task_viewmodel.dart';

class DateFilterStrip extends StatefulWidget {
  const DateFilterStrip({super.key});

  @override
  State<DateFilterStrip> createState() => _DateFilterStripState();
}

class _DateFilterStripState extends State<DateFilterStrip> {
  late ScrollController _scrollController;

  // Show 7 days before today + today + 7 days after
  static const int _daysBefore = 7;
  static const int _daysAfter = 7;
  static const int _totalDays = _daysBefore + 1 + _daysAfter;

  // Width of each date pill + spacing
  static const double _pillWidth = 52.0;
  static const double _pillSpacing = 10.0;
  static const double _allChipWidth = 60.0;
  static const double _allChipSpacing = 10.0;

  late DateTime _today;
  late List<DateTime> _dates;

  @override
  void initState() {
    super.initState();
    _today = _dateOnly(DateTime.now());
    _dates = List.generate(_totalDays, (i) => _today.subtract(Duration(days: _daysBefore - i)));
    _scrollController = ScrollController();

    // Scroll to today after layout
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToToday());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  void _scrollToToday() {
    if (!_scrollController.hasClients) return;
    // Offset = allChip + spacing + (daysBefore * (pillWidth + spacing))
    final offset = _allChipWidth + _allChipSpacing + (_daysBefore * (_pillWidth + _pillSpacing)) - 60;
    _scrollController.animateTo(
      offset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final vm = context.watch<TaskViewModel>();

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: SizedBox(
        height: 72,
        child: ListView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            // "All" chip
            _AllChip(isDark: isDark, vm: vm),
            const SizedBox(width: _allChipSpacing),

            // Date pills
            ..._dates.map((date) {
              final isToday = date == _today;
              final isSelected = vm.selectedDate != null && _dateOnly(vm.selectedDate!) == date;
              final taskCount = vm.tasksForDate(date).length;
              return Padding(
                padding: const EdgeInsets.only(right: _pillSpacing),
                child: _DatePill(
                  date: date,
                  isToday: isToday,
                  isSelected: isSelected,
                  taskCount: taskCount,
                  isDark: isDark,
                  onTap: () => vm.setDateFilter(date),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ─── "All" chip ─────────────────────────────────────────────────────────────
class _AllChip extends StatelessWidget {
  const _AllChip({required this.isDark, required this.vm});
  final bool isDark;
  final TaskViewModel vm;

  @override
  Widget build(BuildContext context) {
    final isSelected = !vm.isDateFilterActive;
    return GestureDetector(
      onTap: vm.clearDateFilter,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 60,
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradient : null,
          color: isSelected ? null : (isDark ? AppColors.darkSurfaceCard : AppColors.lightSurface),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppColors.primaryBlue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 3))]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_view_week_rounded,
              size: 16,
              color: isSelected ? Colors.white : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
            ),
            const SizedBox(height: 4),
            Text(
              'All',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Date Pill ───────────────────────────────────────────────────────────────
class _DatePill extends StatelessWidget {
  const _DatePill({
    required this.date,
    required this.isToday,
    required this.isSelected,
    required this.taskCount,
    required this.isDark,
    required this.onTap,
  });

  final DateTime date;
  final bool isToday;
  final bool isSelected;
  final int taskCount;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dayLabel = DateFormat('E').format(date).toUpperCase(); // MON, TUE...
    final dayNum = date.day.toString();

    Color bgColor;
    Color textColor;
    List<BoxShadow> shadow = [];

    if (isSelected) {
      bgColor = AppColors.primaryBlue;
      textColor = Colors.white;
      shadow = [BoxShadow(color: AppColors.primaryBlue.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))];
    } else if (isToday) {
      bgColor = isDark
          ? AppColors.primaryBlue.withOpacity(0.18)
          : AppColors.primaryBlue.withOpacity(0.1);
      textColor = AppColors.primaryBlue;
    } else {
      bgColor = isDark ? AppColors.darkSurfaceCard : AppColors.lightSurface;
      textColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 52,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : isToday
                    ? AppColors.primaryBlue.withOpacity(0.5)
                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: 1.5,
          ),
          boxShadow: shadow,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dayLabel,
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white.withOpacity(0.85)
                    : isToday
                        ? AppColors.primaryBlue
                        : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              dayNum,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            // Dot indicator for tasks
            AnimatedOpacity(
              opacity: taskCount > 0 ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withOpacity(0.8) : AppColors.primaryBlue,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

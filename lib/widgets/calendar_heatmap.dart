import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';

class CalendarHeatmap extends StatelessWidget {
  final DateTime month;
  final Map<DateTime, int> dailyCompletions;
  final Map<DateTime, int> dailyTotal;

  const CalendarHeatmap({
    super.key,
    required this.month,
    required this.dailyCompletions,
    required this.dailyTotal,
  });

  Color _dotColor(DateTime day) {
    final total = dailyTotal[day] ?? 0;
    if (total == 0) return AppColors.heatmapEmpty;
    final completed = dailyCompletions[day] ?? 0;
    final rate = completed / total;
    if (rate >= 0.9) return AppColors.heatmapHigh;
    if (rate >= 0.5) return AppColors.heatmapMid;
    if (rate > 0) return AppColors.heatmapLow;
    return AppColors.reportBadColor.withOpacity(0.4);
  }

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // Start from Monday (1), offset = firstDay.weekday - 1
    final offset = firstDay.weekday - 1;

    final dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day-of-week labels
        Row(
          children: dayLabels.map((d) => Expanded(
            child: Center(
              child: Text(d,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.lightTextMuted,
                ),
              ),
            ),
          )).toList(),
        ),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 1,
          ),
          itemCount: offset + daysInMonth,
          itemBuilder: (context, index) {
            if (index < offset) return const SizedBox();
            final day = DateTime(month.year, month.month, index - offset + 1);
            final isToday = _isSameDay(day, DateTime.now());
            final isFuture = day.isAfter(DateTime.now());
            final color = isFuture ? AppColors.heatmapEmpty : _dotColor(day);

            return Tooltip(
              message: '${DateFormat('d MMM').format(day)}: ${dailyCompletions[day] ?? 0}/${dailyTotal[day] ?? 0} done',
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                  border: isToday
                      ? Border.all(color: AppColors.primaryBlue, width: 2)
                      : null,
                ),
                child: isFuture
                    ? null
                    : Center(
                        child: Text(
                          '${day.day}',
                          style: TextStyle(
                            fontSize: 9,
                            color: color == AppColors.heatmapEmpty
                                ? AppColors.lightTextMuted
                                : Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        // Legend
        Row(
          children: [
            const Text('Less', style: TextStyle(fontSize: 11, color: AppColors.lightTextMuted)),
            const SizedBox(width: 6),
            ...[ AppColors.heatmapEmpty, AppColors.heatmapLow, AppColors.heatmapMid, AppColors.heatmapHigh]
                .map((c) => Container(
                      width: 12, height: 12,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3)),
                    )),
            const Text('More', style: TextStyle(fontSize: 11, color: AppColors.lightTextMuted)),
          ],
        ),
      ],
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

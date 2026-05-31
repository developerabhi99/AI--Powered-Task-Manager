import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../viewmodels/reports_viewmodel.dart';
import '../../viewmodels/task_viewmodel.dart';
import '../../models/report_model.dart';
import '../../widgets/star_rating_widget.dart';
import '../../widgets/calendar_heatmap.dart';

class ReportsView extends StatefulWidget {
  const ReportsView({super.key});

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taskVM = context.watch<TaskViewModel>();
    final reportsVM = context.watch<ReportsViewModel>();
    reportsVM.updateTasks(taskVM.allTasks.toList());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final cardBgColor = isDark ? AppColors.darkSurfaceCard : Colors.white;
    final textPrimaryColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textMutedColor = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reports 📊',
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Your performance at a glance',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: textMutedColor,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.calendar_month_outlined,
                      color: isDark ? Colors.white : AppColors.primaryBlue,
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Tab Bar ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(22),
                  border: isDark ? Border.all(color: AppColors.darkBorder) : null,
                  boxShadow: isDark
                      ? []
                      : [BoxShadow(color: AppColors.lightCardShadow, blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: textMutedColor,
                  labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                  unselectedLabelStyle: GoogleFonts.outfit(fontSize: 13),
                  dividerColor: Colors.transparent,
                  tabs: const [Tab(text: 'Weekly'), Tab(text: 'Monthly'), Tab(text: 'Yearly')],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // ── Tab Content ───────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _WeeklyTab(reportsVM: reportsVM),
                  _MonthlyTab(reportsVM: reportsVM),
                  _YearlyTab(reportsVM: reportsVM),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// WEEKLY TAB
// ══════════════════════════════════════════════════════════════════════════════
class _WeeklyTab extends StatelessWidget {
  final ReportsViewModel reportsVM;
  const _WeeklyTab({required this.reportsVM});

  @override
  Widget build(BuildContext context) {
    final report = reportsVM.getWeeklyReport();
    return _ReportScroll(
      report: report,
      reportsVM: reportsVM,
      periodLabel: 'This Week',
      extraCharts: [
        _SectionHeader('Daily Breakdown'),
        const SizedBox(height: 12),
        _DailyBarChart(report: report, days: 7),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// MONTHLY TAB
// ══════════════════════════════════════════════════════════════════════════════
class _MonthlyTab extends StatelessWidget {
  final ReportsViewModel reportsVM;
  const _MonthlyTab({required this.reportsVM});

  @override
  Widget build(BuildContext context) {
    final report = reportsVM.getMonthlyReport();
    final now = DateTime.now();
    return _ReportScroll(
      report: report,
      reportsVM: reportsVM,
      periodLabel: DateFormat('MMMM yyyy').format(now),
      extraCharts: [
        _SectionHeader('Activity Heatmap'),
        const SizedBox(height: 12),
        CalendarHeatmap(
          month: now,
          dailyCompletions: report.dailyCompletions,
          dailyTotal: report.dailyTotal,
        ),
        if (report.bestDay != null) ...[
          const SizedBox(height: 16),
          _BestWorstRow(report: report),
        ],
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// YEARLY TAB
// ══════════════════════════════════════════════════════════════════════════════
class _YearlyTab extends StatelessWidget {
  final ReportsViewModel reportsVM;
  const _YearlyTab({required this.reportsVM});

  @override
  Widget build(BuildContext context) {
    final report = reportsVM.getYearlyReport();
    final monthlyRates = reportsVM.getYearlyMonthlyRates();
    final achievements = reportsVM.getAchievements();

    return _ReportScroll(
      report: report,
      reportsVM: reportsVM,
      periodLabel: '${DateTime.now().year} Overview',
      extraCharts: [
        _SectionHeader('Monthly Progress'),
        const SizedBox(height: 12),
        _MonthlyBarChart(monthlyRates: monthlyRates),
        if (achievements.isNotEmpty) ...[
          const SizedBox(height: 20),
          _SectionHeader('Achievements 🏆'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: achievements.map((a) => _AchievementBadge(emoji: a['emoji']!, label: a['label']!)).toList(),
          ),
        ],
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SHARED REPORT SCROLL LAYOUT
// ══════════════════════════════════════════════════════════════════════════════
class _ReportScroll extends StatefulWidget {
  final PeriodReport report;
  final ReportsViewModel reportsVM;
  final String periodLabel;
  final List<Widget> extraCharts;

  const _ReportScroll({
    required this.report,
    required this.reportsVM,
    required this.periodLabel,
    required this.extraCharts,
  });

  @override
  State<_ReportScroll> createState() => _ReportScrollState();
}

class _ReportScrollState extends State<_ReportScroll> {
  late List<String> _goodNotes;
  late List<String> _badNotes;
  final _goodCtrl = TextEditingController();
  final _badCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _goodNotes = List.from(widget.report.goodNotes);
    _badNotes = List.from(widget.report.badNotes);
  }

  @override
  void dispose() {
    _goodCtrl.dispose();
    _badCtrl.dispose();
    super.dispose();
  }

  void _addGood() {
    if (_goodCtrl.text.trim().isEmpty) return;
    setState(() => _goodNotes.add(_goodCtrl.text.trim()));
    _goodCtrl.clear();
    _saveNotes();
  }

  void _addBad() {
    if (_badCtrl.text.trim().isEmpty) return;
    setState(() => _badNotes.add(_badCtrl.text.trim()));
    _badCtrl.clear();
    _saveNotes();
  }

  void _saveNotes() {
    widget.reportsVM.saveNotes(
      widget.report.period,
      widget.report.from,
      _goodNotes,
      _badNotes,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      children: [
        // Period label
        Text(widget.periodLabel,
            style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primaryBlue)),
        const SizedBox(height: 16),

        // Donut + stats
        _DonutAndStats(report: widget.report),
        const SizedBox(height: 16),
        _PerformanceStatsRow(report: widget.report),
        const SizedBox(height: 24),

        // Extra charts (bar, heatmap, etc.)
        ...widget.extraCharts,
        const SizedBox(height: 24),

        // Star Rating
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader('Rate This Period'),
              const SizedBox(height: 12),
              Center(
                child: StarRatingWidget(
                  rating: widget.report.rating,
                  onRatingChanged: (r) => widget.reportsVM.saveRating(
                    widget.report.period, widget.report.from, r),
                  starSize: 40,
                ),
              ),
              const SizedBox(height: 8),
              Center(child: Text(
                widget.report.rating == 0 ? 'Tap to rate' : _ratingLabel(widget.report.rating),
                style: GoogleFonts.outfit(fontSize: 13, color: AppColors.lightTextMuted),
              )),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Good things
        _NotesCard(
          title: '✅ What Went Well',
          color: AppColors.reportGoodColor,
          notes: _goodNotes,
          controller: _goodCtrl,
          hint: 'Add a win...',
          onAdd: _addGood,
          onRemove: (i) { setState(() => _goodNotes.removeAt(i)); _saveNotes(); },
        ),
        const SizedBox(height: 12),

        // Bad things
        _NotesCard(
          title: '❌ What to Improve',
          color: AppColors.reportBadColor,
          notes: _badNotes,
          controller: _badCtrl,
          hint: 'Add something to improve...',
          onAdd: _addBad,
          onRemove: (i) { setState(() => _badNotes.removeAt(i)); _saveNotes(); },
        ),
      ],
    );
  }

  String _ratingLabel(double r) {
    if (r >= 5) return 'Outstanding! 🌟';
    if (r >= 4) return 'Great job! 💪';
    if (r >= 3) return 'Decent 😊';
    if (r >= 2) return 'Could be better 📈';
    return 'Rough week 💡';
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SUB-WIDGETS
// ══════════════════════════════════════════════════════════════════════════════

class _DonutAndStats extends StatelessWidget {
  final PeriodReport report;
  const _DonutAndStats({required this.report});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rate = report.completionRate;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Task Completion',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: SizedBox(
              width: 130, height: 130,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: 40,
                    sections: [
                      PieChartSectionData(
                        value: report.completedTasks.toDouble().clamp(0.001, double.infinity),
                        color: AppColors.primaryBlue,
                        radius: 16, showTitle: false,
                      ),
                      PieChartSectionData(
                        value: (report.totalTasks - report.completedTasks).toDouble().clamp(0.001, double.infinity),
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        radius: 16, showTitle: false,
                      ),
                    ],
                  )),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: rate),
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeOut,
                    builder: (_, v, __) => Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${(v * 100).round()}%',
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        Text(
                          'Done',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(AppColors.primaryBlue, "Completed", isDark),
              const SizedBox(width: 24),
              _buildLegendItem(isDark ? AppColors.darkBorder : AppColors.lightBorder, "Remaining", isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, bool isDark) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
      ],
    );
  }
}

class _PerformanceStatsRow extends StatelessWidget {
  final PeriodReport report;
  const _PerformanceStatsRow({required this.report});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Row(
      children: [
        // 1. Completed
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceCard : const Color(0xFFEBFDF5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : const Color(0xFFD1FAE5),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 24),
                const SizedBox(height: 8),
                Text(
                  '${report.completedTasks}',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF065F46),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Completed',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.darkTextSecondary : const Color(0xFF047857),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        // 2. Missed
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceCard : const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : const Color(0xFFFEE2E2),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cancel_rounded, color: Color(0xFFEF4444), size: 24),
                const SizedBox(height: 8),
                Text(
                  '${report.missedTasks}',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF991B1B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Missed',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.darkTextSecondary : const Color(0xFFB91C1C),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        // 3. Day Streak
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceCard : const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : const Color(0xFFFFEDD5),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.local_fire_department_rounded, color: Color(0xFFF59E0B), size: 24),
                const SizedBox(height: 8),
                Text(
                  '${report.streakDays}',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF78350F),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Day Streak',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.darkTextSecondary : const Color(0xFFB45309),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final int value;
  final String suffix;
  const _StatRow({required this.icon, required this.color, required this.label, required this.value, this.suffix = ''});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.outfit(fontSize: 13, color: AppColors.lightTextSecondary)),
        const Spacer(),
        TweenAnimationBuilder<int>(
          tween: IntTween(begin: 0, end: value),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOut,
          builder: (_, v, __) => Text('$v$suffix',
              style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.lightTextPrimary)),
        ),
      ],
    );
  }
}

class _DailyBarChart extends StatelessWidget {
  final PeriodReport report;
  final int days;
  const _DailyBarChart({required this.report, required this.days});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final labels = const ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    final bars = List.generate(days, (i) {
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final day = DateTime(monday.year, monday.month, monday.day + i);
      final total = report.dailyTotal[day] ?? 0;
      final done = report.dailyCompletions[day] ?? 0;
      final isToday = day.day == now.day && day.month == now.month;
      return BarChartGroupData(x: i, barRods: [
        BarChartRodData(
          toY: total == 0 ? 0 : done.toDouble(),
          gradient: isToday ? AppColors.purplePinkGradient : AppColors.primaryGradient,
          width: 28, borderRadius: BorderRadius.circular(8),
          backDrawRodData: BackgroundBarChartRodData(
            show: true, toY: total == 0 ? 1 : total.toDouble(),
            color: AppColors.lightBorder,
          ),
        ),
      ]);
    });

    return SizedBox(
      height: 160,
      child: BarChart(BarChartData(
        barGroups: bars,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (double value, TitleMeta meta) => Text(
                labels[value.toInt()],
                style: GoogleFonts.outfit(fontSize: 12, color: AppColors.lightTextMuted),
              ),
            ),
          ),
          leftTitles: const AxisTitles(),
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(enabled: true),
      )),
    );
  }
}

class _MonthlyBarChart extends StatelessWidget {
  final List<double> monthlyRates;
  const _MonthlyBarChart({required this.monthlyRates});

  @override
  Widget build(BuildContext context) {
    final months = ['J','F','M','A','M','J','J','A','S','O','N','D'];
    return SizedBox(
      height: 160,
      child: BarChart(BarChartData(
        barGroups: List.generate(12, (i) => BarChartGroupData(x: i, barRods: [
          BarChartRodData(
            toY: monthlyRates[i],
            gradient: monthlyRates[i] > 0 ? AppColors.primaryGradient : null,
            color: monthlyRates[i] > 0 ? null : AppColors.lightBorder,
            width: 18, borderRadius: BorderRadius.circular(6),
          ),
        ])),
        maxY: 1.0,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (double value, TitleMeta meta) => Text(
                months[value.toInt()],
                style: GoogleFonts.outfit(fontSize: 11, color: AppColors.lightTextMuted),
              ),
            ),
          ),
          leftTitles: const AxisTitles(),
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
      )),
    );
  }
}

class _BestWorstRow extends StatelessWidget {
  final PeriodReport report;
  const _BestWorstRow({required this.report});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (report.bestDay != null) Expanded(child: _Badge(
          label: 'Best Day', value: DateFormat('EEE d').format(report.bestDay!),
          color: AppColors.reportGoodColor, icon: Icons.star_rounded)),
        if (report.worstDay != null && report.bestDay != report.worstDay) ...[
          const SizedBox(width: 12),
          Expanded(child: _Badge(
            label: 'Needs Work', value: DateFormat('EEE d').format(report.worstDay!),
            color: AppColors.reportBadColor, icon: Icons.trending_down_rounded)),
        ],
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;
  const _Badge({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.outfit(fontSize: 11, color: color)),
              Text(value, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ],
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  final String title;
  final Color color;
  final List<String> notes;
  final TextEditingController controller;
  final String hint;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  const _NotesCard({
    required this.title, required this.color, required this.notes,
    required this.controller, required this.hint,
    required this.onAdd, required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return _Card(
      borderColor: color.withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 4, height: 18, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              Text(title, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: textPrimary)),
            ],
          ),
          const SizedBox(height: 10),
          ...notes.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Icon(Icons.circle, color: color, size: 7),
                const SizedBox(width: 8),
                Expanded(child: Text(e.value, style: GoogleFonts.outfit(fontSize: 14, color: textSecondary))),
                GestureDetector(
                  onTap: () => onRemove(e.key),
                  child: Icon(Icons.close, size: 16, color: textMuted),
                ),
              ],
            ),
          )),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  style: GoogleFonts.outfit(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: GoogleFonts.outfit(fontSize: 13, color: AppColors.lightTextMuted),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    filled: true,
                    fillColor: color.withOpacity(0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    isDense: true,
                  ),
                  onSubmitted: (_) => onAdd(),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onAdd,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.add, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AchievementBadge extends StatelessWidget {
  final String emoji, label;
  const _AchievementBadge({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.lightAccentSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryBlue)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text,
      style: GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  final Color? borderColor;
  const _Card({required this.child, this.borderColor});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: borderColor != null 
            ? Border.all(color: borderColor!) 
            : (isDark ? Border.all(color: AppColors.darkBorder) : null),
        boxShadow: isDark
            ? []
            : [BoxShadow(color: AppColors.lightCardShadow, blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: child,
    );
  }
}

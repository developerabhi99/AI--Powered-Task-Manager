import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../viewmodels/task_viewmodel.dart';
import '../../viewmodels/user_profile_viewmodel.dart';
import '../../widgets/task_card.dart';
import '../../widgets/stats_card.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/date_filter_strip.dart';
import '../../widgets/user_avatar_widget.dart';
import '../add_edit_task/add_edit_task_view.dart';
import '../task_detail/task_detail_view.dart';
import '../main_scaffold.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with SingleTickerProviderStateMixin {
  late AnimationController _fabAnimController;
  late Animation<double> _fabScaleAnimation;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fabScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabAnimController, curve: Curves.easeOut),
    );
    _fabAnimController.forward();
  }

  @override
  void dispose() {
    _fabAnimController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _openAddTaskSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddEditTaskView(),
    );
  }

  void _switchToAiTab(BuildContext context) {
    MainScaffold.of(context)?.switchTab(2);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final vm = context.watch<TaskViewModel>();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // --- App Header ---
            SliverToBoxAdapter(
              child: _buildHeader(context, isDark, vm),
            ),

            // --- Stats Row ---
            SliverToBoxAdapter(
              child: _buildStatsRow(context, isDark, vm),
            ),

            // --- Search Bar ---
            SliverToBoxAdapter(
              child: _buildSearchBar(context, isDark, vm),
            ),

            // --- Date Filter Strip ---
            SliverToBoxAdapter(
              child: DateFilterStrip(),
            ),

            // --- Category Filters ---
            SliverToBoxAdapter(
              child: _buildCategoryFilter(context, isDark, vm),
            ),

            // --- Status Filter Tabs ---
            SliverToBoxAdapter(
              child: _buildStatusFilter(context, isDark, vm),
            ),

            // --- Task List ---
            _buildTaskList(context, isDark, vm),
          ],
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabScaleAnimation,
        child: FloatingActionButton.extended(
          onPressed: () => _openAddTaskSheet(context),
          icon: const Icon(Icons.add_rounded),
          label: Text(
            'New Task',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          backgroundColor: isDark ? Colors.white : const Color(0xFF121212),
          foregroundColor: isDark ? Colors.black : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, TaskViewModel vm) {
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Good Morning'
        : now.hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';

    // Contextual subtitle under "My Tasks"
    String dateSubtitle;
    if (!vm.isDateFilterActive) {
      dateSubtitle = 'All Tasks';
    } else {
      final sel = vm.selectedDate!;
      final today = DateTime(now.year, now.month, now.day);
      if (sel == today) {
        dateSubtitle = 'Today, ${DateFormat('d MMM').format(sel)}';
      } else {
        dateSubtitle = DateFormat('EEE, d MMM').format(sel);
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting + ' 👋',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'My Tasks',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 2),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  dateSubtitle,
                  key: ValueKey(dateSubtitle),
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: vm.isDateFilterActive
                        ? AppColors.primaryBlue
                        : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () => _switchToAiTab(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceCard : Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryBlue.withOpacity(0.15),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.primaryBlue,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              UserAvatarWidget(
                profile: context.watch<UserProfileViewModel>().profile,
                size: 42,
                isHero: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, bool isDark, TaskViewModel vm) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: StatsCard(
              label: 'Total',
              value: vm.totalTasksCount.toString(),
              icon: Icons.list_alt_rounded,
              gradient: AppColors.primaryGradient,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatsCard(
              label: 'Today',
              value: vm.todayTasksCount.toString(),
              icon: Icons.today_rounded,
              gradient: AppColors.purplePinkGradient,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatsCard(
              label: 'Done',
              value: vm.completedTasksCount.toString(),
              icon: Icons.check_circle_outline_rounded,
              gradient: AppColors.priorityLowGradient,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, bool isDark, TaskViewModel vm) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: TextField(
        controller: _searchController,
        onChanged: vm.setSearchQuery,
        style: GoogleFonts.outfit(
          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'Search tasks...',
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.darkTextMuted),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    vm.setSearchQuery('');
                  },
                )
              : Icon(
                  Icons.tune_rounded,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  size: 20,
                ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter(BuildContext context, bool isDark, TaskViewModel vm) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
      child: SizedBox(
        height: 44,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            // "All" chip
            CategoryChip(
              label: 'All',
              icon: Icons.apps_rounded,
              color: AppColors.primaryBlue,
              isSelected: vm.selectedCategoryId == 'all',
              onTap: () => vm.setCategoryFilter('all'),
            ),
            const SizedBox(width: 8),
            ...vm.categories.map((cat) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: CategoryChip(
                  label: cat.name,
                  icon: cat.icon,
                  color: cat.color,
                  isSelected: vm.selectedCategoryId == cat.id,
                  onTap: () => vm.setCategoryFilter(cat.id),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFilter(BuildContext context, bool isDark, TaskViewModel vm) {
    final filters = ['all', 'active', 'completed'];
    final labels = ['All Tasks', 'Active', 'Completed'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: List.generate(filters.length, (i) {
          final isSelected = vm.statusFilter == filters[i];
          return Padding(
            padding: EdgeInsets.only(right: i < filters.length - 1 ? 8 : 0),
            child: GestureDetector(
              onTap: () => vm.setStatusFilter(filters[i]),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryBlue
                      : (isDark ? AppColors.darkSurfaceCard : AppColors.lightSurface),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                ),
                child: Text(
                  labels[i],
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTaskList(BuildContext context, bool isDark, TaskViewModel vm) {
    final tasks = vm.filteredTasks;
    if (tasks.isEmpty) {
      // Special message when a specific date is selected and has no tasks
      final isFreeDay = vm.isDateFilterActive;
      final freeDayLabel = vm.selectedDate != null
          ? DateFormat('d MMM').format(vm.selectedDate!)
          : '';

      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isFreeDay ? '🎉' : '📭',
                style: const TextStyle(fontSize: 56),
              ),
              const SizedBox(height: 12),
              Text(
                isFreeDay ? 'You\'re free on $freeDayLabel!' : 'No tasks found',
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isFreeDay
                    ? 'Enjoy your free day or add a new task ✨'
                    : 'Tap + to create your first task',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final task = tasks[index];
            return TweenAnimationBuilder<double>(
              key: ValueKey(task.id),
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 400 + (index * 80)),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value.clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Dismissible(
                  key: ValueKey('dismiss_${task.id}'),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => vm.deleteTask(task.id),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B6B), Color(0xFFEE5A24)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
                  ),
                  child: TaskCard(
                    task: task,
                    isDark: isDark,
                    onToggleComplete: () => vm.toggleTaskCompletion(task.id),
                    onEdit: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TaskDetailView(taskId: task.id),
                        ),
                      );
                    },
                    onDelete: () => vm.deleteTask(task.id),
                  ),
                ),
              ),
            );
          },
          childCount: tasks.length,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/task_model.dart';
import '../../viewmodels/task_viewmodel.dart';
import '../add_edit_task/add_edit_task_view.dart';

class TaskDetailView extends StatefulWidget {
  final String taskId;

  const TaskDetailView({super.key, required this.taskId});

  @override
  State<TaskDetailView> createState() => _TaskDetailViewState();
}

class _TaskDetailViewState extends State<TaskDetailView> {
  void _openEditTaskSheet(BuildContext context, TaskModel task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddEditTaskView(taskToEdit: task),
    );
  }

  void _showDeleteDialog(BuildContext context, TaskViewModel vm, TaskModel task) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Task', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete "${task.title}"?', style: GoogleFonts.outfit()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.outfit()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context); // Close details screen
              vm.deleteTask(task.id);
            },
            child: Text('Delete', style: GoogleFonts.outfit(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final vm = context.watch<TaskViewModel>();
    
    // Dynamically retrieve task to remain reactive to edits or deletions
    final taskIndex = vm.allTasks.indexWhere((t) => t.id == widget.taskId);
    if (taskIndex == -1) {
      // Task was deleted, pop details screen safely after layout
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      });
      return const Scaffold(body: SizedBox());
    }

    final task = vm.allTasks[taskIndex];
    final priorityColor = AppColors.getPriorityColor(task.priority.name);
    final completedSubtasksCount = task.subtasks.where((s) => s.isCompleted).length;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          'Task Detail',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, size: 22),
            onPressed: () => _openEditTaskSheet(context, task),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Category & Priority Badges ---
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: task.category.color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(task.category.icon, size: 14, color: task.category.color),
                              const SizedBox(width: 6),
                              Text(
                                task.category.name,
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: task.category.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: priorityColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            task.priority.name.toUpperCase(),
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: priorityColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // --- Task Title ---
                    Text(
                      task.title,
                      style: GoogleFonts.outfit(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- Details Card (Due date, duration, reminder, notes) ---
                    Text(
                      'Details',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceCard : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: isDark ? Border.all(color: AppColors.darkBorder) : null,
                        boxShadow: isDark
                            ? []
                            : [
                                BoxShadow(
                                  color: AppColors.lightCardShadow,
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailItem(
                            icon: Icons.calendar_today_rounded,
                            label: "Due Date & Time",
                            value: DateFormat('MMM dd, yyyy - h:mm a').format(task.dueDate),
                            isDark: isDark,
                          ),
                          const Divider(height: 24, thickness: 1),
                          _buildDetailItem(
                            icon: Icons.timer_outlined,
                            label: "Duration",
                            value: task.duration > 0 ? _formatDuration(task.duration) : "None",
                            isDark: isDark,
                          ),
                          const Divider(height: 24, thickness: 1),
                          _buildDetailItem(
                            icon: Icons.notifications_none_rounded,
                            label: "Reminder",
                            value: task.reminderMinutes != -1 ? _formatReminder(task.reminderMinutes) : "None",
                            isDark: isDark,
                          ),
                          if (task.description.isNotEmpty) ...[
                            const Divider(height: 24, thickness: 1),
                            _buildDetailItem(
                              icon: Icons.notes_rounded,
                              label: "Description",
                              value: task.description,
                              isDark: isDark,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- Subtasks Checklist Section ---
                    if (task.subtasks.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Subtasks',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            ),
                          ),
                          Text(
                            '$completedSubtasksCount of ${task.subtasks.length} done',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Subtask Progress bar
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceCard : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: isDark ? Border.all(color: AppColors.darkBorder) : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Completion',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  ),
                                ),
                                Text(
                                  '${(task.progressPercentage * 100).toInt()}%',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: priorityColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: task.progressPercentage,
                                backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                valueColor: AlwaysStoppedAnimation<Color>(priorityColor),
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Checklist items
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: task.subtasks.length,
                        itemBuilder: (context, idx) {
                          final subtask = task.subtasks[idx];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkSurfaceCard : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: isDark ? Border.all(color: AppColors.darkBorder) : null,
                              ),
                              child: ListTile(
                                dense: true,
                                leading: Checkbox(
                                  value: subtask.isCompleted,
                                  activeColor: priorityColor,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  onChanged: (_) => vm.toggleSubtaskCompletion(task.id, subtask.id),
                                ),
                                title: Text(
                                  subtask.title,
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    decoration: subtask.isCompleted ? TextDecoration.lineThrough : null,
                                    color: subtask.isCompleted
                                        ? (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)
                                        : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // --- Bottom Action Area ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Complete / Active wide button
                  Expanded(
                    child: GestureDetector(
                      onTap: () => vm.toggleTaskCompletion(task.id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white : const Color(0xFF121212),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              task.isCompleted ? Icons.undo_rounded : Icons.check_rounded,
                              color: isDark ? Colors.black : Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              task.isCompleted ? 'Mark Active' : 'Mark Complete',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.black : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Delete task button
                  TextButton.icon(
                    onPressed: () => _showDeleteDialog(context, vm, task),
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 20),
                    label: Text(
                      'Delete Task',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.danger,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatReminder(int minutes) {
    if (minutes == 0) return "At Start";
    if (minutes < 60) return "$minutes minutes before";
    final hours = minutes ~/ 60;
    return "$hours hour${hours > 1 ? 's' : ''} before";
  }

  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) {
      return "$hours hour${hours > 1 ? 's' : ''}${mins > 0 ? ' $mins mins' : ''}";
    }
    return "$mins minutes";
  }
}

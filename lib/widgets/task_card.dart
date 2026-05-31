import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../models/task_model.dart';

class TaskCard extends StatefulWidget {
  final TaskModel task;
  final bool isDark;
  final VoidCallback onToggleComplete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TaskCard({
    super.key,
    required this.task,
    required this.isDark,
    required this.onToggleComplete,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  bool _pressed = false;

  TaskModel get task => widget.task;
  bool get isDark => widget.isDark;

  @override
  Widget build(BuildContext context) {
    final priorityColor = AppColors.getPriorityColor(task.priority.name);
    final priorityGradient = AppColors.getPriorityGradient(task.priority.name);

    return GestureDetector(
      onTap: widget.onEdit, // Tapping card will trigger onEdit, which navigates to DetailView
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceCard : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: isDark ? Border.all(color: AppColors.darkBorder) : null,
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: AppColors.lightCardShadow,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          clipBehavior: Clip.antiAlias, // Clip the left color bar to card corners
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Far Left Accent Color Stripe
                Container(
                  width: 5,
                  color: task.category.color,
                ),
                
                // 2. Main content area
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Row(
                      children: [
                        // Checkbox
                        GestureDetector(
                          onTap: widget.onToggleComplete,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              gradient: task.isCompleted ? priorityGradient : null,
                              shape: BoxShape.circle,
                              border: task.isCompleted
                                  ? null
                                  : Border.all(
                                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                      width: 2,
                                    ),
                            ),
                            child: task.isCompleted
                                ? const Icon(Icons.check, color: Colors.white, size: 14)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Title & Subtitle (Category • Time)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                task.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: task.isCompleted
                                      ? (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)
                                      : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                                  decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                  decorationColor: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    task.category.icon,
                                    size: 11,
                                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "${task.category.name}  •  ${DateFormat('h:mm a').format(task.dueDate)}",
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Priority Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: priorityColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: priorityColor.withOpacity(0.2)),
                          ),
                          child: Text(
                            task.priority.name.toUpperCase(),
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: priorityColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

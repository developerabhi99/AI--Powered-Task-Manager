import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../models/task_model.dart';
import '../../models/category_model.dart';
import '../../models/subtask_model.dart';
import '../../viewmodels/task_viewmodel.dart';

class AddEditTaskView extends StatefulWidget {
  final TaskModel? taskToEdit;

  const AddEditTaskView({super.key, this.taskToEdit});

  @override
  State<AddEditTaskView> createState() => _AddEditTaskViewState();
}

class _AddEditTaskViewState extends State<AddEditTaskView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;

  late DateTime _selectedDate;
  late TaskPriority _selectedPriority;
  late CategoryModel _selectedCategory;
  List<SubtaskModel> _subtasks = [];
  final TextEditingController _subtaskInputController = TextEditingController();
  
  late int _selectedDuration; // in minutes
  late String _durationOption;
  late int _selectedReminderMinutes; // in minutes (-1 for none)

  @override
  void initState() {
    super.initState();
    final task = widget.taskToEdit;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descController = TextEditingController(text: task?.description ?? '');
    _selectedDate = task?.dueDate ?? DateTime.now();
    _selectedPriority = task?.priority ?? TaskPriority.medium;
    _subtasks = task?.subtasks != null ? List.from(task!.subtasks) : [];
    
    _selectedDuration = task?.duration ?? 0;
    _selectedReminderMinutes = task?.reminderMinutes ?? -1;
    if (_selectedDuration == 0) {
      _durationOption = 'none';
    } else if (_selectedDuration == 15) {
      _durationOption = '15m';
    } else if (_selectedDuration == 30) {
      _durationOption = '30m';
    } else if (_selectedDuration == 45) {
      _durationOption = '45m';
    } else if (_selectedDuration == 60) {
      _durationOption = '1h';
    } else if (_selectedDuration == 120) {
      _durationOption = '2h';
    } else {
      _durationOption = 'custom';
    }

    final viewModel = Provider.of<TaskViewModel>(context, listen: false);
    _selectedCategory = task?.category ?? viewModel.categories.first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _subtaskInputController.dispose();
    super.dispose();
  }

  void _addSubtask() {
    final title = _subtaskInputController.text.trim();
    if (title.isNotEmpty) {
      setState(() {
        _subtasks.add(SubtaskModel(
          id: const Uuid().v4(),
          title: title,
          isCompleted: false,
        ));
        _subtaskInputController.clear();
      });
    }
  }

  void _removeSubtask(int index) {
    setState(() {
      _subtasks.removeAt(index);
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: AppColors.primaryBlue,
                    onPrimary: Colors.white,
                    surface: AppColors.darkSurfaceCard,
                  )
                : const ColorScheme.light(
                    primary: AppColors.primaryBlue,
                    onPrimary: Colors.white,
                    surface: AppColors.lightSurface,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      if (!context.mounted) return;
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
        builder: (context, child) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: isDark
                  ? const ColorScheme.dark(
                      primary: AppColors.primaryBlue,
                      surface: AppColors.darkSurfaceCard,
                    )
                  : const ColorScheme.light(
                      primary: AppColors.primaryBlue,
                      surface: AppColors.lightSurface,
                    ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  void _saveTask() {
    if (_formKey.currentState!.validate()) {
      final viewModel = Provider.of<TaskViewModel>(context, listen: false);
      final isEditing = widget.taskToEdit != null;

      final task = TaskModel(
        id: widget.taskToEdit?.id ?? const Uuid().v4(),
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        dueDate: _selectedDate,
        priority: _selectedPriority,
        category: _selectedCategory,
        subtasks: _subtasks,
        isCompleted: widget.taskToEdit?.isCompleted ?? false,
        duration: _selectedDuration,
        reminderMinutes: _selectedReminderMinutes,
      );

      if (isEditing) {
        viewModel.updateTask(task);
      } else {
        viewModel.addTask(task);
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final viewModel = Provider.of<TaskViewModel>(context);
    final isEditing = widget.taskToEdit != null;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 20,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Edit Task' : 'Create New Task',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Title Field
              TextFormField(
                controller: _titleController,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
                decoration: const InputDecoration(
                  labelText: 'Task Title',
                  hintText: 'Enter title...',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description Field
              TextFormField(
                controller: _descController,
                maxLines: 3,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Enter detailed description...',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),

              // Category Selector
              Text('Category', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: viewModel.categories.length,
                  itemBuilder: (context, index) {
                    final cat = viewModel.categories[index];
                    final isSelected = cat.id == _selectedCategory.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(cat.name),
                        avatar: Icon(cat.icon, size: 16, color: isSelected ? Colors.white : cat.color),
                        selected: isSelected,
                        selectedColor: cat.color,
                        checkmarkColor: Colors.white,
                        labelStyle: GoogleFonts.outfit(
                          color: isSelected
                              ? Colors.white
                              : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedCategory = cat;
                            });
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Priority Selector
              Text('Priority', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Row(
                children: TaskPriority.values.map((priority) {
                  final priorityName = priority.name[0].toUpperCase() + priority.name.substring(1);
                  final isSelected = _selectedPriority == priority;
                  final priorityColor = AppColors.getPriorityColor(priority.name);

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedPriority = priority;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: priorityColor,
                            borderRadius: BorderRadius.circular(12),
                            border: isSelected
                                ? Border.all(
                                    color: isDark ? Colors.white : Colors.black,
                                    width: 2.5,
                                  )
                                : Border.all(color: Colors.transparent),
                          ),
                          child: Center(
                            child: Text(
                              priorityName,
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Due Date & Time Picker
              GestureDetector(
                onTap: () => _selectDate(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DUE DATE & TIME',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkTextMuted,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('MMM dd, yyyy \'at\' hh:mm a').format(_selectedDate),
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        Icons.calendar_today,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Task Duration Selector
              Text('Task Duration', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildDurationChip('None', 'none', 0),
                    _buildDurationChip('15m', '15m', 15),
                    _buildDurationChip('30m', '30m', 30),
                    _buildDurationChip('45m', '45m', 45),
                    _buildDurationChip('1h', '1h', 60),
                    _buildDurationChip('2h', '2h', 120),
                    _buildDurationChip('Custom', 'custom', -1),
                  ],
                ),
              ),
              if (_durationOption == 'custom') ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface.withOpacity(0.5) : AppColors.lightSurfaceCard,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hours: ${_selectedDuration ~/ 60}h',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                            Slider(
                              value: (_selectedDuration ~/ 60).toDouble(),
                              min: 0,
                              max: 12,
                              divisions: 12,
                              activeColor: AppColors.primaryBlue,
                              inactiveColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                              onChanged: (val) {
                                setState(() {
                                  final mins = _selectedDuration % 60;
                                  _selectedDuration = (val.toInt() * 60) + mins;
                                  if (_selectedDuration == 0) _selectedDuration = 5;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Minutes: ${_selectedDuration % 60}m',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                            Slider(
                              value: (_selectedDuration % 60).toDouble(),
                              min: 0,
                              max: 55,
                              divisions: 11,
                              activeColor: AppColors.primaryBlue,
                              inactiveColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                              onChanged: (val) {
                                setState(() {
                                  final hrs = _selectedDuration ~/ 60;
                                  _selectedDuration = (hrs * 60) + val.toInt();
                                  if (_selectedDuration == 0) _selectedDuration = 5;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // Task Reminder Selector
              Text('Task Reminder (Before Start)', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildReminderChip('None', -1),
                    _buildReminderChip('At Start', 0),
                    _buildReminderChip('5m', 5),
                    _buildReminderChip('15m', 15),
                    _buildReminderChip('30m', 30),
                    _buildReminderChip('1h', 60),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Subtasks
              Text(
                'Subtasks (${_subtasks.length})',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _subtaskInputController,
                      style: GoogleFonts.outfit(fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Add a subtask...',
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: (_) => _addSubtask(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _addSubtask,
                    icon: const Icon(Icons.add),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_subtasks.isNotEmpty)
                Container(
                  constraints: const BoxConstraints(maxHeight: 180),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _subtasks.length,
                    itemBuilder: (context, index) {
                      final sub = _subtasks[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurface.withOpacity(0.5)
                                : AppColors.lightBackground,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.checklist_rtl_rounded,
                                size: 16,
                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  sub.title,
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 16, color: AppColors.danger),
                                onPressed: () => _removeSubtask(index),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 24),

              // Save Button
              GestureDetector(
                onTap: _saveTask,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: AppColors.purplePinkGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentPink.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        isEditing ? 'Save Changes' : 'Save Task',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
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
    );
  }

  Widget _buildDurationChip(String label, String option, int minutes) {
    final isSelected = _durationOption == option;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: AppColors.primaryBlue,
        checkmarkColor: Colors.white,
        labelStyle: GoogleFonts.outfit(
          color: isSelected
              ? Colors.white
              : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _durationOption = option;
              if (minutes != -1) {
                _selectedDuration = minutes;
              } else {
                // If custom, default to 30 mins
                _selectedDuration = 30;
              }
            });
          }
        },
      ),
    );
  }

  Widget _buildReminderChip(String label, int minutes) {
    final isSelected = _selectedReminderMinutes == minutes;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: AppColors.primaryBlue,
        checkmarkColor: Colors.white,
        labelStyle: GoogleFonts.outfit(
          color: isSelected
              ? Colors.white
              : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _selectedReminderMinutes = minutes;
            });
          }
        },
      ),
    );
  }
}

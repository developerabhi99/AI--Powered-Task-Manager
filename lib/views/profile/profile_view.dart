import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../viewmodels/user_profile_viewmodel.dart';
import '../../viewmodels/task_viewmodel.dart';
import '../../viewmodels/fitness_viewmodel.dart';
import '../../services/notification_service.dart';
import '../../widgets/user_avatar_widget.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> with TickerProviderStateMixin {
  bool _isEditing = false;
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _bioCtrl;

  late AnimationController _avatarController;
  late AnimationController _formController;
  late Animation<double> _avatarScale;
  late Animation<double> _formFade;
  late Animation<Offset> _formSlide;

  @override
  void initState() {
    super.initState();
    final profile = context.read<UserProfileViewModel>().profile;
    _nameCtrl = TextEditingController(text: profile.name);
    _emailCtrl = TextEditingController(text: profile.email);
    _phoneCtrl = TextEditingController(text: profile.phone);
    _bioCtrl = TextEditingController(text: profile.bio);

    _avatarController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _formController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

    _avatarScale = CurvedAnimation(parent: _avatarController, curve: Curves.elasticOut);
    _formFade = CurvedAnimation(parent: _formController, curve: Curves.easeOut);
    _formSlide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _formController, curve: Curves.easeOut));

    _avatarController.forward();
    Future.delayed(const Duration(milliseconds: 200), () => _formController.forward());
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose();
    _phoneCtrl.dispose(); _bioCtrl.dispose();
    _avatarController.dispose(); _formController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _buildImageSourceSheet(),
    );
    if (source == null) return;
    final file = await picker.pickImage(source: source, imageQuality: 85, maxWidth: 512);
    if (file != null && mounted) {
      await context.read<UserProfileViewModel>().updateAvatar(file.path);
    }
  }

  Widget _buildImageSourceSheet() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Update Photo', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primaryBlue),
            title: Text('Camera', style: GoogleFonts.outfit()),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_rounded, color: AppColors.primaryIndigo),
            title: Text('Gallery', style: GoogleFonts.outfit()),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfile() async {
    await context.read<UserProfileViewModel>().updateProfile(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      bio: _bioCtrl.text.trim(),
    );
    setState(() => _isEditing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Profile updated! ✨', style: GoogleFonts.outfit()),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  Future<void> _updateFitnessGoals(BuildContext context, FitnessViewModel vm) async {
    final stepsCtrl = TextEditingController(text: vm.dailyData.stepGoal.toString());
    final calsCtrl = TextEditingController(text: vm.dailyData.calorieGoal.toString());

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Fitness Goals', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: stepsCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Daily Step Goal'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: calsCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Daily Calorie Goal'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final steps = int.tryParse(stepsCtrl.text) ?? 10000;
              final cals = int.tryParse(calsCtrl.text) ?? 2000;
              vm.setGoals(steps, cals);
              Navigator.pop(ctx);
            },
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _updateReminderTime(BuildContext context, FitnessViewModel vm) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: vm.reminderHour, minute: vm.reminderMinute),
    );
    if (picked != null) {
      await vm.setReminderTime(picked.hour, picked.minute);
      await NotificationService.scheduleDailyWorkoutReminder(hour: picked.hour, minute: picked.minute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileVM = context.watch<UserProfileViewModel>();
    final taskVM = context.watch<TaskViewModel>();
    final fitnessVM = context.watch<FitnessViewModel>();
    final profile = profileVM.profile;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: CustomScrollView(
        slivers: [
          // ── Gradient Header ──────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.primaryBlue,
            actions: [
              TextButton.icon(
                onPressed: () => setState(() => _isEditing = !_isEditing),
                icon: Icon(_isEditing ? Icons.close : Icons.edit_rounded, color: Colors.white, size: 18),
                label: Text(_isEditing ? 'Cancel' : 'Edit',
                    style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: AppColors.profileGradient),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                // ── Avatar ────────────────────────────────────────────────
                Transform.translate(
                  offset: const Offset(0, -55),
                  child: Column(
                    children: [
                      ScaleTransition(
                        scale: _avatarScale,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Hero(
                              tag: 'user_avatar',
                              child: UserAvatarWidget(profile: profile, size: 100, showRing: true),
                            ),
                            GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                width: 32, height: 32,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryBlue,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(profile.name, style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.bold, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
                      const SizedBox(height: 4),
                      Text('Personal Task Manager', style: GoogleFonts.outfit(fontSize: 14, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
                    ],
                  ),
                ),

                // ── Stats Row ────────────────────────────────────────────
                Transform.translate(
                  offset: const Offset(0, -30),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        _StatChip(value: taskVM.totalTasksCount, label: 'Created'),
                        const SizedBox(width: 12),
                        _StatChip(value: taskVM.completedTasksCount, label: 'Completed'),
                        const SizedBox(width: 12),
                        _StatChip(value: taskVM.todayTasksCount, label: 'Today'),
                      ],
                    ),
                  ),
                ),

                // ── Edit Form / Info ──────────────────────────────────────
                FadeTransition(
                  opacity: _formFade,
                  child: SlideTransition(
                    position: _formSlide,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionLabel('Personal Info'),
                          const SizedBox(height: 12),
                          _ProfileField(label: 'Full Name', icon: Icons.person_outline_rounded,
                              controller: _nameCtrl, enabled: _isEditing),
                          const SizedBox(height: 12),
                          _ProfileField(label: 'Email', icon: Icons.email_outlined,
                              controller: _emailCtrl, enabled: _isEditing, keyboardType: TextInputType.emailAddress),
                          const SizedBox(height: 12),
                          _ProfileField(label: 'Phone', icon: Icons.phone_outlined,
                              controller: _phoneCtrl, enabled: _isEditing, keyboardType: TextInputType.phone),
                          const SizedBox(height: 12),
                          _ProfileField(label: 'Bio', icon: Icons.notes_rounded,
                              controller: _bioCtrl, enabled: _isEditing, maxLines: 3),

                          if (_isEditing) ...[
                            const SizedBox(height: 20),
                            _GradientButton(label: 'Save Changes', onTap: _saveProfile),
                          ],

                          const SizedBox(height: 24),
                          _SectionLabel('Settings'),
                          const SizedBox(height: 12),
                          _SettingsTile(icon: Icons.notifications_outlined, label: 'Notifications', trailing:
                              Switch(
                                value: profileVM.isNotificationsEnabled,
                                activeColor: AppColors.primaryBlue,
                                onChanged: (v) {
                                  profileVM.setNotificationsEnabled(v);
                                },
                              )),
                          _SettingsTile(
                            icon: Icons.dark_mode_outlined,
                            label: 'Dark Mode',
                            trailing: Switch(
                              value: profileVM.isDarkMode,
                              onChanged: (val) {
                                profileVM.setDarkMode(val);
                              },
                              activeColor: AppColors.primaryBlue,
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              showAboutDialog(
                                context: context,
                                applicationName: 'Personal Task Manager',
                                applicationVersion: '1.0.0',
                                applicationLegalese: '© 2026 Your Company',
                                applicationIcon: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: AppColors.primaryBlue, borderRadius: BorderRadius.circular(12)),
                                  child: const Icon(Icons.check_circle_outline, color: Colors.white, size: 32),
                                ),
                              );
                            },
                            child: _SettingsTile(icon: Icons.info_outline_rounded, label: 'About App', trailing:
                                Icon(Icons.chevron_right_rounded, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
                          ),
                              
                          const SizedBox(height: 24),
                          _SectionLabel('Fitness Settings'),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: () => _updateFitnessGoals(context, fitnessVM),
                            child: _SettingsTile(
                              icon: Icons.flag_rounded, 
                              label: 'Daily Goals', 
                              trailing: Text(
                                '${fitnessVM.dailyData.stepGoal} steps, ${fitnessVM.dailyData.calorieGoal} kcal', 
                                style: TextStyle(color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () => _updateReminderTime(context, fitnessVM),
                            child: _SettingsTile(
                              icon: Icons.alarm_rounded, 
                              label: 'Workout Reminder', 
                              trailing: Text(
                                TimeOfDay(hour: fitnessVM.reminderHour, minute: fitnessVM.reminderMinute).format(context), 
                                style: TextStyle(color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Supporting Widgets ─────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final int value;
  final String label;
  const _StatChip({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDark ? AppColors.darkCardShadow : AppColors.lightCardShadow,
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          children: [
            TweenAnimationBuilder<int>(
              tween: IntTween(begin: 0, end: value),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOut,
              builder: (_, v, __) => Text('$v', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
            ),
            const SizedBox(height: 2),
            Text(label, style: GoogleFonts.outfit(fontSize: 11, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text,
      style: GoogleFonts.outfit(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController controller;
  final bool enabled;
  final TextInputType keyboardType;
  final int maxLines;

  const _ProfileField({
    required this.label, required this.icon,
    required this.controller, required this.enabled,
    this.keyboardType = TextInputType.text, this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: enabled
            ? [BoxShadow(color: AppColors.primaryBlue.withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 4))]
            : [BoxShadow(color: isDark ? Colors.black.withOpacity(0.2) : AppColors.lightCardShadow, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: GoogleFonts.outfit(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary, fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.outfit(color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
          prefixIcon: Icon(icon, color: enabled ? AppColors.primaryBlue : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted), size: 20),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}

class _GradientButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _GradientButton({required this.label, required this.onTap});

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final btnBgColor = isDark ? Colors.white : const Color(0xFF121212);
    final btnTextColor = isDark ? Colors.black : Colors.white;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: btnBgColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              widget.label,
              style: GoogleFonts.outfit(
                color: btnTextColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget trailing;
  const _SettingsTile({required this.icon, required this.label, required this.trailing});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: isDark ? AppColors.darkCardShadow : AppColors.lightCardShadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primaryBlue, size: 22),
        title: Text(label, style: GoogleFonts.outfit(fontSize: 15, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
        trailing: trailing,
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/user_profile_model.dart';

class UserAvatarWidget extends StatelessWidget {
  final UserProfileModel profile;
  final double size;
  final VoidCallback? onTap;
  final bool showRing;
  final bool isHero;

  const UserAvatarWidget({
    super.key,
    required this.profile,
    this.size = 44,
    this.onTap,
    this.showRing = true,
    this.isHero = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget avatar = GestureDetector(
      onTap: onTap,
      child: _buildAvatar(),
    );

    if (isHero) {
      return Hero(tag: 'user_avatar', child: avatar);
    }
    return avatar;
  }

  Widget _buildAvatar() {
    final ringSize = size + (showRing ? 6 : 0);
    return Container(
      width: ringSize,
      height: ringSize,
      decoration: showRing
          ? const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.profileGradient,
            )
          : null,
      padding: showRing ? const EdgeInsets.all(3) : EdgeInsets.zero,
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        padding: const EdgeInsets.all(2),
        child: ClipOval(
          child: _avatarContent(),
        ),
      ),
    );
  }

  Widget _avatarContent() {
    if (profile.avatarPath != null && profile.avatarPath!.isNotEmpty) {
      return Image.file(
        File(profile.avatarPath!),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _initialsWidget(),
      );
    }
    return _initialsWidget();
  }

  Widget _initialsWidget() {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        gradient: AppColors.profileGradient,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          profile.initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.35,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

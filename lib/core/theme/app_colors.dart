import 'package:flutter/material.dart';

class AppColors {
  // ── Light Theme Backgrounds ──────────────────────────────────────────────
  static const Color lightBackground = Color(0xFFEEF2FF); // soft indigo-white
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceCard = Color(0xFFF5F7FF);
  static const Color lightAccentSurface = Color(0xFFE8EEFF);

  // ── Dark Theme Backgrounds ───────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF0F111A);
  static const Color darkSurface = Color(0xFF161925);
  static const Color darkSurfaceCard = Color(0xFF1E2235);

  // ── Borders ──────────────────────────────────────────────────────────────
  static const Color darkBorder = Color(0xFF2E344E);
  static const Color lightBorder = Color(0xFFDDE2F5);

  // ── Card Shadows ─────────────────────────────────────────────────────────
  static const Color lightCardShadow = Color(0x18000066);
  static const Color darkCardShadow = Color(0x40000000);

  // ── Primary Accent ───────────────────────────────────────────────────────
  static const Color primaryBlue = Color(0xFF3B82F6);   // vibrant blue
  static const Color primaryIndigo = Color(0xFF6366F1); // indigo
  static const Color primaryPurple = Color(0xFF8B5CF6); // purple

  static const Color accentPurple = Color(0xFF9B5DE5);
  static const Color accentPink = Color(0xFFF15BB5);

  // ── Priority Colors ──────────────────────────────────────────────────────
  static const Color priorityHighStart = Color(0xFFFF4B72);
  static const Color priorityHighEnd = Color(0xFFFF7660);

  static const Color priorityMediumStart = Color(0xFFFF9F43);
  static const Color priorityMediumEnd = Color(0xFFFFC048);

  static const Color priorityLowStart = Color(0xFF05C46B);
  static const Color priorityLowEnd = Color(0xFF0BE881);

  // ── Text Colors ──────────────────────────────────────────────────────────
  static const Color darkTextPrimary = Color(0xFFF8F9FA);
  static const Color darkTextSecondary = Color(0xFFA4B0BE);
  static const Color darkTextMuted = Color(0xFF747D8C);

  static const Color lightTextPrimary = Color(0xFF1A1D2E);
  static const Color lightTextSecondary = Color(0xFF4B5563);
  static const Color lightTextMuted = Color(0xFF9CA3AF);

  // ── Status Colors ────────────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);

  // ── Reports Colors ───────────────────────────────────────────────────────
  static const Color reportGoodColor = Color(0xFF00B894);  // teal green
  static const Color reportBadColor = Color(0xFFFF7675);   // coral red
  static const Color starColor = Color(0xFFFDCB6E);        // warm gold
  static const Color heatmapEmpty = Color(0xFFE5E7EB);
  static const Color heatmapLow = Color(0xFFBFDBFE);
  static const Color heatmapMid = Color(0xFF60A5FA);
  static const Color heatmapHigh = Color(0xFF2563EB);

  // ── Gradients ────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryBlue, primaryIndigo],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient profileGradient = LinearGradient(
    colors: [primaryIndigo, primaryPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purplePinkGradient = LinearGradient(
    colors: [accentPurple, accentPink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient priorityHighGradient = LinearGradient(
    colors: [priorityHighStart, priorityHighEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient priorityMediumGradient = LinearGradient(
    colors: [priorityMediumStart, priorityMediumEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient priorityLowGradient = LinearGradient(
    colors: [priorityLowStart, priorityLowEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient reportGoodGradient = LinearGradient(
    colors: [Color(0xFF00B894), Color(0xFF00CEC9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient reportBadGradient = LinearGradient(
    colors: [Color(0xFFFF7675), Color(0xFFD63031)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Helpers ──────────────────────────────────────────────────────────────
  static LinearGradient getPriorityGradient(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return priorityHighGradient;
      case 'medium':
        return priorityMediumGradient;
      case 'low':
      default:
        return priorityLowGradient;
    }
  }

  static Color getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return priorityHighStart;
      case 'medium':
        return priorityMediumStart;
      case 'low':
      default:
        return priorityLowStart;
    }
  }
}

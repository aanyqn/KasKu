import 'package:flutter/material.dart';

/// Kasku design tokens — Emerald-Teal color palette
class AppColors {
  AppColors._();

  // ── Brand ──────────────────────────────────────────────────────────────────
  static const emerald = Color(0xFF10B981);
  static const emeraldLight = Color(0xFF34D399);
  static const emeraldDark = Color(0xFF059669);
  static const teal = Color(0xFF14B8A6);

  // ── Dark theme surfaces ────────────────────────────────────────────────────
  static const darkBackground = Color(0xFF0D1117);
  static const darkSurface = Color(0xFF161B22);
  static const darkCard = Color(0xFF1C2128);
  static const darkElevated = Color(0xFF21262D);
  static const darkBorder = Color(0xFF30363D);

  // ── Light theme surfaces ───────────────────────────────────────────────────
  static const lightBackground = Color(0xFFF6F8FA);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightBorder = Color(0xFFD0D7DE);

  // ── Semantic ───────────────────────────────────────────────────────────────
  static const income = Color(0xFF10B981);    // green
  static const expense = Color(0xFFF85149);   // red
  static const warning = Color(0xFFD29922);   // amber

  // ── Text ───────────────────────────────────────────────────────────────────
  static const textPrimary = Color(0xFFF0F6FC);
  static const textSecondary = Color(0xFF8B949E);
  static const textMuted = Color(0xFF484F58);
  static const textPrimaryLight = Color(0xFF24292F);
  static const textSecondaryLight = Color(0xFF57606A);

  // ── Chart palette (for pie chart slices) ───────────────────────────────────
  static const chartColors = [
    Color(0xFF10B981), // emerald
    Color(0xFF3B82F6), // blue
    Color(0xFFF59E0B), // amber
    Color(0xFFEC4899), // pink
    Color(0xFF8B5CF6), // violet
    Color(0xFF06B6D4), // cyan
    Color(0xFFF97316), // orange
    Color(0xFF84CC16), // lime
    Color(0xFFEF4444), // red
    Color(0xFF6366F1), // indigo
  ];
}

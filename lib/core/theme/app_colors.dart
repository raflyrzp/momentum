import 'package:flutter/material.dart';

/// Token warna Momentum (dark-mode first).
abstract final class AppColors {
  static const background = Color(0xFF0F1115); // Deep Obsidian
  static const surface = Color(0xFF181B22); // Slate Charcoal
  static const surfaceHigh = Color(0xFF20242D);
  static const primary = Color(0xFF6366F1); // Electric Indigo
  static const reward = Color(0xFF10B981); // Emerald Mint
  static const streak = Color(0xFFF59E0B); // Amber Flame
  static const shield = Color(0xFF06B6D4); // Cyan Frost
  static const text = Color(0xFFF8FAFC); // Snow
  static const textMuted = Color(0xFF94A3B8); // Slate
  static const danger = Color(0xFFF87171);
}

abstract final class AppRadius {
  static const double card = 16;
  static const borderRadius = BorderRadius.all(Radius.circular(card));
}

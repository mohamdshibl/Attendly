import 'package:flutter/material.dart';

class AppColors {
  // Primary & Brand Colors
  static const Color primary = Color(0xFF0F172A);      // Slate 900
  static const Color primaryLight = Color(0xFF1E293B); // Slate 800
  static const Color secondary = Color(0xFF0D9488);    // Teal 600
  static const Color secondaryLight = Color(0xFF14B8A6); // Teal 500
  static const Color accent = Color(0xFF3B82F6);       // Blue 500

  // Neutral Colors
  static const Color background = Color(0xFFF8FAFC);   // Slate 50
  static const Color surface = Color(0xFFFFFFFF);      // White
  static const Color border = Color(0xFFE2E8F0);       // Slate 200
  
  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A);  // Slate 900
  static const Color textSecondary = Color(0xFF64748B); // Slate 500
  static const Color textLight = Color(0xFF94A3B8);     // Slate 400

  // Status & Semantic Colors
  static const Color success = Color(0xFF10B981);      // Green 500 (Present/On Time)
  static const Color warning = Color(0xFFF59E0B);      // Amber 500 (Late)
  static const Color error = Color(0xFFEF4444);        // Red 500 (Absent / Error)
  static const Color info = Color(0xFF3B82F6);         // Blue 500 (Checked Out)
  static const Color pending = Color(0xFF64748B);      // Slate 500 (Not Checked In)
}

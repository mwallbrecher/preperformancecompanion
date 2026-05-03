import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle get prompt => GoogleFonts.dmSans(
        fontSize: 24,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        letterSpacing: -0.4,
        height: 1.3,
      );

  static TextStyle get promptSecondary => GoogleFonts.dmSans(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.5,
      );

  static TextStyle get cardTitle => GoogleFonts.dmSans(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: -0.2,
      );

  static TextStyle get cardSubtitle => GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.4,
      );

  static TextStyle get ghostButton => GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        letterSpacing: 0.1,
      );

  static TextStyle get completionTitle => GoogleFonts.dmSans(
        fontSize: 28,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
        height: 1.2,
      );

  static TextStyle get completionBody => GoogleFonts.dmSans(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.5,
      );

  static TextStyle get debugMono => const TextStyle(
        fontFamily: 'monospace',
        fontSize: 11,
        color: Color(0xFF444444),
        height: 1.4,
      );

  static TextStyle get debugLabel => GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get durationOption => GoogleFonts.dmSans(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      );

  static TextStyle get nodeLabel => GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        height: 1.2,
      );
}

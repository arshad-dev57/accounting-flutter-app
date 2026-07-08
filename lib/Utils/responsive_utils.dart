// lib/core/utils/responsive_utils.dart
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class ResponsiveUtils {
  // ── Breakpoints ──────────────────────────────────────────────────
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 1200;

  static bool isWeb(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1200;

  // ── Screen padding ───────────────────────────────────────────────
  static EdgeInsets getScreenPadding(BuildContext context) {
    if (isWeb(context)) {
      return EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h);
    } else if (isTablet(context)) {
      return EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h);
    } else {
      return EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h);
    }
  }

  // ── Form container width ─────────────────────────────────────────
  /// On web the form sits inside the right half, so we cap it.
  /// On tablet we use a comfortable centered column.
  /// On mobile it fills the screen.
  static double getFormWidth(BuildContext context) {
    if (isWeb(context)) return 38.w;
    if (isTablet(context)) return 55.w;
    return double.infinity;
  }

  // ── Illustration panel — only for web left side ──────────────────
  static bool showImageSection(BuildContext context) => isWeb(context);

  // ── Typography ───────────────────────────────────────────────────
  static double getHeadingFontSize(BuildContext context) {
    if (isWeb(context)) return 22.sp;
    if (isTablet(context)) return 20.sp;
    return 18.sp;
  }

  static double getSubheadingFontSize(BuildContext context) {
    if (isWeb(context)) return 12.sp;
    if (isTablet(context)) return 12.sp;
    return 11.sp;
  }

  // ── Button height ────────────────────────────────────────────────
  static double getButtonHeight(BuildContext context) {
    if (isWeb(context)) return 6.h;
    if (isTablet(context)) return 5.5.h;
    return 6.h;
  }

  // ── Logo size ────────────────────────────────────────────────────
  static double getLogoSize(BuildContext context) {
    if (isWeb(context)) return 10.w;
    if (isTablet(context)) return 12.w;
    return 18.w;
  }
  // ResponsiveUtils class mein add karo

// ── Icon size ────────────────────────────────────────────────────
static double getIconSize(BuildContext context) {
  if (isWeb(context)) return 24;
  if (isTablet(context)) return 20;
  return 18;
}
}

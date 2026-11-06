import 'package:flutter/material.dart';

class AppSizes {
  static const double space2 = 2;
  static const double space4 = 4;
  static const double space6 = 6;
  static const double space8 = 8;
  static const double space10 = 10;
  static const double space12 = 12;
  static const double space14 = 14;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space22 = 22;
  static const double space24 = 24;
  static const double space32 = 32;
  static const double space36 = 36;
  static const double space48 = 48;

  static const double radiusM = 12;
  static const double radiusL = 24;

  static const double topBarHeight = 48;

  static const double compactBreakpointWidth = 700;
  static const double compactBreakpointHeight = 500;

  static bool isCompactLayout(BoxConstraints constraints) {
    return constraints.maxWidth < compactBreakpointWidth ||
        constraints.maxHeight < compactBreakpointHeight;
  }

  static bool isCompactSize(Size size) {
    return size.width < compactBreakpointWidth ||
        size.height < compactBreakpointHeight;
  }

  static double keyWidth(double screenWidth) {
    return (screenWidth / 20).clamp(24.0, 60.0).toDouble();
  }

  static double overlayHorizontalPadding(double screenWidth) {
    return (screenWidth * 0.03).clamp(4.0, 32.0);
  }

  static double overlayVerticalPadding(double screenHeight) {
    return (screenHeight * 0.01).clamp(1.0, 16.0);
  }

  static double chordRootFontSize(double sizeBasis) {
    return (sizeBasis * 0.2).clamp(24.0, 120.0);
  }

  static double chordSuffixFontSize(double sizeBasis) {
    return (sizeBasis * 0.2).clamp(16.0, 110.0);
  }
}

extension AppSizedBoxExtension on num {
  SizedBox get sbHeight => SizedBox(height: toDouble());
  SizedBox get sbWidth => SizedBox(width: toDouble());
}

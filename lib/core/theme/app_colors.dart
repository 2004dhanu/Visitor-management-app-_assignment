import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const Color indigo = Color(0xFF4F46E5);
  static const Color indigoBright = Color(0xFF5B52F0);
  static const Color violet = Color(0xFF8B5CF6);
  static const Color indigoLight = Color(0xFF818CF8);
  static const Color indigoSoft = Color(0xFFEEF0FE);
  static const Color indigoDeep = Color(0xFF312E81);

  static const Color registered = Color(0xFF4F46E5);
  static const Color checkedIn = Color(0xFF16A34A);
  static const Color checkedOut = Color(0xFF64748B);
  static const Color exit = Color(0xFFEF4444);

  static const Color danger = Color(0xFFEF4444);
  static const Color dangerSoft = Color(0xFFFEECEC);
  static const Color warning = Color(0xFFF59E0B);
  static const Color successSoft = Color(0xFFEAF8EF);

  static const Color canvas = Color(0xFFF6F7FB);
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F3F9);
  static const Color slate200 = Color(0xFFE8EAF2);
  static const Color slate300 = Color(0xFFCBD2E0);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate950 = Color(0xFF070B16);

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF4F5BF5), Color(0xFF8B5CF6)],
  );

  static const LinearGradient subtleGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFC9CCF7), Color(0xFFDED8F8)],
  );

  static Color tileWash(Color accent) => accent.withValues(alpha: 0.05);
}

class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  static const double gutter = 18;

  static const double navClearance = 118;
}

class AppRadius {
  const AppRadius._();

  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 22;
  static const double pill = 999;
}

class AppShadows {
  const AppShadows._();

  static List<BoxShadow> card(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return const [
        BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 4)),
      ];
    }
    return const [
      BoxShadow(color: Color(0x0A0F172A), blurRadius: 10, offset: Offset(0, 3)),
    ];
  }

  static List<BoxShadow> floating(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return const [
        BoxShadow(color: Color(0x66000000), blurRadius: 24, offset: Offset(0, 8)),
      ];
    }
    return const [
      BoxShadow(color: Color(0x140F172A), blurRadius: 22, offset: Offset(0, 8)),
      BoxShadow(color: Color(0x0A0F172A), blurRadius: 4, offset: Offset(0, 2)),
    ];
  }
}

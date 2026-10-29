import 'package:intl/intl.dart';

class AppDate {
  const AppDate._();

  static final DateFormat _full = DateFormat('dd MMM yyyy, hh:mm a');
  static final DateFormat _timeOnly = DateFormat('hh:mm a');
  static final DateFormat _dayMonth = DateFormat('d MMM');

  static DateTime? tryParseLocal(String? iso) {
    if (iso == null || iso.trim().isEmpty) return null;
    return DateTime.tryParse(iso)?.toLocal();
  }

  static String nowIso() => toIso(DateTime.now());

  static String toIso(DateTime dateTime) {
    final local = dateTime.toLocal();
    final offset = local.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final absolute = offset.abs();
    final hours = absolute.inHours.toString().padLeft(2, '0');
    final minutes = (absolute.inMinutes % 60).toString().padLeft(2, '0');
    final stamp = local.toIso8601String().split('.').first;
    return '$stamp$sign$hours:$minutes';
  }

  static bool isToday(String? iso) {
    final date = tryParseLocal(iso);
    if (date == null) return false;
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  static String format(String? iso, {String fallback = 'Not recorded'}) {
    final date = tryParseLocal(iso);
    return date == null ? fallback : _full.format(date);
  }

  static String formatTime(String? iso, {String fallback = 'Not recorded'}) {
    final date = tryParseLocal(iso);
    return date == null ? fallback : _timeOnly.format(date);
  }

  static String relativeLabel(String? iso, {String fallback = ''}) {
    final date = tryParseLocal(iso);
    if (date == null) return fallback;

    final now = DateTime.now();
    final day = DateTime(date.year, date.month, date.day);
    final today = DateTime(now.year, now.month, now.day);
    final difference = today.difference(day).inDays;

    if (difference == 0) return _timeOnly.format(date);
    if (difference == 1) return 'Yesterday';
    return _dayMonth.format(date);
  }

  static String relativeLong(String? iso, {String fallback = ''}) {
    final date = tryParseLocal(iso);
    if (date == null) return fallback;

    final now = DateTime.now();
    final day = DateTime(date.year, date.month, date.day);
    final today = DateTime(now.year, now.month, now.day);
    final difference = today.difference(day).inDays;

    if (difference == 0) return 'Today, ${_timeOnly.format(date)}';
    if (difference == 1) return 'Yesterday, ${_timeOnly.format(date)}';
    return _full.format(date);
  }
}

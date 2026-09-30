import 'package:intl/intl.dart';

class AppDateUtils {
  AppDateUtils._();

  static String formatFull(DateTime? dateTime) {
    if (dateTime == null) return '';
    final local = dateTime.toLocal();
    try {
      final dateFormat = DateFormat("EEEE d 'de' MMMM · h:mm a", 'es');
      final formatted = dateFormat.format(local);
      return formatted[0].toUpperCase() + formatted.substring(1);
    } catch (_) {
      try {
        return DateFormat("EEEE d 'de' MMMM · h:mm a").format(local);
      } catch (_) {
        return DateFormat('yyyy-MM-dd HH:mm').format(local);
      }
    }
  }

  static String formatShort(DateTime? dateTime) {
    if (dateTime == null) return '';
    final local = dateTime.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final itemDate = DateTime(local.year, local.month, local.day);

    if (itemDate == today) {
      final timeStr = DateFormat('h:mm a').format(local);
      return 'Hoy · $timeStr';
    }

    final tomorrow = today.add(const Duration(days: 1));
    if (itemDate == tomorrow) {
      final timeStr = DateFormat('h:mm a').format(local);
      return 'Mañana · $timeStr';
    }

    try {
      final dateFormat = DateFormat("d 'de' MMM · h:mm a", 'es');
      return dateFormat.format(local);
    } catch (_) {
      try {
        return DateFormat("d MMM · h:mm a").format(local);
      } catch (_) {
        return DateFormat('dd/MM/yyyy HH:mm').format(local);
      }
    }
  }

  static String formatEventBadge(DateTime? dateTime) {
    if (dateTime == null) return '';
    final local = dateTime.toLocal();
    try {
      return DateFormat('dd MMM', 'es').format(local).toUpperCase();
    } catch (_) {
      try {
        return DateFormat('dd MMM').format(local).toUpperCase();
      } catch (_) {
        return DateFormat('dd/MM').format(local);
      }
    }
  }

  static String formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final local = dateTime.toLocal();
    return DateFormat('HH:mm').format(local);
  }

  static String? toIso8601(DateTime? dateTime) {
    if (dateTime == null) return null;
    return dateTime.toUtc().toIso8601String();
  }

  static DateTime? parseIso(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}

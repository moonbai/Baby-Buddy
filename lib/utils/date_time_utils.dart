import 'package:intl/intl.dart';

class DateTimeUtils {
  static String formatForApi(DateTime dateTime) {
    return DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'").format(dateTime.toUtc());
  }

  static String formatDateOnly(DateTime dateTime) {
    return DateFormat("yyyy-MM-dd").format(dateTime.toLocal());
  }

  static String formatTimeOnly(DateTime dateTime) {
    return DateFormat("HH:mm:ss").format(dateTime.toLocal());
  }

  static DateTime parseServerTime(String timeStr) {
    try {
      return DateTime.parse(timeStr).toLocal();
    } catch (e) {
      return DateTime.now();
    }
  }

  static String formatDisplayTime(String timeStr) {
    try {
      final dt = parseServerTime(timeStr);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timeStr;
    }
  }
}

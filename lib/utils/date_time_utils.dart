import 'package:intl/intl.dart';

class DateTimeUtils {
  static String formatForApi(DateTime dateTime) {
    return DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(dateTime.toLocal());
  }

  static String formatDateOnly(DateTime dateTime) {
    return DateFormat("yyyy-MM-dd").format(dateTime.toLocal());
  }

  static String formatTimeOnly(DateTime dateTime) {
    return DateFormat("HH:mm:ss").format(dateTime.toLocal());
  }

  static DateTime parseServerTime(String timeStr) {
    try {
      if (timeStr.contains('Z')) {
        return DateTime.parse(timeStr).toLocal();
      } else if (timeStr.contains('+') || (timeStr.contains('-') && timeStr.indexOf('-') > 10)) {
        return DateTime.parse(timeStr).toLocal();
      } else {
        return DateTime.parse(timeStr);
      }
    } catch (e) {
      return DateTime.now();
    }
  }
}

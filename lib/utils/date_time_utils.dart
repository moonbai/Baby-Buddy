import 'package:intl/intl.dart';

class DateTimeUtils {
  static String toIso8601WithLocalTimezone(DateTime dateTime) {
    return DateFormat("yyyy-MM-dd'T'HH:mm:ssZZZZZ").format(dateTime);
  }

  static String formatForApi(DateTime dateTime) {
    return DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(dateTime.toUtc());
  }

  static String formatDateOnly(DateTime dateTime) {
    return DateFormat("yyyy-MM-dd").format(dateTime);
  }

  static String formatTimeOnly(DateTime dateTime) {
    return DateFormat("HH:mm:ss").format(dateTime.toUtc());
  }

  static DateTime parseServerTime(String timeStr) {
    try {
      if (timeStr.contains('Z')) {
        return DateTime.parse(timeStr).toLocal();
      } else if (timeStr.contains('+') || timeStr.contains('-', timeStr.indexOf('T'))) {
        return DateTime.parse(timeStr).toLocal();
      } else {
        return DateTime.parse(timeStr).toLocal();
      }
    } catch (e) {
      return DateTime.now().toLocal();
    }
  }
}

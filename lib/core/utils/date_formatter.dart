import 'package:intl/intl.dart';

class DateFormatter {
  static String formatDate(DateTime date) {
    return DateFormat(
      'dd MMM yyyy',
    ).format(date);
  }

  static String formatDateTime(
      DateTime date) {
    return DateFormat(
      'dd MMM yyyy HH:mm',
    ).format(date);
  }

  static String formatTime(DateTime date) {
    return DateFormat(
      'HH:mm',
    ).format(date);
  }
}
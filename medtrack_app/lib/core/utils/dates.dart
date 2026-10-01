import 'package:intl/intl.dart';

/// Date/time utilities — all dates stored UTC, displayed in Asia/Kolkata
class DateUtils {
  DateUtils._();

  static final _dateFormatter = DateFormat('dd MMM yyyy');
  static final _dateTimeFormatter = DateFormat('dd MMM yyyy, hh:mm a');
  static final _timeFormatter = DateFormat('hh:mm a');
  static final _dayFormatter = DateFormat('EEE, dd MMM');
  static final _monthYearFormatter = DateFormat('MMM yyyy');
  static final _fullDateFormatter = DateFormat('EEEE, dd MMMM yyyy');

  /// Format as "12 Apr 2025"
  static String formatDate(DateTime dt) => _dateFormatter.format(dt.toLocal());

  /// Format as "12 Apr 2025, 10:24 AM"
  static String formatDateTime(DateTime dt) =>
      _dateTimeFormatter.format(dt.toLocal());

  /// Format as "10:24 AM"
  static String formatTime(DateTime dt) => _timeFormatter.format(dt.toLocal());

  /// Format as "Mon, 12 Apr"
  static String formatDayDate(DateTime dt) =>
      _dayFormatter.format(dt.toLocal());

  /// Format as "Apr 2025"
  static String formatMonthYear(DateTime dt) =>
      _monthYearFormatter.format(dt.toLocal());

  /// Format as "Monday, 12 April 2025"
  static String formatFullDate(DateTime dt) =>
      _fullDateFormatter.format(dt.toLocal());

  /// Relative label: "Today", "Yesterday", "12 Apr 2025"
  static String formatRelative(DateTime dt) {
    final local = dt.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(local.year, local.month, local.day);

    if (dateOnly == today) return 'Today';
    if (dateOnly == today.subtract(const Duration(days: 1))) return 'Yesterday';
    if (dateOnly == today.add(const Duration(days: 1))) return 'Tomorrow';
    return _dateFormatter.format(local);
  }

  /// Relative time label: "Just now", "5 min ago", "2 hours ago", "Yesterday", date
  static String formatRelativeTime(DateTime dt) {
    final local = dt.toLocal();
    final diff = DateTime.now().difference(local);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return _dateFormatter.format(local);
  }

  /// Days until a future date (negative = already past)
  static int daysUntil(DateTime target) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate =
        DateTime(target.year, target.month, target.day);
    return targetDate.difference(today).inDays;
  }

  /// Days since a past date
  static int daysSince(DateTime past) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final pastDate = DateTime(past.year, past.month, past.day);
    return today.difference(pastDate).inDays;
  }

  /// Is same calendar day?
  static bool isSameDay(DateTime a, DateTime b) {
    final al = a.toLocal();
    final bl = b.toLocal();
    return al.year == bl.year && al.month == bl.month && al.day == bl.day;
  }

  /// Start of day in local time (for queries)
  static DateTime startOfDay(DateTime dt) {
    final local = dt.toLocal();
    return DateTime(local.year, local.month, local.day).toUtc();
  }

  /// End of day in local time (for queries)
  static DateTime endOfDay(DateTime dt) {
    final local = dt.toLocal();
    return DateTime(local.year, local.month, local.day, 23, 59, 59, 999)
        .toUtc();
  }

  /// Days remaining in recycle bin (30-day retention)
  static int recycleBinDaysLeft(DateTime deletedAt) {
    final expiresAt = deletedAt.add(const Duration(days: 30));
    return daysUntil(expiresAt).clamp(0, 30);
  }

  /// Licence expiry status label
  static String licenceExpiryLabel(int daysLeft) {
    if (daysLeft < 0) return 'Expired ${-daysLeft} days ago';
    if (daysLeft == 0) return 'Expires today';
    if (daysLeft <= 30) return 'Expires in $daysLeft days';
    return 'Valid — expires in $daysLeft days';
  }
}

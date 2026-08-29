abstract class TimeService {
  DateTime now();
  
  // Helper to get only the date portion (yyyy-MM-dd)
  String getTodayDateString() {
    final currentDate = now();
    final year = currentDate.year;
    final month = currentDate.month.toString().padLeft(2, '0');
    final day = currentDate.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}

class LocalTimeService extends TimeService {
  @override
  DateTime now() {
    // Note: Since this is a local-only MVP, this relies on the user's system clock,
    // which can be modified by the user. In production, this service can be swapped
    // with a ServerTimeService or NTPTimeService to prevent clock tampering.
    return DateTime.now();
  }
}

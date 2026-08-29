import '../../data/models/official_holiday_model.dart';

class LeaveDaysCalculator {
  /// Calculates the number of chargeable leave days for a given period.
  /// If the leave type is ANNUAL or CASUAL, it excludes weekly rest days (Friday/Saturday)
  /// and official holidays. Otherwise, it counts all calendar days.
  static int calculateChargeableDays({
    required DateTime startDate,
    required DateTime endDate,
    required String leaveTypeCode,
    required List<OfficialHolidayModel> holidays,
  }) {
    if (endDate.isBefore(startDate)) return 0;

    int days = 0;
    DateTime current = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);

    // Normalize holiday dates (yyyy-MM-dd)
    final holidayDates = holidays.map((h) {
      return DateTime(h.date.year, h.date.month, h.date.day);
    }).toSet();

    while (!current.isAfter(end)) {
      if (leaveTypeCode == 'ANNUAL' || leaveTypeCode == 'CASUAL') {
        // Exclude Friday (5) and Saturday (6) in Egypt
        final isWeekend = current.weekday == DateTime.friday || current.weekday == DateTime.saturday;
        final isHoliday = holidayDates.contains(current);

        if (!isWeekend && !isHoliday) {
          days++;
        }
      } else {
        // Count all calendar days for SICK, MATERNITY, HAJJ, etc.
        days++;
      }
      current = current.add(const Duration(days: 1));
    }

    return days;
  }
}

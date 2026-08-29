import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/time_service.dart';
import '../../../domain/repositories/attendance_repository.dart';
import 'attendance_history_state.dart';

class AttendanceHistoryCubit extends Cubit<AttendanceHistoryState> {
  final AttendanceRepository _attendanceRepository;
  final TimeService _timeService;

  AttendanceHistoryCubit(
    this._attendanceRepository,
    this._timeService,
  ) : super(const AttendanceHistoryInitial());

  Future<void> loadHistory({
    required int employeeId,
    String filterType = 'today', // 'today', 'week', 'month', 'custom'
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    emit(const AttendanceHistoryLoading());
    try {
      // 1. Fetch all records for this employee
      final allRecords = await _attendanceRepository.getAttendanceForEmployee(employeeId);
      final now = _timeService.now();
      final todayStr = _timeService.getTodayDateString();

      // Sort by date descending (most recent first)
      allRecords.sort((a, b) => b.date.compareTo(a.date));

      // 2. Apply filtering
      final filtered = allRecords.where((record) {
        final recordDate = DateTime.parse(record.date);
        
        switch (filterType) {
          case 'today':
            return record.date == todayStr;
          case 'week':
            // Current week (last 7 days inclusive)
            final startOfRange = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
            return recordDate.isAfter(startOfRange.subtract(const Duration(seconds: 1)));
          case 'month':
            // Current month (last 30 days inclusive)
            final startOfRange = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 29));
            return recordDate.isAfter(startOfRange.subtract(const Duration(seconds: 1)));
          case 'custom':
            if (startDate == null || endDate == null) return true;
            // Normalize start and end date to beginning/end of day
            final startNormalized = DateTime(startDate.year, startDate.month, startDate.day);
            final endNormalized = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
            return recordDate.isAfter(startNormalized.subtract(const Duration(seconds: 1))) &&
                   recordDate.isBefore(endNormalized);
          default:
            return true;
        }
      }).toList();

      emit(AttendanceHistoryLoaded(
        records: filtered,
        filterType: filterType,
        startDate: startDate,
        endDate: endDate,
      ));
    } catch (e) {
      emit(AttendanceHistoryError('خطأ أثناء تحميل سجل الحضور: $e'));
    }
  }
}

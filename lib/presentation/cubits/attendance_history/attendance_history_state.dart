import '../../../data/models/attendance_model.dart';

abstract class AttendanceHistoryState {
  const AttendanceHistoryState();
}

class AttendanceHistoryInitial extends AttendanceHistoryState {
  const AttendanceHistoryInitial();
}

class AttendanceHistoryLoading extends AttendanceHistoryState {
  const AttendanceHistoryLoading();
}

class AttendanceHistoryLoaded extends AttendanceHistoryState {
  final List<AttendanceModel> records;
  final String filterType; // 'today', 'week', 'month', 'custom'
  final DateTime? startDate;
  final DateTime? endDate;

  const AttendanceHistoryLoaded({
    required this.records,
    required this.filterType,
    this.startDate,
    this.endDate,
  });
}

class AttendanceHistoryError extends AttendanceHistoryState {
  final String message;
  const AttendanceHistoryError(this.message);
}

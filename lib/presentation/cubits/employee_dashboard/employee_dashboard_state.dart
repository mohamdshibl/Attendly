import '../../../data/models/attendance_model.dart';
import '../../../data/models/shift_model.dart';

abstract class EmployeeDashboardState {
  const EmployeeDashboardState();
}

class EmployeeDashboardInitial extends EmployeeDashboardState {
  const EmployeeDashboardInitial();
}

class EmployeeDashboardLoading extends EmployeeDashboardState {
  const EmployeeDashboardLoading();
}

class EmployeeDashboardLoaded extends EmployeeDashboardState {
  final ShiftModel shift;
  final AttendanceModel? todayAttendance; // Null if not checked in yet

  const EmployeeDashboardLoaded({
    required this.shift,
    this.todayAttendance,
  });

  EmployeeDashboardLoaded copyWith({
    ShiftModel? shift,
    AttendanceModel? todayAttendance,
    bool clearTodayAttendance = false,
  }) {
    return EmployeeDashboardLoaded(
      shift: shift ?? this.shift,
      todayAttendance: clearTodayAttendance ? null : (todayAttendance ?? this.todayAttendance),
    );
  }
}

class EmployeeDashboardError extends EmployeeDashboardState {
  final String message;
  const EmployeeDashboardError(this.message);
}

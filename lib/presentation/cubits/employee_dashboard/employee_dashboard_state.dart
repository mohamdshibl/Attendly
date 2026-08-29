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
  final bool onLeave;
  final String? leaveType;
  final bool isHoliday;
  final String? holidayName;

  const EmployeeDashboardLoaded({
    required this.shift,
    this.todayAttendance,
    this.onLeave = false,
    this.leaveType,
    this.isHoliday = false,
    this.holidayName,
  });

  EmployeeDashboardLoaded copyWith({
    ShiftModel? shift,
    AttendanceModel? todayAttendance,
    bool clearTodayAttendance = false,
    bool? onLeave,
    String? leaveType,
    bool? isHoliday,
    String? holidayName,
  }) {
    return EmployeeDashboardLoaded(
      shift: shift ?? this.shift,
      todayAttendance: clearTodayAttendance ? null : (todayAttendance ?? this.todayAttendance),
      onLeave: onLeave ?? this.onLeave,
      leaveType: leaveType ?? this.leaveType,
      isHoliday: isHoliday ?? this.isHoliday,
      holidayName: holidayName ?? this.holidayName,
    );
  }
}

class EmployeeDashboardError extends EmployeeDashboardState {
  final String message;
  const EmployeeDashboardError(this.message);
}

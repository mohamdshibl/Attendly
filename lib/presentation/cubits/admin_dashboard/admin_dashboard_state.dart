import '../../../data/models/attendance_model.dart';
import '../../../data/models/employee_model.dart';
import '../../../data/models/shift_model.dart';

abstract class AdminDashboardState {
  const AdminDashboardState();
}

class AdminDashboardInitial extends AdminDashboardState {
  const AdminDashboardInitial();
}

class AdminDashboardLoading extends AdminDashboardState {
  const AdminDashboardLoading();
}

class AdminDashboardLoaded extends AdminDashboardState {
  final int totalEmployees;
  final int presentToday;
  final int lateToday;
  final int absentToday;
  final int currentlyCheckedIn;
  final List<EmployeeModel> employees;
  final List<ShiftModel> shifts;
  final List<AttendanceModel> todayAttendance;
  final List<AttendanceModel> allAttendance;

  const AdminDashboardLoaded({
    required this.totalEmployees,
    required this.presentToday,
    required this.lateToday,
    required this.absentToday,
    required this.currentlyCheckedIn,
    required this.employees,
    required this.shifts,
    required this.todayAttendance,
    required this.allAttendance,
  });

  AdminDashboardLoaded copyWith({
    int? totalEmployees,
    int? presentToday,
    int? lateToday,
    int? absentToday,
    int? currentlyCheckedIn,
    List<EmployeeModel>? employees,
    List<ShiftModel>? shifts,
    List<AttendanceModel>? todayAttendance,
    List<AttendanceModel>? allAttendance,
  }) {
    return AdminDashboardLoaded(
      totalEmployees: totalEmployees ?? this.totalEmployees,
      presentToday: presentToday ?? this.presentToday,
      lateToday: lateToday ?? this.lateToday,
      absentToday: absentToday ?? this.absentToday,
      currentlyCheckedIn: currentlyCheckedIn ?? this.currentlyCheckedIn,
      employees: employees ?? this.employees,
      shifts: shifts ?? this.shifts,
      todayAttendance: todayAttendance ?? this.todayAttendance,
      allAttendance: allAttendance ?? this.allAttendance,
    );
  }
}

class AdminDashboardError extends AdminDashboardState {
  final String message;
  const AdminDashboardError(this.message);
}

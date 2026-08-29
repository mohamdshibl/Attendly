import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/time_service.dart';
import '../../../domain/repositories/attendance_repository.dart';
import '../../../domain/repositories/employee_repository.dart';
import '../../../domain/repositories/shift_repository.dart';
import 'admin_dashboard_state.dart';

class AdminDashboardCubit extends Cubit<AdminDashboardState> {
  final EmployeeRepository _employeeRepository;
  final ShiftRepository _shiftRepository;
  final AttendanceRepository _attendanceRepository;
  final TimeService _timeService;

  AdminDashboardCubit(
    this._employeeRepository,
    this._shiftRepository,
    this._attendanceRepository,
    this._timeService,
  ) : super(const AdminDashboardInitial());

  // Load all statistics and core admin data
  Future<void> loadDashboard() async {
    emit(const AdminDashboardLoading());
    try {
      final employees = await _employeeRepository.getEmployees();
      final shifts = await _shiftRepository.getShifts();
      final allAttendance = await _attendanceRepository.getAllAttendance();

      final todayStr = _timeService.getTodayDateString();

      // Filter active employees (excluding admins for attendance stats)
      final activeStaff = employees.where((e) => e.role != 'admin' && e.isActive).toList();
      final totalEmployees = activeStaff.length;

      // Filter today's attendance logs
      final todayAttendance = allAttendance.where((a) => a.date == todayStr).toList();

      final presentToday = todayAttendance.length;
      final lateToday = todayAttendance.where((a) => a.status == 'LATE').length;
      final currentlyCheckedIn = todayAttendance.where((a) => a.checkOut == null).length;
      final absentToday = totalEmployees - presentToday;

      emit(AdminDashboardLoaded(
        totalEmployees: totalEmployees,
        presentToday: presentToday,
        lateToday: lateToday,
        absentToday: absentToday < 0 ? 0 : absentToday, // Safe guard
        currentlyCheckedIn: currentlyCheckedIn,
        employees: employees,
        shifts: shifts,
        todayAttendance: todayAttendance,
        allAttendance: allAttendance,
      ));
    } catch (e) {
      emit(AdminDashboardError('خطأ أثناء تحميل لوحة تحكم المسؤول: $e'));
    }
  }
}

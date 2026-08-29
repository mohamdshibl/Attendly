import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/time_service.dart';
import '../../../data/models/attendance_model.dart';
import '../../../domain/repositories/attendance_repository.dart';
import '../../../domain/repositories/shift_repository.dart';
import 'employee_dashboard_state.dart';

class EmployeeDashboardCubit extends Cubit<EmployeeDashboardState> {
  final AttendanceRepository _attendanceRepository;
  final ShiftRepository _shiftRepository;
  final TimeService _timeService;

  EmployeeDashboardCubit(
    this._attendanceRepository,
    this._shiftRepository,
    this._timeService,
  ) : super(const EmployeeDashboardInitial());

  // Load shift information and today's attendance status
  Future<void> loadDashboard(int employeeId, int shiftId) async {
    emit(const EmployeeDashboardLoading());
    try {
      final shift = await _shiftRepository.getShiftById(shiftId);
      if (shift == null) {
        emit(const EmployeeDashboardError('لم يتم العثور على الشيفت الخاص بالموظف'));
        return;
      }

      final todayStr = _timeService.getTodayDateString();
      final todayAttendance = await _attendanceRepository.getAttendanceForEmployeeOnDate(
        employeeId,
        todayStr,
      );

      emit(EmployeeDashboardLoaded(
        shift: shift,
        todayAttendance: todayAttendance,
      ));
    } catch (e) {
      emit(EmployeeDashboardError('حدث خطأ أثناء تحميل البيانات: $e'));
    }
  }

  // Handle Employee Check-in
  Future<void> checkIn(int employeeId, int shiftId) async {
    final currentState = state;
    if (currentState is! EmployeeDashboardLoaded) return;

    try {
      final todayStr = _timeService.getTodayDateString();
      final now = _timeService.now();

      // 1. Check if they already checked in today
      final existing = await _attendanceRepository.getAttendanceForEmployeeOnDate(
        employeeId,
        todayStr,
      );
      if (existing != null) {
        emit(const EmployeeDashboardError('لقد قمت بتسجيل الحضور بالفعل اليوم'));
        return;
      }

      final shift = currentState.shift;

      // 2. Parse shift start time (format: "HH:mm")
      final parts = shift.startTime.split(':');
      final startHour = int.parse(parts[0]);
      final startMinute = int.parse(parts[1]);

      // Construct shift start DateTime on today's date
      final shiftStart = DateTime(
        now.year,
        now.month,
        now.day,
        startHour,
        startMinute,
      );

      // 3. Calculate late minutes
      int lateMinutes = 0;
      String status = 'CHECKED_IN';

      if (now.isAfter(shiftStart)) {
        final diffMinutes = now.difference(shiftStart).inMinutes;
        if (diffMinutes > shift.gracePeriod) {
          lateMinutes = diffMinutes;
          status = 'LATE';
        }
      }

      // 4. Save record
      final newRecord = AttendanceModel(
        employeeId: employeeId,
        date: todayStr,
        checkIn: now,
        status: status,
        lateMinutes: lateMinutes,
        createdAt: now,
        updatedAt: now,
      );

      await _attendanceRepository.saveAttendance(newRecord);

      // Reload dashboard
      await loadDashboard(employeeId, shiftId);
    } catch (e) {
      emit(EmployeeDashboardError('خطأ أثناء تسجيل الحضور: $e'));
    }
  }

  // Handle Employee Check-out
  Future<void> checkOut(int employeeId, int shiftId) async {
    final currentState = state;
    if (currentState is! EmployeeDashboardLoaded) return;

    try {
      final todayStr = _timeService.getTodayDateString();
      final now = _timeService.now();

      // 1. Find today's attendance record
      final existing = await _attendanceRepository.getAttendanceForEmployeeOnDate(
        employeeId,
        todayStr,
      );

      if (existing == null) {
        emit(const EmployeeDashboardError('يجب عليك تسجيل الحضور أولاً'));
        return;
      }

      if (existing.checkOut != null) {
        emit(const EmployeeDashboardError('لقد قمت بتسجيل الانصراف بالفعل اليوم'));
        return;
      }

      // 2. Calculate worked minutes
      final checkInTime = existing.checkIn!;
      final workedMinutes = now.difference(checkInTime).inMinutes;

      // 3. Update status & checkout time
      final updatedRecord = existing.copyWith(
        checkOut: now,
        workedMinutes: workedMinutes,
        status: 'CHECKED_OUT',
        updatedAt: now,
      );

      await _attendanceRepository.saveAttendance(updatedRecord);

      // Reload dashboard
      await loadDashboard(employeeId, shiftId);
    } catch (e) {
      emit(EmployeeDashboardError('خطأ أثناء تسجيل الانصراف: $e'));
    }
  }
}

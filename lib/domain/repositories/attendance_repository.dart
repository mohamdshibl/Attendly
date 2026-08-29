import '../../data/models/attendance_model.dart';

abstract class AttendanceRepository {
  Future<List<AttendanceModel>> getAttendanceForEmployee(int employeeId);
  Future<AttendanceModel?> getAttendanceForEmployeeOnDate(int employeeId, String dateString);
  Future<List<AttendanceModel>> getAllAttendance();
  Future<int> saveAttendance(AttendanceModel attendance);
  Future<void> deleteAttendance(int id);
}

import '../../core/database/database_helper.dart';
import '../../core/database/schema_constants.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../models/attendance_model.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final DatabaseHelper _dbHelper;

  AttendanceRepositoryImpl(this._dbHelper);

  @override
  Future<List<AttendanceModel>> getAttendanceForEmployee(int employeeId) async {
    final list = await _dbHelper.queryAllByIndex(
      SchemaConstants.storeAttendance,
      SchemaConstants.indexEmployeeId,
      employeeId,
    );
    return list.map((e) => AttendanceModel.fromMap(e)).toList();
  }

  @override
  Future<AttendanceModel?> getAttendanceForEmployeeOnDate(int employeeId, String dateString) async {
    // Look up via the compound index [employeeId, date]
    final map = await _dbHelper.queryByIndex(
      SchemaConstants.storeAttendance,
      SchemaConstants.indexEmployeeIdDate,
      [employeeId, dateString],
    );
    if (map == null) return null;
    return AttendanceModel.fromMap(map);
  }

  @override
  Future<List<AttendanceModel>> getAllAttendance() async {
    final list = await _dbHelper.queryAll(SchemaConstants.storeAttendance);
    return list.map((e) => AttendanceModel.fromMap(e)).toList();
  }

  @override
  Future<int> saveAttendance(AttendanceModel attendance) async {
    final key = await _dbHelper.put(SchemaConstants.storeAttendance, attendance.toMap());
    return key as int;
  }

  @override
  Future<void> deleteAttendance(int id) async {
    await _dbHelper.delete(SchemaConstants.storeAttendance, id);
  }
}

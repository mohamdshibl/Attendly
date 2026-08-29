class SchemaConstants {
  static const String dbName = 'attendly_db';
  static const int dbVersion = 1;

  // Stores
  static const String storeShifts = 'shifts';
  static const String storeEmployees = 'employees';
  static const String storeAttendance = 'attendance';
  static const String storeSettings = 'settings';

  // Indexes
  static const String indexName = 'name';
  static const String indexEmployeeCode = 'employeeCode';
  static const String indexShiftId = 'shiftId';
  static const String indexEmployeeId = 'employeeId';
  static const String indexDate = 'date';
  static const String indexEmployeeIdDate = 'employeeId_date';
}

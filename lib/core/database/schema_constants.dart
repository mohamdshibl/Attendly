class SchemaConstants {
  static const String dbName = 'attendly_db';
  static const int dbVersion = 2;

  // Stores
  static const String storeShifts = 'shifts';
  static const String storeEmployees = 'employees';
  static const String storeAttendance = 'attendance';
  static const String storeSettings = 'settings';
  static const String storeLeaveTypes = 'leave_types';
  static const String storeLeaveRequests = 'leave_requests';
  static const String storeLeaveBalances = 'leave_balances';
  static const String storeOfficialHolidays = 'official_holidays';
  static const String storeAuditLogs = 'audit_logs';

  // Indexes
  static const String indexName = 'name';
  static const String indexEmployeeCode = 'employeeCode';
  static const String indexShiftId = 'shiftId';
  static const String indexEmployeeId = 'employeeId';
  static const String indexDate = 'date';
  static const String indexEmployeeIdDate = 'employeeId_date';
  
  static const String indexStatus = 'status';
  static const String indexStartDate = 'startDate';
  static const String indexEndDate = 'endDate';
  static const String indexLeaveTypeId = 'leaveTypeId';
  static const String indexLeaveYear = 'leaveYear';
  static const String indexEmployeeIdStatus = 'employeeId_status';
  static const String indexEmployeeTypeYear = 'employeeId_leaveTypeId_leaveYear';
}

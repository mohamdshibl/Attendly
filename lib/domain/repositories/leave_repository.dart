import '../../data/models/leave_type_model.dart';
import '../../data/models/leave_request_model.dart';
import '../../data/models/leave_balance_model.dart';

abstract class LeaveRepository {
  // Leave Types
  Future<List<LeaveTypeModel>> getLeaveTypes();
  Future<void> saveLeaveType(LeaveTypeModel type);
  Future<void> deleteLeaveType(int id);
  Future<LeaveTypeModel?> getLeaveTypeById(int id);

  // Leave Requests
  Future<List<LeaveRequestModel>> getLeaveRequests();
  Future<List<LeaveRequestModel>> getLeaveRequestsForEmployee(int employeeId);
  Future<void> saveLeaveRequest(LeaveRequestModel request);
  Future<LeaveRequestModel?> getLeaveRequestById(int id);

  // Leave Balances
  Future<List<LeaveBalanceModel>> getLeaveBalancesForEmployee(int employeeId, int year);
  Future<LeaveBalanceModel?> getLeaveBalance(int employeeId, int leaveTypeId, int year);
  Future<void> saveLeaveBalance(LeaveBalanceModel balance);

  // Seeding
  Future<void> seedLeaveTypes();
}

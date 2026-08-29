import '../../data/models/employee_model.dart';
import '../../data/models/leave_request_model.dart';
import '../../data/models/leave_balance_model.dart';
import '../../data/models/leave_type_model.dart';

abstract class LeavePolicy {
  /// Calculates the annual entitlement for this leave type for a specific employee.
  int calculateEntitlement(EmployeeModel employee, int year);

  /// Validates a leave request. Returns null if valid, or an error string if invalid.
  String? validateRequest({
    required EmployeeModel employee,
    required LeaveRequestModel request,
    required LeaveTypeModel leaveType,
    required List<LeaveRequestModel> employeeHistory,
    required List<LeaveBalanceModel> employeeBalances,
    required int chargeableDays,
  });
}

import '../../data/models/employee_model.dart';
import '../../data/models/leave_balance_model.dart';
import '../../data/models/leave_request_model.dart';
import '../../data/models/leave_type_model.dart';
import 'leave_policy.dart';

class PaternityLeavePolicy implements LeavePolicy {
  @override
  int calculateEntitlement(EmployeeModel employee, int year) => 1;

  @override
  String? validateRequest({
    required EmployeeModel employee,
    required LeaveRequestModel request,
    required LeaveTypeModel leaveType,
    required List<LeaveRequestModel> employeeHistory,
    required List<LeaveBalanceModel> employeeBalances,
    required int chargeableDays,
  }) {
    // 1. Gender check
    if (employee.gender.trim().toLowerCase() != 'male') {
      return 'إجازة الأبوة ورعاية المولود متاحة للموظفين الذكور فقط';
    }

    // 2. Lifetime limit: max 3 times
    final totalUsed = employeeHistory
        .where((r) => r.leaveTypeId == leaveType.id && (r.status == 'APPROVED' || r.status == 'PENDING') && r.id != request.id)
        .length;

    if (totalUsed >= 3) {
      return 'تم تجاوز الحد الأقصى لإجازة الأبوة المسموح بها قانوناً (3 مرات طوال مسيرتك المهنية)';
    }

    // 3. Duration check
    if (chargeableDays > 1) {
      return 'تمنح إجازة الأبوة ليوم واحد فقط يوم الولادة';
    }

    return null;
  }
}

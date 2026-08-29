import '../../data/models/employee_model.dart';
import '../../data/models/leave_balance_model.dart';
import '../../data/models/leave_request_model.dart';
import '../../data/models/leave_type_model.dart';
import 'leave_policy.dart';

class HajjLeavePolicy implements LeavePolicy {
  @override
  int calculateEntitlement(EmployeeModel employee, int year) => 30; // 30 days once in a lifetime

  @override
  String? validateRequest({
    required EmployeeModel employee,
    required LeaveRequestModel request,
    required LeaveTypeModel leaveType,
    required List<LeaveRequestModel> employeeHistory,
    required List<LeaveBalanceModel> employeeBalances,
    required int chargeableDays,
  }) {
    // 1. Service check: >= 5 years
    if (employee.hireDate == null) {
      return 'يتطلب تقديم طلب إجازة الحج قضاء 5 سنوات خدمة مستمرة مع صاحب العمل';
    }

    final serviceDays = request.startDate.difference(employee.hireDate!).inDays;
    final yearsOfService = serviceDays / 365.25;
    if (yearsOfService < 5.0) {
      return 'تتطلب إجازة الحج قضاء 5 سنوات خدمة مستمرة مع صاحب العمل (خدمتك الحالية: ${yearsOfService.toStringAsFixed(1)} سنة)';
    }

    // 2. Lifetime limit: once
    final totalUsed = employeeHistory
        .where((r) => r.leaveTypeId == leaveType.id && (r.status == 'APPROVED' || r.status == 'PENDING') && r.id != request.id)
        .length;

    if (totalUsed >= 1) {
      return 'تم استخدام إجازة الحج مسبقاً (تمنح مرة واحدة فقط طوال فترة الخدمة)';
    }

    // 3. Duration check
    if (chargeableDays > 30) {
      return 'الحد الأقصى لإجازة الحج هو 30 يوماً (شهر كامل)';
    }

    return null;
  }
}

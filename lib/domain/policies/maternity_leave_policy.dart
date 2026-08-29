import '../../data/models/employee_model.dart';
import '../../data/models/leave_balance_model.dart';
import '../../data/models/leave_request_model.dart';
import '../../data/models/leave_type_model.dart';
import 'leave_policy.dart';

class MaternityLeavePolicy implements LeavePolicy {
  @override
  int calculateEntitlement(EmployeeModel employee, int year) => 120; // 4 months = 120 days

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
    if (employee.gender.trim().toLowerCase() != 'female') {
      return 'إجازة الوضع والأمومة متاحة للموظفات الإناث فقط';
    }

    // 2. Requires documentation
    if (request.attachmentPath == null || request.attachmentPath!.trim().isEmpty) {
      return 'يرجى إرفاق شهادة الميلاد أو التقرير الطبي لطلب إجازة الوضع';
    }

    // 3. Lifetime limit: max 3 times
    final totalUsed = employeeHistory
        .where((r) => r.leaveTypeId == leaveType.id && (r.status == 'APPROVED' || r.status == 'PENDING') && r.id != request.id)
        .length;

    if (totalUsed >= 3) {
      return 'تم تجاوز الحد الأقصى لإجازة الوضع قانوناً (3 مرات طوال مسيرتك المهنية)';
    }

    // 4. Duration check
    if (chargeableDays > 120) {
      return 'الحد الأقصى لإجازة الوضع هو 120 يوماً (4 أشهر)';
    }

    return null;
  }
}

import '../../data/models/employee_model.dart';
import '../../data/models/leave_balance_model.dart';
import '../../data/models/leave_request_model.dart';
import '../../data/models/leave_type_model.dart';
import 'leave_policy.dart';

class SickLeavePolicy implements LeavePolicy {
  @override
  int calculateEntitlement(EmployeeModel employee, int year) => 180; // 180 days per year under Social Insurance rules

  @override
  String? validateRequest({
    required EmployeeModel employee,
    required LeaveRequestModel request,
    required LeaveTypeModel leaveType,
    required List<LeaveRequestModel> employeeHistory,
    required List<LeaveBalanceModel> employeeBalances,
    required int chargeableDays,
  }) {
    // Requires medical document
    if (request.attachmentPath == null || request.attachmentPath!.trim().isEmpty) {
      return 'يرجى إرفاق التقرير الطبي أو الشهادة المعتمدة لطلب الإجازة المرضية';
    }

    final balance = employeeBalances.firstWhere(
      (b) => b.leaveTypeId == leaveType.id,
      orElse: () => LeaveBalanceModel(
        employeeId: employee.id!,
        leaveTypeId: leaveType.id!,
        leaveYear: request.startDate.year,
        entitlement: calculateEntitlement(employee, request.startDate.year),
      ),
    );

    final pendingDays = employeeHistory
        .where((r) => r.leaveTypeId == leaveType.id && r.status == 'PENDING' && r.id != request.id)
        .fold(0, (sum, r) => sum + r.numberOfDays);

    final available = balance.entitlement - balance.used - pendingDays;
    if (chargeableDays > available) {
      return 'رصيد الإجازات المرضية غير كافٍ (المتاح حالياً: $available يوم)';
    }

    return null;
  }
}

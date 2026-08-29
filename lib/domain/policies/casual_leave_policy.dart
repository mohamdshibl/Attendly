import '../../data/models/employee_model.dart';
import '../../data/models/leave_balance_model.dart';
import '../../data/models/leave_request_model.dart';
import '../../data/models/leave_type_model.dart';
import 'leave_policy.dart';

class CasualLeavePolicy implements LeavePolicy {
  @override
  int calculateEntitlement(EmployeeModel employee, int year) => 7; // Max 7 days per year

  @override
  String? validateRequest({
    required EmployeeModel employee,
    required LeaveRequestModel request,
    required LeaveTypeModel leaveType,
    required List<LeaveRequestModel> employeeHistory,
    required List<LeaveBalanceModel> employeeBalances,
    required int chargeableDays,
  }) {
    // 1. Max 2 days per request
    if (chargeableDays > 2) {
      return 'الحد الأقصى للإجازة العارضة في المرة الواحدة هو يومين فقط';
    }

    // 2. Max 7 days per year
    final year = request.startDate.year;
    final approvedCasualDays = employeeHistory
        .where((r) => r.leaveTypeId == leaveType.id && r.status == 'APPROVED' && r.startDate.year == year)
        .fold(0, (sum, r) => sum + r.numberOfDays);

    final pendingCasualDays = employeeHistory
        .where((r) => r.leaveTypeId == leaveType.id && r.status == 'PENDING' && r.startDate.year == year && r.id != request.id)
        .fold(0, (sum, r) => sum + r.numberOfDays);

    if (approvedCasualDays + pendingCasualDays + chargeableDays > 7) {
      final remainingCasual = 7 - approvedCasualDays - pendingCasualDays;
      return 'رصيد الإجازة العارضة السنوي غير كافٍ (المتبقي: $remainingCasual يوم)';
    }

    // 3. Deducts from annual leave balance, so check annual balance
    // Find the annual leave balance (code: 'ANNUAL' or the one that is NOT casual and has entitlement > 7)
    final annualBalance = employeeBalances.firstWhere(
      (b) => b.leaveTypeId != leaveType.id,
      orElse: () => LeaveBalanceModel(
        employeeId: employee.id!,
        leaveTypeId: 1, // Fallback ID
        leaveYear: year,
        entitlement: 21,
      ),
    );

    // Sum up pending for both annual and casual since casual deducts from annual
    final annualPending = employeeHistory
        .where((r) => (r.leaveTypeId == annualBalance.leaveTypeId || r.leaveTypeId == leaveType.id) && r.status == 'PENDING' && r.id != request.id)
        .fold(0, (sum, r) => sum + r.numberOfDays);

    final annualAvailable = annualBalance.entitlement - annualBalance.used - annualPending;
    if (chargeableDays > annualAvailable) {
      return 'الرصيد السنوي الاعتيادي غير كافٍ لخصم الإجازة العارضة (المتاح حالياً: $annualAvailable يوم)';
    }

    return null;
  }
}

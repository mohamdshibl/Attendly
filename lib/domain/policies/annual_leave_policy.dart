import '../../data/models/employee_model.dart';
import '../../data/models/leave_balance_model.dart';
import '../../data/models/leave_request_model.dart';
import '../../data/models/leave_type_model.dart';
import 'leave_policy.dart';

class AnnualLeavePolicy implements LeavePolicy {
  @override
  int calculateEntitlement(EmployeeModel employee, int year) {
    if (employee.hireDate == null) return 21;

    final currentDate = DateTime(year, 12, 31);
    final hireDate = employee.hireDate!;

    final serviceDays = currentDate.difference(hireDate).inDays;
    final yearsOfService = serviceDays / 365.25;

    int baseEntitlement = 21;

    if (yearsOfService < 1.0) {
      if (serviceDays >= 180) {
        baseEntitlement = ((serviceDays / 365.25) * 15).round();
      } else {
        baseEntitlement = 0;
      }
    } else if (yearsOfService >= 10.0) {
      baseEntitlement = 30;
    }

    if (employee.birthDate != null) {
      final age = currentDate.difference(employee.birthDate!).inDays / 365.25;
      if (age >= 50.0) {
        baseEntitlement = 30;
      }
    }

    if (employee.isDisabled) {
      baseEntitlement = 45;
    }

    if (employee.workClassification == 'hazardous' || employee.workClassification == 'remote') {
      baseEntitlement += 7;
    }

    return baseEntitlement;
  }

  @override
  String? validateRequest({
    required EmployeeModel employee,
    required LeaveRequestModel request,
    required LeaveTypeModel leaveType,
    required List<LeaveRequestModel> employeeHistory,
    required List<LeaveBalanceModel> employeeBalances,
    required int chargeableDays,
  }) {
    // 1. Get annual leave balance
    final balance = employeeBalances.firstWhere(
      (b) => b.leaveTypeId == leaveType.id,
      orElse: () => LeaveBalanceModel(
        employeeId: employee.id!,
        leaveTypeId: leaveType.id!,
        leaveYear: request.startDate.year,
        entitlement: calculateEntitlement(employee, request.startDate.year),
      ),
    );

    // 2. Calculate remaining balance (also account for pending requests in system)
    final pendingDays = employeeHistory
        .where((r) => r.leaveTypeId == leaveType.id && r.status == 'PENDING' && r.id != request.id)
        .fold(0, (sum, r) => sum + r.numberOfDays);

    final available = balance.entitlement - balance.used - pendingDays;
    if (chargeableDays > available) {
      return 'رصيد الإجازات السنوية غير كافٍ (المتاح حالياً: $available يوم)';
    }

    return null;
  }
}

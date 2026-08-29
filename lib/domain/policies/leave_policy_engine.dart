import '../../data/models/employee_model.dart';
import '../../data/models/leave_balance_model.dart';
import '../../data/models/leave_request_model.dart';
import '../../data/models/leave_type_model.dart';
import 'leave_policy.dart';
import 'annual_leave_policy.dart';
import 'casual_leave_policy.dart';
import 'sick_leave_policy.dart';
import 'maternity_leave_policy.dart';
import 'paternity_leave_policy.dart';
import 'hajj_leave_policy.dart';

class LeavePolicyEngine {
  final Map<String, LeavePolicy> _policies = {
    'ANNUAL': AnnualLeavePolicy(),
    'CASUAL': CasualLeavePolicy(),
    'SICK': SickLeavePolicy(),
    'MATERNITY': MaternityLeavePolicy(),
    'PATERNITY': PaternityLeavePolicy(),
    'HAJJ': HajjLeavePolicy(),
  };

  /// Gets the policy instance for a given leave type code
  LeavePolicy? getPolicy(String code) => _policies[code];

  /// Calculates dynamic entitlement for a specific leave type
  int getEntitlement(EmployeeModel employee, LeaveTypeModel leaveType, int year) {
    final policy = getPolicy(leaveType.code);
    if (policy != null) {
      return policy.calculateEntitlement(employee, year);
    }
    // Default to the type's configured annual limit or a fallback
    return leaveType.annualLimit ?? 21;
  }

  /// Validates a leave request against the corresponding policy rules
  String? validateRequest({
    required EmployeeModel employee,
    required LeaveRequestModel request,
    required LeaveTypeModel leaveType,
    required List<LeaveRequestModel> employeeHistory,
    required List<LeaveBalanceModel> employeeBalances,
    required int chargeableDays,
  }) {
    // 1. General validations
    if (!employee.isActive) {
      return 'حساب الموظف غير نشط؛ لا يمكنه تقديم طلب إجازة';
    }
    if (!leaveType.isActive) {
      return 'نوع الإجازة المطلوبة غير نشط حالياً';
    }
    if (request.endDate.isBefore(request.startDate)) {
      return 'تاريخ نهاية الإجازة لا يمكن أن يكون قبل تاريخ بدايتها';
    }
    if (chargeableDays <= 0) {
      return 'مدة الإجازة القابلة للخصم يجب أن تكون يوماً واحداً على الأقل';
    }

    // 2. Max days check from configuration if defined
    if (leaveType.maxDaysPerRequest != null && chargeableDays > leaveType.maxDaysPerRequest!) {
      return 'تجاوز الحد الأقصى للأيام المسموح بها في الطلب الواحد وهو ${leaveType.maxDaysPerRequest} يوم';
    }

    // 3. Overlap check with existing APPROVED requests
    final hasOverlap = employeeHistory.any((r) =>
        r.status == 'APPROVED' &&
        r.id != request.id &&
        ((request.startDate.isBefore(r.endDate) || request.startDate.isAtSameMomentAs(r.endDate)) &&
            (request.endDate.isAfter(r.startDate) || request.endDate.isAtSameMomentAs(r.startDate))));

    if (hasOverlap) {
      return 'يوجد تداخل مع إجازة معتمدة أخرى في نفس الفترة المحددة';
    }

    // 4. Policy specific validation
    final policy = getPolicy(leaveType.code);
    if (policy != null) {
      return policy.validateRequest(
        employee: employee,
        request: request,
        leaveType: leaveType,
        employeeHistory: employeeHistory,
        employeeBalances: employeeBalances,
        chargeableDays: chargeableDays,
      );
    }

    return null;
  }
}

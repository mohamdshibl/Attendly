import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/leave_request_model.dart';
import '../../../data/models/leave_balance_model.dart';
import '../../../data/models/leave_type_model.dart';
import '../../../data/models/audit_log_model.dart';
import '../../../domain/repositories/leave_repository.dart';
import '../../../domain/repositories/employee_repository.dart';
import '../../../domain/repositories/holiday_repository.dart';
import '../../../domain/repositories/audit_log_repository.dart';
import '../../../domain/policies/leave_policy_engine.dart';
import '../../../core/utils/leave_days_calculator.dart';
import 'leave_request_state.dart';

class LeaveRequestCubit extends Cubit<LeaveRequestState> {
  final LeaveRepository _leaveRepo;
  final EmployeeRepository _employeeRepo;
  final HolidayRepository _holidayRepo;
  final AuditLogRepository _auditLogRepo;
  final LeavePolicyEngine _policyEngine;

  LeaveRequestCubit({
    required LeaveRepository leaveRepo,
    required EmployeeRepository employeeRepo,
    required HolidayRepository holidayRepo,
    required AuditLogRepository auditLogRepo,
    required LeavePolicyEngine policyEngine,
  })  : _leaveRepo = leaveRepo,
        _employeeRepo = employeeRepo,
        _holidayRepo = holidayRepo,
        _auditLogRepo = auditLogRepo,
        _policyEngine = policyEngine,
        super(const LeaveRequestState());

  Future<void> loadLeaveData(int employeeId, int year) async {
    emit(state.copyWith(isLoading: true));
    try {
      final employee = await _employeeRepo.getEmployeeById(employeeId);
      if (employee == null) {
        emit(state.copyWith(isLoading: false, errorMessage: 'الموظف غير موجود'));
        return;
      }

      final leaveTypes = await _leaveRepo.getLeaveTypes();
      final requests = await _leaveRepo.getLeaveRequestsForEmployee(employeeId);
      final holidays = await _holidayRepo.getHolidays();

      // Sync and retrieve balances
      final balances = <LeaveBalanceModel>[];
      final existingBalances = await _leaveRepo.getLeaveBalancesForEmployee(employeeId, year);

      for (final type in leaveTypes) {
        final match = existingBalances.firstWhere(
          (b) => b.leaveTypeId == type.id,
          orElse: () => LeaveBalanceModel(
            employeeId: employeeId,
            leaveTypeId: type.id!,
            leaveYear: year,
            entitlement: _policyEngine.getEntitlement(employee, type, year),
            used: 0,
            pending: 0,
          ),
        );

        if (match.id == null) {
          await _leaveRepo.saveLeaveBalance(match);
        }
        balances.add(match);
      }

      // Re-query saved balances to get IDs
      final savedBalances = await _leaveRepo.getLeaveBalancesForEmployee(employeeId, year);

      emit(state.copyWith(
        isLoading: false,
        leaveTypes: leaveTypes,
        requests: requests,
        balances: savedBalances,
        holidays: holidays,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> submitRequest({
    required int employeeId,
    required int leaveTypeId,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
    String? attachmentPath,
  }) async {
    emit(state.copyWith(isLoading: true));
    try {
      final employee = await _employeeRepo.getEmployeeById(employeeId);
      if (employee == null) {
        emit(state.copyWith(isLoading: false, errorMessage: 'الموظف غير موجود'));
        return;
      }

      final leaveType = state.leaveTypes.firstWhere((t) => t.id == leaveTypeId);
      final holidays = await _holidayRepo.getHolidays();

      // Calculate chargeable days
      final chargeableDays = LeaveDaysCalculator.calculateChargeableDays(
        startDate: startDate,
        endDate: endDate,
        leaveTypeCode: leaveType.code,
        holidays: holidays,
      );

      // Construct temporary model to validate
      final tempRequest = LeaveRequestModel(
        employeeId: employeeId,
        leaveTypeId: leaveTypeId,
        startDate: startDate,
        endDate: endDate,
        numberOfDays: chargeableDays,
        reason: reason,
        attachmentPath: attachmentPath,
        createdAt: DateTime.now(),
      );

      // Validate request using Policy Engine
      final validationError = _policyEngine.validateRequest(
        employee: employee,
        request: tempRequest,
        leaveType: leaveType,
        employeeHistory: state.requests,
        employeeBalances: state.balances,
        chargeableDays: chargeableDays,
      );

      if (validationError != null) {
        emit(state.copyWith(isLoading: false, errorMessage: validationError));
        return;
      }

      // Save leave request
      await _leaveRepo.saveLeaveRequest(tempRequest);

      // Update pending balance
      await _updatePendingBalance(state.balances, leaveType, chargeableDays, true);

      // Log audit action
      await _auditLogRepo.logAction(AuditLogModel(
        actorId: employeeId,
        action: 'LEAVE_REQUESTED',
        entityType: 'leave_request',
        timestamp: DateTime.now(),
        metadata: '{"leaveType": "${leaveType.code}", "days": $chargeableDays}',
      ));

      emit(state.copyWith(successMessage: 'تم تقديم طلب الإجازة بنجاح'));
      await loadLeaveData(employeeId, startDate.year);
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> cancelRequest(int requestId) async {
    emit(state.copyWith(isLoading: true));
    try {
      final request = await _leaveRepo.getLeaveRequestById(requestId);
      if (request == null) {
        emit(state.copyWith(isLoading: false, errorMessage: 'الطلب غير موجود'));
        return;
      }

      if (request.status != 'PENDING') {
        emit(state.copyWith(isLoading: false, errorMessage: 'يمكن إلغاء الطلبات المعلقة فقط'));
        return;
      }

      // Update request status to CANCELLED
      final cancelledRequest = request.copyWith(status: 'CANCELLED');
      await _leaveRepo.saveLeaveRequest(cancelledRequest);

      // Update pending balance (decrement)
      final leaveType = state.leaveTypes.firstWhere((t) => t.id == request.leaveTypeId);
      await _updatePendingBalance(state.balances, leaveType, request.numberOfDays, false);

      // Log audit action
      await _auditLogRepo.logAction(AuditLogModel(
        actorId: request.employeeId,
        action: 'LEAVE_CANCELLED',
        entityType: 'leave_request',
        entityId: requestId,
        timestamp: DateTime.now(),
      ));

      emit(state.copyWith(successMessage: 'تم إلغاء طلب الإجازة بنجاح'));
      await loadLeaveData(request.employeeId, request.startDate.year);
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> _updatePendingBalance(
    List<LeaveBalanceModel> balances,
    LeaveTypeModel type,
    int days,
    bool increment,
  ) async {
    final change = increment ? days : -days;

    // 1. Update own balance
    final ownBalance = balances.firstWhere((b) => b.leaveTypeId == type.id);
    final updatedOwn = ownBalance.copyWith(pending: ownBalance.pending + change);
    await _leaveRepo.saveLeaveBalance(updatedOwn);

    // 2. If it deducts from annual, update annual balance as well
    if (type.deductsFromAnnual && type.code != 'ANNUAL') {
      final annualType = state.leaveTypes.firstWhere((t) => t.code == 'ANNUAL');
      final annualBalance = balances.firstWhere((b) => b.leaveTypeId == annualType.id);
      final updatedAnnual = annualBalance.copyWith(pending: annualBalance.pending + change);
      await _leaveRepo.saveLeaveBalance(updatedAnnual);
    }
  }
}

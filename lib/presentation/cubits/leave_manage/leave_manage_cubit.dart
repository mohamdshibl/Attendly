import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/leave_request_model.dart';
import '../../../data/models/audit_log_model.dart';
import '../../../domain/repositories/leave_repository.dart';
import '../../../domain/repositories/employee_repository.dart';
import '../../../domain/repositories/audit_log_repository.dart';
import 'leave_manage_state.dart';

class LeaveManageCubit extends Cubit<LeaveManageState> {
  final LeaveRepository _leaveRepo;
  final EmployeeRepository _employeeRepo;
  final AuditLogRepository _auditLogRepo;

  LeaveManageCubit({
    required LeaveRepository leaveRepo,
    required EmployeeRepository employeeRepo,
    required AuditLogRepository auditLogRepo,
  })  : _leaveRepo = leaveRepo,
        _employeeRepo = employeeRepo,
        _auditLogRepo = auditLogRepo,
        super(const LeaveManageState());

  Future<void> loadAllRequests() async {
    emit(state.copyWith(isLoading: true));
    try {
      final employees = await _employeeRepo.getEmployees();
      final leaveTypes = await _leaveRepo.getLeaveTypes();
      final requests = await _leaveRepo.getLeaveRequests();

      // Sort requests descending by creation date
      requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      emit(state.copyWith(
        isLoading: false,
        employees: employees,
        leaveTypes: leaveTypes,
        requests: requests,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> approveRequest(int requestId, int adminId) async {
    emit(state.copyWith(isLoading: true));
    try {
      final request = await _leaveRepo.getLeaveRequestById(requestId);
      if (request == null) {
        emit(state.copyWith(isLoading: false, errorMessage: 'طلب الإجازة غير موجود'));
        return;
      }

      if (request.status != 'PENDING') {
        emit(state.copyWith(isLoading: false, errorMessage: 'يمكن الموافقة على الطلبات المعلقة فقط'));
        return;
      }

      // Update status to APPROVED
      final approvedRequest = request.copyWith(
        status: 'APPROVED',
        reviewedAt: DateTime.now(),
        reviewedBy: adminId,
      );
      await _leaveRepo.saveLeaveRequest(approvedRequest);

      // Adjust balances: Move from pending to used
      final leaveType = state.leaveTypes.firstWhere((t) => t.id == request.leaveTypeId);
      final balances = await _leaveRepo.getLeaveBalancesForEmployee(request.employeeId, request.startDate.year);

      final ownBalance = balances.firstWhere((b) => b.leaveTypeId == leaveType.id);
      final updatedOwn = ownBalance.copyWith(
        pending: (ownBalance.pending - request.numberOfDays).clamp(0, 999),
        used: ownBalance.used + request.numberOfDays,
      );
      await _leaveRepo.saveLeaveBalance(updatedOwn);

      // If it deducts from annual, also update the annual balance
      if (leaveType.deductsFromAnnual && leaveType.code != 'ANNUAL') {
        final annualType = state.leaveTypes.firstWhere((t) => t.code == 'ANNUAL');
        final annualBalance = balances.firstWhere((b) => b.leaveTypeId == annualType.id);
        final updatedAnnual = annualBalance.copyWith(
          pending: (annualBalance.pending - request.numberOfDays).clamp(0, 999),
          used: annualBalance.used + request.numberOfDays,
        );
        await _leaveRepo.saveLeaveBalance(updatedAnnual);
      }

      // Log audit action
      await _auditLogRepo.logAction(AuditLogModel(
        actorId: adminId,
        action: 'LEAVE_APPROVED',
        entityType: 'leave_request',
        entityId: requestId,
        timestamp: DateTime.now(),
        metadata: '{"employeeId": ${request.employeeId}, "days": ${request.numberOfDays}}',
      ));

      emit(state.copyWith(successMessage: 'تمت الموافقة على طلب الإجازة بنجاح'));
      await loadAllRequests();
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> rejectRequest(int requestId, int adminId, String rejectionReason) async {
    if (rejectionReason.trim().isEmpty) {
      emit(state.copyWith(isLoading: false, errorMessage: 'يرجى إدخال سبب الرفض'));
      return;
    }

    emit(state.copyWith(isLoading: true));
    try {
      final request = await _leaveRepo.getLeaveRequestById(requestId);
      if (request == null) {
        emit(state.copyWith(isLoading: false, errorMessage: 'طلب الإجازة غير موجود'));
        return;
      }

      if (request.status != 'PENDING') {
        emit(state.copyWith(isLoading: false, errorMessage: 'يمكن رفض الطلبات المعلقة فقط'));
        return;
      }

      // Update status to REJECTED
      final rejectedRequest = request.copyWith(
        status: 'REJECTED',
        reviewedAt: DateTime.now(),
        reviewedBy: adminId,
        rejectionReason: rejectionReason,
      );
      await _leaveRepo.saveLeaveRequest(rejectedRequest);

      // Adjust balances: Decrement pending
      final leaveType = state.leaveTypes.firstWhere((t) => t.id == request.leaveTypeId);
      final balances = await _leaveRepo.getLeaveBalancesForEmployee(request.employeeId, request.startDate.year);

      final ownBalance = balances.firstWhere((b) => b.leaveTypeId == leaveType.id);
      final updatedOwn = ownBalance.copyWith(
        pending: (ownBalance.pending - request.numberOfDays).clamp(0, 999),
      );
      await _leaveRepo.saveLeaveBalance(updatedOwn);

      // If it deducts from annual, also update the annual balance
      if (leaveType.deductsFromAnnual && leaveType.code != 'ANNUAL') {
        final annualType = state.leaveTypes.firstWhere((t) => t.code == 'ANNUAL');
        final annualBalance = balances.firstWhere((b) => b.leaveTypeId == annualType.id);
        final updatedAnnual = annualBalance.copyWith(
          pending: (annualBalance.pending - request.numberOfDays).clamp(0, 999),
        );
        await _leaveRepo.saveLeaveBalance(updatedAnnual);
      }

      // Log audit action
      await _auditLogRepo.logAction(AuditLogModel(
        actorId: adminId,
        action: 'LEAVE_REJECTED',
        entityType: 'leave_request',
        entityId: requestId,
        timestamp: DateTime.now(),
        metadata: '{"employeeId": ${request.employeeId}, "reason": "$rejectionReason"}',
      ));

      emit(state.copyWith(successMessage: 'تم رفض طلب الإجازة بنجاح'));
      await loadAllRequests();
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }
}

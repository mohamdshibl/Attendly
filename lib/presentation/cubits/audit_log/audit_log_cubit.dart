import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/audit_log_repository.dart';
import '../../../domain/repositories/employee_repository.dart';
import 'audit_log_state.dart';

class AuditLogCubit extends Cubit<AuditLogState> {
  final AuditLogRepository _auditLogRepo;
  final EmployeeRepository _employeeRepo;

  AuditLogCubit({
    required AuditLogRepository auditLogRepo,
    required EmployeeRepository employeeRepo,
  })  : _auditLogRepo = auditLogRepo,
        _employeeRepo = employeeRepo,
        super(const AuditLogState());

  Future<void> loadLogs() async {
    emit(state.copyWith(isLoading: true));
    try {
      final logs = await _auditLogRepo.getAuditLogs();
      final employees = await _employeeRepo.getEmployees();
      emit(state.copyWith(
        isLoading: false,
        logs: logs,
        employees: employees,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }
}

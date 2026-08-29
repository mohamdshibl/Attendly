import '../../../data/models/audit_log_model.dart';
import '../../../data/models/employee_model.dart';

class AuditLogState {
  final bool isLoading;
  final List<AuditLogModel> logs;
  final List<EmployeeModel> employees;
  final String? errorMessage;

  const AuditLogState({
    this.isLoading = false,
    this.logs = const [],
    this.employees = const [],
    this.errorMessage,
  });

  AuditLogState copyWith({
    bool? isLoading,
    List<AuditLogModel>? logs,
    List<EmployeeModel>? employees,
    String? errorMessage,
  }) {
    return AuditLogState(
      isLoading: isLoading ?? this.isLoading,
      logs: logs ?? this.logs,
      employees: employees ?? this.employees,
      errorMessage: errorMessage,
    );
  }
}

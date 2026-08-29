import '../../../data/models/leave_request_model.dart';
import '../../../data/models/employee_model.dart';
import '../../../data/models/leave_type_model.dart';

class LeaveManageState {
  final bool isLoading;
  final List<LeaveRequestModel> requests;
  final List<EmployeeModel> employees;
  final List<LeaveTypeModel> leaveTypes;
  final String? errorMessage;
  final String? successMessage;

  const LeaveManageState({
    this.isLoading = false,
    this.requests = const [],
    this.employees = const [],
    this.leaveTypes = const [],
    this.errorMessage,
    this.successMessage,
  });

  LeaveManageState copyWith({
    bool? isLoading,
    List<LeaveRequestModel>? requests,
    List<EmployeeModel>? employees,
    List<LeaveTypeModel>? leaveTypes,
    String? errorMessage,
    String? successMessage,
  }) {
    return LeaveManageState(
      isLoading: isLoading ?? this.isLoading,
      requests: requests ?? this.requests,
      employees: employees ?? this.employees,
      leaveTypes: leaveTypes ?? this.leaveTypes,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

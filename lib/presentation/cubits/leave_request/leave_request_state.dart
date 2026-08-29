import '../../../data/models/leave_type_model.dart';
import '../../../data/models/leave_request_model.dart';
import '../../../data/models/leave_balance_model.dart';
import '../../../data/models/official_holiday_model.dart';

class LeaveRequestState {
  final bool isLoading;
  final List<LeaveTypeModel> leaveTypes;
  final List<LeaveRequestModel> requests;
  final List<LeaveBalanceModel> balances;
  final List<OfficialHolidayModel> holidays;
  final String? errorMessage;
  final String? successMessage;

  const LeaveRequestState({
    this.isLoading = false,
    this.leaveTypes = const [],
    this.requests = const [],
    this.balances = const [],
    this.holidays = const [],
    this.errorMessage,
    this.successMessage,
  });

  LeaveRequestState copyWith({
    bool? isLoading,
    List<LeaveTypeModel>? leaveTypes,
    List<LeaveRequestModel>? requests,
    List<LeaveBalanceModel>? balances,
    List<OfficialHolidayModel>? holidays,
    String? errorMessage,
    String? successMessage,
  }) {
    return LeaveRequestState(
      isLoading: isLoading ?? this.isLoading,
      leaveTypes: leaveTypes ?? this.leaveTypes,
      requests: requests ?? this.requests,
      balances: balances ?? this.balances,
      holidays: holidays ?? this.holidays,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

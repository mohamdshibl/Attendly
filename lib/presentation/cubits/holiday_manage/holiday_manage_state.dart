import '../../../data/models/official_holiday_model.dart';

class HolidayManageState {
  final bool isLoading;
  final List<OfficialHolidayModel> holidays;
  final String? errorMessage;
  final String? successMessage;

  const HolidayManageState({
    this.isLoading = false,
    this.holidays = const [],
    this.errorMessage,
    this.successMessage,
  });

  HolidayManageState copyWith({
    bool? isLoading,
    List<OfficialHolidayModel>? holidays,
    String? errorMessage,
    String? successMessage,
  }) {
    return HolidayManageState(
      isLoading: isLoading ?? this.isLoading,
      holidays: holidays ?? this.holidays,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

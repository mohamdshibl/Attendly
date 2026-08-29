import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/official_holiday_model.dart';
import '../../../data/models/audit_log_model.dart';
import '../../../domain/repositories/holiday_repository.dart';
import '../../../domain/repositories/audit_log_repository.dart';
import 'holiday_manage_state.dart';

class HolidayManageCubit extends Cubit<HolidayManageState> {
  final HolidayRepository _holidayRepo;
  final AuditLogRepository _auditLogRepo;

  HolidayManageCubit({
    required HolidayRepository holidayRepo,
    required AuditLogRepository auditLogRepo,
  })  : _holidayRepo = holidayRepo,
        _auditLogRepo = auditLogRepo,
        super(const HolidayManageState());

  Future<void> loadHolidays() async {
    emit(state.copyWith(isLoading: true));
    try {
      final list = await _holidayRepo.getHolidays();
      // Sort holidays by date
      list.sort((a, b) => a.date.compareTo(b.date));
      emit(state.copyWith(isLoading: false, holidays: list));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> addHoliday({
    required String name,
    required DateTime date,
    bool isRecurring = false,
    bool isPaid = true,
    String? notes,
    required int adminId,
  }) async {
    if (name.trim().isEmpty) {
      emit(state.copyWith(isLoading: false, errorMessage: 'يرجى إدخال اسم العطلة'));
      return;
    }

    emit(state.copyWith(isLoading: true));
    try {
      // Check if holiday already exists on this date
      final existing = await _holidayRepo.getHolidayByDate(date);
      if (existing != null) {
        emit(state.copyWith(isLoading: false, errorMessage: 'توجد عطلة رسمية مسجلة بالفعل في هذا التاريخ'));
        return;
      }

      final holiday = OfficialHolidayModel(
        name: name,
        date: date,
        isRecurring: isRecurring,
        isPaid: isPaid,
        notes: notes,
      );

      await _holidayRepo.saveHoliday(holiday);

      // Log audit action
      await _auditLogRepo.logAction(AuditLogModel(
        actorId: adminId,
        action: 'HOLIDAY_ADDED',
        entityType: 'official_holiday',
        timestamp: DateTime.now(),
        metadata: '{"name": "$name", "date": "${date.toIso8601String().substring(0, 10)}"}',
      ));

      emit(state.copyWith(successMessage: 'تم إضافة العطلة الرسمية بنجاح'));
      await loadHolidays();
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> deleteHoliday(int id, int adminId) async {
    emit(state.copyWith(isLoading: true));
    try {
      await _holidayRepo.deleteHoliday(id);

      // Log audit action
      await _auditLogRepo.logAction(AuditLogModel(
        actorId: adminId,
        action: 'HOLIDAY_REMOVED',
        entityType: 'official_holiday',
        entityId: id,
        timestamp: DateTime.now(),
      ));

      emit(state.copyWith(successMessage: 'تم حذف العطلة الرسمية بنجاح'));
      await loadHolidays();
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }
}

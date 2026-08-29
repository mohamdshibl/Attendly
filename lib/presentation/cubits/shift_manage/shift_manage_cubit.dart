import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/shift_model.dart';
import '../../../domain/repositories/shift_repository.dart';
import 'shift_manage_state.dart';

class ShiftManageCubit extends Cubit<ShiftManageState> {
  final ShiftRepository _shiftRepository;

  ShiftManageCubit(this._shiftRepository) : super(const ShiftManageInitial());

  // Add a new shift
  Future<void> addShift({
    required String name,
    required String startTime,
    required String endTime,
    required int gracePeriod,
  }) async {
    emit(const ShiftManageLoading());
    try {
      final newShift = ShiftModel(
        name: name.trim(),
        startTime: startTime,
        endTime: endTime,
        gracePeriod: gracePeriod,
        isActive: true,
      );
      await _shiftRepository.saveShift(newShift);
      emit(const ShiftManageSuccess());
    } catch (e) {
      emit(ShiftManageError('خطأ أثناء إضافة الوردية: $e'));
    }
  }

  // Update an existing shift
  Future<void> updateShift({
    required ShiftModel originalShift,
    required String name,
    required String startTime,
    required String endTime,
    required int gracePeriod,
    required bool isActive,
  }) async {
    emit(const ShiftManageLoading());
    try {
      final updatedShift = originalShift.copyWith(
        name: name.trim(),
        startTime: startTime,
        endTime: endTime,
        gracePeriod: gracePeriod,
        isActive: isActive,
      );
      await _shiftRepository.saveShift(updatedShift);
      emit(const ShiftManageSuccess());
    } catch (e) {
      emit(ShiftManageError('خطأ أثناء تعديل الوردية: $e'));
    }
  }

  // Toggle activation status
  Future<void> toggleShiftStatus(ShiftModel shift) async {
    emit(const ShiftManageLoading());
    try {
      final updated = shift.copyWith(isActive: !shift.isActive);
      await _shiftRepository.saveShift(updated);
      emit(const ShiftManageSuccess());
    } catch (e) {
      emit(ShiftManageError('خطأ أثناء تعديل حالة الوردية: $e'));
    }
  }

  // Delete a shift
  Future<void> deleteShift(int id) async {
    emit(const ShiftManageLoading());
    try {
      await _shiftRepository.deleteShift(id);
      emit(const ShiftManageSuccess());
    } catch (e) {
      emit(ShiftManageError('خطأ أثناء حذف الوردية: $e'));
    }
  }
}

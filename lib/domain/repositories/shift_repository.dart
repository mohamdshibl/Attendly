import '../../data/models/shift_model.dart';

abstract class ShiftRepository {
  Future<List<ShiftModel>> getShifts();
  Future<ShiftModel?> getShiftById(int id);
  Future<int> saveShift(ShiftModel shift);
  Future<void> deleteShift(int id);
}

import '../../core/database/database_helper.dart';
import '../../core/database/schema_constants.dart';
import '../../domain/repositories/shift_repository.dart';
import '../models/shift_model.dart';

class ShiftRepositoryImpl implements ShiftRepository {
  final DatabaseHelper _dbHelper;

  ShiftRepositoryImpl(this._dbHelper);

  @override
  Future<List<ShiftModel>> getShifts() async {
    final list = await _dbHelper.queryAll(SchemaConstants.storeShifts);
    return list.map((e) => ShiftModel.fromMap(e)).toList();
  }

  @override
  Future<ShiftModel?> getShiftById(int id) async {
    final map = await _dbHelper.queryById(SchemaConstants.storeShifts, id);
    if (map == null) return null;
    return ShiftModel.fromMap(map);
  }

  @override
  Future<int> saveShift(ShiftModel shift) async {
    final key = await _dbHelper.put(SchemaConstants.storeShifts, shift.toMap());
    return key as int;
  }

  @override
  Future<void> deleteShift(int id) async {
    await _dbHelper.delete(SchemaConstants.storeShifts, id);
  }
}

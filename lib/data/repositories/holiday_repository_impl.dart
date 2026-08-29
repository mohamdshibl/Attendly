import '../../core/database/database_helper.dart';
import '../../core/database/schema_constants.dart';
import '../../domain/repositories/holiday_repository.dart';
import '../models/official_holiday_model.dart';

class HolidayRepositoryImpl implements HolidayRepository {
  final DatabaseHelper _dbHelper;

  HolidayRepositoryImpl(this._dbHelper);

  @override
  Future<List<OfficialHolidayModel>> getHolidays() async {
    final list = await _dbHelper.queryAll(SchemaConstants.storeOfficialHolidays);
    return list.map((e) => OfficialHolidayModel.fromMap(e)).toList();
  }

  @override
  Future<void> saveHoliday(OfficialHolidayModel holiday) async {
    await _dbHelper.put(SchemaConstants.storeOfficialHolidays, holiday.toMap());
  }

  @override
  Future<void> deleteHoliday(int id) async {
    await _dbHelper.delete(SchemaConstants.storeOfficialHolidays, id);
  }

  @override
  Future<OfficialHolidayModel?> getHolidayByDate(DateTime date) async {
    final formattedDate = date.toIso8601String().substring(0, 10);
    final map = await _dbHelper.queryByIndex(
      SchemaConstants.storeOfficialHolidays,
      SchemaConstants.indexDate,
      formattedDate,
    );
    if (map == null) return null;
    return OfficialHolidayModel.fromMap(map);
  }
}

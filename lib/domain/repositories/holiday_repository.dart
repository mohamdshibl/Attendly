import '../../data/models/official_holiday_model.dart';

abstract class HolidayRepository {
  Future<List<OfficialHolidayModel>> getHolidays();
  Future<void> saveHoliday(OfficialHolidayModel holiday);
  Future<void> deleteHoliday(int id);
  Future<OfficialHolidayModel?> getHolidayByDate(DateTime date);
}

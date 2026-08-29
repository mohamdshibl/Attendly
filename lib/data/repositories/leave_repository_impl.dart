import '../../core/database/database_helper.dart';
import '../../core/database/schema_constants.dart';
import '../../domain/repositories/leave_repository.dart';
import '../models/leave_balance_model.dart';
import '../models/leave_request_model.dart';
import '../models/leave_type_model.dart';

class LeaveRepositoryImpl implements LeaveRepository {
  final DatabaseHelper _dbHelper;

  LeaveRepositoryImpl(this._dbHelper);

  // Leave Types
  @override
  Future<List<LeaveTypeModel>> getLeaveTypes() async {
    final list = await _dbHelper.queryAll(SchemaConstants.storeLeaveTypes);
    return list.map((e) => LeaveTypeModel.fromMap(e)).toList();
  }

  @override
  Future<LeaveTypeModel?> getLeaveTypeById(int id) async {
    final map = await _dbHelper.queryById(SchemaConstants.storeLeaveTypes, id);
    if (map == null) return null;
    return LeaveTypeModel.fromMap(map);
  }

  @override
  Future<void> saveLeaveType(LeaveTypeModel type) async {
    await _dbHelper.put(SchemaConstants.storeLeaveTypes, type.toMap());
  }

  @override
  Future<void> deleteLeaveType(int id) async {
    await _dbHelper.delete(SchemaConstants.storeLeaveTypes, id);
  }

  // Leave Requests
  @override
  Future<List<LeaveRequestModel>> getLeaveRequests() async {
    final list = await _dbHelper.queryAll(SchemaConstants.storeLeaveRequests);
    return list.map((e) => LeaveRequestModel.fromMap(e)).toList();
  }

  @override
  Future<List<LeaveRequestModel>> getLeaveRequestsForEmployee(int employeeId) async {
    final list = await _dbHelper.queryAllByIndex(
      SchemaConstants.storeLeaveRequests,
      SchemaConstants.indexEmployeeId,
      employeeId,
    );
    return list.map((e) => LeaveRequestModel.fromMap(e)).toList();
  }

  @override
  Future<LeaveRequestModel?> getLeaveRequestById(int id) async {
    final map = await _dbHelper.queryById(SchemaConstants.storeLeaveRequests, id);
    if (map == null) return null;
    return LeaveRequestModel.fromMap(map);
  }

  @override
  Future<void> saveLeaveRequest(LeaveRequestModel request) async {
    await _dbHelper.put(SchemaConstants.storeLeaveRequests, request.toMap());
  }

  // Leave Balances
  @override
  Future<List<LeaveBalanceModel>> getLeaveBalancesForEmployee(int employeeId, int year) async {
    final all = await _dbHelper.queryAllByIndex(
      SchemaConstants.storeLeaveBalances,
      SchemaConstants.indexEmployeeId,
      employeeId,
    );
    return all
        .map((e) => LeaveBalanceModel.fromMap(e))
        .where((element) => element.leaveYear == year)
        .toList();
  }

  @override
  Future<LeaveBalanceModel?> getLeaveBalance(int employeeId, int leaveTypeId, int year) async {
    final all = await _dbHelper.queryAllByIndex(
      SchemaConstants.storeLeaveBalances,
      SchemaConstants.indexEmployeeId,
      employeeId,
    );
    for (final map in all) {
      final model = LeaveBalanceModel.fromMap(map);
      if (model.leaveTypeId == leaveTypeId && model.leaveYear == year) {
        return model;
      }
    }
    return null;
  }

  @override
  Future<void> saveLeaveBalance(LeaveBalanceModel balance) async {
    await _dbHelper.put(SchemaConstants.storeLeaveBalances, balance.toMap());
  }

  @override
  Future<void> seedLeaveTypes() async {
    final seedSetting = await _dbHelper.queryById(SchemaConstants.storeSettings, 'is_leave_types_seeded');
    if (seedSetting != null && seedSetting['value'] == 1) {
      return; // Already seeded
    }

    final defaultTypes = [
      LeaveTypeModel(
        name: 'إجازة اعتيادية سنوية',
        code: 'ANNUAL',
        paid: true,
        deductsFromAnnual: true,
        requiresApproval: true,
        requiresDocument: false,
      ),
      LeaveTypeModel(
        name: 'إجازة عارضة طارئة',
        code: 'CASUAL',
        paid: true,
        deductsFromAnnual: true,
        requiresApproval: true,
        requiresDocument: false,
        maxDaysPerRequest: 2,
        annualLimit: 7,
      ),
      LeaveTypeModel(
        name: 'إجازة مرضية',
        code: 'SICK',
        paid: true,
        deductsFromAnnual: false,
        requiresApproval: true,
        requiresDocument: true,
      ),
      LeaveTypeModel(
        name: 'إجازة وضع وأمومة',
        code: 'MATERNITY',
        paid: true,
        deductsFromAnnual: false,
        requiresApproval: true,
        requiresDocument: true,
        lifetimeLimit: 3,
      ),
      LeaveTypeModel(
        name: 'إجازة رعاية مولود/أبوة',
        code: 'PATERNITY',
        paid: true,
        deductsFromAnnual: false,
        requiresApproval: true,
        requiresDocument: false,
        lifetimeLimit: 3,
        maxDaysPerRequest: 1,
      ),
      LeaveTypeModel(
        name: 'إجازة حج وزيارة',
        code: 'HAJJ',
        paid: true,
        deductsFromAnnual: false,
        requiresApproval: true,
        requiresDocument: true,
        lifetimeLimit: 1,
      ),
      LeaveTypeModel(
        name: 'إجازة غير مدفوعة / أخرى',
        code: 'OTHER',
        paid: false,
        deductsFromAnnual: false,
        requiresApproval: true,
        requiresDocument: false,
      ),
    ];

    for (final type in defaultTypes) {
      await _dbHelper.put(SchemaConstants.storeLeaveTypes, type.toMap());
    }

    await _dbHelper.put(SchemaConstants.storeSettings, {
      'key': 'is_leave_types_seeded',
      'value': 1,
    });
  }
}

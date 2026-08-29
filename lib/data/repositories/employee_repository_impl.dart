import '../../core/database/database_helper.dart';
import '../../core/database/schema_constants.dart';
import '../../core/utils/hash_utils.dart';
import '../../domain/repositories/employee_repository.dart';
import '../models/employee_model.dart';
import '../models/shift_model.dart';

class EmployeeRepositoryImpl implements EmployeeRepository {
  final DatabaseHelper _dbHelper;

  EmployeeRepositoryImpl(this._dbHelper);

  @override
  Future<List<EmployeeModel>> getEmployees() async {
    final list = await _dbHelper.queryAll(SchemaConstants.storeEmployees);
    return list.map((e) => EmployeeModel.fromMap(e)).toList();
  }

  @override
  Future<EmployeeModel?> getEmployeeById(int id) async {
    final map = await _dbHelper.queryById(SchemaConstants.storeEmployees, id);
    if (map == null) return null;
    return EmployeeModel.fromMap(map);
  }

  @override
  Future<EmployeeModel?> getEmployeeByCode(String code) async {
    final trimmed = code.trim();
    final map = await _dbHelper.queryByIndex(
      SchemaConstants.storeEmployees,
      SchemaConstants.indexEmployeeCode,
      trimmed,
    );
    if (map != null) {
      return EmployeeModel.fromMap(map);
    }

    // Fallback: Case-insensitive scan
    final all = await getEmployees();
    final normalized = trimmed.toLowerCase();
    for (final emp in all) {
      if (emp.employeeCode.trim().toLowerCase() == normalized) {
        return emp;
      }
    }
    return null;
  }

  @override
  Future<int> saveEmployee(EmployeeModel employee) async {
    final key = await _dbHelper.put(SchemaConstants.storeEmployees, employee.toMap());
    return key as int;
  }

  @override
  Future<void> deleteEmployee(int id) async {
    await _dbHelper.delete(SchemaConstants.storeEmployees, id);
  }

  @override
  Future<EmployeeModel?> authenticate(String employeeCode, String pinOrPassword) async {
    final employee = await getEmployeeByCode(employeeCode);
    if (employee == null) return null;

    // Check if the employee is active
    if (!employee.isActive) return null;

    // Verify password hash
    final isValid = HashUtils.verifyPassword(pinOrPassword.trim(), employee.passwordHash);
    if (!isValid) return null;

    return employee;
  }

  @override
  Future<void> seedDefaultAdmin() async {
    // 1. Check if seeded already by reading settings
    final seedSetting = await _dbHelper.queryById(SchemaConstants.storeSettings, 'is_seeded');
    if (seedSetting != null && seedSetting['value'] == 1) {
      return; // Already seeded
    }

    // 2. Seed a default shift
    final shifts = await _dbHelper.queryAll(SchemaConstants.storeShifts);
    int defaultShiftId = 1;
    if (shifts.isEmpty) {
      final defaultShift = ShiftModel(
        name: 'الشيفت الصباحي (Default)',
        startTime: '09:00',
        endTime: '17:00',
        gracePeriod: 15,
        isActive: true,
      );
      defaultShiftId = await _dbHelper.put(SchemaConstants.storeShifts, defaultShift.toMap()) as int;
    } else {
      defaultShiftId = ShiftModel.fromMap(shifts.first).id ?? 1;
    }

    // 3. Seed default Admin if not exists
    final employees = await _dbHelper.queryAll(SchemaConstants.storeEmployees);
    final adminExists = employees.any((e) => e['role'] == 'admin');
    if (!adminExists) {
      final defaultAdmin = EmployeeModel(
        employeeCode: 'admin',
        name: 'مدير النظام',
        passwordHash: HashUtils.hashPassword('admin123'),
        department: 'الإدارة',
        shiftId: defaultShiftId,
        isActive: true,
        role: 'admin',
        createdAt: DateTime.now(),
      );
      await _dbHelper.put(SchemaConstants.storeEmployees, defaultAdmin.toMap());
    }

    // 4. Mark database as seeded in settings
    await _dbHelper.put(SchemaConstants.storeSettings, {
      'key': 'is_seeded',
      'value': 1,
    });
  }
}

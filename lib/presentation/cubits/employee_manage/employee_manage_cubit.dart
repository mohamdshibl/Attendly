import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/hash_utils.dart';
import '../../../data/models/employee_model.dart';
import '../../../domain/repositories/employee_repository.dart';
import 'employee_manage_state.dart';

class EmployeeManageCubit extends Cubit<EmployeeManageState> {
  final EmployeeRepository _employeeRepository;

  EmployeeManageCubit(this._employeeRepository) : super(const EmployeeManageInitial());

  // Add a new employee, validating unique code and hashing their PIN
  Future<void> addEmployee({
    required String employeeCode,
    required String name,
    required String pin,
    required String department,
    required int shiftId,
  }) async {
    emit(const EmployeeManageLoading());
    try {
      final existing = await _employeeRepository.getEmployeeByCode(employeeCode.trim());
      if (existing != null) {
        emit(const EmployeeManageError('كود الموظف مستخدم بالفعل'));
        return;
      }

      final newEmployee = EmployeeModel(
        employeeCode: employeeCode.trim(),
        name: name.trim(),
        passwordHash: HashUtils.hashPassword(pin),
        department: department.trim(),
        shiftId: shiftId,
        isActive: true,
        role: 'employee',
        createdAt: DateTime.now(),
      );

      await _employeeRepository.saveEmployee(newEmployee);
      emit(const EmployeeManageSuccess());
    } catch (e) {
      emit(EmployeeManageError('خطأ أثناء إضافة الموظف: $e'));
    }
  }

  // Update existing employee, optionally updating their PIN
  Future<void> updateEmployee({
    required EmployeeModel originalEmployee,
    required String employeeCode,
    required String name,
    String? pin, // Null or empty means no password change
    required String department,
    required int shiftId,
    required bool isActive,
  }) async {
    emit(const EmployeeManageLoading());
    try {
      final trimmedCode = employeeCode.trim();
      if (trimmedCode != originalEmployee.employeeCode) {
        final existing = await _employeeRepository.getEmployeeByCode(trimmedCode);
        if (existing != null) {
          emit(const EmployeeManageError('كود الموظف مستخدم بالفعل'));
          return;
        }
      }

      final updatedEmployee = originalEmployee.copyWith(
        employeeCode: trimmedCode,
        name: name.trim(),
        passwordHash: pin != null && pin.isNotEmpty 
            ? HashUtils.hashPassword(pin) 
            : originalEmployee.passwordHash,
        department: department.trim(),
        shiftId: shiftId,
        isActive: isActive,
      );

      await _employeeRepository.saveEmployee(updatedEmployee);
      emit(const EmployeeManageSuccess());
    } catch (e) {
      emit(EmployeeManageError('خطأ أثناء تعديل الموظف: $e'));
    }
  }

  // Toggle activation status
  Future<void> toggleEmployeeStatus(EmployeeModel employee) async {
    emit(const EmployeeManageLoading());
    try {
      final updated = employee.copyWith(isActive: !employee.isActive);
      await _employeeRepository.saveEmployee(updated);
      emit(const EmployeeManageSuccess());
    } catch (e) {
      emit(EmployeeManageError('خطأ أثناء تعديل حالة الموظف: $e'));
    }
  }
}

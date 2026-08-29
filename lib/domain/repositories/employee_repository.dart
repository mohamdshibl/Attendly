import '../../data/models/employee_model.dart';

abstract class EmployeeRepository {
  Future<List<EmployeeModel>> getEmployees();
  Future<EmployeeModel?> getEmployeeById(int id);
  Future<EmployeeModel?> getEmployeeByCode(String code);
  Future<int> saveEmployee(EmployeeModel employee);
  Future<void> deleteEmployee(int id);
  Future<EmployeeModel?> authenticate(String employeeCode, String pinOrPassword);
  Future<void> seedDefaultAdmin();
}

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/database/schema_constants.dart';
import '../../../domain/repositories/employee_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final EmployeeRepository _employeeRepository;
  final DatabaseHelper _dbHelper;

  AuthCubit(this._employeeRepository, this._dbHelper) : super(const AuthInitial());

  // Check if session exists in IndexedDB (enables persistent login across browser refreshes)
  Future<void> checkSession() async {
    emit(const AuthLoading());
    try {
      final session = await _dbHelper.queryById(
        SchemaConstants.storeSettings,
        'current_session_employee_id',
      );
      if (session != null && session['value'] != null) {
        final employeeId = session['value'] as int;
        final employee = await _employeeRepository.getEmployeeById(employeeId);
        if (employee != null && employee.isActive) {
          emit(Authenticated(employee));
          return;
        }
      }
      emit(const Unauthenticated());
    } catch (e) {
      emit(AuthError('خطأ أثناء التحقق من الجلسة: $e'));
    }
  }

  // Log in using Employee Code and Password/PIN
  Future<void> login(String code, String pinOrPassword) async {
    emit(const AuthLoading());
    try {
      final employee = await _employeeRepository.authenticate(code.trim(), pinOrPassword.trim());
      if (employee != null) {
        // Save current user session ID
        await _dbHelper.put(SchemaConstants.storeSettings, {
          'key': 'current_session_employee_id',
          'value': employee.id,
        });
        emit(Authenticated(employee));
      } else {
        emit(const AuthError('بيانات الدخول غير صحيحة أو الحساب غير نشط'));
      }
    } catch (e) {
      emit(AuthError('حدث خطأ أثناء تسجيل الدخول: $e'));
    }
  }

  // Clear session and log out
  Future<void> logout() async {
    emit(const AuthLoading());
    try {
      await _dbHelper.delete(SchemaConstants.storeSettings, 'current_session_employee_id');
      emit(const Unauthenticated());
    } catch (e) {
      emit(AuthError('حدث خطأ أثناء تسجيل الخروج: $e'));
    }
  }
}

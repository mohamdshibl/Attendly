import 'package:get_it/get_it.dart';
import '../database/database_helper.dart';
import '../services/time_service.dart';
import '../../domain/repositories/leave_repository.dart';
import '../../domain/repositories/holiday_repository.dart';
import '../../domain/repositories/audit_log_repository.dart';
import '../../domain/repositories/shift_repository.dart';
import '../../domain/repositories/employee_repository.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../../domain/policies/leave_policy_engine.dart';
import '../../data/repositories/attendance_repository_impl.dart';
import '../../data/repositories/employee_repository_impl.dart';
import '../../data/repositories/shift_repository_impl.dart';
import '../../data/repositories/leave_repository_impl.dart';
import '../../data/repositories/holiday_repository_impl.dart';
import '../../data/repositories/audit_log_repository_impl.dart';
import '../../presentation/cubits/auth/auth_cubit.dart';
import '../../presentation/cubits/employee_dashboard/employee_dashboard_cubit.dart';
import '../../presentation/cubits/attendance_history/attendance_history_cubit.dart';
import '../../presentation/cubits/admin_dashboard/admin_dashboard_cubit.dart';
import '../../presentation/cubits/employee_manage/employee_manage_cubit.dart';
import '../../presentation/cubits/shift_manage/shift_manage_cubit.dart';
import '../../presentation/cubits/leave_request/leave_request_cubit.dart';
import '../../presentation/cubits/leave_manage/leave_manage_cubit.dart';
import '../../presentation/cubits/holiday_manage/holiday_manage_cubit.dart';
import '../../presentation/cubits/audit_log/audit_log_cubit.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Database Helper
  final dbHelper = DatabaseHelper();
  await dbHelper.open();
  sl.registerSingleton<DatabaseHelper>(dbHelper);

  // Core Services
  sl.registerLazySingleton<TimeService>(() => LocalTimeService());

  // Policies
  sl.registerLazySingleton<LeavePolicyEngine>(() => LeavePolicyEngine());

  // Repositories
  sl.registerLazySingleton<ShiftRepository>(() => ShiftRepositoryImpl(sl()));
  sl.registerLazySingleton<EmployeeRepository>(() => EmployeeRepositoryImpl(sl()));
  sl.registerLazySingleton<AttendanceRepository>(() => AttendanceRepositoryImpl(sl()));
  sl.registerLazySingleton<LeaveRepository>(() => LeaveRepositoryImpl(sl()));
  sl.registerLazySingleton<HolidayRepository>(() => HolidayRepositoryImpl(sl()));
  sl.registerLazySingleton<AuditLogRepository>(() => AuditLogRepositoryImpl(sl()));

  // Cubits
  sl.registerFactory(() => AuthCubit(sl(), sl()));
  sl.registerFactory(() => EmployeeDashboardCubit(sl(), sl(), sl(), sl(), sl()));
  sl.registerFactory(() => AttendanceHistoryCubit(sl(), sl()));
  sl.registerFactory(() => AdminDashboardCubit(sl(), sl(), sl(), sl()));
  sl.registerFactory(() => EmployeeManageCubit(sl()));
  sl.registerFactory(() => ShiftManageCubit(sl()));
  sl.registerFactory(() => LeaveRequestCubit(
        leaveRepo: sl(),
        employeeRepo: sl(),
        holidayRepo: sl(),
        auditLogRepo: sl(),
        policyEngine: sl(),
      ));
  sl.registerFactory(() => LeaveManageCubit(
        leaveRepo: sl(),
        employeeRepo: sl(),
        auditLogRepo: sl(),
      ));
  sl.registerFactory(() => HolidayManageCubit(
        holidayRepo: sl(),
        auditLogRepo: sl(),
      ));
  sl.registerFactory(() => AuditLogCubit(
        auditLogRepo: sl(),
        employeeRepo: sl(),
      ));

  // Seed data
  await sl<EmployeeRepository>().seedDefaultAdmin();
  await sl<LeaveRepository>().seedLeaveTypes();
}

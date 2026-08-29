import 'package:get_it/get_it.dart';
import '../database/database_helper.dart';
import '../services/time_service.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../../domain/repositories/employee_repository.dart';
import '../../domain/repositories/shift_repository.dart';
import '../../data/repositories/attendance_repository_impl.dart';
import '../../data/repositories/employee_repository_impl.dart';
import '../../data/repositories/shift_repository_impl.dart';
import '../../presentation/cubits/auth/auth_cubit.dart';
import '../../presentation/cubits/employee_dashboard/employee_dashboard_cubit.dart';
import '../../presentation/cubits/attendance_history/attendance_history_cubit.dart';
import '../../presentation/cubits/admin_dashboard/admin_dashboard_cubit.dart';
import '../../presentation/cubits/employee_manage/employee_manage_cubit.dart';
import '../../presentation/cubits/shift_manage/shift_manage_cubit.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Database Helper
  final dbHelper = DatabaseHelper();
  await dbHelper.open();
  sl.registerSingleton<DatabaseHelper>(dbHelper);

  // Core Services
  sl.registerLazySingleton<TimeService>(() => LocalTimeService());

  // Repositories
  sl.registerLazySingleton<ShiftRepository>(() => ShiftRepositoryImpl(sl()));
  sl.registerLazySingleton<EmployeeRepository>(() => EmployeeRepositoryImpl(sl()));
  sl.registerLazySingleton<AttendanceRepository>(() => AttendanceRepositoryImpl(sl()));

  // Cubits
  sl.registerFactory(() => AuthCubit(sl(), sl()));
  sl.registerFactory(() => EmployeeDashboardCubit(sl(), sl(), sl()));
  sl.registerFactory(() => AttendanceHistoryCubit(sl(), sl()));
  sl.registerFactory(() => AdminDashboardCubit(sl(), sl(), sl(), sl()));
  sl.registerFactory(() => EmployeeManageCubit(sl()));
  sl.registerFactory(() => ShiftManageCubit(sl()));

  // Seed default admin
  await sl<EmployeeRepository>().seedDefaultAdmin();
}

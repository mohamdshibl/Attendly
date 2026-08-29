import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../cubits/auth/auth_cubit.dart';
import '../cubits/auth/auth_state.dart';
import 'login_screen.dart';
import 'employee_dashboard_screen.dart';
import 'attendance_history_screen.dart';
import 'admin/admin_dashboard_screen.dart';
import 'admin/employee_list_screen.dart';
import 'admin/shift_list_screen.dart';
import 'admin/reports_screen.dart';
import '../cubits/admin_dashboard/admin_dashboard_cubit.dart';
import '../../core/di/service_locator.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  void initState() {
    super.initState();
    // Check local session on startup
    context.read<AuthCubit>().checkSession();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is AuthInitial || state is AuthLoading) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.secondary),
            ),
          );
        } else if (state is Authenticated) {
          if (state.employee.role == 'admin') {
            return const AdminMainShell();
          } else {
            return EmployeeMainShell(employee: state.employee);
          }
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}

// ----------------------------------------------------
// Admin Shell Layout (Sidebar & Main content swap)
// ----------------------------------------------------
class AdminMainShell extends StatefulWidget {
  const AdminMainShell({super.key});

  @override
  State<AdminMainShell> createState() => _AdminMainShellState();
}

class _AdminMainShellState extends State<AdminMainShell> {
  int _selectedTabIndex = 0;

  final List<Widget> _views = const [
    AdminDashboardView(),
    EmployeeListView(),
    ShiftListView(),
    ReportsView(),
    AdminSettingsView(),
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    return BlocProvider<AdminDashboardCubit>(
      create: (context) => sl<AdminDashboardCubit>()..loadDashboard(),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: !isDesktop
              ? AppBar(
                  title: const Text('إدارة الحضور والانصراف', style: AppTextStyles.h2),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                )
              : null,
          drawer: !isDesktop ? _buildDrawer() : null,
          body: Row(
            children: [
              if (isDesktop) _buildSidebar(),
              Expanded(
                child: ClipRRect(
                  child: _views[_selectedTabIndex],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 260,
      color: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sidebar Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            child: Row(
              children: [
                const Icon(Icons.fingerprint_rounded, color: AppColors.secondaryLight, size: 32),
                const SizedBox(width: 12),
                Text(
                  'حضور ودوام',
                  style: AppTextStyles.h2.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.primaryLight, height: 1),
          const SizedBox(height: 16),

          // Sidebar Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildSidebarItem(0, 'لوحة التحكم', Icons.dashboard_outlined),
                _buildSidebarItem(1, 'الموظفين', Icons.people_outline_rounded),
                _buildSidebarItem(2, 'الورديات', Icons.schedule_outlined),
                _buildSidebarItem(3, 'التقارير', Icons.analytics_outlined),
                _buildSidebarItem(4, 'إعدادات النظام', Icons.settings_outlined),
              ],
            ),
          ),

          // Sidebar Footer: Logout
          const Divider(color: AppColors.primaryLight, height: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListTile(
              onTap: () => context.read<AuthCubit>().logout(),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              leading: const Icon(Icons.logout_rounded, color: AppColors.error),
              title: Text(
                'تسجيل خروج',
                style: AppTextStyles.bodyBold.copyWith(color: AppColors.error),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index, String title, IconData icon) {
    final isSelected = _selectedTabIndex == index;
    final activeColor = AppColors.secondaryLight;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        selected: isSelected,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        selectedTileColor: activeColor.withOpacity(0.1),
        leading: Icon(icon, color: isSelected ? activeColor : AppColors.textLight),
        title: Text(
          title,
          style: AppTextStyles.bodyBold.copyWith(
            color: isSelected ? Colors.white : AppColors.textLight,
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: AppColors.primary,
        child: Column(
          children: [
            DrawerHeader(
              child: Row(
                children: [
                  const Icon(Icons.fingerprint_rounded, color: AppColors.secondaryLight, size: 48),
                  const SizedBox(width: 12),
                  Text(
                    'حضور ودوام',
                    style: AppTextStyles.h1.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  _buildDrawerItem(0, 'لوحة التحكم', Icons.dashboard_outlined),
                  _buildDrawerItem(1, 'الموظفين', Icons.people_outline_rounded),
                  _buildDrawerItem(2, 'الورديات', Icons.schedule_outlined),
                  _buildDrawerItem(3, 'التقارير', Icons.analytics_outlined),
                  _buildDrawerItem(4, 'إعدادات النظام', Icons.settings_outlined),
                ],
              ),
            ),
            const Divider(color: AppColors.primaryLight),
            ListTile(
              onTap: () {
                Navigator.of(context).pop();
                context.read<AuthCubit>().logout();
              },
              leading: const Icon(Icons.logout_rounded, color: AppColors.error),
              title: Text('تسجيل خروج', style: AppTextStyles.bodyBold.copyWith(color: AppColors.error)),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(int index, String title, IconData icon) {
    final isSelected = _selectedTabIndex == index;
    return ListTile(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
        Navigator.of(context).pop();
      },
      selected: isSelected,
      selectedTileColor: AppColors.secondaryLight.withOpacity(0.1),
      leading: Icon(icon, color: isSelected ? AppColors.secondaryLight : AppColors.textLight),
      title: Text(title, style: AppTextStyles.bodyBold.copyWith(color: isSelected ? Colors.white : AppColors.textLight)),
    );
  }
}

// ----------------------------------------------------
// Employee Shell Layout (Header, Tabs Navigation)
// ----------------------------------------------------
class EmployeeMainShell extends StatefulWidget {
  final dynamic employee; // EmployeeModel

  const EmployeeMainShell({super.key, required this.employee});

  @override
  State<EmployeeMainShell> createState() => _EmployeeMainShellState();
}

class _EmployeeMainShellState extends State<EmployeeMainShell> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> views = [
      EmployeeDashboardView(employee: widget.employee),
      AttendanceHistoryView(employee: widget.employee),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          title: Row(
            children: [
              const Icon(Icons.fingerprint_rounded, color: AppColors.secondaryLight, size: 28),
              const SizedBox(width: 10),
              Text('بوابة الموظف', style: AppTextStyles.h2.copyWith(color: Colors.white)),
            ],
          ),
          actions: [
            // Logout
            TextButton.icon(
              onPressed: () => context.read<AuthCubit>().logout(),
              icon: const Icon(Icons.logout_rounded, color: Colors.white70, size: 18),
              label: Text(
                'تسجيل خروج',
                style: AppTextStyles.bodyBold.copyWith(color: Colors.white70),
              ),
            ),
            const SizedBox(width: 12),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              color: AppColors.primaryLight,
              child: Row(
                children: [
                  _buildTabButton(0, 'لوحة التحكم اليومية', Icons.dashboard_outlined),
                  _buildTabButton(1, 'سجل الحضور والانصراف', Icons.history_rounded),
                ],
              ),
            ),
          ),
        ),
        body: views[_selectedTabIndex],
      ),
    );
  }

  Widget _buildTabButton(int index, String title, IconData icon) {
    final isSelected = _selectedTabIndex == index;
    final activeColor = AppColors.secondaryLight;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? activeColor : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isSelected ? activeColor : Colors.white60),
            const SizedBox(width: 8),
            Text(
              title,
              style: AppTextStyles.bodyBold.copyWith(
                color: isSelected ? Colors.white : Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// Admin Settings View
// ----------------------------------------------------
class AdminSettingsView extends StatelessWidget {
  const AdminSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('إعدادات النظام', style: AppTextStyles.h1),
          const SizedBox(height: 4),
          Text('تفاصيل فنية وإعدادات الأمان وقاعدة البيانات المحلية', style: AppTextStyles.caption),
          const SizedBox(height: 32),

          Expanded(
            child: ListView(
              children: [
                _buildSettingCard(
                  'قاعدة بيانات IndexedDB',
                  'تم إعداد قاعدة البيانات محلياً داخل المتصفح وهي تعمل بوضع عدم الاتصال بالكامل (Offline-First).',
                  Icons.storage_rounded,
                  AppColors.secondary,
                ),
                const SizedBox(height: 16),
                _buildSettingCard(
                  'أمان كلمات المرور (PIN)',
                  'يتم تشفير الرموز السرية للموظفين محلياً باستخدام خوارزمية SHA-256 قبل الحفظ.',
                  Icons.security_rounded,
                  AppColors.success,
                ),
                const SizedBox(height: 16),
                _buildSettingCard(
                  'التحقق من وقت النظام',
                  'يعتمد هذا الاصدار التجريبي (MVP) على الساعة المحلية للجهاز. لمنع التلاعب بالوقت، يدعم النظام مستقبلاً الاتصال بخوادم NTP الخارجية أو نظام API مركزي.',
                  Icons.lock_clock_rounded,
                  AppColors.warning,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard(String title, String description, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.h2),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: AppTextStyles.body.copyWith(color: AppColors.textSecondary, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

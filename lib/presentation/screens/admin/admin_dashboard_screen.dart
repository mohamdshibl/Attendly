import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' as intl;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../cubits/admin_dashboard/admin_dashboard_cubit.dart';
import '../../cubits/admin_dashboard/admin_dashboard_state.dart';
import '../../../data/models/employee_model.dart';

class AdminDashboardView extends StatelessWidget {
  const AdminDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminDashboardCubit, AdminDashboardState>(
      builder: (context, state) {
        if (state is AdminDashboardLoading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.secondary));
        } else if (state is AdminDashboardError) {
          return Center(
            child: Text(state.message, style: const TextStyle(color: AppColors.error)),
          );
        } else if (state is AdminDashboardLoaded) {
          return RefreshIndicator(
            onRefresh: () => context.read<AdminDashboardCubit>().loadDashboard(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Admin Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('لوحة التحكم الإدارية', style: AppTextStyles.h1),
                          const SizedBox(height: 4),
                          Text('نظرة عامة على حضور الموظفين لهذا اليوم', style: AppTextStyles.caption),
                        ],
                      ),
                      // Refresh button
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, color: AppColors.secondary),
                        onPressed: () => context.read<AdminDashboardCubit>().loadDashboard(),
                        tooltip: 'تحديث البيانات',
                      ),
                    ],
                  ),
                    const SizedBox(height: 24),

                    // Stats Grid
                    LayoutBuilder(
                      builder: (context, constraints) {
                        int crossAxisCount = 5;
                        if (constraints.maxWidth < 600) {
                          crossAxisCount = 1;
                        } else if (constraints.maxWidth < 900) {
                          crossAxisCount = 2;
                        } else if (constraints.maxWidth < 1200) {
                          crossAxisCount = 3;
                        }
                        
                        return GridView.count(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          childAspectRatio: 1.8,
                          children: [
                            _buildStatCard('إجمالي الموظفين', '${state.totalEmployees}', Icons.people_outline, AppColors.primary),
                            _buildStatCard('حضور اليوم', '${state.presentToday}', Icons.check_circle_outline, AppColors.success),
                            _buildStatCard('متأخر اليوم', '${state.lateToday}', Icons.warning_amber_rounded, AppColors.warning),
                            _buildStatCard('غياب اليوم', '${state.absentToday}', Icons.cancel_outlined, AppColors.error),
                            _buildStatCard('متواجد حالياً', '${state.currentlyCheckedIn}', Icons.meeting_room_outlined, AppColors.accent),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 32),

                    // Today's Activity Table
                    Text('سجل النشاط اليومي', style: AppTextStyles.h2),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: state.todayAttendance.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(48.0),
                                child: Column(
                                  children: [
                                    const Icon(Icons.info_outline, color: AppColors.textLight, size: 48),
                                    const SizedBox(height: 16),
                                    Text('لا توجد عمليات تسجيل حضور أو انصراف اليوم بعد.', style: AppTextStyles.h3.copyWith(color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                            )
                          : _buildActivityTable(state),
                    ),
                  ],
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: AppTextStyles.display.copyWith(color: color, fontSize: 28),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTable(AdminDashboardLoaded state) {
    final timeFormat = intl.DateFormat('hh:mm a', 'ar');

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(AppColors.background),
                dataRowMinHeight: 56,
                dataRowMaxHeight: 56,
                columns: const [
                  DataColumn(label: Text('الموظف', style: AppTextStyles.bodyBold)),
                  DataColumn(label: Text('القسم', style: AppTextStyles.bodyBold)),
                  DataColumn(label: Text('حضور', style: AppTextStyles.bodyBold)),
                  DataColumn(label: Text('انصراف', style: AppTextStyles.bodyBold)),
                  DataColumn(label: Text('دقائق التأخير', style: AppTextStyles.bodyBold)),
                  DataColumn(label: Text('الحالة', style: AppTextStyles.bodyBold)),
                ],
                rows: state.todayAttendance.map((record) {
                  // Find employee details
                  final emp = state.employees.firstWhere(
                    (e) => e.id == record.employeeId,
                    orElse: () => _unknownEmployee(),
                  );

                  return DataRow(
                    cells: [
                      // Employee Name & Code
                      DataCell(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(emp.name, style: AppTextStyles.bodyBold),
                            Text(emp.employeeCode, style: AppTextStyles.caption),
                          ],
                        ),
                      ),
                      // Department
                      DataCell(Text(emp.department, style: AppTextStyles.body)),
                      // Check-in
                      DataCell(Text(
                        record.checkIn != null ? timeFormat.format(record.checkIn!) : '--:--',
                        style: AppTextStyles.body,
                      )),
                      // Check-out
                      DataCell(Text(
                        record.checkOut != null ? timeFormat.format(record.checkOut!) : '--:--',
                        style: AppTextStyles.body,
                      )),
                      // Late Minutes
                      DataCell(Text(
                        record.lateMinutes > 0 ? '${record.lateMinutes} دقيقة' : 'لا يوجد',
                        style: AppTextStyles.body.copyWith(
                          color: record.lateMinutes > 0 ? AppColors.error : AppColors.textPrimary,
                        ),
                      )),
                      // Status Badge
                      DataCell(_buildStatusBadge(record.status)),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    String text = '';
    Color color = Colors.grey;

    switch (status) {
      case 'CHECKED_IN':
        text = 'حاضر';
        color = AppColors.success;
        break;
      case 'LATE':
        text = 'متأخر';
        color = AppColors.warning;
        break;
      case 'CHECKED_OUT':
        text = 'منصرف';
        color = AppColors.info;
        break;
      case 'ABSENT':
        text = 'غائب';
        color = AppColors.error;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  EmployeeModel _unknownEmployee() {
    return EmployeeModel(
      id: -1,
      employeeCode: 'N/A',
      name: 'موظف محذوف',
      passwordHash: '',
      department: 'N/A',
      shiftId: -1,
      role: 'employee',
      createdAt: DateTime.now(),
    );
  }
}

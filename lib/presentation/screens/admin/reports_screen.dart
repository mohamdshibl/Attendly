import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' as intl;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../cubits/admin_dashboard/admin_dashboard_cubit.dart';
import '../../cubits/admin_dashboard/admin_dashboard_state.dart';
import '../../../data/models/attendance_model.dart';
import '../../../data/models/employee_model.dart';

class ReportsView extends StatefulWidget {
  const ReportsView({super.key});

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView> {
  int? _selectedEmployeeId;
  String _selectedDepartment = 'الكل';
  String _selectedStatus = 'الكل';
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    // Default date range: last 30 days
    final now = DateTime.now();
    _selectedDateRange = DateTimeRange(
      start: now.subtract(const Duration(days: 29)),
      end: now,
    );
  }

  void _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2025),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ar'),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.secondary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminDashboardCubit, AdminDashboardState>(
      builder: (context, state) {
        if (state is! AdminDashboardLoaded) {
          return const Center(child: CircularProgressIndicator(color: AppColors.secondary));
        }

        // Get unique departments list for filters
        final departments = {'الكل', ...state.employees.map((e) => e.department).where((d) => d.isNotEmpty)};
        
        // Filter attendance records based on selected options
        final filteredRecords = state.allAttendance.where((record) {
          // 1. Employee filter
          if (_selectedEmployeeId != null && record.employeeId != _selectedEmployeeId) {
            return false;
          }

          // Fetch matching employee
          final emp = state.employees.firstWhere(
            (e) => e.id == record.employeeId,
            orElse: () => _placeholderEmployee(),
          );

          // 2. Department filter
          if (_selectedDepartment != 'الكل' && emp.department != _selectedDepartment) {
            return false;
          }

          // 3. Status filter
          if (_selectedStatus != 'الكل' && record.status != _selectedStatus) {
            return false;
          }

          // 4. Date Range filter
          if (_selectedDateRange != null) {
            final recordDate = DateTime.parse(record.date);
            final start = DateTime(_selectedDateRange!.start.year, _selectedDateRange!.start.month, _selectedDateRange!.start.day);
            final end = DateTime(_selectedDateRange!.end.year, _selectedDateRange!.end.month, _selectedDateRange!.end.day, 23, 59, 59);
            if (recordDate.isBefore(start) || recordDate.isAfter(end)) {
              return false;
            }
          }

          return true;
        }).toList();

        // Sort by date descending (most recent first)
        filteredRecords.sort((a, b) => b.date.compareTo(a.date));

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('تقارير الحضور والانصراف', style: AppTextStyles.h1),
                  const SizedBox(height: 4),
                  Text('عرض وتصدير تقارير الموظفين مع خيارات تصفية متقدمة', style: AppTextStyles.caption),
                ],
              ),
              const SizedBox(height: 24),

              // Filter Controls Card
              _buildFiltersCard(state.employees, departments),
              const SizedBox(height: 24),

              // Reports Table
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: filteredRecords.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.analytics_outlined, color: AppColors.textLight, size: 64),
                              const SizedBox(height: 16),
                              Text('لا توجد سجلات حضور مطابقة للمرشحات المحددة', style: AppTextStyles.h3.copyWith(color: AppColors.textSecondary)),
                            ],
                          ),
                        )
                      : _buildReportsTable(filteredRecords, state.employees),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFiltersCard(List<EmployeeModel> employees, Set<String> departments) {
    // Only employees (exclude admin)
    final staffList = employees.where((e) => e.role != 'admin').toList();
    final dateFormat = intl.DateFormat('yyyy-MM-dd');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 800;
          return Column(
            children: [
              GridView.count(
                crossAxisCount: isWide ? 4 : 1,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                childAspectRatio: isWide ? 2.5 : 5,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // Date Range Picker Trigger
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('الفترة الزمنية', style: AppTextStyles.caption),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: _selectDateRange,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedDateRange != null
                                    ? '${dateFormat.format(_selectedDateRange!.start)} - ${dateFormat.format(_selectedDateRange!.end)}'
                                    : 'اختر الفترة...',
                                style: AppTextStyles.body,
                              ),
                              const Icon(Icons.date_range_rounded, size: 20, color: AppColors.secondary),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Employee Dropdown
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('الموظف', style: AppTextStyles.caption),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<int?>(
                        value: _selectedEmployeeId,
                        style: AppTextStyles.body,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('جميع الموظفين')),
                          ...staffList.map((e) {
                            return DropdownMenuItem(value: e.id, child: Text(e.name));
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedEmployeeId = value;
                          });
                        },
                      ),
                    ],
                  ),

                  // Department Dropdown
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('القسم', style: AppTextStyles.caption),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _selectedDepartment,
                        style: AppTextStyles.body,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        items: departments.map((d) {
                          return DropdownMenuItem(value: d, child: Text(d));
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedDepartment = value;
                            });
                          }
                        },
                      ),
                    ],
                  ),

                  // Status Dropdown
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('حالة الحضور', style: AppTextStyles.caption),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        style: AppTextStyles.body,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'الكل', child: Text('جميع الحالات')),
                          DropdownMenuItem(value: 'CHECKED_IN', child: Text('حاضر')),
                          DropdownMenuItem(value: 'LATE', child: Text('متأخر')),
                          DropdownMenuItem(value: 'CHECKED_OUT', child: Text('منصرف')),
                          DropdownMenuItem(value: 'ABSENT', child: Text('غائب')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedStatus = value;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildReportsTable(List<AttendanceModel> records, List<EmployeeModel> employees) {
    final dateFormat = intl.DateFormat('EEEE، yyyy-MM-dd', 'ar');
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
                dataRowMinHeight: 64,
                dataRowMaxHeight: 64,
                columns: const [
                  DataColumn(label: Text('الموظف', style: AppTextStyles.bodyBold)),
                  DataColumn(label: Text('التاريخ', style: AppTextStyles.bodyBold)),
                  DataColumn(label: Text('حضور', style: AppTextStyles.bodyBold)),
                  DataColumn(label: Text('انصراف', style: AppTextStyles.bodyBold)),
                  DataColumn(label: Text('ساعات العمل', style: AppTextStyles.bodyBold)),
                  DataColumn(label: Text('تأخير', style: AppTextStyles.bodyBold)),
                  DataColumn(label: Text('الحالة', style: AppTextStyles.bodyBold)),
                ],
                rows: records.map((record) {
                  final emp = employees.firstWhere(
                    (e) => e.id == record.employeeId,
                    orElse: () => _placeholderEmployee(),
                  );

                  return DataRow(
                    cells: [
                      // Employee
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
                      // Date
                      DataCell(Text(dateFormat.format(DateTime.parse(record.date)), style: AppTextStyles.body)),
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
                      // Worked Hours
                      DataCell(Text(
                        record.checkOut != null ? '${record.workedHours.toStringAsFixed(2)} ساعة' : '--',
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

  EmployeeModel _placeholderEmployee() {
    return EmployeeModel(
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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' as intl;
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/di/service_locator.dart';
import '../../data/models/employee_model.dart';
import '../../data/models/attendance_model.dart';
import '../cubits/attendance_history/attendance_history_cubit.dart';
import '../cubits/attendance_history/attendance_history_state.dart';

class AttendanceHistoryView extends StatefulWidget {
  final EmployeeModel employee;

  const AttendanceHistoryView({super.key, required this.employee});

  @override
  State<AttendanceHistoryView> createState() => _AttendanceHistoryViewState();
}

class _AttendanceHistoryViewState extends State<AttendanceHistoryView> {
  late AttendanceHistoryCubit _cubit;
  String _selectedFilter = 'today';
  DateTimeRange? _customDateRange;

  @override
  void initState() {
    super.initState();
    _cubit = sl<AttendanceHistoryCubit>();
    _cubit.loadHistory(employeeId: widget.employee.id!, filterType: _selectedFilter);
  }

  void _onFilterChanged(String? filterType) async {
    if (filterType == null) return;
    
    if (filterType == 'custom') {
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2025),
        lastDate: DateTime.now().add(const Duration(days: 365)),
        locale: const Locale('ar'),
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
          _selectedFilter = filterType;
          _customDateRange = picked;
        });
        _cubit.loadHistory(
          employeeId: widget.employee.id!,
          filterType: filterType,
          startDate: picked.start,
          endDate: picked.end,
        );
      }
    } else {
      setState(() {
        _selectedFilter = filterType;
        _customDateRange = null;
      });
      _cubit.loadHistory(employeeId: widget.employee.id!, filterType: filterType);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and Filters
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('سجل الحضور والانصراف', style: AppTextStyles.h1),
                    const SizedBox(height: 4),
                    Text('عرض وتصفية سجلات حضور الموظف', style: AppTextStyles.caption),
                  ],
                ),
                // Filter Dropdown
                _buildFilterSelector(),
              ],
            ),
            const SizedBox(height: 24),

            // Date Range Display if custom
            if (_selectedFilter == 'custom' && _customDateRange != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.secondary.withOpacity(0.2)),
                  ),
                  child: Text(
                    'الفترة من: ${intl.DateFormat('yyyy-MM-dd').format(_customDateRange!.start)} إلى: ${intl.DateFormat('yyyy-MM-dd').format(_customDateRange!.end)}',
                    style: AppTextStyles.bodyBold.copyWith(color: AppColors.secondary),
                  ),
                ),
              ),

            // Logs Table List
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: BlocBuilder<AttendanceHistoryCubit, AttendanceHistoryState>(
                  builder: (context, state) {
                    if (state is AttendanceHistoryLoading) {
                      return const Center(child: CircularProgressIndicator(color: AppColors.secondary));
                    } else if (state is AttendanceHistoryError) {
                      return Center(
                        child: Text(state.message, style: const TextStyle(color: AppColors.error)),
                      );
                    } else if (state is AttendanceHistoryLoaded) {
                      if (state.records.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.history_toggle_off_rounded, color: AppColors.textLight, size: 64),
                              const SizedBox(height: 16),
                              Text('لا توجد سجلات حضور للفترة المحددة', style: AppTextStyles.h3.copyWith(color: AppColors.textSecondary)),
                            ],
                          ),
                        );
                      }
                      return _buildTableLayout(state.records);
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButton<String>(
        value: _selectedFilter,
        underline: const SizedBox(),
        icon: const Icon(Icons.filter_list_rounded, color: AppColors.secondary),
        style: AppTextStyles.body,
        items: const [
          DropdownMenuItem(value: 'today', child: Text('سجل اليوم')),
          DropdownMenuItem(value: 'week', child: Text('سجل هذا الأسبوع')),
          DropdownMenuItem(value: 'month', child: Text('سجل هذا الشهر')),
          DropdownMenuItem(value: 'custom', child: Text('تاريخ مخصص...')),
        ],
        onChanged: _onFilterChanged,
      ),
    );
  }

  Widget _buildTableLayout(List<AttendanceModel> records) {
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
                dataRowMinHeight: 56,
                dataRowMaxHeight: 56,
                columns: const [
                  DataColumn(label: Text('اليوم والتاريخ', style: AppTextStyles.bodyBold)),
                  DataColumn(label: Text('حضور', style: AppTextStyles.bodyBold)),
                  DataColumn(label: Text('انصراف', style: AppTextStyles.bodyBold)),
                  DataColumn(label: Text('الحالة', style: AppTextStyles.bodyBold)),
                  DataColumn(label: Text('ساعات العمل', style: AppTextStyles.bodyBold)),
                  DataColumn(label: Text('تأخير', style: AppTextStyles.bodyBold)),
                ],
                rows: records.map((record) {
                  return DataRow(
                    cells: [
                      // Date
                      DataCell(Text(
                        dateFormat.format(DateTime.parse(record.date)),
                        style: AppTextStyles.body,
                      )),
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
                      // Status
                      DataCell(_buildStatusBadge(record.status)),
                      // Worked Hours
                      DataCell(Text(
                        record.checkOut != null
                            ? '${record.workedHours.toStringAsFixed(2)} ساعة'
                            : '--',
                        style: AppTextStyles.body,
                      )),
                      // Late Minutes
                      DataCell(Text(
                        record.lateMinutes > 0 ? '${record.lateMinutes} دقيقة' : 'لا يوجد',
                        style: AppTextStyles.body.copyWith(
                          color: record.lateMinutes > 0 ? AppColors.error : AppColors.textPrimary,
                        ),
                      )),
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
      case 'NOT_CHECKED_IN':
        text = 'لم يسجل حضور';
        color = AppColors.pending;
        break;
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
}

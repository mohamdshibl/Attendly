import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' as intl;
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/time_service.dart';
import '../../core/di/service_locator.dart';
import '../../data/models/employee_model.dart';
import '../../data/models/shift_model.dart';
import '../../data/models/attendance_model.dart';
import '../cubits/employee_dashboard/employee_dashboard_cubit.dart';
import '../cubits/employee_dashboard/employee_dashboard_state.dart';

class EmployeeDashboardView extends StatefulWidget {
  final EmployeeModel employee;

  const EmployeeDashboardView({super.key, required this.employee});

  @override
  State<EmployeeDashboardView> createState() => _EmployeeDashboardViewState();
}

class _EmployeeDashboardViewState extends State<EmployeeDashboardView> {
  late EmployeeDashboardCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<EmployeeDashboardCubit>();
    _cubit.loadDashboard(widget.employee.id!, widget.employee.shiftId);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<EmployeeDashboardCubit, EmployeeDashboardState>(
        builder: (context, state) {
          if (state is EmployeeDashboardLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.secondary),
            );
          } else if (state is EmployeeDashboardError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                  const SizedBox(height: 16),
                  Text(state.message, style: AppTextStyles.h3),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _cubit.loadDashboard(widget.employee.id!, widget.employee.shiftId),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
                    child: const Text('إعادة المحاولة', style: TextStyle(fontFamily: 'Inter')),
                  )
                ],
              ),
            );
          } else if (state is EmployeeDashboardLoaded) {
            final shift = state.shift;
            final record = state.todayAttendance;

            // Determine status and buttons availability
            final bool canCheckIn = record == null;
            final bool canCheckOut = record != null && record.checkOut == null;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'مرحباً، ${widget.employee.name}',
                            style: AppTextStyles.h1.copyWith(color: AppColors.primary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'كود الموظف: ${widget.employee.employeeCode} | قسم: ${widget.employee.department}',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                      _buildStatusBadge(record?.status ?? 'NOT_CHECKED_IN'),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Middle Section: Clock and Action Buttons
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 800;
                      return Flex(
                        direction: isWide ? Axis.horizontal : Axis.vertical,
                        children: [
                          // Clock Widget
                          Expanded(
                            flex: isWide ? 1 : 0,
                            child: _buildClockCard(),
                          ),
                          if (isWide) const SizedBox(width: 24) else const SizedBox(height: 24),
                          // Actions (Check In / Out)
                          Expanded(
                            flex: isWide ? 1 : 0,
                            child: _buildActionCard(canCheckIn, canCheckOut),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  // Bottom Section: Shift Configuration and Today's Log
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 800;
                      return Flex(
                        direction: isWide ? Axis.horizontal : Axis.vertical,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Shift Details
                          Expanded(
                            flex: isWide ? 1 : 0,
                            child: _buildShiftDetailsCard(shift),
                          ),
                          if (isWide) const SizedBox(width: 24) else const SizedBox(height: 24),
                          // Today's Log Detail
                          Expanded(
                            flex: isWide ? 1 : 0,
                            child: _buildTodayLogCard(record),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  // Ticking Real-Time Clock
  Widget _buildClockCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const RealTimeClock(),
          const SizedBox(height: 8),
          Text(
            intl.DateFormat('EEEE، d MMMM yyyy', 'ar').format(sl<TimeService>().now()),
            style: AppTextStyles.caption.copyWith(color: AppColors.textLight, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // Attendance Check-In / Check-Out Actions
  Widget _buildActionCard(bool canCheckIn, bool canCheckOut) {
    return Container(
      padding: const EdgeInsets.all(24),
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'تسجيل الحضور والانصراف اليومي',
            textAlign: TextAlign.center,
            style: AppTextStyles.h3,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: canCheckIn
                      ? () => _cubit.checkIn(widget.employee.id!, widget.employee.shiftId)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    disabledBackgroundColor: AppColors.border,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.login_rounded, color: Colors.white),
                  label: Text(
                    'تسجيل حضور',
                    style: AppTextStyles.button.copyWith(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: canCheckOut
                      ? () => _cubit.checkOut(widget.employee.id!, widget.employee.shiftId)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.info,
                    disabledBackgroundColor: AppColors.border,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.logout_rounded, color: Colors.white),
                  label: Text(
                    'تسجيل انصراف',
                    style: AppTextStyles.button.copyWith(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Shift Details Widget
  Widget _buildShiftDetailsCard(ShiftModel shift) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule_rounded, color: AppColors.secondary),
              const SizedBox(width: 8),
              Text('تفاصيل الوردية الحالية', style: AppTextStyles.h2),
            ],
          ),
          const SizedBox(height: 20),
          _buildDetailRow('اسم الوردية:', shift.name),
          _buildDetailRow('بداية الوردية:', shift.startTime),
          _buildDetailRow('نهاية الوردية:', shift.endTime),
          _buildDetailRow('فترة السماح بالدقائق:', '${shift.gracePeriod} دقيقة'),
        ],
      ),
    );
  }

  // Today's Attendance Log details card
  Widget _buildTodayLogCard(AttendanceModel? record) {
    final timeFormat = intl.DateFormat('hh:mm a', 'ar');

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description_outlined, color: AppColors.accent),
              const SizedBox(width: 8),
              Text('سجل الحضور اليوم', style: AppTextStyles.h2),
            ],
          ),
          const SizedBox(height: 20),
          _buildDetailRow(
            'وقت الحضور:',
            record?.checkIn != null ? timeFormat.format(record!.checkIn!) : '--:--',
          ),
          _buildDetailRow(
            'وقت الانصراف:',
            record?.checkOut != null ? timeFormat.format(record!.checkOut!) : '--:--',
          ),
          _buildDetailRow(
            'ساعات العمل:',
            record != null && record.checkOut != null
                ? '${record.workedHours.toStringAsFixed(2)} ساعة'
                : '--:--',
          ),
          _buildDetailRow(
            'دقائق التأخير:',
            record != null && record.lateMinutes > 0 ? '${record.lateMinutes} دقيقة' : 'لا يوجد',
            valueColor: record != null && record.lateMinutes > 0 ? AppColors.error : AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
          Text(
            value,
            style: AppTextStyles.bodyBold.copyWith(
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
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
        text = 'حاضر (في الوقت)';
        color = AppColors.success;
        break;
      case 'LATE':
        text = 'متأخر';
        color = AppColors.warning;
        break;
      case 'CHECKED_OUT':
        text = 'تم تسجيل الانصراف';
        color = AppColors.info;
        break;
      case 'ABSENT':
        text = 'غائب';
        color = AppColors.error;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: AppTextStyles.bodyBold.copyWith(color: color),
      ),
    );
  }
}

// Stateful Clock for ticking digital time
class RealTimeClock extends StatefulWidget {
  const RealTimeClock({super.key});

  @override
  State<RealTimeClock> createState() => _RealTimeClockState();
}

class _RealTimeClockState extends State<RealTimeClock> {
  late Timer _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = sl<TimeService>().now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _now = sl<TimeService>().now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final format = intl.DateFormat('hh:mm:ss a', 'ar');
    return Text(
      format.format(_now),
      style: AppTextStyles.display.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        letterSpacing: 2,
        fontSize: 36,
      ),
    );
  }
}

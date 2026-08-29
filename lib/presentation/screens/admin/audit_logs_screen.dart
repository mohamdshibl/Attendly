import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/di/service_locator.dart';
import '../../../data/models/audit_log_model.dart';
import '../../../data/models/employee_model.dart';
import '../../cubits/audit_log/audit_log_cubit.dart';
import '../../cubits/audit_log/audit_log_state.dart';

class AuditLogsView extends StatefulWidget {
  const AuditLogsView({super.key});

  @override
  State<AuditLogsView> createState() => _AuditLogsViewState();
}

class _AuditLogsViewState extends State<AuditLogsView> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuditLogCubit>(
      create: (context) => sl<AuditLogCubit>()..loadLogs(),
      child: BlocConsumer<AuditLogCubit, AuditLogState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!, style: const TextStyle(fontFamily: 'Inter')),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.isLoading && state.logs.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: AppColors.secondary));
          }

          final sortedLogs = List<AuditLogModel>.from(state.logs);
          sortedLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const Text('سجل المعاملات والرقابة (Audit Logs)', style: AppTextStyles.h1),
                const SizedBox(height: 4),
                Text(
                  'سجل غير قابل للتعديل يتتبع جميع الحركات والأحداث الإدارية وتسجيل الحضور والانصراف داخل النظام',
                  style: AppTextStyles.caption.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 32),

                // Table logs
                Expanded(
                  child: sortedLogs.isEmpty
                      ? _buildEmptyState()
                      : Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: ListView.separated(
                              itemCount: sortedLogs.length,
                              separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.border),
                              itemBuilder: (context, index) {
                                final log = sortedLogs[index];
                                final actor = state.employees.firstWhere(
                                  (e) => e.id == log.actorId,
                                  orElse: () => EmployeeModel(
                                    employeeCode: 'EMP-?',
                                    name: 'نظام تلقائي / غير معروف',
                                    passwordHash: '',
                                    department: 'System',
                                    shiftId: 0,
                                    role: 'system',
                                    createdAt: DateTime.now(),
                                  ),
                                );

                                return _buildLogTile(log, actor);
                              },
                            ),
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off_rounded, size: 64, color: AppColors.textLight.withOpacity(0.4)),
          const SizedBox(height: 16),
          const Text('لا توجد أي معاملات مسجلة في النظام حتى الآن.', style: AppTextStyles.h3),
        ],
      ),
    );
  }

  Widget _buildLogTile(AuditLogModel log, EmployeeModel actor) {
    Color iconColor = AppColors.secondary;
    IconData icon = Icons.info_outline_rounded;
    String actionArabic = log.action;

    switch (log.action) {
      case 'CHECKED_IN':
        icon = Icons.login_rounded;
        iconColor = AppColors.success;
        actionArabic = 'تسجيل دخول حضور';
        break;
      case 'CHECKED_OUT':
        icon = Icons.logout_rounded;
        iconColor = AppColors.info;
        actionArabic = 'تسجيل انصراف';
        break;
      case 'LEAVE_REQUESTED':
        icon = Icons.beach_access_rounded;
        iconColor = AppColors.warning;
        actionArabic = 'تقديم طلب إجازة';
        break;
      case 'LEAVE_APPROVED':
        icon = Icons.check_circle_rounded;
        iconColor = AppColors.success;
        actionArabic = 'الموافقة على إجازة';
        break;
      case 'LEAVE_REJECTED':
        icon = Icons.cancel_rounded;
        iconColor = AppColors.error;
        actionArabic = 'رفض طلب إجازة';
        break;
      case 'LEAVE_CANCELLED':
        icon = Icons.remove_circle_outline_rounded;
        iconColor = AppColors.textSecondary;
        actionArabic = 'إلغاء طلب إجازة';
        break;
      case 'HOLIDAY_ADDED':
        icon = Icons.event_available_rounded;
        iconColor = AppColors.accent;
        actionArabic = 'إضافة عطلة رسمية';
        break;
      case 'HOLIDAY_REMOVED':
        icon = Icons.event_busy_rounded;
        iconColor = AppColors.error;
        actionArabic = 'حذف عطلة رسمية';
        break;
      case 'EMPLOYEE_CREATED':
        icon = Icons.person_add_alt_rounded;
        iconColor = AppColors.secondary;
        actionArabic = 'إنشاء ملف موظف';
        break;
      case 'EMPLOYEE_DELETED':
        icon = Icons.person_remove_rounded;
        iconColor = AppColors.error;
        actionArabic = 'حذف ملف موظف';
        break;
    }

    String metadataText = '';
    if (log.metadata != null) {
      try {
        final Map<String, dynamic> meta = json.decode(log.metadata!);
        if (meta.containsKey('days')) {
          metadataText += 'المدة: ${meta['days']} يوم';
        }
        if (meta.containsKey('leaveType')) {
          metadataText += ' | النوع: ${meta['leaveType']}';
        }
        if (meta.containsKey('name')) {
          metadataText += ' | الاسم: ${meta['name']}';
        }
        if (meta.containsKey('reason')) {
          metadataText += ' | السبب: ${meta['reason']}';
        }
      } catch (_) {
        metadataText = log.metadata!;
      }
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(actionArabic, style: AppTextStyles.bodyBold),
          Text(
            DateFormat('yyyy-MM-dd HH:mm:ss').format(log.timestamp),
            style: AppTextStyles.caption.copyWith(fontSize: 12),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'بواسطة: ${actor.name} (${actor.employeeCode})',
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary, fontSize: 13),
            ),
            if (metadataText.isNotEmpty)
              Text(
                metadataText,
                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
              ),
          ],
        ),
      ),
    );
  }
}

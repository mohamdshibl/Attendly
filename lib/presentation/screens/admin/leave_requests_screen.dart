import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/di/service_locator.dart';
import '../../../data/models/employee_model.dart';
import '../../../data/models/leave_request_model.dart';
import '../../../data/models/leave_type_model.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart';
import '../../cubits/leave_manage/leave_manage_cubit.dart';
import '../../cubits/leave_manage/leave_manage_state.dart';

class LeaveRequestsView extends StatefulWidget {
  const LeaveRequestsView({super.key});

  @override
  State<LeaveRequestsView> createState() => _LeaveRequestsViewState();
}

class _LeaveRequestsViewState extends State<LeaveRequestsView> {
  String _selectedFilter = 'PENDING'; // 'PENDING', 'APPROVED', 'REJECTED', 'ALL'

  @override
  Widget build(BuildContext context) {
    // Get current logged-in admin ID
    final authState = context.read<AuthCubit>().state;
    final adminId = authState is Authenticated ? authState.employee.id! : 1;

    return BlocProvider<LeaveManageCubit>(
      create: (context) => sl<LeaveManageCubit>()..loadAllRequests(),
      child: BlocConsumer<LeaveManageCubit, LeaveManageState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!, style: const TextStyle(fontFamily: 'Inter')),
                backgroundColor: AppColors.error,
              ),
            );
          }
          if (state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.successMessage!, style: const TextStyle(fontFamily: 'Inter')),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.isLoading && state.requests.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: AppColors.secondary));
          }

          // Calculate counts
          final pendingCount = state.requests.where((r) => r.status == 'PENDING').length;
          final approvedCount = state.requests.where((r) => r.status == 'APPROVED').length;
          final rejectedCount = state.requests.where((r) => r.status == 'REJECTED').length;

          // Filter requests
          final filteredRequests = state.requests.where((r) {
            if (_selectedFilter == 'ALL') return true;
            return r.status == _selectedFilter;
          }).toList();

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const Text('طلبات الإجازات والمعاملات', style: AppTextStyles.h1),
                const SizedBox(height: 4),
                Text(
                  'مراجعة طلبات الإجازات المقدمة من الموظفين واعتمادها قانونياً مع تحديث الأرصدة تلقائياً',
                  style: AppTextStyles.caption.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 24),

                // Statistics Row
                Row(
                  children: [
                    _buildStatCard('الطلبات المعلقة', '$pendingCount', AppColors.warning, Icons.pending_actions_rounded),
                    const SizedBox(width: 16),
                    _buildStatCard('إجازات المعتمدة', '$approvedCount', AppColors.success, Icons.check_circle_outline_rounded),
                    const SizedBox(width: 16),
                    _buildStatCard('الطلبات المرفوضة', '$rejectedCount', AppColors.error, Icons.cancel_outlined),
                  ],
                ),
                const SizedBox(height: 24),

                // Filters Tabs Bar
                Row(
                  children: [
                    _buildFilterTab('PENDING', 'قيد الانتظار ($pendingCount)', AppColors.warning),
                    const SizedBox(width: 8),
                    _buildFilterTab('APPROVED', 'مقبولة ($approvedCount)', AppColors.success),
                    const SizedBox(width: 8),
                    _buildFilterTab('REJECTED', 'مرفوضة ($rejectedCount)', AppColors.error),
                    const SizedBox(width: 8),
                    _buildFilterTab('ALL', 'الكل (${state.requests.length})', AppColors.primary),
                  ],
                ),
                const SizedBox(height: 16),

                // Requests List
                Expanded(
                  child: filteredRequests.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          itemCount: filteredRequests.length,
                          itemBuilder: (context, index) {
                            final request = filteredRequests[index];
                            final employee = state.employees.firstWhere(
                              (e) => e.id == request.employeeId,
                              orElse: () => EmployeeModel(
                                employeeCode: 'EMP-?',
                                name: 'موظف غير معروف',
                                passwordHash: '',
                                department: 'Unknown',
                                shiftId: 0,
                                role: 'employee',
                                createdAt: DateTime.now(),
                              ),
                            );
                            final leaveType = state.leaveTypes.firstWhere(
                              (t) => t.id == request.leaveTypeId,
                              orElse: () => LeaveTypeModel(name: 'غير معروف', code: 'OTHER'),
                            );

                            return _buildRequestCard(context, request, employee, leaveType, adminId);
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Row(
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.caption),
                const SizedBox(height: 4),
                Text(value, style: AppTextStyles.display.copyWith(fontSize: 24, height: 1.1)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab(String filterCode, String label, Color color) {
    final isSelected = _selectedFilter == filterCode;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = filterCode;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodyBold.copyWith(
            color: isSelected ? color : AppColors.textSecondary,
          ),
        ),
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
          Icon(Icons.assignment_rounded, size: 64, color: AppColors.textLight.withOpacity(0.4)),
          const SizedBox(height: 16),
          const Text('لا توجد طلبات إجازة تطابق الفلتر المحدد.', style: AppTextStyles.h3),
        ],
      ),
    );
  }

  Widget _buildRequestCard(
    BuildContext context,
    LeaveRequestModel request,
    EmployeeModel employee,
    LeaveTypeModel leaveType,
    int adminId,
  ) {
    final cubit = context.read<LeaveManageCubit>();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Employee info and Leave Type badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.08),
                    child: Text(
                      employee.name.substring(0, 1),
                      style: AppTextStyles.bodyBold.copyWith(color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(employee.name, style: AppTextStyles.h3),
                      Text('كود الموظف: ${employee.employeeCode}', style: AppTextStyles.caption),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  leaveType.name,
                  style: AppTextStyles.bodyBold.copyWith(color: AppColors.secondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Row 2: Details Grid
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailItem('تاريخ البدء', DateFormat('yyyy-MM-dd').format(request.startDate)),
              _buildDetailItem('تاريخ الانتهاء', DateFormat('yyyy-MM-dd').format(request.endDate)),
              _buildDetailItem('مدة الإجازة', '${request.numberOfDays} يوم'),
              _buildDetailItem('تاريخ التقديم', DateFormat('yyyy-MM-dd HH:mm').format(request.createdAt)),
            ],
          ),
          const SizedBox(height: 16),

          // Row 3: Reason & Attachments
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('سبب الإجازة:', style: AppTextStyles.bodyBold),
              const SizedBox(height: 4),
              Text(
                request.reason,
                style: AppTextStyles.body.copyWith(color: AppColors.textSecondary, height: 1.4),
              ),
            ],
          ),
          if (request.attachmentPath != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.attachment_rounded, size: 16, color: AppColors.secondary),
                  const SizedBox(width: 8),
                  Text(
                    request.attachmentPath!,
                    style: AppTextStyles.caption.copyWith(color: AppColors.secondary, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 16),
                  InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('محاكاة فتح الملف: ${request.attachmentPath!}')),
                      );
                    },
                    child: const Text(
                      'معاينة المستند',
                      style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Rejection details if rejected
          if (request.status == 'REJECTED' && request.rejectionReason != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error.withOpacity(0.2)),
              ),
              child: Text(
                'سبب الرفض: ${request.rejectionReason!}',
                style: AppTextStyles.body.copyWith(color: AppColors.error),
              ),
            ),
          ],

          // Actions
          if (request.status == 'PENDING') ...[
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => _showRejectDialog(context, cubit, request.id!, adminId),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('رفض الطلب', style: AppTextStyles.bodyBold),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => cubit.approveRequest(request.id!, adminId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('الموافقة والاعتماد', style: AppTextStyles.button),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.bodyBold),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, LeaveManageCubit cubit, int requestId, int adminId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('رفض طلب الإجازة', style: AppTextStyles.h2),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('يرجى كتابة سبب رفض الطلب للموظف:', style: AppTextStyles.bodyBold),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'اكتب سبب الرفض هنا...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('إلغاء', style: AppTextStyles.bodyBold),
            ),
            ElevatedButton(
              onPressed: () {
                final reason = controller.text.trim();
                if (reason.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('يجب إدخال سبب الرفض لإتمام الإجراء')),
                  );
                  return;
                }
                Navigator.of(dialogCtx).pop();
                cubit.rejectRequest(requestId, adminId, reason);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
              child: const Text('تأكيد الرفض', style: AppTextStyles.button),
            ),
          ],
        ),
      ),
    );
  }
}

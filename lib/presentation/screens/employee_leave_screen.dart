import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/di/service_locator.dart';
import '../../core/utils/leave_days_calculator.dart';
import '../../data/models/leave_balance_model.dart';
import '../../data/models/leave_request_model.dart';
import '../../data/models/leave_type_model.dart';
import '../../data/models/official_holiday_model.dart';
import '../cubits/leave_request/leave_request_cubit.dart';
import '../cubits/leave_request/leave_request_state.dart';

class EmployeeLeaveView extends StatefulWidget {
  final dynamic employee; // EmployeeModel

  const EmployeeLeaveView({super.key, required this.employee});

  @override
  State<EmployeeLeaveView> createState() => _EmployeeLeaveViewState();
}

class _EmployeeLeaveViewState extends State<EmployeeLeaveView> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider<LeaveRequestCubit>(
      create: (context) => sl<LeaveRequestCubit>()
        ..loadLeaveData(widget.employee.id!, DateTime.now().year),
      child: BlocConsumer<LeaveRequestCubit, LeaveRequestState>(
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
          if (state.isLoading && state.leaveTypes.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: AppColors.secondary));
          }

          return Scaffold(
            backgroundColor: AppColors.background,
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('إدارة الإجازات والطلبات', style: AppTextStyles.h1),
                          const SizedBox(height: 4),
                          Text(
                            'متابعة أرصدة إجازاتك وتقديم طلبات إجازة جديدة وفقاً لقانون العمل المصري',
                            style: AppTextStyles.caption.copyWith(fontSize: 14),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showNewRequestDialog(context, state),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: const Text('تقديم طلب إجازة', style: AppTextStyles.button),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Balances Section Header
                  const Text('أرصدة الإجازات السنوية', style: AppTextStyles.h2),
                  const SizedBox(height: 16),

                  // Balances Cards Grid
                  _buildBalancesGrid(state),
                  const SizedBox(height: 36),

                  // Previous Requests Header
                  const Text('سجل طلبات الإجازات', style: AppTextStyles.h2),
                  const SizedBox(height: 16),

                  // Requests Table / List
                  _buildRequestsList(context, state),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBalancesGrid(LeaveRequestState state) {
    if (state.balances.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: Text('لا توجد أرصدة إجازات مسجلة لهذا العام.', style: AppTextStyles.body),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1100
            ? 4
            : constraints.maxWidth > 800
                ? 3
                : constraints.maxWidth > 550
                    ? 2
                    : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.6,
          ),
          itemCount: state.balances.length,
          itemBuilder: (context, index) {
            final balance = state.balances[index];
            final leaveType = state.leaveTypes.firstWhere(
              (t) => t.id == balance.leaveTypeId,
              orElse: () => LeaveTypeModel(name: 'غير معروف', code: 'OTHER'),
            );
            return _buildBalanceCard(balance, leaveType);
          },
        );
      },
    );
  }

  Widget _buildBalanceCard(LeaveBalanceModel balance, LeaveTypeModel leaveType) {
    Color accentColor = AppColors.secondary;
    IconData icon = Icons.beach_access_rounded;

    switch (leaveType.code) {
      case 'ANNUAL':
        accentColor = AppColors.secondary;
        icon = Icons.calendar_today_rounded;
        break;
      case 'CASUAL':
        accentColor = AppColors.warning;
        icon = Icons.bolt_rounded;
        break;
      case 'SICK':
        accentColor = AppColors.error;
        icon = Icons.medical_services_outlined;
        break;
      case 'MATERNITY':
      case 'PATERNITY':
        accentColor = Colors.pinkAccent;
        icon = Icons.child_care_rounded;
        break;
      case 'HAJJ':
        accentColor = AppColors.accent;
        icon = Icons.mosque_rounded;
        break;
    }

    final remaining = balance.entitlement - balance.used;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              Text(
                'المتبقي: $remaining يوم',
                style: AppTextStyles.bodyBold.copyWith(color: accentColor, fontSize: 13),
              ),
            ],
          ),
          const Spacer(),
          Text(leaveType.name, style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBalanceSubItem('الرصيد', '${balance.entitlement}'),
              _buildBalanceSubItem('المستخدم', '${balance.used}'),
              _buildBalanceSubItem('معلق', '${balance.pending}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceSubItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption.copyWith(fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: AppTextStyles.bodyBold.copyWith(color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildRequestsList(BuildContext context, LeaveRequestState state) {
    if (state.requests.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(Icons.assignment_turned_in_outlined, size: 48, color: AppColors.textLight.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text('لم تقم بتقديم أي طلبات إجازة بعد.', style: AppTextStyles.body),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 32,
            headingRowColor: MaterialStateProperty.all(AppColors.primary.withOpacity(0.02)),
            columns: const [
              DataColumn(label: Text('نوع الإجازة', style: AppTextStyles.bodyBold)),
              DataColumn(label: Text('من تاريخ', style: AppTextStyles.bodyBold)),
              DataColumn(label: Text('إلى تاريخ', style: AppTextStyles.bodyBold)),
              DataColumn(label: Text('المدة (أيام)', style: AppTextStyles.bodyBold)),
              DataColumn(label: Text('السبب', style: AppTextStyles.bodyBold)),
              DataColumn(label: Text('حالة الطلب', style: AppTextStyles.bodyBold)),
              DataColumn(label: Text('الإجراءات', style: AppTextStyles.bodyBold)),
            ],
            rows: state.requests.map((request) {
              final leaveType = state.leaveTypes.firstWhere(
                (t) => t.id == request.leaveTypeId,
                orElse: () => LeaveTypeModel(name: 'غير معروف', code: 'OTHER'),
              );

              return DataRow(
                cells: [
                  DataCell(Text(leaveType.name, style: AppTextStyles.bodyBold)),
                  DataCell(Text(DateFormat('yyyy-MM-dd').format(request.startDate))),
                  DataCell(Text(DateFormat('yyyy-MM-dd').format(request.endDate))),
                  DataCell(Text('${request.numberOfDays} يوم')),
                  DataCell(
                    SizedBox(
                      width: 150,
                      child: Text(
                        request.reason,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body,
                      ),
                    ),
                  ),
                  DataCell(_buildStatusBadge(request.status)),
                  DataCell(
                    request.status == 'PENDING'
                        ? TextButton(
                            onPressed: () => _confirmCancelRequest(context, request),
                            style: TextButton.styleFrom(foregroundColor: AppColors.error),
                            child: const Text('إلغاء الطلب', style: AppTextStyles.bodyBold),
                          )
                        : const Text('-'),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = AppColors.pending;
    String text = 'معلق';

    switch (status) {
      case 'PENDING':
        color = AppColors.warning;
        text = 'قيد الانتظار';
        break;
      case 'APPROVED':
        color = AppColors.success;
        text = 'مقبول';
        break;
      case 'REJECTED':
        color = AppColors.error;
        text = 'مرفوض';
        break;
      case 'CANCELLED':
        color = AppColors.textSecondary;
        text = 'ملغي';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _confirmCancelRequest(BuildContext context, LeaveRequestModel request) {
    final cubit = context.read<LeaveRequestCubit>();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('إلغاء طلب الإجازة', textAlign: TextAlign.right),
        content: const Text(
          'هل أنت متأكد من رغبتك في إلغاء طلب الإجازة هذا؟ سيتم إرجاع الرصيد المعلق تلقائياً.',
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('إلغاء', style: AppTextStyles.bodyBold),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              cubit.cancelRequest(request.id!);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('تأكيد الإلغاء', style: AppTextStyles.button),
          ),
        ],
      ),
    );
  }

  void _showNewRequestDialog(BuildContext parentContext, LeaveRequestState state) {
    final cubit = parentContext.read<LeaveRequestCubit>();
    showDialog(
      context: parentContext,
      builder: (context) {
        return BlocProvider<LeaveRequestCubit>.value(
          value: cubit,
          child: NewLeaveRequestDialog(
            leaveTypes: state.leaveTypes,
            balances: state.balances,
            holidays: state.holidays,
            employeeId: widget.employee.id!,
          ),
        );
      },
    );
  }
}

class NewLeaveRequestDialog extends StatefulWidget {
  final List<LeaveTypeModel> leaveTypes;
  final List<LeaveBalanceModel> balances;
  final List<OfficialHolidayModel> holidays;
  final int employeeId;

  const NewLeaveRequestDialog({
    super.key,
    required this.leaveTypes,
    required this.balances,
    required this.holidays,
    required this.employeeId,
  });

  @override
  State<NewLeaveRequestDialog> createState() => _NewLeaveRequestDialogState();
}

class _NewLeaveRequestDialogState extends State<NewLeaveRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedLeaveTypeId;
  DateTime? _startDate;
  DateTime? _endDate;
  final _reasonController = TextEditingController();
  String? _attachmentName;
  int _calculatedDays = 0;

  @override
  void initState() {
    super.initState();
    if (widget.leaveTypes.isNotEmpty) {
      _selectedLeaveTypeId = widget.leaveTypes.first.id;
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _calculateDays() {
    if (_startDate == null || _endDate == null || _selectedLeaveTypeId == null) {
      setState(() {
        _calculatedDays = 0;
      });
      return;
    }

    final leaveType = widget.leaveTypes.firstWhere((t) => t.id == _selectedLeaveTypeId);
    final days = LeaveDaysCalculator.calculateChargeableDays(
      startDate: _startDate!,
      endDate: _endDate!,
      leaveTypeCode: leaveType.code,
      holidays: widget.holidays,
    );

    setState(() {
      _calculatedDays = days;
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedType = widget.leaveTypes.firstWhere(
      (t) => t.id == _selectedLeaveTypeId,
      orElse: () => widget.leaveTypes.first,
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('طلب إجازة جديدة', style: AppTextStyles.h2),
        content: Container(
          width: 500,
          constraints: const BoxConstraints(maxHeight: 580),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Leave Type Dropdown
                  const Text('نوع الإجازة', style: AppTextStyles.bodyBold),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int>(
                    value: _selectedLeaveTypeId,
                    items: widget.leaveTypes.map((t) {
                      final balance = widget.balances.firstWhere(
                        (b) => b.leaveTypeId == t.id,
                        orElse: () => LeaveBalanceModel(
                          employeeId: widget.employeeId,
                          leaveTypeId: t.id!,
                          leaveYear: DateTime.now().year,
                          entitlement: 0,
                        ),
                      );
                      final remaining = balance.entitlement - balance.used;
                      return DropdownMenuItem<int>(
                        value: t.id,
                        child: Text('${t.name} (المتبقي: $remaining يوم)'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedLeaveTypeId = val;
                      });
                      _calculateDays();
                    },
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Start Date Picker
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('تاريخ البدء', style: AppTextStyles.bodyBold),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _startDate ?? DateTime.now(),
                                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (date != null) {
                                  setState(() {
                                    _startDate = date;
                                    // Normalize end date if before start date
                                    if (_endDate != null && _endDate!.isBefore(date)) {
                                      _endDate = date;
                                    }
                                  });
                                  _calculateDays();
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _startDate != null
                                          ? DateFormat('yyyy-MM-dd').format(_startDate!)
                                          : 'اختر تاريخ',
                                      style: AppTextStyles.body,
                                    ),
                                    const Icon(Icons.calendar_today_rounded, size: 16, color: Colors.grey),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // End Date Picker
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('تاريخ الانتهاء', style: AppTextStyles.bodyBold),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _endDate ?? (_startDate ?? DateTime.now()),
                                  firstDate: _startDate ?? DateTime.now().subtract(const Duration(days: 30)),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (date != null) {
                                  setState(() {
                                    _endDate = date;
                                  });
                                  _calculateDays();
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _endDate != null
                                          ? DateFormat('yyyy-MM-dd').format(_endDate!)
                                          : 'اختر تاريخ',
                                      style: AppTextStyles.body,
                                    ),
                                    const Icon(Icons.calendar_today_rounded, size: 16, color: Colors.grey),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Calculated Chargeable Days Display
                  if (_calculatedDays > 0)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
                      ),
                      child: Text(
                        'إجمالي الأيام المخصومة: $_calculatedDays يوم (${selectedType.code == 'ANNUAL' || selectedType.code == 'CASUAL' ? 'يستثني العطلات الأسبوعية والرسمية' : 'أيام متتالية'})',
                        style: AppTextStyles.bodyBold.copyWith(color: AppColors.secondary),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Reason
                  const Text('سبب الإجازة', style: AppTextStyles.bodyBold),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _reasonController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'اكتب سبب تقديم طلب الإجازة بالتفصيل...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'يرجى إدخال سبب الإجازة';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Mock Attachment Upload
                  const Text('المرفقات الطبية أو الثبوتية', style: AppTextStyles.bodyBold),
                  const SizedBox(height: 6),
                  OutlinedButton.icon(
                    onPressed: () {
                      // Mock selecting file
                      setState(() {
                        _attachmentName = 'document_report_${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}.pdf';
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: Icon(
                      _attachmentName != null ? Icons.check_circle_rounded : Icons.cloud_upload_outlined,
                      color: _attachmentName != null ? AppColors.success : AppColors.secondary,
                    ),
                    label: Text(
                      _attachmentName ?? 'إرفاق ملف (تقرير طبي، شهادة ميلاد، إلخ)',
                      style: AppTextStyles.body.copyWith(
                        color: _attachmentName != null ? AppColors.success : AppColors.secondary,
                      ),
                    ),
                  ),
                  if (selectedType.requiresDocument && _attachmentName == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Text(
                        'تتطلب هذه الإجازة إرفاق مستند ثبوتي لإتمام الطلب قانوناً',
                        style: AppTextStyles.caption.copyWith(color: AppColors.error),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء', style: AppTextStyles.bodyBold),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                if (_startDate == null || _endDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('يرجى تحديد فترة الإجازة')),
                  );
                  return;
                }

                if (selectedType.requiresDocument && _attachmentName == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('يرجى إرفاق المستند الثبوتي لهذه الإجازة أولاً')),
                  );
                  return;
                }

                context.read<LeaveRequestCubit>().submitRequest(
                      employeeId: widget.employeeId,
                      leaveTypeId: _selectedLeaveTypeId!,
                      startDate: _startDate!,
                      endDate: _endDate!,
                      reason: _reasonController.text,
                      attachmentPath: _attachmentName,
                    );
                Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
            ),
            child: const Text('إرسال الطلب', style: AppTextStyles.button),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/di/service_locator.dart';
import '../../../data/models/official_holiday_model.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart';
import '../../cubits/holiday_manage/holiday_manage_cubit.dart';
import '../../cubits/holiday_manage/holiday_manage_state.dart';

class HolidayListView extends StatefulWidget {
  const HolidayListView({super.key});

  @override
  State<HolidayListView> createState() => _HolidayListViewState();
}

class _HolidayListViewState extends State<HolidayListView> {
  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    final adminId = authState is Authenticated ? authState.employee.id! : 1;

    return BlocProvider<HolidayManageCubit>(
      create: (context) => sl<HolidayManageCubit>()..loadHolidays(),
      child: BlocConsumer<HolidayManageCubit, HolidayManageState>(
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
          if (state.isLoading && state.holidays.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: AppColors.secondary));
          }

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('العطلات والإجازات الرسمية', style: AppTextStyles.h1),
                        const SizedBox(height: 4),
                        Text(
                          'تحديد الأعياد والمناسبات الرسمية التي تستثنى تلقائياً من خصومات الإجازات السنوية',
                          style: AppTextStyles.caption.copyWith(fontSize: 14),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showAddHolidayDialog(context, state, adminId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: const Text('إضافة عطلة رسمية', style: AppTextStyles.button),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // List Table
                Expanded(
                  child: state.holidays.isEmpty
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
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: DataTable(
                                headingRowColor: MaterialStateProperty.all(AppColors.primary.withOpacity(0.02)),
                                columns: const [
                                  DataColumn(label: Text('المناسبة / العطلة', style: AppTextStyles.bodyBold)),
                                  DataColumn(label: Text('التاريخ', style: AppTextStyles.bodyBold)),
                                  DataColumn(label: Text('يتكرر سنوياً', style: AppTextStyles.bodyBold)),
                                  DataColumn(label: Text('مدفوعة الأجر', style: AppTextStyles.bodyBold)),
                                  DataColumn(label: Text('ملاحظات', style: AppTextStyles.bodyBold)),
                                  DataColumn(label: Text('الإجراءات', style: AppTextStyles.bodyBold)),
                                ],
                                rows: state.holidays.map((h) {
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(h.name, style: AppTextStyles.bodyBold)),
                                      DataCell(Text(DateFormat('yyyy-MM-dd').format(h.date))),
                                      DataCell(Text(h.isRecurring ? 'نعم' : 'لا')),
                                      DataCell(Text(h.isPaid ? 'نعم' : 'لا')),
                                      DataCell(Text(h.notes ?? '-')),
                                      DataCell(
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                                          onPressed: () => _confirmDeleteHoliday(context, h, adminId),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
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
          Icon(Icons.event_busy_rounded, size: 64, color: AppColors.textLight.withOpacity(0.4)),
          const SizedBox(height: 16),
          const Text('لا توجد عطلات رسمية مسجلة حالياً.', style: AppTextStyles.h3),
        ],
      ),
    );
  }

  void _confirmDeleteHoliday(BuildContext context, OfficialHolidayModel holiday, int adminId) {
    final cubit = context.read<HolidayManageCubit>();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('حذف عطلة رسمية', textAlign: TextAlign.right),
        content: Text(
          'هل أنت متأكد من رغبتك في حذف العطلة الرسمية (${holiday.name})؟ سيتم إعادة حساب إجازات الموظفين بناءً على التعديل الجديد.',
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
              cubit.deleteHoliday(holiday.id!, adminId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('تأكيد الحذف', style: AppTextStyles.button),
          ),
        ],
      ),
    );
  }

  void _showAddHolidayDialog(BuildContext parentContext, HolidayManageState state, int adminId) {
    final cubit = parentContext.read<HolidayManageCubit>();
    showDialog(
      context: parentContext,
      builder: (context) {
        return BlocProvider<HolidayManageCubit>.value(
          value: cubit,
          child: AddHolidayDialog(adminId: adminId),
        );
      },
    );
  }
}

class AddHolidayDialog extends StatefulWidget {
  final int adminId;

  const AddHolidayDialog({super.key, required this.adminId});

  @override
  State<AddHolidayDialog> createState() => _AddHolidayDialogState();
}

class _AddHolidayDialogState extends State<AddHolidayDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _selectedDate;
  bool _isRecurring = true;
  bool _isPaid = true;

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('إضافة عطلة رسمية جديدة', style: AppTextStyles.h2),
        content: SizedBox(
          width: 450,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Holiday Name
                  const Text('اسم العطلة / المناسبة', style: AppTextStyles.bodyBold),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'مثال: عيد الفطر، ثورة 23 يوليو...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'يرجى إدخال اسم العطلة الرسمية';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Date Picker
                  const Text('تاريخ العطلة', style: AppTextStyles.bodyBold),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(DateTime.now().year - 1),
                        lastDate: DateTime(DateTime.now().year + 5),
                      );
                      if (date != null) {
                        setState(() {
                          _selectedDate = date;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedDate != null
                                ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
                                : 'اختر تاريخ العطلة الرسمية',
                            style: AppTextStyles.body,
                          ),
                          const Icon(Icons.calendar_today_rounded, size: 16, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Switches
                  Row(
                    children: [
                      Expanded(
                        child: SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('تتكرر سنوياً', style: AppTextStyles.bodyBold),
                          value: _isRecurring,
                          onChanged: (val) => setState(() => _isRecurring = val),
                          activeColor: AppColors.secondary,
                        ),
                      ),
                      Expanded(
                        child: SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('مدفوعة الأجر', style: AppTextStyles.bodyBold),
                          value: _isPaid,
                          onChanged: (val) => setState(() => _isPaid = val),
                          activeColor: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Notes
                  const Text('ملاحظات إضافية (اختياري)', style: AppTextStyles.bodyBold),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'أي تفاصيل أو ملاحظات حول العطلة الرسمية...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
                if (_selectedDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('يرجى تحديد تاريخ العطلة أولاً')),
                  );
                  return;
                }

                context.read<HolidayManageCubit>().addHoliday(
                      name: _nameController.text,
                      date: _selectedDate!,
                      isRecurring: _isRecurring,
                      isPaid: _isPaid,
                      notes: _notesController.text.trim().isEmpty ? null : _notesController.text,
                      adminId: widget.adminId,
                    );
                Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
            ),
            child: const Text('حفظ وإضافة', style: AppTextStyles.button),
          ),
        ],
      ),
    );
  }
}

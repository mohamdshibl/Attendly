import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/di/service_locator.dart';
import '../../../data/models/shift_model.dart';
import '../../cubits/admin_dashboard/admin_dashboard_cubit.dart';
import '../../cubits/admin_dashboard/admin_dashboard_state.dart';
import '../../cubits/shift_manage/shift_manage_cubit.dart';
import '../../cubits/shift_manage/shift_manage_state.dart';

class ShiftListView extends StatefulWidget {
  const ShiftListView({super.key});

  @override
  State<ShiftListView> createState() => _ShiftListViewState();
}

class _ShiftListViewState extends State<ShiftListView> {
  late ShiftManageCubit _manageCubit;

  @override
  void initState() {
    super.initState();
    _manageCubit = sl<ShiftManageCubit>();
  }

  void _showShiftDialog({ShiftModel? shift}) {
    final outerContext = context;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return BlocProvider.value(
          value: _manageCubit,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: _ShiftFormDialog(
              shift: shift,
              onSuccess: () {
                // Reload dashboard data
                outerContext.read<AdminDashboardCubit>().loadDashboard();
                Navigator.of(context).pop();
              },
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(ShiftModel shift) {
    final outerContext = context;
    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تأكيد الحذف', style: AppTextStyles.h2),
            content: Text('هل أنت متأكد من رغبتك في حذف وردية "${shift.name}"؟', style: AppTextStyles.body),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('إلغاء', style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Inter')),
              ),
              ElevatedButton(
                onPressed: () async {
                  final dashboardCubit = outerContext.read<AdminDashboardCubit>();
                  await _manageCubit.deleteShift(shift.id!);
                  dashboardCubit.loadDashboard();
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم حذف الوردية بنجاح'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                child: const Text('حذف', style: TextStyle(fontFamily: 'Inter')),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminDashboardCubit, AdminDashboardState>(
      builder: (context, state) {
        if (state is! AdminDashboardLoaded) {
          return const Center(child: CircularProgressIndicator(color: AppColors.secondary));
        }

        final shifts = state.shifts;

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
                      Text('إدارة الورديات (الشيفتات)', style: AppTextStyles.h1),
                      const SizedBox(height: 4),
                      Text('إضافة وتعديل وحذف أوقات الورديات الرسمية وفترات السماح', style: AppTextStyles.caption),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showShiftDialog(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded, color: Colors.white),
                    label: Text('إضافة وردية جديدة', style: AppTextStyles.button),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Shifts Table
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: shifts.isEmpty
                      ? Center(
                          child: Text(
                            'لا توجد ورديات مضافة حالياً.',
                            style: AppTextStyles.h3.copyWith(color: AppColors.textSecondary),
                          ),
                        )
                      : _buildShiftsTable(shifts),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShiftsTable(List<ShiftModel> shifts) {
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
                  DataColumn(label: Text('اسم الوردية', style: AppTextStyles.bodyBold)),
                  DataColumn(label: Text('بداية الدوام', style: AppTextStyles.bodyBold)),
                  DataColumn(label: Text('نهاية الدوام', style: AppTextStyles.bodyBold)),
                  DataColumn(label: Text('فترة السماح', style: AppTextStyles.bodyBold)),
                  DataColumn(label: Text('الحالة', style: AppTextStyles.bodyBold)),
                  DataColumn(label: Text('خيارات', style: AppTextStyles.bodyBold)),
                ],
                rows: shifts.map((shift) {
                  return DataRow(
                    cells: [
                      DataCell(Text(shift.name, style: AppTextStyles.bodyBold)),
                      DataCell(Text(shift.startTime, style: AppTextStyles.body)),
                      DataCell(Text(shift.endTime, style: AppTextStyles.body)),
                      DataCell(Text('${shift.gracePeriod} دقيقة', style: AppTextStyles.body)),
                      DataCell(
                        Switch(
                          value: shift.isActive,
                          activeColor: AppColors.secondary,
                          onChanged: (value) async {
                            final dashboardCubit = context.read<AdminDashboardCubit>();
                            await _manageCubit.toggleShiftStatus(shift);
                            dashboardCubit.loadDashboard();
                          },
                        ),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: AppColors.secondary),
                              onPressed: () => _showShiftDialog(shift: shift),
                              tooltip: 'تعديل',
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                              onPressed: () => _confirmDelete(shift),
                              tooltip: 'حذف',
                            ),
                          ],
                        ),
                      ),
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
}

// Dialog form for creating / updating shift
class _ShiftFormDialog extends StatefulWidget {
  final ShiftModel? shift;
  final VoidCallback onSuccess;

  const _ShiftFormDialog({
    this.shift,
    required this.onSuccess,
  });

  @override
  State<_ShiftFormDialog> createState() => _ShiftFormDialogState();
}

class _ShiftFormDialogState extends State<_ShiftFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  final _graceController = TextEditingController();
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    if (widget.shift != null) {
      _nameController.text = widget.shift!.name;
      _startTimeController.text = widget.shift!.startTime;
      _endTimeController.text = widget.shift!.endTime;
      _graceController.text = widget.shift!.gracePeriod.toString();
      _isActive = widget.shift!.isActive;
    } else {
      _startTimeController.text = '09:00';
      _endTimeController.text = '17:00';
      _graceController.text = '15';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _graceController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(TextEditingController controller) async {
    final initialParts = controller.text.split(':');
    final initialHour = int.parse(initialParts[0]);
    final initialMinute = int.parse(initialParts[1]);

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMinute),
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
      final hour = picked.hour.toString().padLeft(2, '0');
      final minute = picked.minute.toString().padLeft(2, '0');
      setState(() {
        controller.text = '$hour:$minute';
      });
    }
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text;
      final start = _startTimeController.text;
      final end = _endTimeController.text;
      final grace = int.parse(_graceController.text);

      if (widget.shift != null) {
        context.read<ShiftManageCubit>().updateShift(
              originalShift: widget.shift!,
              name: name,
              startTime: start,
              endTime: end,
              gracePeriod: grace,
              isActive: _isActive,
            );
      } else {
        context.read<ShiftManageCubit>().addShift(
              name: name,
              startTime: start,
              endTime: end,
              gracePeriod: grace,
            );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.shift != null;

    return BlocConsumer<ShiftManageCubit, ShiftManageState>(
      listener: (context, state) {
        if (state is ShiftManageSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isEdit ? 'تم تعديل الوردية بنجاح' : 'تم إضافة الوردية بنجاح'),
              backgroundColor: AppColors.success,
            ),
          );
          widget.onSuccess();
        } else if (state is ShiftManageError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is ShiftManageLoading;

        return AlertDialog(
          title: Text(isEdit ? 'تعديل الوردية' : 'إضافة وردية جديدة', style: AppTextStyles.h2),
          content: SizedBox(
            width: 400,
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Name
                    Text('اسم الوردية', style: AppTextStyles.caption),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _nameController,
                      style: AppTextStyles.body,
                      decoration: const InputDecoration(
                        hintText: 'مثال: الشيفت الصباحي',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty ? 'يرجى إدخال اسم الوردية' : null,
                    ),
                    const SizedBox(height: 16),

                    // Start Time & End Time
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('بداية الدوام', style: AppTextStyles.caption),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _startTimeController,
                                style: AppTextStyles.body,
                                readOnly: true,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  suffixIcon: Icon(Icons.access_time_rounded, size: 20),
                                ),
                                onTap: () => _selectTime(_startTimeController),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('نهاية الدوام', style: AppTextStyles.caption),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _endTimeController,
                                style: AppTextStyles.body,
                                readOnly: true,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  suffixIcon: Icon(Icons.access_time_rounded, size: 20),
                                ),
                                onTap: () => _selectTime(_endTimeController),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Grace Period
                    Text('فترة السماح بالدقائق (قبل احتساب التأخير)', style: AppTextStyles.caption),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _graceController,
                      style: AppTextStyles.body,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'مثال: 15',
                        border: OutlineInputBorder(),
                        suffixText: 'دقيقة',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'يرجى إدخال فترة السماح';
                        }
                        if (int.tryParse(value) == null) {
                          return 'يرجى إدخال رقم صحيح';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Active Switch (Only if editing)
                    if (isEdit)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('الوردية نشطة ومتاحة للاستخدام', style: AppTextStyles.body),
                          Switch(
                            value: _isActive,
                            activeColor: AppColors.secondary,
                            onChanged: (value) {
                              setState(() {
                                _isActive = value;
                              });
                            },
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.of(context).pop(),
              child: const Text('إلغاء', style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Inter')),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : _save,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('حفظ', style: TextStyle(fontFamily: 'Inter')),
            ),
          ],
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/di/service_locator.dart';
import '../../../data/models/employee_model.dart';
import '../../../data/models/shift_model.dart';
import '../../cubits/admin_dashboard/admin_dashboard_cubit.dart';
import '../../cubits/admin_dashboard/admin_dashboard_state.dart';
import '../../cubits/employee_manage/employee_manage_cubit.dart';
import '../../cubits/employee_manage/employee_manage_state.dart';

class EmployeeListView extends StatefulWidget {
  const EmployeeListView({super.key});

  @override
  State<EmployeeListView> createState() => _EmployeeListViewState();
}

class _EmployeeListViewState extends State<EmployeeListView> {
  late EmployeeManageCubit _manageCubit;

  @override
  void initState() {
    super.initState();
    _manageCubit = sl<EmployeeManageCubit>();
  }

  void _showEmployeeDialog({EmployeeModel? employee, required List<ShiftModel> shifts}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return BlocProvider.value(
          value: _manageCubit,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: _EmployeeFormDialog(
              employee: employee,
              shifts: shifts,
              onSuccess: () {
                // Reload dashboard data
                sl<AdminDashboardCubit>().loadDashboard();
                Navigator.of(context).pop();
              },
            ),
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

        final employees = state.employees;
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
                      Text('إدارة الموظفين', style: AppTextStyles.h1),
                      const SizedBox(height: 4),
                      Text('إضافة وتعديل وتفعيل حسابات الموظفين', style: AppTextStyles.caption),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: shifts.isEmpty
                        ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('يجب إضافة وردية واحدة على الأقل أولاً'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        : () => _showEmployeeDialog(shifts: shifts),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded, color: Colors.white),
                    label: Text('إضافة موظف جديد', style: AppTextStyles.button),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Employees Table
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: employees.isEmpty
                      ? Center(
                          child: Text(
                            'لا يوجد موظفون مضافون حالياً.',
                            style: AppTextStyles.h3.copyWith(color: AppColors.textSecondary),
                          ),
                        )
                      : _buildEmployeesTable(employees, shifts),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmployeesTable(List<EmployeeModel> employees, List<ShiftModel> shifts) {
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
                  DataColumn(label: Text('كود الموظف', style: AppTextStyles.bodyBold)),
                  DataColumn(label: Text('الاسم', style: AppTextStyles.bodyBold)),
                  DataColumn(label: Text('القسم', style: AppTextStyles.bodyBold)),
                  DataColumn(label: Text('الوردية', style: AppTextStyles.bodyBold)),
                  DataColumn(label: Text('الدور', style: AppTextStyles.bodyBold)),
                  DataColumn(label: Text('الحالة', style: AppTextStyles.bodyBold)),
                  DataColumn(label: Text('خيارات', style: AppTextStyles.bodyBold)),
                ],
                rows: employees.map((employee) {
                  final shift = shifts.firstWhere(
                    (s) => s.id == employee.shiftId,
                    orElse: () => ShiftModel(name: 'N/A', startTime: '', endTime: '', gracePeriod: 0),
                  );

                  final isAdmin = employee.role == 'admin';

                  return DataRow(
                    cells: [
                      DataCell(Text(employee.employeeCode, style: AppTextStyles.body)),
                      DataCell(Text(employee.name, style: AppTextStyles.bodyBold)),
                      DataCell(Text(employee.department, style: AppTextStyles.body)),
                      DataCell(Text(shift.name, style: AppTextStyles.body)),
                      DataCell(Text(isAdmin ? 'مسؤول' : 'موظف', style: AppTextStyles.body)),
                      DataCell(
                        isAdmin
                            ? const Text('نشط دائماً', style: TextStyle(color: AppColors.success))
                            : Switch(
                                value: employee.isActive,
                                activeColor: AppColors.secondary,
                                onChanged: (value) async {
                                  await _manageCubit.toggleEmployeeStatus(employee);
                                  sl<AdminDashboardCubit>().loadDashboard();
                                },
                              ),
                      ),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: AppColors.secondary),
                          onPressed: () => _showEmployeeDialog(employee: employee, shifts: shifts),
                          tooltip: 'تعديل البيانات',
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

// Dialog form for creating / updating employee
class _EmployeeFormDialog extends StatefulWidget {
  final EmployeeModel? employee;
  final List<ShiftModel> shifts;
  final VoidCallback onSuccess;

  const _EmployeeFormDialog({
    this.employee,
    required this.shifts,
    required this.onSuccess,
  });

  @override
  State<_EmployeeFormDialog> createState() => _EmployeeFormDialogState();
}

class _EmployeeFormDialogState extends State<_EmployeeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _pinController = TextEditingController();
  final _departmentController = TextEditingController();
  int? _selectedShiftId;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    if (widget.employee != null) {
      _codeController.text = widget.employee!.employeeCode;
      _nameController.text = widget.employee!.name;
      _departmentController.text = widget.employee!.department;
      _selectedShiftId = widget.employee!.shiftId;
      _isActive = widget.employee!.isActive;
    } else if (widget.shifts.isNotEmpty) {
      _selectedShiftId = widget.shifts.first.id;
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _pinController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final code = _codeController.text;
      final name = _nameController.text;
      final pin = _pinController.text;
      final dept = _departmentController.text;
      final shiftId = _selectedShiftId!;

      if (widget.employee != null) {
        context.read<EmployeeManageCubit>().updateEmployee(
              originalEmployee: widget.employee!,
              employeeCode: code,
              name: name,
              pin: pin.isEmpty ? null : pin,
              department: dept,
              shiftId: shiftId,
              isActive: _isActive,
            );
      } else {
        context.read<EmployeeManageCubit>().addEmployee(
              employeeCode: code,
              name: name,
              pin: pin,
              department: dept,
              shiftId: shiftId,
            );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.employee != null;

    return BlocConsumer<EmployeeManageCubit, EmployeeManageState>(
      listener: (context, state) {
        if (state is EmployeeManageSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isEdit ? 'تم تعديل بيانات الموظف بنجاح' : 'تم إضافة الموظف بنجاح'),
              backgroundColor: AppColors.success,
            ),
          );
          widget.onSuccess();
        } else if (state is EmployeeManageError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is EmployeeManageLoading;

        return AlertDialog(
          title: Text(isEdit ? 'تعديل بيانات موظف' : 'إضافة موظف جديد', style: AppTextStyles.h2),
          content: SizedBox(
            width: 400,
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Code
                    Text('كود الموظف (يجب أن يكون فريداً)', style: AppTextStyles.caption),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _codeController,
                      style: AppTextStyles.body,
                      decoration: const InputDecoration(
                        hintText: 'مثال: EMP101',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty ? 'يرجى إدخال كود الموظف' : null,
                    ),
                    const SizedBox(height: 16),

                    // Name
                    Text('الاسم الكامل', style: AppTextStyles.caption),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _nameController,
                      style: AppTextStyles.body,
                      decoration: const InputDecoration(
                        hintText: 'مثال: محمد الشبل',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty ? 'يرجى إدخال اسم الموظف' : null,
                    ),
                    const SizedBox(height: 16),

                    // PIN
                    Text(
                      isEdit ? 'الرمز السري الجديد (اتركه فارغاً للاحتفاظ بالقديم)' : 'الرمز السري',
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _pinController,
                      style: AppTextStyles.body,
                      obscureText: true,
                      decoration: const InputDecoration(
                        hintText: '••••••',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (!isEdit && (value == null || value.isEmpty)) {
                          return 'يرجى إدخال الرمز السري';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Department
                    Text('القسم / الإدارة', style: AppTextStyles.caption),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _departmentController,
                      style: AppTextStyles.body,
                      decoration: const InputDecoration(
                        hintText: 'مثال: الهندسة، المبيعات، إلخ.',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty ? 'يرجى إدخال القسم' : null,
                    ),
                    const SizedBox(height: 16),

                    // Shift Dropdown
                    Text('الوردية / الشيفت', style: AppTextStyles.caption),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int>(
                      value: _selectedShiftId,
                      style: AppTextStyles.body,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: widget.shifts.map((s) {
                        return DropdownMenuItem<int>(
                          value: s.id,
                          child: Text('${s.name} (${s.startTime} - ${s.endTime})'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedShiftId = value;
                        });
                      },
                      validator: (value) => value == null ? 'يرجى اختيار الوردية' : null,
                    ),
                    const SizedBox(height: 16),

                    // Active Switch (Only if editing)
                    if (isEdit && widget.employee?.role != 'admin')
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('نشط / يمكنه تسجيل الدخول', style: AppTextStyles.body),
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

abstract class EmployeeManageState {
  const EmployeeManageState();
}

class EmployeeManageInitial extends EmployeeManageState {
  const EmployeeManageInitial();
}

class EmployeeManageLoading extends EmployeeManageState {
  const EmployeeManageLoading();
}

class EmployeeManageSuccess extends EmployeeManageState {
  const EmployeeManageSuccess();
}

class EmployeeManageError extends EmployeeManageState {
  final String message;
  const EmployeeManageError(this.message);
}

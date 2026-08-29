abstract class ShiftManageState {
  const ShiftManageState();
}

class ShiftManageInitial extends ShiftManageState {
  const ShiftManageInitial();
}

class ShiftManageLoading extends ShiftManageState {
  const ShiftManageLoading();
}

class ShiftManageSuccess extends ShiftManageState {
  const ShiftManageSuccess();
}

class ShiftManageError extends ShiftManageState {
  final String message;
  const ShiftManageError(this.message);
}

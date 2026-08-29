class LeaveBalanceModel {
  final int? id;
  final int employeeId;
  final int leaveTypeId;
  final int leaveYear;
  final int entitlement;
  final int used;
  final int pending;

  LeaveBalanceModel({
    this.id,
    required this.employeeId,
    required this.leaveTypeId,
    required this.leaveYear,
    required this.entitlement,
    this.used = 0,
    this.pending = 0,
  });

  int get remaining => entitlement - used;

  LeaveBalanceModel copyWith({
    int? id,
    int? employeeId,
    int? leaveTypeId,
    int? leaveYear,
    int? entitlement,
    int? used,
    int? pending,
  }) {
    return LeaveBalanceModel(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      leaveTypeId: leaveTypeId ?? this.leaveTypeId,
      leaveYear: leaveYear ?? this.leaveYear,
      entitlement: entitlement ?? this.entitlement,
      used: used ?? this.used,
      pending: pending ?? this.pending,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'employeeId': employeeId,
      'leaveTypeId': leaveTypeId,
      'leaveYear': leaveYear,
      'entitlement': entitlement,
      'used': used,
      'pending': pending,
    };
    if (id != null) map['id'] = id;
    return map;
  }

  factory LeaveBalanceModel.fromMap(Map<String, dynamic> map) {
    return LeaveBalanceModel(
      id: map['id'] as int?,
      employeeId: map['employeeId'] as int,
      leaveTypeId: map['leaveTypeId'] as int,
      leaveYear: map['leaveYear'] as int,
      entitlement: map['entitlement'] as int,
      used: map['used'] as int? ?? 0,
      pending: map['pending'] as int? ?? 0,
    );
  }
}

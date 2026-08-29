class LeaveRequestModel {
  final int? id;
  final int employeeId;
  final int leaveTypeId;
  final DateTime startDate;
  final DateTime endDate;
  final int numberOfDays;
  final String reason;
  final String? attachmentPath; // Local file or base64 representation/name
  final String status; // 'PENDING', 'APPROVED', 'REJECTED', 'CANCELLED'
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final int? reviewedBy; // Admin employee ID who reviewed
  final String? rejectionReason;

  LeaveRequestModel({
    this.id,
    required this.employeeId,
    required this.leaveTypeId,
    required this.startDate,
    required this.endDate,
    required this.numberOfDays,
    required this.reason,
    this.attachmentPath,
    this.status = 'PENDING',
    required this.createdAt,
    this.reviewedAt,
    this.reviewedBy,
    this.rejectionReason,
  });

  LeaveRequestModel copyWith({
    int? id,
    int? employeeId,
    int? leaveTypeId,
    DateTime? startDate,
    DateTime? endDate,
    int? numberOfDays,
    String? reason,
    String? attachmentPath,
    String? status,
    DateTime? createdAt,
    DateTime? reviewedAt,
    int? reviewedBy,
    String? rejectionReason,
  }) {
    return LeaveRequestModel(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      leaveTypeId: leaveTypeId ?? this.leaveTypeId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      numberOfDays: numberOfDays ?? this.numberOfDays,
      reason: reason ?? this.reason,
      attachmentPath: attachmentPath ?? this.attachmentPath,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'employeeId': employeeId,
      'leaveTypeId': leaveTypeId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'numberOfDays': numberOfDays,
      'reason': reason,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
    if (id != null) map['id'] = id;
    if (attachmentPath != null) map['attachmentPath'] = attachmentPath;
    if (reviewedAt != null) map['reviewedAt'] = reviewedAt!.toIso8601String();
    if (reviewedBy != null) map['reviewedBy'] = reviewedBy;
    if (rejectionReason != null) map['rejectionReason'] = rejectionReason;
    return map;
  }

  factory LeaveRequestModel.fromMap(Map<String, dynamic> map) {
    return LeaveRequestModel(
      id: map['id'] as int?,
      employeeId: map['employeeId'] as int,
      leaveTypeId: map['leaveTypeId'] as int,
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: DateTime.parse(map['endDate'] as String),
      numberOfDays: map['numberOfDays'] as int,
      reason: map['reason'] as String,
      attachmentPath: map['attachmentPath'] as String?,
      status: map['status'] as String? ?? 'PENDING',
      createdAt: DateTime.parse(map['createdAt'] as String),
      reviewedAt: map['reviewedAt'] != null ? DateTime.parse(map['reviewedAt'] as String) : null,
      reviewedBy: map['reviewedBy'] as int?,
      rejectionReason: map['rejectionReason'] as String?,
    );
  }
}

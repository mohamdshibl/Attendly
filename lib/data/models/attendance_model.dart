class AttendanceModel {
  final int? id;
  final int employeeId;
  final String date; // format: "yyyy-MM-dd"
  final DateTime? checkIn;
  final DateTime? checkOut;
  final String status; // 'NOT_CHECKED_IN', 'CHECKED_IN', 'CHECKED_OUT', 'ABSENT', 'LATE'
  final int lateMinutes;
  final int workedMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;

  AttendanceModel({
    this.id,
    required this.employeeId,
    required this.date,
    this.checkIn,
    this.checkOut,
    required this.status,
    this.lateMinutes = 0,
    this.workedMinutes = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  AttendanceModel copyWith({
    int? id,
    int? employeeId,
    String? date,
    DateTime? checkIn,
    DateTime? checkOut,
    String? status,
    int? lateMinutes,
    int? workedMinutes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      date: date ?? this.date,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      status: status ?? this.status,
      lateMinutes: lateMinutes ?? this.lateMinutes,
      workedMinutes: workedMinutes ?? this.workedMinutes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'employeeId': employeeId,
      'date': date,
      'checkIn': checkIn?.toIso8601String(),
      'checkOut': checkOut?.toIso8601String(),
      'status': status,
      'lateMinutes': lateMinutes,
      'workedMinutes': workedMinutes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory AttendanceModel.fromMap(Map<String, dynamic> map) {
    return AttendanceModel(
      id: map['id'] as int?,
      employeeId: map['employeeId'] as int,
      date: map['date'] as String,
      checkIn: map['checkIn'] != null ? DateTime.parse(map['checkIn'] as String) : null,
      checkOut: map['checkOut'] != null ? DateTime.parse(map['checkOut'] as String) : null,
      status: map['status'] as String,
      lateMinutes: map['lateMinutes'] as int? ?? 0,
      workedMinutes: map['workedMinutes'] as int? ?? 0,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  double get workedHours => workedMinutes / 60.0;
}

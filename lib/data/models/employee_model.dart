class EmployeeModel {
  final int? id;
  final String employeeCode;
  final String name;
  final String passwordHash;
  final String department;
  final int shiftId;
  final bool isActive;
  final String role; // 'employee' or 'admin'
  final DateTime createdAt;

  EmployeeModel({
    this.id,
    required this.employeeCode,
    required this.name,
    required this.passwordHash,
    required this.department,
    required this.shiftId,
    this.isActive = true,
    this.role = 'employee',
    required this.createdAt,
  });

  EmployeeModel copyWith({
    int? id,
    String? employeeCode,
    String? name,
    String? passwordHash,
    String? department,
    int? shiftId,
    bool? isActive,
    String? role,
    DateTime? createdAt,
  }) {
    return EmployeeModel(
      id: id ?? this.id,
      employeeCode: employeeCode ?? this.employeeCode,
      name: name ?? this.name,
      passwordHash: passwordHash ?? this.passwordHash,
      department: department ?? this.department,
      shiftId: shiftId ?? this.shiftId,
      isActive: isActive ?? this.isActive,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'employeeCode': employeeCode,
      'name': name,
      'passwordHash': passwordHash,
      'department': department,
      'shiftId': shiftId,
      'isActive': isActive ? 1 : 0,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory EmployeeModel.fromMap(Map<String, dynamic> map) {
    return EmployeeModel(
      id: map['id'] as int?,
      employeeCode: map['employeeCode'] as String,
      name: map['name'] as String,
      passwordHash: map['passwordHash'] as String,
      department: map['department'] as String,
      shiftId: map['shiftId'] as int,
      isActive: map['isActive'] == 1 || map['isActive'] == true,
      role: map['role'] as String? ?? 'employee',
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}

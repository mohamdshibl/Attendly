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
  final String phone;
  final DateTime? hireDate;
  final DateTime? birthDate;
  final String gender; // 'male' or 'female'
  final bool isDisabled;
  final String workClassification; // 'normal', 'hazardous', 'remote'
  final DateTime? updatedAt;

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
    this.phone = '',
    this.hireDate,
    this.birthDate,
    this.gender = 'male',
    this.isDisabled = false,
    this.workClassification = 'normal',
    this.updatedAt,
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
    String? phone,
    DateTime? hireDate,
    DateTime? birthDate,
    String? gender,
    bool? isDisabled,
    String? workClassification,
    DateTime? updatedAt,
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
      phone: phone ?? this.phone,
      hireDate: hireDate ?? this.hireDate,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      isDisabled: isDisabled ?? this.isDisabled,
      workClassification: workClassification ?? this.workClassification,
      updatedAt: updatedAt ?? this.updatedAt,
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
      'phone': phone,
      'gender': gender,
      'isDisabled': isDisabled ? 1 : 0,
      'workClassification': workClassification,
    };
    if (id != null) {
      map['id'] = id;
    }
    if (hireDate != null) {
      map['hireDate'] = hireDate!.toIso8601String();
    }
    if (birthDate != null) {
      map['birthDate'] = birthDate!.toIso8601String();
    }
    if (updatedAt != null) {
      map['updatedAt'] = updatedAt!.toIso8601String();
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
      phone: map['phone'] as String? ?? '',
      gender: map['gender'] as String? ?? 'male',
      isDisabled: map['isDisabled'] == 1 || map['isDisabled'] == true,
      workClassification: map['workClassification'] as String? ?? 'normal',
      hireDate: map['hireDate'] != null ? DateTime.parse(map['hireDate'] as String) : null,
      birthDate: map['birthDate'] != null ? DateTime.parse(map['birthDate'] as String) : null,
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : null,
    );
  }
}

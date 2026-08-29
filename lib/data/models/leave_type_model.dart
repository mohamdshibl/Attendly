class LeaveTypeModel {
  final int? id;
  final String name;
  final String code; // 'ANNUAL', 'CASUAL', 'SICK', 'MATERNITY', 'PATERNITY', 'HAJJ', 'OTHER'
  final bool paid;
  final bool deductsFromAnnual;
  final bool requiresApproval;
  final bool requiresDocument;
  final int? maxDaysPerRequest;
  final int? annualLimit;
  final int? lifetimeLimit;
  final bool isActive;

  LeaveTypeModel({
    this.id,
    required this.name,
    required this.code,
    this.paid = true,
    this.deductsFromAnnual = false,
    this.requiresApproval = true,
    this.requiresDocument = false,
    this.maxDaysPerRequest,
    this.annualLimit,
    this.lifetimeLimit,
    this.isActive = true,
  });

  LeaveTypeModel copyWith({
    int? id,
    String? name,
    String? code,
    bool? paid,
    bool? deductsFromAnnual,
    bool? requiresApproval,
    bool? requiresDocument,
    int? maxDaysPerRequest,
    int? annualLimit,
    int? lifetimeLimit,
    bool? isActive,
  }) {
    return LeaveTypeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      paid: paid ?? this.paid,
      deductsFromAnnual: deductsFromAnnual ?? this.deductsFromAnnual,
      requiresApproval: requiresApproval ?? this.requiresApproval,
      requiresDocument: requiresDocument ?? this.requiresDocument,
      maxDaysPerRequest: maxDaysPerRequest ?? this.maxDaysPerRequest,
      annualLimit: annualLimit ?? this.annualLimit,
      lifetimeLimit: lifetimeLimit ?? this.lifetimeLimit,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'code': code,
      'paid': paid ? 1 : 0,
      'deductsFromAnnual': deductsFromAnnual ? 1 : 0,
      'requiresApproval': requiresApproval ? 1 : 0,
      'requiresDocument': requiresDocument ? 1 : 0,
      'isActive': isActive ? 1 : 0,
    };
    if (id != null) map['id'] = id;
    if (maxDaysPerRequest != null) map['maxDaysPerRequest'] = maxDaysPerRequest;
    if (annualLimit != null) map['annualLimit'] = annualLimit;
    if (lifetimeLimit != null) map['lifetimeLimit'] = lifetimeLimit;
    return map;
  }

  factory LeaveTypeModel.fromMap(Map<String, dynamic> map) {
    return LeaveTypeModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      code: map['code'] as String,
      paid: map['paid'] == 1 || map['paid'] == true,
      deductsFromAnnual: map['deductsFromAnnual'] == 1 || map['deductsFromAnnual'] == true,
      requiresApproval: map['requiresApproval'] == 1 || map['requiresApproval'] == true,
      requiresDocument: map['requiresDocument'] == 1 || map['requiresDocument'] == true,
      maxDaysPerRequest: map['maxDaysPerRequest'] as int?,
      annualLimit: map['annualLimit'] as int?,
      lifetimeLimit: map['lifetimeLimit'] as int?,
      isActive: map['isActive'] == 1 || map['isActive'] == true,
    );
  }
}

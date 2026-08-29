class OfficialHolidayModel {
  final int? id;
  final String name;
  final DateTime date;
  final bool isRecurring;
  final bool isPaid;
  final String? notes;

  OfficialHolidayModel({
    this.id,
    required this.name,
    required this.date,
    this.isRecurring = false,
    this.isPaid = true,
    this.notes,
  });

  OfficialHolidayModel copyWith({
    int? id,
    String? name,
    DateTime? date,
    bool? isRecurring,
    bool? isPaid,
    String? notes,
  }) {
    return OfficialHolidayModel(
      id: id ?? this.id,
      name: name ?? this.name,
      date: date ?? this.date,
      isRecurring: isRecurring ?? this.isRecurring,
      isPaid: isPaid ?? this.isPaid,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'date': date.toIso8601String().substring(0, 10), // Store as yyyy-MM-dd
      'isRecurring': isRecurring ? 1 : 0,
      'isPaid': isPaid ? 1 : 0,
    };
    if (id != null) map['id'] = id;
    if (notes != null) map['notes'] = notes;
    return map;
  }

  factory OfficialHolidayModel.fromMap(Map<String, dynamic> map) {
    return OfficialHolidayModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      date: DateTime.parse(map['date'] as String),
      isRecurring: map['isRecurring'] == 1 || map['isRecurring'] == true,
      isPaid: map['isPaid'] == 1 || map['isPaid'] == true,
      notes: map['notes'] as String?,
    );
  }
}

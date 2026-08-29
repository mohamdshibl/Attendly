class ShiftModel {
  final int? id;
  final String name;
  final String startTime; // format: "HH:mm"
  final String endTime;   // format: "HH:mm"
  final int gracePeriod;  // in minutes
  final bool isActive;

  ShiftModel({
    this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.gracePeriod,
    this.isActive = true,
  });

  ShiftModel copyWith({
    int? id,
    String? name,
    String? startTime,
    String? endTime,
    int? gracePeriod,
    bool? isActive,
  }) {
    return ShiftModel(
      id: id ?? this.id,
      name: name ?? this.name,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      gracePeriod: gracePeriod ?? this.gracePeriod,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'startTime': startTime,
      'endTime': endTime,
      'gracePeriod': gracePeriod,
      'isActive': isActive ? 1 : 0, // Store booleans as integers (0/1) for compatibility
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory ShiftModel.fromMap(Map<String, dynamic> map) {
    return ShiftModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      startTime: map['startTime'] as String,
      endTime: map['endTime'] as String,
      gracePeriod: map['gracePeriod'] as int,
      isActive: map['isActive'] == 1 || map['isActive'] == true,
    );
  }
}

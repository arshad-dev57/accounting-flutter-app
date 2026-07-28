// core/FiscalYear/models/fiscal_year_model.dart

class FiscalYear {
  final String id;
  final String userId;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final DateTime? closedAt;
  final String? closedBy;
  final String? periodType;
  final DateTime createdAt;
  final DateTime updatedAt;

  FiscalYear({
    required this.id,
    required this.userId,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.closedAt,
    this.closedBy,
    this.periodType,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FiscalYear.fromJson(Map<String, dynamic> json) {
    return FiscalYear(
      id: json['id'] ?? json['_id'] ?? '',
      userId: json['userId'] ?? json['user_id'] ?? '',
      name: json['name'] ?? '',
      startDate: json['startDate'] != null 
          ? DateTime.parse(json['startDate']) 
          : (json['start_date'] != null ? DateTime.parse(json['start_date']) : DateTime.now()),
      endDate: json['endDate'] != null 
          ? DateTime.parse(json['endDate']) 
          : (json['end_date'] != null ? DateTime.parse(json['end_date']) : DateTime.now()),
      status: json['status'] ?? 'Open',
      closedAt: json['closedAt'] != null 
          ? DateTime.parse(json['closedAt']) 
          : (json['closed_at'] != null ? DateTime.parse(json['closed_at']) : null),
      closedBy: json['closedBy'] ?? json['closed_by'],
      periodType: json['periodType'] ?? json['period_type'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : (json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now()),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : (json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'user_id': userId,
      'name': name,
      'startDate': startDate.toIso8601String(),
      'start_date': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'status': status,
      'closedAt': closedAt?.toIso8601String(),
      'closed_at': closedAt?.toIso8601String(),
      'closedBy': closedBy,
      'closed_by': closedBy,
      'periodType': periodType,
      'period_type': periodType,
      'createdAt': createdAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isOpen => status == 'Open';
  bool get isClosed => status == 'Closed';
  
  String get statusDisplay {
    switch (status.toLowerCase()) {
      case 'open':
        return 'Open';
      case 'closed':
        return 'Closed';
      default:
        return status;
    }
  }
}

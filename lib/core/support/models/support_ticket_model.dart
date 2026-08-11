class SupportTicketModel {
  final String id;
  final String ticketNumber;
  final String title;
  final String description;
  final String category;
  final String priority;
  final String status;
  final String? stepsToReproduce;
  final String? attachmentUrl;
  final String? adminResponse;
  final String? module;
  final String userId;
  final String? companyId;
  final DateTime? resolvedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  SupportTicketModel({
    required this.id,
    required this.ticketNumber,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    this.stepsToReproduce,
    this.attachmentUrl,
    this.adminResponse,
    this.module,
    required this.userId,
    this.companyId,
    this.resolvedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SupportTicketModel.fromJson(Map<String, dynamic> json) {
    return SupportTicketModel(
      id: (json['id'] ?? '').toString(),
      ticketNumber: (json['ticketNumber'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      category: (json['category'] ?? 'General').toString(),
      priority: (json['priority'] ?? 'Medium').toString(),
      status: (json['status'] ?? 'Open').toString(),
      stepsToReproduce: json['stepsToReproduce']?.toString(),
      attachmentUrl: json['attachmentUrl']?.toString(),
      adminResponse: json['adminResponse']?.toString(),
      module: json['module']?.toString(),
      userId: (json['userId'] ?? '').toString(),
      companyId: json['companyId']?.toString(),
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.tryParse(json['resolvedAt'].toString())
          : null,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  String get dateLabel {
    final d = createdAt;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}

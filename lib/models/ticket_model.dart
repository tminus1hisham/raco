/// Ticket record returned by the API (`/v1/api/tickets/get/all`).
class TicketModel {
  final int id;
  final String ticketType;
  final String comment;
  final String attachments;
  final String status;
  final String approvalRemarks;
  final String createdById;
  final String createdByName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TicketModel({
    required this.id,
    required this.ticketType,
    required this.comment,
    required this.attachments,
    required this.status,
    required this.approvalRemarks,
    required this.createdById,
    required this.createdByName,
    this.createdAt,
    this.updatedAt,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    return TicketModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      ticketType: json['ticketType']?.toString() ?? '',
      comment: json['comment']?.toString() ?? '',
      attachments: json['attachments']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      approvalRemarks: json['approvalRemarks']?.toString() ?? '',
      createdById: json['createdById']?.toString() ?? '',
      createdByName: json['createdByName']?.toString() ?? '',
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  static List<TicketModel> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .whereType<Map<String, dynamic>>()
        .map((json) => TicketModel.fromJson(json))
        .toList();
  }
}

/// Payload for creating/updating a ticket (`CreateTicketRequest`).
class CreateTicketModel {
  final String comment;
  final String ticketType;
  final String attachments;

  CreateTicketModel({
    required this.comment,
    required this.ticketType,
    this.attachments = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'comment': comment,
      'ticketType': ticketType,
      'attachments': attachments,
    };
  }
}

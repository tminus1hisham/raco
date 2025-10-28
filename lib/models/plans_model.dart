class PlanModel {
  final int id;
  final String planName;
  final double price;
  final int durationInDays;
  final DateTime createdAt;
  final DateTime updatedAt;

  PlanModel({
    required this.id,
    required this.planName,
    required this.price,
    required this.durationInDays,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PlanModel.fromJson(Map<String, dynamic> json) {
    return PlanModel(
      id: json['id'] ?? 0,
      planName: json['planName'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      durationInDays: json['durationInDays'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'planName': planName,
      'price': price,
      'durationInDays': durationInDays,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static List<PlanModel> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => PlanModel.fromJson(json)).toList();
  }
}

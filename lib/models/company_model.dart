class CompanyModel {
  final bool success;
  final String message;
  final List<Company> data;

  CompanyModel({
    required this.success,
    required this.message,
    required this.data,
  });

  factory CompanyModel.fromJson(Map<dynamic, dynamic> json) {
    return CompanyModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data:
          (json['data'] as List?)
              ?.map((company) => Company.fromJson(company))
              .toList() ??
          [],
    );
  }
}

class Company {
  final String fullName;
  final String phoneNumber;

  Company({required this.fullName, required this.phoneNumber});

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      fullName: json['fullName'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'fullName': fullName, 'phoneNumber': phoneNumber};
  }
}

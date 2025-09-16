class ChangePasswordModel {
  final String phoneNumber;
  final String currentPassword;
  final String newPassword;

  ChangePasswordModel({
    required this.phoneNumber,
    required this.currentPassword,
    required this.newPassword,
  });

  factory ChangePasswordModel.fromJson(Map<String, dynamic> json) {
    return ChangePasswordModel(
      phoneNumber: json['phoneNumber'] as String,
      currentPassword: json['currentPassword'] as String,
      newPassword: json['newPassword'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phoneNumber': phoneNumber,
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    };
  }
}

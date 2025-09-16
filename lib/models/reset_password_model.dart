class ResetPasswordModel {
  final String phoneNumber;
  final String newPassword;
  final String resetToken;

  ResetPasswordModel({
    required this.phoneNumber,
    required this.newPassword,
    required this.resetToken,
  });

  factory ResetPasswordModel.fromJson(Map<String, dynamic> json) {
    return ResetPasswordModel(
      phoneNumber: json['phoneNumber'] as String,
      newPassword: json['newPassword'] as String,
      resetToken: json['resetToken'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phoneNumber': phoneNumber,
      'newPassword': newPassword,
      'resetToken': resetToken,
    };
  }
}

class DeleteAccountModel {
  final String fullname;
  final String phoneNumber;
  final String reason;

  DeleteAccountModel({
    required this.fullname,
    required this.phoneNumber,
    required this.reason,
  });

  factory DeleteAccountModel.fromJson(Map<String, dynamic> json) {
    return DeleteAccountModel(
      fullname: json['fullname'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      reason: json['reason'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'fullname': fullname, 'phoneNumber': phoneNumber, 'reason': reason};
  }
}

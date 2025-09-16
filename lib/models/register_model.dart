class RegisterModel {
  final String fullName;
  final String phoneNumber;
  final String emailAddress;
  final String userRole;
  final String password;
  final String userFirebaseToken;

  RegisterModel({
    required this.fullName,
    required this.phoneNumber,
    required this.password,
    required this.emailAddress,
    required this.userRole,
    required this.userFirebaseToken,
  });

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'password': password,
      'emailAddress': emailAddress,
      'userFirebaseToken': userFirebaseToken,
      'userRole': userRole,
    };
  }

  factory RegisterModel.fromJson(Map<String, dynamic> json) {
    return RegisterModel(
      fullName: json['fullName'],
      phoneNumber: json['phoneNumber'],
      emailAddress: json['emailAddress'],
      userFirebaseToken: json['userFirebaseToken'],
      password: json['password'],
      userRole: json['userRole'],
    );
  }
}

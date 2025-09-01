class RegisterModel {
  final String fullname;
  final String email;
  final String password;
  final String phoneNumber;

  RegisterModel({
    required this.fullname,
    required this.password,
    required this.email,
    required this.phoneNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': fullname,
      'password': password,
      'email': email,
      'phoneNumber': phoneNumber,
    };
  }

  factory RegisterModel.fromJson(Map<String, dynamic> json) {
    return RegisterModel(
      fullname: json['fullname'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      password: json['password'],
    );
  }
}

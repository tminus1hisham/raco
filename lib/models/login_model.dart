class LoginModel {
  final String phoneNumberOrEmail;
  final String password;

  LoginModel({required this.phoneNumberOrEmail, required this.password});

  Map<String, dynamic> toJson() {
    return {'phoneNumberOrEmail': phoneNumberOrEmail, 'password': password};
  }

  factory LoginModel.fromJson(Map<String, dynamic> json) {
    return LoginModel(
      phoneNumberOrEmail: json['phoneNumberOrEmail'],
      password: json['password'],
    );
  }
}

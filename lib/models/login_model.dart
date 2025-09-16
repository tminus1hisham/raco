class LoginModel {
  final String phoneNumber;
  final String password;
  final String firebaseToken;
  final String deviceModel;
  final String userAgent;
  final String location;
  final String ipAddress;

  LoginModel({
    required this.phoneNumber,
    required this.password,
    required this.firebaseToken,
    required this.deviceModel,
    required this.userAgent,
    required this.location,
    required this.ipAddress,
  });

  /// Factory constructor to create an instance from JSON
  factory LoginModel.fromJson(Map<String, dynamic> json) {
    return LoginModel(
      phoneNumber: json['phoneNumber'] ?? '',
      password: json['password'] ?? '',
      firebaseToken: json['firebaseToken'] ?? '',
      deviceModel: json['deviceModel'] ?? '',
      userAgent: json['userAgent'] ?? '',
      location: json['location'] ?? '',
      ipAddress: json['ipAddress'] ?? '',
    );
  }

  /// Convert instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'phoneNumber': phoneNumber,
      'password': password,
      'firebaseToken': firebaseToken,
      'deviceModel': deviceModel,
      'userAgent': userAgent,
      'location': location,
      'ipAddress': ipAddress,
    };
  }
}

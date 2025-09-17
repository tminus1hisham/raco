class UserModel {
  final int id;
  final String userId;
  final String fullName;
  final String phoneNumber;
  final String emailAddress;
  final String userOtp;
  final DateTime? otpCreatedAt;
  final String userRole;
  final String profileImage;
  final bool privacyPolicyStatus;
  final bool userActive;
  final bool isDeleted;
  final String createdBy;
  final String createdByName;
  final String updatedBy;
  final String updatedByName;
  final String deletedBy;
  final String deletedByName;
  final String firebaseToken;
  final String adminPhoneNumber;
  final DeviceModel? devices;
  final String assignedDevices;
  final DateTime? lastLogin;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.phoneNumber,
    required this.emailAddress,
    required this.userOtp,
    this.otpCreatedAt,
    required this.userRole,
    required this.profileImage,
    required this.privacyPolicyStatus,
    required this.userActive,
    required this.isDeleted,
    required this.createdBy,
    required this.createdByName,
    required this.updatedBy,
    required this.updatedByName,
    required this.deletedBy,
    required this.deletedByName,
    required this.firebaseToken,
    required this.adminPhoneNumber,
    this.devices,
    required this.assignedDevices,
    this.lastLogin,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? '',
      fullName: json['fullName'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      emailAddress: json['emailAddress'] ?? '',
      userOtp: json['userOtp'] ?? '',
      otpCreatedAt: json['otpCreatedAt'] != null
          ? DateTime.tryParse(json['otpCreatedAt'])
          : null,
      userRole: json['userRole'] ?? '',
      profileImage: json['profileImage'] ?? '',
      privacyPolicyStatus: json['privacyPolicyStatus'] ?? false,
      userActive: json['userActive'] ?? false,
      isDeleted: json['isDeleted'] ?? false,
      createdBy: json['createdBy'] ?? '',
      createdByName: json['createdByName'] ?? '',
      updatedBy: json['updatedBy'] ?? '',
      updatedByName: json['updatedByName'] ?? '',
      deletedBy: json['deletedBy'] ?? '',
      deletedByName: json['deletedByName'] ?? '',
      firebaseToken: json['firebaseToken'] ?? '',
      adminPhoneNumber: json['adminPhoneNumber'] ?? '',
      devices: json['devices'] != null
          ? DeviceModel.fromJson(json['devices'])
          : null,
      assignedDevices: json['assignedDevices'] ?? '',
      lastLogin: json['lastLogin'] != null
          ? DateTime.tryParse(json['lastLogin'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "userId": userId,
      "fullName": fullName,
      "phoneNumber": phoneNumber,
      "emailAddress": emailAddress,
      "userOtp": userOtp,
      "otpCreatedAt": otpCreatedAt?.toIso8601String(),
      "userRole": userRole,
      "profileImage": profileImage,
      "privacyPolicyStatus": privacyPolicyStatus,
      "userActive": userActive,
      "isDeleted": isDeleted,
      "createdBy": createdBy,
      "createdByName": createdByName,
      "updatedBy": updatedBy,
      "updatedByName": updatedByName,
      "deletedBy": deletedBy,
      "deletedByName": deletedByName,
      "firebaseToken": firebaseToken,
      "adminPhoneNumber": adminPhoneNumber,
      "devices": devices?.toJson(),
      "assignedDevices": assignedDevices,
      "lastLogin": lastLogin?.toIso8601String(),
      "createdAt": createdAt?.toIso8601String(),
      "updatedAt": updatedAt?.toIso8601String(),
    };
  }
}

class DeviceModel {
  final int id;
  final String userId;
  final String name;
  final String ownerId;
  final String phone;
  final String numberPlate;
  final String chassis;
  final String make;
  final String certNo;
  final String type;
  final String serial;
  final String date;
  final String agent;
  final int agentID;
  final String location;
  final String email;
  final String agentPhone;
  final String businessReg;
  final String technicianName;
  final String deviceType;
  final String certificateUrl;
  final bool certificateActiveStatus;
  final DateTime? certificateExpirey;
  final bool isDeviceOnline;
  final int signalStrength;
  final String createdBy;
  final String updatedBy;
  final int speed;
  final String latitude;
  final String longitude;
  final int ignitionStatus;
  final bool headlights;
  final bool dashboardindicators;
  final bool revcounter;
  final bool enginestart;
  final bool enginestop;
  final bool directionIndicators;
  final bool gearboxSpeedsensor;
  final bool vehiclebatteryvoltage;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DeviceModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.ownerId,
    required this.phone,
    required this.numberPlate,
    required this.chassis,
    required this.make,
    required this.certNo,
    required this.type,
    required this.serial,
    required this.date,
    required this.agent,
    required this.agentID,
    required this.location,
    required this.email,
    required this.agentPhone,
    required this.businessReg,
    required this.technicianName,
    required this.deviceType,
    required this.certificateUrl,
    required this.certificateActiveStatus,
    this.certificateExpirey,
    required this.isDeviceOnline,
    required this.signalStrength,
    required this.createdBy,
    required this.updatedBy,
    required this.speed,
    required this.latitude,
    required this.longitude,
    required this.ignitionStatus,
    required this.headlights,
    required this.dashboardindicators,
    required this.revcounter,
    required this.enginestart,
    required this.enginestop,
    required this.directionIndicators,
    required this.gearboxSpeedsensor,
    required this.vehiclebatteryvoltage,
    this.createdAt,
    this.updatedAt,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      ownerId: json['ownerId'] ?? '',
      phone: json['phone'] ?? '',
      numberPlate: json['numberPlate'] ?? '',
      chassis: json['chassis'] ?? '',
      make: json['make'] ?? '',
      certNo: json['certNo'] ?? '',
      type: json['type'] ?? '',
      serial: json['serial'] ?? '',
      date: json['date'] ?? '',
      agent: json['agent'] ?? '',
      agentID: json['agentID'] ?? 0,
      location: json['location'] ?? '',
      email: json['email'] ?? '',
      agentPhone: json['agentPhone'] ?? '',
      businessReg: json['businessReg'] ?? '',
      technicianName: json['technicianName'] ?? '',
      deviceType: json['deviceType'] ?? '',
      certificateUrl: json['certificateUrl'] ?? '',
      certificateActiveStatus: json['certificateActiveStatus'] ?? false,
      certificateExpirey: json['certificateExpirey'] != null
          ? DateTime.tryParse(json['certificateExpirey'])
          : null,
      isDeviceOnline: json['isDeviceOnline'] ?? false,
      signalStrength: json['signalStrength'] ?? 0,
      createdBy: json['createdBy'] ?? '',
      updatedBy: json['updatedBy'] ?? '',
      speed: json['speed'] ?? 0,
      latitude: json['latitude'] ?? '',
      longitude: json['longitude'] ?? '',
      ignitionStatus: json['ignitionStatus'] ?? 0,
      headlights: json['headlights'] ?? false,
      dashboardindicators: json['dashboardindicators'] ?? false,
      revcounter: json['revcounter'] ?? false,
      enginestart: json['enginestart'] ?? false,
      enginestop: json['enginestop'] ?? false,
      directionIndicators: json['directionIndicators'] ?? false,
      gearboxSpeedsensor: json['gearboxSpeedsensor'] ?? false,
      vehiclebatteryvoltage: json['vehiclebatteryvoltage'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "userId": userId,
      "name": name,
      "ownerId": ownerId,
      "phone": phone,
      "numberPlate": numberPlate,
      "chassis": chassis,
      "make": make,
      "certNo": certNo,
      "type": type,
      "serial": serial,
      "date": date,
      "agent": agent,
      "agentID": agentID,
      "location": location,
      "email": email,
      "agentPhone": agentPhone,
      "businessReg": businessReg,
      "technicianName": technicianName,
      "deviceType": deviceType,
      "certificateUrl": certificateUrl,
      "certificateActiveStatus": certificateActiveStatus,
      "certificateExpirey": certificateExpirey?.toIso8601String(),
      "isDeviceOnline": isDeviceOnline,
      "signalStrength": signalStrength,
      "createdBy": createdBy,
      "updatedBy": updatedBy,
      "speed": speed,
      "latitude": latitude,
      "longitude": longitude,
      "ignitionStatus": ignitionStatus,
      "headlights": headlights,
      "dashboardindicators": dashboardindicators,
      "revcounter": revcounter,
      "enginestart": enginestart,
      "enginestop": enginestop,
      "directionIndicators": directionIndicators,
      "gearboxSpeedsensor": gearboxSpeedsensor,
      "vehiclebatteryvoltage": vehiclebatteryvoltage,
      "createdAt": createdAt?.toIso8601String(),
      "updatedAt": updatedAt?.toIso8601String(),
    };
  }
}

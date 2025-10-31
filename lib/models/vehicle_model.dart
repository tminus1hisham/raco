import 'dart:convert';

class DevicesModel {
  final List<Device> devices;
  final int totalDevices;
  final int onlineDevices;
  final int offlineDevices;
  final int activeCertificates;
  final int expiredCertificates;
  final int idle;
  final int stopped;
  final int inMotion;

  DevicesModel({
    required this.devices,
    required this.totalDevices,
    required this.onlineDevices,
    required this.offlineDevices,
    required this.activeCertificates,
    required this.expiredCertificates,
    required this.idle,
    required this.stopped,
    required this.inMotion,
  });

  factory DevicesModel.fromJson(Map<String, dynamic> json) {
    return DevicesModel(
      devices: (json['devices'] as List<dynamic>)
          .map((e) => Device.fromJson(e))
          .toList(),
      totalDevices: json['totalDevices'] ?? 0,
      onlineDevices: json['onlineDevices'] ?? 0,
      offlineDevices: json['offlineDevices'] ?? 0,
      activeCertificates: json['activeCertificates'] ?? 0,
      expiredCertificates: json['expiredCertificates'] ?? 0,
      idle: json['idle'] ?? 0,
      stopped: json['stopped'] ?? 0,
      inMotion: json['inMotion'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "devices": devices.map((e) => e.toJson()).toList(),
      "totalDevices": totalDevices,
      "onlineDevices": onlineDevices,
      "offlineDevices": offlineDevices,
      "activeCertificates": activeCertificates,
      "expiredCertificates": expiredCertificates,
      "idle": idle,
      "stopped": stopped,
      "inMotion": inMotion,
    };
  }

  static DevicesModel fromJsonString(String str) =>
      DevicesModel.fromJson(json.decode(str));

  String toJsonString() => json.encode(toJson());
}

class Device {
  final int id;
  final String deviceId;
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
  final String agentID;
  final String location;
  final String email;
  final String agentPhone;
  final String businessReg;
  final String technicianName;
  final String group;
  final String deviceType;
  final String certificateUrl;
  final bool certificateActiveStatus;
  final String certificateExpirey;
  final int signalStrength;
  final String createdBy;
  final String updatedBy;
  final String speed;
  final String latitude;
  final String longitude;
  final int ignitionStatus;
  final bool isDeviceOnline;
  final bool headlights;
  final bool dashboardIndicators;
  final bool revCounter;
  final bool engineStart;
  final bool engineStop;
  final bool directionIndicators;
  final bool gearboxSpeedSensor;
  final bool vehicleBatteryVoltage;
  final String createdAt;
  final String updatedAt;
  final String course;

  Device({
    required this.id,
    required this.deviceId,
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
    required this.group,
    required this.deviceType,
    required this.certificateUrl,
    required this.certificateActiveStatus,
    required this.certificateExpirey,
    required this.signalStrength,
    required this.createdBy,
    required this.updatedBy,
    required this.speed,
    required this.latitude,
    required this.longitude,
    required this.ignitionStatus,
    required this.isDeviceOnline,
    required this.headlights,
    required this.dashboardIndicators,
    required this.revCounter,
    required this.engineStart,
    required this.engineStop,
    required this.directionIndicators,
    required this.gearboxSpeedSensor,
    required this.vehicleBatteryVoltage,
    required this.createdAt,
    required this.updatedAt,
    required this.course,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'] ?? 0,
      deviceId: json['deviceId'] ?? "",
      userId: json['userId'] ?? "",
      name: json['name'] ?? "",
      ownerId: json['ownerId'] ?? "",
      phone: json['phone'] ?? "",
      numberPlate: json['numberPlate'] ?? "",
      chassis: json['chassis'] ?? "",
      make: json['make'] ?? "",
      certNo: json['certNo'] ?? "",
      type: json['type'] ?? "",
      serial: json['serial'] ?? "",
      date: json['date'] ?? "",
      agent: json['agent'] ?? "",
      agentID: json['agentID'] ?? "",
      location: json['location'] ?? "",
      email: json['email'] ?? "",
      agentPhone: json['agentPhone'] ?? "",
      businessReg: json['businessReg'] ?? "",
      technicianName: json['technicianName'] ?? "",
      group: json['group'] ?? "",
      deviceType: json['deviceType'] ?? "",
      certificateUrl: json['certificateUrl'] ?? "",
      certificateActiveStatus: json['certificateActiveStatus'] ?? false,
      certificateExpirey: json['certificateExpirey'] ?? "",
      signalStrength: json['signalStrength'] ?? 0,
      createdBy: json['createdBy'] ?? "",
      updatedBy: json['updatedBy'] ?? "",
      speed: json['speed'] ?? "0",
      latitude: json['latitude'] ?? "",
      longitude: json['longitude'] ?? "",
      ignitionStatus: json['ignitionStatus'] ?? 0,
      isDeviceOnline: json['isDeviceOnline'] ?? false,
      headlights: json['headlights'] ?? false,
      dashboardIndicators: json['dashboardindicators'] ?? false,
      revCounter: json['revcounter'] ?? false,
      engineStart: json['enginestart'] ?? false,
      engineStop: json['enginestop'] ?? false,
      directionIndicators: json['directionIndicators'] ?? false,
      gearboxSpeedSensor: json['gearboxSpeedsensor'] ?? false,
      vehicleBatteryVoltage: json['vehiclebatteryvoltage'] ?? false,
      createdAt: json['createdAt'] ?? "",
      updatedAt: json['updatedAt'] ?? "",
      course: json['course'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "deviceId": deviceId,
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
      "group": group,
      "deviceType": deviceType,
      "certificateUrl": certificateUrl,
      "certificateActiveStatus": certificateActiveStatus,
      "certificateExpirey": certificateExpirey,
      "signalStrength": signalStrength,
      "createdBy": createdBy,
      "updatedBy": updatedBy,
      "speed": speed,
      "latitude": latitude,
      "longitude": longitude,
      "ignitionStatus": ignitionStatus,
      "isDeviceOnline": isDeviceOnline,
      "headlights": headlights,
      "dashboardindicators": dashboardIndicators,
      "revcounter": revCounter,
      "enginestart": engineStart,
      "enginestop": engineStop,
      "directionIndicators": directionIndicators,
      "gearboxSpeedsensor": gearboxSpeedSensor,
      "vehiclebatteryvoltage": vehicleBatteryVoltage,
      "createdAt": createdAt,
      "updatedAt": updatedAt,
      "course": course,
    };
  }
}

class Certificate {
  final String company;
  final String name;
  final String id;
  final String phone;
  final String reg;
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
  final String group;

  Certificate({
    required this.company,
    required this.name,
    required this.id,
    required this.phone,
    required this.reg,
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
    required this.group,
  });

  /// Factory constructor to create a Certificate from JSON
  factory Certificate.fromJson(Map<String, dynamic> json) {
    return Certificate(
      company: json['company'] ?? '',
      name: json['Name'] ?? '',
      id: json['ID'] ?? '',
      phone: json['Phone'] ?? '',
      reg: json['reg'] ?? '',
      chassis: json['chassis'] ?? '',
      make: json['make'] ?? '',
      certNo: json['CertNo'] ?? '',
      type: json['Type'] ?? '',
      serial: json['serial'] ?? '',
      date: json['date'] ?? '',
      agent: json['agent'] ?? '',
      agentID: json['agentID'] ?? '',
      location: json['location'] ?? '',
      email: json['email'] ?? '',
      agentPhone: json['agentPhone'] ?? '',
      businessReg: json['businessReg'] ?? '',
      group: json['group'] ?? '',
    );
  }

  /// Converts the Certificate object back to JSON
  Map<String, dynamic> toJson() {
    return {
      'company': company,
      'Name': name,
      'ID': id,
      'Phone': phone,
      'reg': reg,
      'chassis': chassis,
      'make': make,
      'CertNo': certNo,
      'Type': type,
      'serial': serial,
      'date': date,
      'agent': agent,
      'agentID': agentID,
      'location': location,
      'email': email,
      'agentPhone': agentPhone,
      'businessReg': businessReg,
      'group': group,
    };
  }
}

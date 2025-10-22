class ReportModel {
  final int id;
  final String deviceId;
  final String sr;
  final int dt;
  final String spd;
  final String lg;
  final String ew;
  final String lt;
  final String ns;
  final String rg;
  final int ig;
  final int bt;
  final int en;
  final int wr;
  final int fx;
  final String course;
  final String vcc;
  final int vf;
  final int gsm;
  final String? sg;
  final int cl;
  final String imei;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReportModel({
    required this.id,
    required this.deviceId,
    required this.sr,
    required this.dt,
    required this.spd,
    required this.lg,
    required this.ew,
    required this.lt,
    required this.ns,
    required this.rg,
    required this.ig,
    required this.bt,
    required this.en,
    required this.wr,
    required this.fx,
    required this.course,
    required this.vcc,
    required this.vf,
    required this.gsm,
    required this.sg,
    required this.cl,
    required this.imei,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory method to create an instance from JSON
  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'],
      deviceId: json['deviceId'],
      sr: json['sr'],
      dt: json['dt'],
      spd: json['spd'].toString().trim(),
      lg: json['lg'],
      ew: json['ew'],
      lt: json['lt'],
      ns: json['ns'],
      rg: json['rg'],
      ig: json['ig'],
      bt: json['bt'],
      en: json['en'],
      wr: json['wr'],
      fx: json['fx'],
      course: json['course'].toString().trim(),
      vcc: json['vcc'].toString().trim(),
      vf: json['vf'],
      gsm: json['gsm'],
      sg: json['sg'] == "NULL" ? null : json['sg'],
      cl: json['cl'],
      imei: json['imei'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deviceId': deviceId,
      'sr': sr,
      'dt': dt,
      'spd': spd,
      'lg': lg,
      'ew': ew,
      'lt': lt,
      'ns': ns,
      'rg': rg,
      'ig': ig,
      'bt': bt,
      'en': en,
      'wr': wr,
      'fx': fx,
      'course': course,
      'vcc': vcc,
      'vf': vf,
      'gsm': gsm,
      'sg': sg,
      'cl': cl,
      'imei': imei,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Parse a list of JSON records
  static List<ReportModel> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => ReportModel.fromJson(json)).toList();
  }
}

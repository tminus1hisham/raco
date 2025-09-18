class IpLocationModel {
  final String ip;
  final String? country;
  final String? region;
  final String? city;
  final double? lat;
  final double? lon;
  final String? isp;

  IpLocationModel({
    required this.ip,
    this.country,
    this.region,
    this.city,
    this.lat,
    this.lon,
    this.isp,
  });

  factory IpLocationModel.fromIpApi(Map<String, dynamic> json) {
    return IpLocationModel(
      ip: json['query'] ?? '',
      country: json['country'],
      region: json['regionName'],
      city: json['city'],
      lat: (json['lat'] as num?)?.toDouble(),
      lon: (json['lon'] as num?)?.toDouble(),
      isp: json['isp'],
    );
  }

  @override
  String toString() {
    return "$city, $region, $country";
  }
}

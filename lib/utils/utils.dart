import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class Utils {
  /// Returns the great-circle distance in **metres** between two coordinates
  /// using the Haversine formula.
  static double haversineDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const R = 6371000.0; // Earth radius in metres
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static double _toRad(double deg) => deg * pi / 180;

  Future<String?> getLocalIpAddress() async {
    for (var interface in await NetworkInterface.list()) {
      for (var addr in interface.addresses) {
        if (addr.type == InternetAddressType.IPv4) {
          return addr.address;
        }
      }
    }
    return null;
  }

  Future<String?> getDeviceBrand() async {
    final deviceInfoPlugin = DeviceInfoPlugin();

    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        return androidInfo.brand;
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        return iosInfo.utsname.machine;
      }
    } catch (e) {
      print('Error getting device brand: $e');
    }
    return null;
  }

  String normalizePhoneNumber(String value) {
    value = value.trim().replaceAll(RegExp(r'[\s()+-]'), '');

    if (value.isEmpty) {
      return value;
    }

    if (value.startsWith("0")) {
      value = "254${value.substring(1)}";
    } else if (!value.startsWith("254")) {
      value = "254$value";
    }

    return value;
  }

  String formatDate(String isoDate) {
    try {
      DateTime parsedDate = DateTime.parse(isoDate);

      String formattedDate = DateFormat("MMM d, yyyy").format(parsedDate);

      return formattedDate;
    } catch (e) {
      return isoDate;
    }
  }

  String formatTime(String isoDate) {
    try {
      DateTime parsedDate = DateTime.parse(isoDate).toLocal();

      String formattedDate = DateFormat("hh:mm a").format(parsedDate);

      return formattedDate;
    } catch (e) {
      print("Error formatting time: $e");
      return isoDate;
    }
  }
}

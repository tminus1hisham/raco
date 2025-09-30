import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class Utils {
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
    value = value.trim();

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
}

import 'package:location/location.dart';

class LocationService {
  final Location _locationController = Location();

  Future<bool> requestLocationPermission() async {
    try {
      bool serviceEnabled = await _locationController.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _locationController.requestService();
        if (!serviceEnabled) {
          return false;
        }
      }

      PermissionStatus permissionGranted = await _locationController
          .hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _locationController.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          return false;
        }
      }

      return true;
    } catch (e) {
      print("Error requesting location permission: $e");
      return false;
    }
  }
}

// import 'package:geolocator/geolocator.dart';
//
// class LocationService {
//   Future<bool> requestLocationPermission() async {
//     try {
//       // Check if location services are enabled
//       bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//       if (!serviceEnabled) {
//         // Ask user to enable location services
//         await Geolocator.openLocationSettings();
//         // Re-check after user returns
//         serviceEnabled = await Geolocator.isLocationServiceEnabled();
//         if (!serviceEnabled) {
//           return false;
//         }
//       }
//
//       // Check current permission status
//       LocationPermission permission = await Geolocator.checkPermission();
//
//       if (permission == LocationPermission.denied) {
//         permission = await Geolocator.requestPermission();
//         if (permission == LocationPermission.denied) {
//           return false;
//         }
//       }
//
//       if (permission == LocationPermission.deniedForever) {
//         // Permissions are denied forever, direct user to app settings
//         await Geolocator.openAppSettings();
//         return false;
//       }
//
//       // Permission granted
//       return true;
//     } catch (e) {
//       print("Error requesting location permission: $e");
//       return false;
//     }
//   }
//
//   Future<Position?> getCurrentLocation() async {
//     try {
//       bool hasPermission = await requestLocationPermission();
//       if (!hasPermission) return null;
//
//       Position position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//       );
//       return position;
//     } catch (e) {
//       print("Error getting current location: $e");
//       return null;
//     }
//   }
// }

import 'dart:ui' as ui;

import 'package:atom/config/constants.dart';
import 'package:atom/widgets/custom_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle, ByteData;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class VehicleLocationScreen extends StatefulWidget {
  final double latitude;
  final double longitude;

  const VehicleLocationScreen({
    Key? key,
    required this.latitude,
    required this.longitude,
  }) : super(key: key);

  @override
  State<VehicleLocationScreen> createState() => _VehicleLocationScreenState();
}

class _VehicleLocationScreenState extends State<VehicleLocationScreen> {
  GoogleMapController? mapController;
  late LatLng position;
  BitmapDescriptor? carIcon;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    position = LatLng(widget.latitude, widget.longitude);
    _loadCarIcon();
  }

  Future<void> _loadCarIcon() async {
    carIcon = await _resizeAndLoadIcon('assets/green_car.png', 140);
    setState(() {
      isLoading = false;
    });
  }

  Future<BitmapDescriptor> _resizeAndLoadIcon(
    String assetPath,
    int width,
  ) async {
    final ByteData data = await rootBundle.load(assetPath);
    final ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
    );
    final ui.FrameInfo fi = await codec.getNextFrame();
    final ByteData? bytes = await fi.image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? Center(
              child: LoadingAnimationWidget.threeArchedCircle(
                color: kBlue,
                size: 50,
              ),
            )
          : Stack(
              children: [
                Positioned.fill(
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: position,
                      zoom: 15,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId("vehicle_marker"),
                        position: position,
                        icon: carIcon ?? BitmapDescriptor.defaultMarker,
                        infoWindow: const InfoWindow(title: "Vehicle"),
                      ),
                    },
                    onMapCreated: (controller) {
                      mapController = controller;
                    },
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: true,
                  ),
                ),

                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  left: 0,
                  right: 0,
                  child: customHeader(
                    label: "Live Location",
                    icon: Icons.drive_eta_rounded,
                    showBackButton: true,
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

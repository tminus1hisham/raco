import 'package:atom/config/constants.dart';
import 'package:atom/controllers/renew_certificate_controller.dart';
import 'package:atom/models/vehicle_model.dart';
import 'package:atom/routes/routes.dart';
import 'package:atom/services/local_storage_service.dart';
import 'package:atom/utils/utils.dart';
import 'package:atom/views/cars/commands.dart';
import 'package:atom/views/cars/driver_behaviour.dart';
import 'package:atom/views/cars/geofencing_screen.dart';
import 'package:atom/views/cars/vehicle_details.dart';
import 'package:atom/views/cars/vehicle_live_location.dart';
import 'package:atom/views/playback_screen.dart';
import 'package:atom/views/reports_screen.dart';
import 'package:atom/views/violations_screen.dart';
import 'package:atom/widgets/custom_header.dart';
import 'package:atom/widgets/inputs/custom_input.dart';
import 'package:atom/widgets/modal/custom_alert.dart';
import 'package:atom/widgets/modal/infomation_modal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class SelectedCarScreen extends StatefulWidget {
  final String carModel;
  final String licensePlate;
  final Device devices;

  const SelectedCarScreen({
    super.key,
    required this.carModel,
    required this.licensePlate,
    required this.devices,
  });

  @override
  State<SelectedCarScreen> createState() => _SelectedCarScreenState();
}

class _SelectedCarScreenState extends State<SelectedCarScreen> {
  final _utils = Utils();
  final TextEditingController _phoneNumberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchPhoneNumber();
  }

  final RenewCertificateController _controller = Get.put(
    RenewCertificateController(),
  );

  void fetchPhoneNumber() async {
    final savedPhone = await StorageService.getData('phone');

    setState(() {
      if (savedPhone != null && savedPhone.isNotEmpty) {
        _phoneNumberController.text = savedPhone;
      }
    });
  }

  bool _isCertificateExpired(String expiryDate) {
    try {
      final parsedDate = DateTime.parse(expiryDate);
      final now = DateTime.now();

      return parsedDate.isBefore(now) || parsedDate.isAtSameMomentAs(now);
    } catch (e) {
      return true;
    }
  }

  void _showPlanBottomSheet(BuildContext context) {
    showModalBottomSheet(
      backgroundColor: kWhite,
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        int? selectedIndex;

        return Obx(() {
          if (_controller.isLoading.value) {
            return const Padding(
              padding: EdgeInsets.all(40.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final plans = _controller.plans;

          if (plans.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(40.0),
              child: Center(child: Text("No plans available.")),
            );
          }

          //  Use DraggableScrollableSheet for min height = half screen
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.5,
            // starts at half screen
            minChildSize: 0.5,
            // cannot shrink below half
            maxChildSize: 0.9,
            // can expand up to 90%
            builder: (context, scrollController) {
              return StatefulBuilder(
                builder: (context, setState) {
                  return Padding(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 20,
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: ListView(
                      controller: scrollController,
                      children: [
                        Center(
                          child: Container(
                            height: 5,
                            width: 40,
                            decoration: BoxDecoration(
                              color: Colors.grey[400],
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Select a Plan",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        InputField(
                          hintText: 'Phone number',
                          prefixIcon: Icons.phone,
                          controller: _phoneNumberController,
                          isRequired: true,
                          integerOnly: true,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "This filed is required";
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 10),

                        ...List.generate(plans.length, (index) {
                          final plan = plans[index];
                          final isSelected = selectedIndex == index;
                          return GestureDetector(
                            onTap: () {
                              setState(() => selectedIndex = index);
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? kBlue.withOpacity(0.1)
                                    : Colors.white,
                                border: Border.all(
                                  color: isSelected ? kBlue : Colors.grey[300]!,
                                  width: isSelected ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_off,
                                    color: isSelected ? kBlue : Colors.grey,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          plan.planName.isNotEmpty
                                              ? plan.planName
                                              : "Unnamed Plan",
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "${plan.durationInDays} ${plan.durationInDays > 1 ? 'Years' : 'Year'}",
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    "KES ${plan.price}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),

                        const SizedBox(height: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          onPressed: selectedIndex != null
                              ? () async {
                                  Navigator.pop(context);

                                  final parentContext = this.context;

                                  showCupertinoDialog(
                                    context: parentContext,
                                    builder: (context) => ActionDialog(
                                      title: "Renew Certificate",
                                      message:
                                          "Do you want to proceed with renewing your certificate using the ${plans[selectedIndex!].planName}?",
                                      confirmText: "Renew",
                                      cancelText: "Cancel",
                                      onConfirm: () async {
                                        bool success = await _controller
                                            .renewCertificate(
                                              parentContext,
                                              widget.licensePlate,
                                              _phoneNumberController.text
                                                  .trim(),
                                              plans[selectedIndex!].price
                                                  .toInt(),
                                            );

                                        if (!mounted) return;

                                        if (success) {
                                          CustomAlertDialog(
                                            context: parentContext,
                                            title: "Success",
                                            message:
                                                "Payment request successful, please pay to renew your certificate",
                                            icon:
                                                "assets/animations/Success.json",
                                            buttonColor: kSuccessGreen,
                                          );
                                        } else {
                                          CustomAlertDialog(
                                            context: parentContext,
                                            title: "Error",
                                            message: "Payment request failed.",
                                            icon:
                                                "assets/animations/Failed.json",
                                            buttonColor: kRed,
                                          );
                                        }
                                      },
                                    ),
                                  );
                                }
                              : null,

                          child: const Text(
                            "Renew",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  );
                },
              );
            },
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isVehicleActive = widget.devices.ignitionStatus == 0;
    return Obx(
      () => Scaffold(
        backgroundColor: kBgGrey,
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 10),
                  customHeader(
                    label: widget.licensePlate,
                    icon: Icons.drive_eta_rounded,
                    showBackButton: true,
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  Expanded(
                    child: ListView(
                      children: [
                        SizedBox(height: 16),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Quick Actions',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: kGrey,
                                    ),
                                  ),
                                  StatefulBuilder(
                                    builder: (context, setModalState) {
                                      return Row(
                                        children: [
                                          Text(
                                            isVehicleActive
                                                ? "ENGINE ON"
                                                : " ENGINE OFF",
                                            style: TextStyle(
                                              fontSize: 15,
                                              color: isVehicleActive
                                                  ? Colors.green
                                                  : Colors.grey[600],
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          SizedBox(width: 10),
                                          Switch(
                                            value: isVehicleActive,
                                            onChanged: (bool value) {},
                                            activeColor: Colors.green,
                                            activeTrackColor: Colors.green
                                                .withOpacity(0.3),
                                            inactiveThumbColor: Colors.grey,
                                            inactiveTrackColor: Colors.grey
                                                .withOpacity(0.3),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildQuickActionButton(
                                      title: 'Vehicle Safety',
                                      icon: Icons.safety_check_outlined,
                                      color: Colors.green,
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                DriverBehaviour(),
                                          ),
                                        );
                                      },
                                    ),
                                  ),

                                  SizedBox(width: 12),
                                  Expanded(
                                    child: _buildQuickActionButton(
                                      title: 'Location History',
                                      icon: Icons.route,
                                      color: kBlue,
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                PlaybackScreen(
                                                  numberPlate: widget
                                                      .devices
                                                      .numberPlate,
                                                ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: _buildQuickActionButton(
                                      title: 'violations',
                                      icon: Icons.warning_amber,
                                      color: kRed,
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                ViolationsScreen(
                                                  numberPlate: widget
                                                      .devices
                                                      .numberPlate,
                                                ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Vehicle Management',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: kGrey,
                                ),
                              ),
                              SizedBox(height: 16),
                              _buildSettingsCard(
                                child: Column(
                                  children: [
                                    _buildCommandItem(
                                      showBanner: false,
                                      title: 'Details',
                                      subtitle:
                                          "View a detailed infomation of the vehicle.",
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                VehicleDetails(
                                                  vehiclePlate: "KDG001A",
                                                  device: widget.devices,
                                                ),
                                          ),
                                        );
                                      },
                                    ),
                                    _buildDivider(),
                                    _buildCommandItem(
                                      showBanner: false,
                                      title: 'Commands',
                                      subtitle:
                                          "View all the commands of a vehicle.",
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => Commands(),
                                          ),
                                        );
                                      },
                                    ),
                                    _buildDivider(),
                                    _buildCommandItem(
                                      showBanner: false,
                                      title: 'Command History',
                                      subtitle:
                                          "View all the commands actioned.",
                                      onTap: () {
                                        Navigator.pushNamed(
                                          context,
                                          AppRoutes.commandHistory,
                                        );
                                      },
                                    ),
                                    _buildDivider(),
                                    _buildCommandItem(
                                      showBanner: false,
                                      title: 'Geo Fence',
                                      subtitle:
                                          "Set a radius where your car to operate.",
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                GeofencingScreen(
                                                  numberPlate:
                                                      widget.licensePlate,
                                                ),
                                          ),
                                        );
                                      },
                                    ),
                                    _buildDivider(),
                                    _buildCommandItem(
                                      showBanner: false,
                                      title: 'View Live Location',
                                      subtitle:
                                          "See your the vehicle live location.",
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                VehicleLocationScreen(
                                                  deviceId:
                                                      widget.devices.deviceId,
                                                  latitude:
                                                      double.tryParse(
                                                        widget.devices.latitude,
                                                      ) ??
                                                      0.0,
                                                  longitude:
                                                      double.tryParse(
                                                        widget
                                                            .devices
                                                            .longitude,
                                                      ) ??
                                                      0.0,
                                                ),
                                          ),
                                        );
                                      },
                                    ),
                                    _buildDivider(),
                                    _buildCommandItem(
                                      showBanner: false,
                                      title: 'Reports',
                                      subtitle: "See all the reports.",
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ReportsScreen(
                                              numberPlate: widget.licensePlate,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    _buildDivider(),
                                    _buildCommandItem(
                                      showBanner: _isCertificateExpired(
                                        widget.devices.certificateExpirey,
                                      ),
                                      title: 'Certificate',
                                      subtitle:
                                          'Expiry: ${_utils.formatDate(widget.devices.certificateExpirey)}',
                                      onTap: () {
                                        _showPlanBottomSheet(context);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_controller.isLoading.value)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: LoadingAnimationWidget.fourRotatingDots(
                    color: kBlue,
                    size: 50,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required Widget child, VoidCallback? onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: child,
        ),
      ),
    );
  }

  Widget _buildCommandItem({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool showBanner,
    Color? textColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textColor ?? Colors.black87,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                if (showBanner) ...[
                  Container(
                    decoration: BoxDecoration(
                      color: kRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    child: Text(
                      "Expired",
                      style: TextStyle(
                        color: kRed,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  SizedBox(width: 5),
                ],

                Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(height: 1, color: Colors.grey.shade100);
  }

  Widget _buildQuickActionButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              spreadRadius: 1,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

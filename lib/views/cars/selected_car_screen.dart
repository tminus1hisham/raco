import 'package:atom/config/app_theme.dart';
import 'package:atom/config/constants.dart';
import 'package:atom/services/api_service.dart';
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
  bool _engineToggling = false;
  bool? _localEngineOn; // optimistic local state while API request is in flight

  @override
  void initState() {
    super.initState();
    fetchPhoneNumber();
  }

  final RenewCertificateController _controller = Get.put(
    RenewCertificateController(),
  );

  @override
  void dispose() {
    _phoneNumberController.dispose();
    super.dispose();
  }

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

  Future<void> _toggleEngine(bool turnOn) async {
    if (_engineToggling) return;
    setState(() {
      _engineToggling = true;
      _localEngineOn = turnOn;
    });
    try {
      final success = await ApiService.sendEngineCommand(
        widget.devices.numberPlate,
        turnOn,
      );
      if (!success && mounted) {
        setState(() => _localEngineOn = !turnOn);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${turnOn ? 'start' : 'stop'} engine. Please try again.'),
            backgroundColor: kRed,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _localEngineOn = !turnOn);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Network error. Please check your connection.'),
            backgroundColor: kRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _engineToggling = false);
    }
  }

  void _showPlanBottomSheet(BuildContext context) {
    final col = context.col;
    showModalBottomSheet(
      backgroundColor: col.surface,
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(kRadiusLG)),
      ),
      builder: (context) {
        final sheetCol = context.col;
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

          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.5,
            minChildSize: 0.5,
            maxChildSize: 0.9,
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
                              color: sheetCol.border,
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
                              return "This field is required";
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
                                    ? kBlue.withValues(alpha: 0.1)
                                    : sheetCol.surface,
                                border: Border.all(
                                  color: isSelected ? kBlue : sheetCol.border,
                                  width: isSelected ? 2 : 1,
                                ),
                                borderRadius:
                                    BorderRadius.circular(kRadiusMD),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_off,
                                    color:
                                        isSelected ? kBlue : sheetCol.textSecondary,
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
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: sheetCol.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "${plan.durationInDays} ${plan.durationInDays > 1 ? 'Years' : 'Year'}",
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: sheetCol.textSecondary,
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
                              borderRadius:
                                  BorderRadius.circular(kRadiusSM),
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
                                              plans[selectedIndex!].id.toInt(),
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
                                            message:
                                                "Payment request failed.",
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
                            style: TextStyle(fontSize: 16, color: kWhite),
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
    final col = context.col;
    final isVehicleActive = _localEngineOn ?? (widget.devices.ignitionStatus == 0);
    final isOnline = widget.devices.isDeviceOnline;
    final isCertificateExpired = _isCertificateExpired(
      widget.devices.certificateExpirey,
    );
    final signalStrength = "${widget.devices.signalStrength}%";
    final vehicleSpeed = "${widget.devices.speed} km/h";
    final vehicleLocation = widget.devices.location.trim().isEmpty
        ? "Location unavailable"
        : widget.devices.location;

    return Obx(
      () => Scaffold(
        backgroundColor: col.bg,
        body: Stack(
          children: [
            SafeArea(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  const SizedBox(height: 10),
                  customHeader(
                    label: widget.licensePlate,
                    icon: Icons.drive_eta_rounded,
                    showBackButton: true,
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildVehicleHeroCard(
                          isOnline: isOnline,
                          isVehicleActive: isVehicleActive,
                          isCertificateExpired: isCertificateExpired,
                          signalStrength: signalStrength,
                          vehicleSpeed: vehicleSpeed,
                          vehicleLocation: vehicleLocation,
                        ),
                        const SizedBox(height: 12),
                        _buildEngineControlCard(col, isVehicleActive),
                        const SizedBox(height: 24),
                        _buildSectionHeader(
                          col: col,
                          title: 'Quick Actions',
                          subtitle: 'Shortcuts for the things you use most',
                        ),
                        const SizedBox(height: 16),
                        Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildQuickActionButton(
                                    col: col,
                                    title: 'Vehicle Safety',
                                    description: 'Driving behaviour and safety trends',
                                    icon: Icons.safety_check_outlined,
                                    color: kSuccessGreen,
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => DriverBehaviour(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildQuickActionButton(
                                    col: col,
                                    title: 'Location History',
                                    description: 'Replay routes and recent movement',
                                    icon: Icons.route,
                                    color: kBlue,
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => PlaybackScreen(
                                            numberPlate: widget.devices.numberPlate,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildQuickActionButton(
                                    col: col,
                                    title: 'Violations',
                                    description: 'Review alerts and risk events',
                                    icon: Icons.warning_amber_rounded,
                                    color: kRed,
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ViolationsScreen(
                                            numberPlate: widget.devices.numberPlate,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildQuickActionButton(
                                    col: col,
                                    title: 'Live Location',
                                    description: 'Open the latest position on the map',
                                    icon: Icons.my_location_rounded,
                                    color: Colors.orange,
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => VehicleLocationScreen(
                                            deviceId: widget.devices.deviceId,
                                            latitude:
                                                double.tryParse(widget.devices.latitude) ??
                                                0.0,
                                            longitude:
                                                double.tryParse(widget.devices.longitude) ??
                                                0.0,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildSectionHeader(
                          col: col,
                          title: 'Vehicle Management',
                          subtitle: 'Configuration, monitoring and reporting',
                        ),
                        const SizedBox(height: 16),
                        _buildSettingsCard(
                          col: col,
                          child: Column(
                            children: [
                              _buildCommandItem(
                                col: col,
                                icon: Icons.info_outline_rounded,
                                showBanner: false,
                                title: 'Details',
                                subtitle:
                                    "View detailed information of the vehicle.",
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => VehicleDetails(
                                        vehiclePlate: widget.licensePlate,
                                        device: widget.devices,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              _buildDivider(col),
                              _buildCommandItem(
                                col: col,
                                icon: Icons.tune_rounded,
                                showBanner: false,
                                title: 'Commands',
                                subtitle: "View all the commands of a vehicle.",
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => Commands(),
                                    ),
                                  );
                                },
                              ),
                              _buildDivider(col),
                              _buildCommandItem(
                                col: col,
                                icon: Icons.history_toggle_off_rounded,
                                showBanner: false,
                                title: 'Command History',
                                subtitle: "View all the commands actioned.",
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.commandHistory,
                                  );
                                },
                              ),
                              _buildDivider(col),
                              _buildCommandItem(
                                col: col,
                                icon: Icons.gps_fixed_rounded,
                                showBanner: false,
                                title: 'Geo Fence',
                                subtitle:
                                    "Set a radius where your car to operate.",
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => GeofencingScreen(
                                        numberPlate: widget.licensePlate,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              _buildDivider(col),
                              _buildCommandItem(
                                col: col,
                                icon: Icons.place_outlined,
                                showBanner: false,
                                title: 'View Live Location',
                                subtitle: "See the vehicle live location.",
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => VehicleLocationScreen(
                                        deviceId: widget.devices.deviceId,
                                        latitude:
                                            double.tryParse(widget.devices.latitude) ??
                                            0.0,
                                        longitude:
                                            double.tryParse(
                                                  widget.devices.longitude,
                                                ) ??
                                                0.0,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              _buildDivider(col),
                              _buildCommandItem(
                                col: col,
                                icon: Icons.bar_chart_rounded,
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
                              _buildDivider(col),
                              _buildCommandItem(
                                col: col,
                                icon: Icons.verified_outlined,
                                showBanner: isCertificateExpired,
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_controller.isLoading.value)
              Container(
                color: Colors.black.withValues(alpha: 0.3),
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

  Widget _buildEngineControlCard(AppColors col, bool isEngineOn) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: col.surface,
        borderRadius: BorderRadius.circular(kRadiusMD),
        boxShadow: [kShadowSM],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: (isEngineOn ? kSuccessGreen : kRed).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isEngineOn ? Icons.power_rounded : Icons.power_off_rounded,
              color: isEngineOn ? kSuccessGreen : kRed,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Engine Control',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: col.textPrimary,
                  ),
                ),
                Text(
                  isEngineOn ? 'Engine is currently running' : 'Engine is currently off',
                  style: TextStyle(fontSize: 13, color: col.textSecondary),
                ),
              ],
            ),
          ),
          if (_engineToggling)
            const SizedBox(
              width: 36,
              height: 24,
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            Switch(
              value: isEngineOn,
              onChanged: _toggleEngine,
              activeColor: kSuccessGreen,
            ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(
      {required AppColors col,
      required Widget child,
      VoidCallback? onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: col.surface,
        borderRadius: BorderRadius.circular(kRadiusMD),
        boxShadow: [kShadowSM],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(kRadiusMD),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(kRadiusMD),
          child: child,
        ),
      ),
    );
  }

  Widget _buildVehicleHeroCard({
    required bool isOnline,
    required bool isVehicleActive,
    required bool isCertificateExpired,
    required String signalStrength,
    required String vehicleSpeed,
    required String vehicleLocation,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            kBlue,
            kBlue.withValues(alpha: 0.82),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(kRadiusLG),
        boxShadow: [kShadowMD],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: kWhite.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.directions_car_filled_rounded,
                  color: kWhite,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.carModel,
                      style: const TextStyle(
                        color: kWhite,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.devices.make.isNotEmpty
                          ? widget.devices.make
                          : "Tracked vehicle",
                      style: TextStyle(
                        color: kWhite.withValues(alpha: 0.82),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStatusChip(
                label: isOnline ? 'Online' : 'Offline',
                color: isOnline ? kSuccessGreen : Colors.orange,
              ),
              _buildStatusChip(
                label: isVehicleActive ? 'Engine On' : 'Engine Off',
                color: isVehicleActive ? kSuccessGreen : Colors.white70,
              ),
              _buildStatusChip(
                label: isCertificateExpired
                    ? 'Certificate Expired'
                    : 'Certificate Active',
                color: isCertificateExpired ? const Color(0xFFFFC857) : kWhite,
                textColor: isCertificateExpired ? kBlack : kBlue,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _buildInfoStat(
                  label: 'Speed',
                  value: vehicleSpeed,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoStat(
                  label: 'Signal',
                  value: signalStrength,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: kWhite.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(kRadiusMD),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.location_on_outlined,
                    color: kWhite,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    vehicleLocation,
                    style: const TextStyle(
                      color: kWhite,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required AppColors col,
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: col.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: col.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip({
    required String label,
    required Color color,
    Color textColor = kWhite,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(kRadiusPill),
        border: Border.all(
          color: color.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildInfoStat({
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kWhite.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(kRadiusMD),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: kWhite.withValues(alpha: 0.72),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: kWhite,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommandItem({
    required AppColors col,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool showBanner,
    Color? textColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: kBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: kBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textColor ?? col.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: col.textSecondary),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                if (showBanner) ...[
                  Container(
                    decoration: BoxDecoration(
                      color: kRed.withValues(alpha: 0.1),
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
                  color: col.border,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(AppColors col) {
    return Container(height: 1, color: col.divider);
  }

  Widget _buildQuickActionButton({
    required AppColors col,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: col.surface,
          borderRadius: BorderRadius.circular(kRadiusMD),
          boxShadow: [kShadowSM],
          border: Border.all(
            color: color.withValues(alpha: 0.12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: col.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                color: col.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

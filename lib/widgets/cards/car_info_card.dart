import 'package:atom/config/app_theme.dart';
import 'package:atom/config/constants.dart';
import 'package:atom/controllers/renew_certificate_controller.dart';
import 'package:atom/services/local_storage_service.dart';
import 'package:atom/widgets/inputs/custom_input.dart';
import 'package:atom/widgets/modal/custom_alert.dart';
import 'package:atom/widgets/modal/infomation_modal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CarInfoCard extends StatefulWidget {
  final String carModel;
  final String licensePlate;
  final IconData carIcon;
  final String status;
  final Color statusColor;
  final Color statusBackgroundColor;
  final String currentSpeed;
  final String topSpeed;
  final VoidCallback onPressed;
  final bool isAdmin;
  final String expiryDate;

  const CarInfoCard({
    super.key,
    required this.carModel,
    required this.licensePlate,
    this.carIcon = Icons.directions_car_rounded,
    required this.status,
    this.statusColor = kSuccessGreen,
    this.statusBackgroundColor = const Color(0xFFE8F5E8),
    required this.currentSpeed,
    required this.topSpeed,
    required this.onPressed,
    required this.isAdmin,
    required this.expiryDate,
  });

  @override
  State<CarInfoCard> createState() => _CarInfoCardState();
}

class _CarInfoCardState extends State<CarInfoCard> {
  @override
  void initState() {
    super.initState();
    fetchPhoneNumber();
  }

  final RenewCertificateController _controller = Get.put(
    RenewCertificateController(),
  );

  final TextEditingController _phoneNumberController = TextEditingController();

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
      backgroundColor: context.col.surface,
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(kRadiusLG)),
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
                              color: context.col.border,
                              borderRadius: BorderRadius.circular(kRadiusPill),
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
                                    : context.col.surface,
                                border: Border.all(
                                  color: isSelected ? kBlue : kLightGrey,
                                  width: isSelected ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(kRadiusMD),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_off,
                                    color: isSelected ? kBlue : kLightGrey,
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
                                            color: context.col.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "${plan.durationInDays} ${plan.durationInDays > 1 ? 'Years' : 'Year'}",
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: context.col.textSecondary,
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
                              borderRadius: BorderRadius.circular(kRadiusMD),
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
    return Padding(
      padding: const EdgeInsets.only(
        left: kSpaceXL,
        right: kSpaceXL,
        top: kSpaceSM,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: kSpaceXL,
          vertical: kSpaceLG,
        ),
        decoration: BoxDecoration(
          color: context.col.surface,
          borderRadius: BorderRadius.circular(kRadiusLG),
          boxShadow: [kShadowSM],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Only this Row is tappable
            InkWell(
              onTap: widget.onPressed,
              borderRadius: BorderRadius.circular(kRadiusLG),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  widget.licensePlate,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: context.col.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: kSpaceSM),
                                Text(
                                  widget.carModel,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: context.col.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              widget.currentSpeed,
                              style: TextStyle(
                                fontSize: 14,
                                color: context.col.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: kSpaceSM),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: kSpaceLG,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: widget.statusBackgroundColor,
                                borderRadius: BorderRadius.circular(
                                  kRadiusPill,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: widget.statusColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    widget.status,
                                    style: TextStyle(
                                      color: widget.statusColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_isCertificateExpired(widget.expiryDate))
                              SizedBox(
                                child: ElevatedButton(
                                  onPressed: () =>
                                      _showPlanBottomSheet(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kSuccessGreen,
                                    foregroundColor: kWhite,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 2,
                                      horizontal: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        kRadiusMD,
                                      ),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: const Text(
                                    'Renew Certificate',
                                    style: TextStyle(
                                      color: kWhite,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                          ],
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
    );
  }
}

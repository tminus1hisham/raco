import 'dart:math';

import 'package:atom/config/constants.dart';
import 'package:atom/controllers/auth_controller.dart';
import 'package:atom/controllers/user_controller.dart';
import 'package:atom/services/local_storage_service.dart';
import 'package:atom/utils/utils.dart';
import 'package:atom/views/transport%20%20managers/manager_car_list.dart';
import 'package:atom/widgets/cards/manager_info_card.dart';
import 'package:atom/widgets/custom_header.dart';
import 'package:atom/widgets/inputs/custom_input.dart';
import 'package:atom/widgets/modal/custom_alert.dart';
import 'package:atom/widgets/modal/infomation_modal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class ManagerScreen extends StatefulWidget {
  const ManagerScreen({super.key});

  @override
  State<ManagerScreen> createState() => _ManagerScreenState();
}

class _ManagerScreenState extends State<ManagerScreen> {
  final AuthController authController = Get.put(AuthController());
  final UserResourceController userController = Get.put(
    UserResourceController(),
  );

  @override
  void initState() {
    super.initState();
    userController.fetchUsers();
  }

  void _showAddManagerBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddManagerBottomSheet(
        onManagerAdded: (manager) {
          setState(() {
            // managers.add(manager);
          });
        },
      ),
    );
  }

  Widget _buildSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 4),
      itemCount: 6,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 12),
        child: Container(
          height: 84,
          decoration: BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.circular(kRadiusLG),
            border: Border.all(color: kDivider),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: kInputBg,
                  borderRadius: BorderRadius.circular(kRadiusMD),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 140,
                      height: 14,
                      decoration: BoxDecoration(
                        color: kInputBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: 100,
                      height: 12,
                      decoration: BoxDecoration(
                        color: kInputBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: kBlue.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.people_outline,
                      color: kBlue,
                      size: 44,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "No managers yet",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: kBlack,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Add your first transport manager to\nget started.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: kGrey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _showAddManagerBottomSheet,
                    icon: Icon(Icons.add, color: kWhite, size: 20),
                    label: Text(
                      "Add Manager",
                      style: TextStyle(
                        color: kWhite,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kBlue,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(kRadiusMD),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        backgroundColor: kBgGrey,
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  SizedBox(height: 10),
                  customHeader(
                    label: "Managers",
                    icon: Icons.people_outline,
                    showBackButton: true,
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  if (!userController.isLoading.value &&
                      userController.users.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                      child: Row(
                        children: [
                          Text(
                            "${userController.users.length} "
                            "${userController.users.length == 1 ? 'manager' : 'managers'}",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: kGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => userController.fetchUsers(),
                      color: kBlue,
                      child:
                          userController.isLoading.value &&
                              userController.users.isEmpty
                          ? _buildSkeletonList()
                          : userController.users.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 100, top: 4),
                        itemCount: userController.users.length,
                        itemBuilder: (context, index) {
                          final manager = userController.users[index];
                          return ManagerInfoCard(
                            fullName: manager.fullName,
                            phoneNumber: manager.phoneNumber,
                            emailAddress: manager.emailAddress,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ManagerCarListScreen(),
                                ),
                              );
                            },
                            onDelete: () {
                              showCupertinoDialog(
                                context: context,
                                builder: (context) => ActionDialog(
                                  title: "Delete",
                                  message:
                                      "Are you sure you want to delete ${manager.fullName} ?",
                                  confirmText: "Delete",
                                  cancelText: "Cancel",
                                  onConfirm: () {
                                    authController.deleteUser(manager.id).then((
                                      success,
                                    ) {
                                      if (success) {
                                        Navigator.pop(context); // Close dialog
                                        CustomAlertDialog(
                                          context: context,
                                          title: "Success",
                                          message:
                                              "Manager deleted successfully.",
                                          icon:
                                              "assets/animations/Success.json",
                                          buttonColor: kSuccessGreen,
                                        );
                                      } else {
                                        Navigator.pop(context); // Close dialog
                                        CustomAlertDialog(
                                          context: context,
                                          title: "Error",
                                          message: "Failed to delete manager.",
                                          icon: "assets/animations/Failed.json",
                                          buttonColor: kRed,
                                        );
                                      }
                                    });
                                    setState(() {
                                      userController.users.removeAt(index);
                                    });
                                  },
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (authController.isLoading.value)
              Container(
                color: kBlack.withValues(alpha: 0.3),
                child: Center(
                  child: LoadingAnimationWidget.fourRotatingDots(
                    color: kBlue,
                    size: 50,
                  ),
                ),
              ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showAddManagerBottomSheet,
          backgroundColor: kBlue,
          elevation: 2,
          icon: Icon(Icons.add, color: kWhite),
          label: Text(
            "Add Manager",
            style: TextStyle(
              color: kWhite,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class AddManagerBottomSheet extends StatefulWidget {
  final Function(Manager) onManagerAdded;

  const AddManagerBottomSheet({super.key, required this.onManagerAdded});

  @override
  State<AddManagerBottomSheet> createState() => _AddManagerBottomSheetState();
}

class _AddManagerBottomSheetState extends State<AddManagerBottomSheet> {
  final UserResourceController userController = Get.put(
    UserResourceController(),
  );
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String adminPhone = '';

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    fetchAdminPhone();
    userController.fetchUsers();
  }

  final utils = Utils();

  final AuthController authController = Get.put(AuthController());

  String generateFourDigitCode() {
    final random = Random();
    int code = 1000 + random.nextInt(9000);
    return code.toString();
  }

  Future fetchAdminPhone() async {
    setState(() async {
      adminPhone = await StorageService.getData('phone');
    });
  }

  Future<bool> _handleSignUp() async {
    authController.fullName.value = _fullNameController.text;
    authController.emailAddress.value = _emailController.text;
    authController.password.value = generateFourDigitCode();
    authController.phoneNumber.value = utils.normalizePhoneNumber(
      _phoneController.text,
    );
    authController.userRole.value = 'Manager';
    authController.userFirebaseToken.value = 'string';
    authController.adminPhoneNumber.value = adminPhone;

    bool success = await authController.register(context);

    if (success) {
      await CustomAlertDialog(
        context: context,
        title: "Success",
        message: "You have successfully added a manager",
        icon: "assets/animations/Success.json",
        buttonColor: kSuccessGreen,
      );
      // Refresh user list
      userController.fetchUsers();
    } else {
      await CustomAlertDialog(
        context: context,
        title: "Error",
        message: "Failed to register, this number is already registered.",
        icon: "assets/animations/Failed.json",
        buttonColor: kRed,
      );
    }

    return success;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(kRadiusPill),
          topRight: Radius.circular(kRadiusPill),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: kLightGrey,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: kBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.person_add_outlined,
                        color: kBlue,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 20),
                    Text(
                      'Add New Manager',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: kBlack,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),

                InputField(
                  hintText: 'Full Name',
                  controller: _fullNameController,
                  prefixIcon: Icons.person_outline,
                  isRequired: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Full name is required';
                    }
                    if (value.trim().length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                ),

                InputField(
                  hintText: 'Phone Number',
                  controller: _phoneController,
                  prefixIcon: Icons.phone_outlined,
                  isRequired: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Phone number is required';
                    }
                    if (!RegExp(r'^\+?[0-9]{10,15}$').hasMatch(value.trim())) {
                      return 'Enter a valid phone number';
                    }
                    return null;
                  },
                ),

                InputField(
                  hintText: 'Email Address',
                  controller: _emailController,
                  prefixIcon: Icons.email_outlined,
                  isRequired: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email is required';
                    }
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value.trim())) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 30),

                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(kRadiusMD),
                            side: BorderSide(color: kLightGrey),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: kGrey,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _handleSignUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kBlue,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(kRadiusMD),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Add Manager',
                          style: TextStyle(
                            color: kWhite,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Manager {
  final String fullName;
  final String phoneNumber;
  final String emailAddress;
  final String password;

  Manager({
    required this.fullName,
    required this.phoneNumber,
    required this.emailAddress,
    required this.password,
  });
}

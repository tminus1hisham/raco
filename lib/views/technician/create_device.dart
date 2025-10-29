import 'package:atom/config/constants.dart';
import 'package:atom/utils/utils.dart';
import 'package:atom/widgets/buttons/custom_button.dart';
import 'package:atom/widgets/custom_header.dart';
import 'package:atom/widgets/inputs/custom_input.dart';
import 'package:flutter/material.dart';

class TechnicianScreen extends StatefulWidget {
  const TechnicianScreen({super.key});

  @override
  State<TechnicianScreen> createState() => _TechnicianScreenState();
}

class _TechnicianScreenState extends State<TechnicianScreen> {
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _regController = TextEditingController();
  final TextEditingController _chassisController = TextEditingController();
  final TextEditingController _makeController = TextEditingController();
  final TextEditingController _certNoController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _serialController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _agentController = TextEditingController();
  final TextEditingController _agentIDController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _agentPhoneNumberController =
      TextEditingController();
  final TextEditingController _businessRegController = TextEditingController();
  final TextEditingController _groupController = TextEditingController();

  final GlobalKey<FormState> _createDeviceKey = GlobalKey<FormState>();
  final Utils utils = Utils();

  Future<void> _register() async {
    if (!_createDeviceKey.currentState!.validate()) {
      return;
    }

    // authController.phoneNumber.value = utils.normalizePhoneNumber(
    //   _phoneNumberController.text,
    // );
    // authController.password.value = _passwordController.text;
    // authController.deviceModel.value = androidInfo.brand;
    // authController.userAgent.value = androidInfo.model;
    // authController.ipAddress.value = userIp;
    // authController.location.value = 'Nairobi';
    //
    // bool success = await authController.login(context);
    //
    // if (!success) {
    //   await CustomAlertDialog(
    //     context: context,
    //     title: "Error",
    //     message: "Failed to register device ",
    //     icon: "assets/animations/Failed.json",
    //     buttonColor: kRed,
    //   );
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhite,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            customHeader(label: "Create Device", icon: Icons.developer_board),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 15),
                child: Form(
                  key: _createDeviceKey,
                  child: ListView(
                    children: [
                      const SizedBox(height: 10),
                      InputField(
                        hintText: 'Company',
                        prefixIcon: Icons.home_work,
                        controller: _companyController,
                        isRequired: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "This filed is required";
                          }
                          return null;
                        },
                      ),
                      InputField(
                        hintText: 'Name',
                        prefixIcon: Icons.person,
                        controller: _nameController,
                        isRequired: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "This filed is required";
                          }
                          return null;
                        },
                      ),
                      InputField(
                        hintText: 'ID',
                        prefixIcon: Icons.numbers_sharp,
                        controller: _idController,
                        isRequired: true,
                        integerOnly: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "This filed is required";
                          }
                          return null;
                        },
                      ),
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
                      InputField(
                        hintText: 'Registration Number',
                        prefixIcon: Icons.label_outline_sharp,
                        controller: _regController,
                        isRequired: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "This filed is required";
                          }
                          return null;
                        },
                      ),
                      InputField(
                        hintText: 'Chassis',
                        prefixIcon: Icons.density_large_sharp,
                        controller: _chassisController,
                        isRequired: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "This filed is required";
                          }
                          return null;
                        },
                      ),
                      InputField(
                        hintText: 'Make',
                        prefixIcon: Icons.directions_car,
                        controller: _makeController,
                        isRequired: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "This filed is required";
                          }
                          return null;
                        },
                      ),
                      InputField(
                        hintText: 'Certificate No',
                        prefixIcon: Icons.numbers_sharp,
                        controller: _certNoController,
                        isRequired: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "This filed is required";
                          }
                          return null;
                        },
                      ),
                      InputField(
                        hintText: 'Type',
                        prefixIcon: Icons.directions_car,
                        controller: _typeController,
                        isRequired: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "This filed is required";
                          }
                          return null;
                        },
                      ),
                      InputField(
                        hintText: 'Serial number',
                        prefixIcon: Icons.numbers_sharp,
                        controller: _serialController,
                        isRequired: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "This filed is required";
                          }
                          return null;
                        },
                      ),
                      InputField(
                        hintText: 'Date',
                        prefixIcon: Icons.calendar_month,
                        controller: _dateController,
                        isRequired: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "This filed is required";
                          }
                          return null;
                        },
                      ),
                      InputField(
                        hintText: 'Agent',
                        prefixIcon: Icons.person,
                        controller: _agentController,
                        isRequired: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "This filed is required";
                          }
                          return null;
                        },
                      ),
                      InputField(
                        hintText: 'Agent ID',
                        prefixIcon: Icons.perm_identity_outlined,
                        controller: _agentIDController,
                        isRequired: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "This filed is required";
                          }
                          return null;
                        },
                      ),
                      InputField(
                        hintText: 'Location',
                        prefixIcon: Icons.pin_drop,
                        controller: _locationController,
                        isRequired: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "This filed is required";
                          }
                          return null;
                        },
                      ),
                      InputField(
                        hintText: 'Email',
                        prefixIcon: Icons.mail,
                        controller: _emailController,
                        isRequired: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "This filed is required";
                          }
                          return null;
                        },
                      ),
                      InputField(
                        hintText: 'Agent Phone number',
                        prefixIcon: Icons.phone,
                        controller: _agentPhoneNumberController,
                        isRequired: true,
                        integerOnly: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "This filed is required";
                          }
                          return null;
                        },
                      ),
                      InputField(
                        hintText: 'Business Registration',
                        prefixIcon: Icons.app_registration,
                        controller: _businessRegController,
                        isRequired: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "This filed is required";
                          }
                          return null;
                        },
                      ),
                      InputField(
                        hintText: 'Group',
                        prefixIcon: Icons.group_work,
                        controller: _groupController,
                        isRequired: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "This filed is required";
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 10),
                      CustomButton(
                        callBackFunction: _register,
                        label: "Register",
                        backgroundColor: kBlue,
                        txtColor: kWhite,
                      ),
                      SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

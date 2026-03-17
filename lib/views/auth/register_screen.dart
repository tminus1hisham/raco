import 'package:atom/config/constants.dart';
import 'package:atom/controllers/auth_controller.dart';
import 'package:atom/utils/utils.dart';
import 'package:atom/widgets/buttons/custom_button.dart';
import 'package:atom/widgets/inputs/custom_input.dart';
import 'package:atom/widgets/modal/infomation_modal.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  bool _agreeToTerms = false;

  final AuthController authController = Get.put(AuthController());
  final GlobalKey<FormState> _registerKey = GlobalKey<FormState>();
  final utils = Utils();

  Future<bool> _handleSignUp() async {
    if (!_registerKey.currentState!.validate()) {
      return false;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return false;
    }

    authController.fullName.value = _fullNameController.text;
    authController.emailAddress.value = _emailController.text;
    authController.password.value = _passwordController.text;
    authController.phoneNumber.value = utils.normalizePhoneNumber(
      _phoneNumberController.text,
    );
    authController.userRole.value = 'Admin';
    authController.userFirebaseToken.value = 'string';
    authController.adminPhoneNumber.value = '';

    bool success = await authController.register(context);

    if (!success) {
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
    return Form(
      key: _registerKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InputField(
              hintText: 'Full Name',
              prefixIcon: Icons.person_outline,
              controller: _fullNameController,
              isRequired: true,
            ),
            InputField(
              hintText: 'Phone Number',
              prefixIcon: Icons.phone_outlined,
              controller: _phoneNumberController,
              integerOnly: true,
              isRequired: true,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return "Phone number is required";
                }
                return null;
              },
            ),
            InputField(
              hintText: 'Enter your email',
              prefixIcon: Icons.email_outlined,
              controller: _emailController,
              isRequired: true,
            ),
            InputField(
              hintText: 'Enter your password',
              prefixIcon: Icons.lock_outline,
              controller: _passwordController,
              isRequired: true,
              password: true,
            ),
            InputField(
              hintText: 'Confirm your password',
              prefixIcon: Icons.lock_outline,
              controller: _confirmPasswordController,
              isRequired: true,
              password: true,
            ),
            SizedBox(height: 10),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _agreeToTerms,
                  onChanged: (value) {
                    setState(() {
                      _agreeToTerms = value ?? false;
                    });
                  },
                  activeColor: kBlue,
                ),
                Expanded(
                  child: Text(
                    'By agreeing to the terms and conditions, you are entering into a legally binding contract with atom.',
                    style: TextStyle(color: kGrey, fontSize: 15),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            CustomButton(
              callBackFunction: () {
                if (_agreeToTerms) {
                  _handleSignUp();
                }
              },
              label: "Sign Up",
              backgroundColor: _agreeToTerms ? kBlue : kGrey,
              txtColor: kWhite,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneNumberController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}

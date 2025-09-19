import 'package:atom/config/constants.dart';
import 'package:atom/controllers/auth_controller.dart';
import 'package:atom/routes/routes.dart';
import 'package:atom/utils/utils.dart';
import 'package:atom/views/auth/register_screen.dart';
import 'package:atom/widgets/buttons/custom_button.dart';
import 'package:atom/widgets/inputs/custom_input.dart';
import 'package:atom/widgets/modal/infomation_modal.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  String userIp = '';
  late TabController _tabController;
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final utils = Utils();

  final AuthController authController = Get.put(AuthController());
  final GlobalKey<FormState> _loginKey = GlobalKey<FormState>();

  void fetchIp() async {
    final ip = await utils.getLocalIpAddress();
    if (ip != null) {
      setState(() {
        userIp = ip;
      });
    }
  }

  Future<void> _login() async {
    if (!_loginKey.currentState!.validate()) {
      return;
    }

    final deviceInfoPlugin = DeviceInfoPlugin();
    final androidInfo = await deviceInfoPlugin.androidInfo;

    authController.phoneNumber.value = utils.normalizePhoneNumber(
      _phoneNumberController.text,
    );
    authController.password.value = _passwordController.text;
    authController.deviceModel.value = androidInfo.brand;
    authController.userAgent.value = androidInfo.model;
    authController.ipAddress.value = userIp;
    authController.location.value = 'Nairobi';

    bool success = await authController.login(context);

    if (!success) {
      await CustomAlertDialog(
        context: context,
        title: "Error",
        message: "Failed to login, please check your credentials",
        icon: "assets/animations/Failed.json",
        buttonColor: kRed,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchIp();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 10),
                      // Logo
                      Center(
                        child: Hero(
                          tag: "logo",
                          child: Image(
                            image: AssetImage('assets/eagle_logo.png'),
                            height: 180,
                            width: 180,
                          ),
                        ),
                      ),

                      Text(
                        'Welcome to Eagles Eye',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Sign up or login below to be able to\ntrack your vehicle',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 40),

                      // Tab bar
                      Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicatorColor: kBlue,
                          indicatorWeight: 3,
                          indicatorSize: TabBarIndicatorSize.tab,
                          labelColor: kGrey,
                          unselectedLabelColor: Colors.grey.shade500,
                          labelStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          tabs: const [
                            Tab(text: 'Login'),
                            Tab(text: 'Sign Up'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Tab content
                      SizedBox(
                        height: 500,
                        child: TabBarView(
                          controller: _tabController,
                          children: [_buildLoginForm(), RegisterScreen()],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (authController.isLoading.value)
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

  Widget _buildLoginForm() {
    return Form(
      key: _loginKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
            hintText: 'Enter your password',
            prefixIcon: Icons.lock_outline,
            password: true,
            controller: _passwordController,
            isRequired: true,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return "This field is required";
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Forgot password
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.forgotPassword);
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Forgot Password?',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
            ),
          ),

          const SizedBox(height: 30),

          CustomButton(
            callBackFunction: _login,
            label: "Login",
            backgroundColor: kBlue,
            txtColor: kWhite,
          ),

          SizedBox(height: 20),
          // Terms text
          Text.rich(
            TextSpan(
              text: 'By signing up, you agree to our ',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
              children: [
                TextSpan(
                  text: 'Terms of service',
                  style: TextStyle(
                    color: kGrey,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const TextSpan(text: '\nand '),
                TextSpan(
                  text: 'Privacy policy',
                  style: TextStyle(
                    color: kGrey,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _phoneNumberController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

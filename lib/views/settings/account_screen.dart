import 'package:atom/config/constants.dart';
import 'package:atom/controllers/user_data_controller.dart';
import 'package:atom/widgets/buttons/custom_border_button.dart';
import 'package:atom/widgets/buttons/custom_button.dart';
import 'package:atom/widgets/custom_header.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class AccountScreen extends StatelessWidget {
  final UserResourceController controller = Get.put(UserResourceController());

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return Scaffold(
          backgroundColor: kBgGrey,
          body: Center(
            child: LoadingAnimationWidget.fourRotatingDots(
              color: kBlue,
              size: 50,
            ),
          ),
        );
      }

      final user = controller.user.value;
      if (user == null) {
        return Scaffold(
          backgroundColor: kBgGrey,
          body: Center(
            child: Text(
              "No user data found",
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
          ),
        );
      }

      return Scaffold(
        backgroundColor: kBgGrey,
        body: SafeArea(
          child: Column(
            children: [
              SizedBox(height: 10),
              customHeader(label: "Profile", icon: Icons.person),
              SizedBox(height: 10),
              Container(
                margin: EdgeInsets.symmetric(horizontal: 20),
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      height: 150,
                      width: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[200],
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child:
                          (user.profileImage != null &&
                              user.profileImage!.isNotEmpty)
                          ? ClipOval(
                              child: Image.network(
                                user.profileImage!,
                                fit: BoxFit.cover,
                                width: 150,
                                height: 150,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.person,
                                    size: 80,
                                    color: Colors.grey,
                                  );
                                },
                              ),
                            )
                          : Icon(Icons.person, size: 80, color: Colors.grey),
                    ),

                    SizedBox(height: 24),

                    _buildInfoRow(
                      Icons.person_outline,
                      'Full Name',
                      user.fullName,
                    ),
                    SizedBox(height: 16),

                    _buildInfoRow(
                      Icons.email_outlined,
                      'Email',
                      user.emailAddress,
                    ),
                    SizedBox(height: 16),

                    _buildInfoRow(
                      Icons.phone_outlined,
                      'Phone',
                      user.phoneNumber,
                    ),
                    SizedBox(height: 32),

                    CustomButton(
                      callBackFunction: () {},
                      label: "Edit Profile",
                      backgroundColor: kBlue,
                      txtColor: kWhite,
                    ),
                    SizedBox(height: 10),

                    CustomBorderButton(
                      callBackFunction: () {
                        Navigator.pop(context);
                      },
                      label: "Back",
                      borderColor: kGrey,
                      txtColor: kBlack,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: kBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: kBlue, size: 20),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

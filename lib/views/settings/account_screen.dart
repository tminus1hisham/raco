import 'package:atom/config/constants.dart';
import 'package:atom/widgets/buttons/custom_border_button.dart';
import 'package:atom/widgets/buttons/custom_button.dart';
import 'package:atom/widgets/custom_header.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class AccountScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgGrey,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 10),
            customHeader(label: "Profile", icon: Icons.person),
            SizedBox(height: 10),
            _buildProfileCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(context) {
    return Container(
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
            width: double.infinity,
            child: Lottie.asset(
              'assets/animations/profile.json',
              fit: BoxFit.contain,
            ),
          ),
          SizedBox(height: 24),

          _buildInfoRow(Icons.person_outline, 'Name', 'John Doe'),
          SizedBox(height: 16),

          _buildInfoRow(Icons.email_outlined, 'Email', 'john.doe@example.com'),
          SizedBox(height: 16),

          _buildInfoRow(Icons.phone_outlined, 'Phone', '+254 712 345 678'),
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
    );
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

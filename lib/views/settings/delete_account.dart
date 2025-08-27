import 'package:atom/config/constants.dart';
import 'package:atom/widgets/buttons/custom_border_button.dart';
import 'package:atom/widgets/buttons/custom_button.dart';
import 'package:atom/widgets/custom_header.dart';
import 'package:atom/widgets/inputs/custom_input.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class DeleteAccount extends StatefulWidget {
  @override
  _DeleteAccountState createState() => _DeleteAccountState();
}

class _DeleteAccountState extends State<DeleteAccount> {
  final TextEditingController reasonController = TextEditingController();
  String selectedReason = '';

  final List<String> reasons = [
    'No longer need the service',
    'Found a better alternative',
    'Privacy concerns',
    'Too expensive',
    'Difficult to use',
    'Not enough features',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 10),
            customHeader(
              label: "Delete Account",
              icon: Icons.delete_outline_outlined,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: _buildDeleteForm(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteForm() {
    return Container(
      padding: EdgeInsets.all(10),
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
          SizedBox(height: 10),
          Container(
            height: 150,
            width: double.infinity,
            child: Lottie.asset(
              'assets/animations/Delete.json',
              fit: BoxFit.contain,
            ),
          ),
          SizedBox(height: 10),

          Text(
            'Why are you deleting your account?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            'Help us improve by telling us why you\'re leaving',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 16),

          Column(
            children: reasons.map((reason) {
              return Container(
                margin: EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: selectedReason == reason
                        ? Colors.blue[400]!
                        : Colors.grey[300]!,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: RadioListTile<String>(
                  value: reason,
                  groupValue: selectedReason,
                  onChanged: (value) {
                    setState(() {
                      selectedReason = value!;
                    });
                  },
                  title: Text(
                    reason,
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  activeColor: Colors.blue[600],
                  dense: true,
                ),
              );
            }).toList(),
          ),

          if (selectedReason == 'Other')
            InputField(
              hintText: 'Please specify your reason',
              controller: reasonController,
              prefixIcon: Icons.edit_outlined,
            ),
          SizedBox(height: 10),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red[100]!),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_rounded, color: kRed, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Warning',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: kRed,
                        ),
                      ),
                      Text(
                        'This action cannot be undone. All your data will be permanently deleted.',
                        style: TextStyle(fontSize: 14, color: Colors.red[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10),

          CustomButton(
            callBackFunction: () {},
            label: "Delete Account",
            backgroundColor: kRed,
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

  @override
  void dispose() {
    reasonController.dispose();
    super.dispose();
  }
}

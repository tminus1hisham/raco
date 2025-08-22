import 'package:atom/config/constants.dart';
import 'package:atom/widgets/buttons/custom_button.dart';
import 'package:atom/widgets/inputs/custom_input.dart';
import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _agreeToTerms = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // First Name field
          InputField(
            hintText: 'Your Name',
            prefixIcon: Icons.person_outline,
            controller: _firstNameController,
            isRequired: true,
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
          SizedBox(height: 10,),

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
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          CustomButton(callBackFunction: () {
            _agreeToTerms ? _handleSignUp : null;
          }, label: "Sign Up", backgroundColor: _agreeToTerms ? kBlue : kGrey, txtColor: kWhite)

        ],
      ),
    );
  }

  Widget _buildPasswordRequirement(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 16,
            color: Colors.grey.shade500,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _handleSignUp() {
    // Handle sign up logic
    if (_passwordController.text != _confirmPasswordController.text) {
      // Show error: passwords don't match
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    print('Sign up with:');
    print('Name: ${_firstNameController.text}');
    print('Email: ${_emailController.text}');
    print('Password: ${_passwordController.text}');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
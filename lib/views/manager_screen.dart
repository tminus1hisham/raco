import 'package:atom/config/constants.dart';
import 'package:atom/views/cars/manager_car_list.dart';
import 'package:atom/widgets/cards/manager_info_card.dart';
import 'package:atom/widgets/custom_header.dart';
import 'package:atom/widgets/inputs/custom_input.dart';
import 'package:atom/widgets/modal/custom_alert.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ManagerScreen extends StatefulWidget {
  const ManagerScreen({super.key});

  @override
  State<ManagerScreen> createState() => _ManagerScreenState();
}

class _ManagerScreenState extends State<ManagerScreen> {
  List<Manager> managers = [
    Manager(
      fullName: "John Doe",
      phoneNumber: "+254712345678",
      emailAddress: "john.doe@example.com",
      password: "password123",
    ),
    Manager(
      fullName: "Jane Smith",
      phoneNumber: "+254798765432",
      emailAddress: "jane.smith@example.com",
      password: "password456",
    ),
    Manager(
      fullName: "Mike Johnson",
      phoneNumber: "+254723456789",
      emailAddress: "mike.johnson@example.com",
      password: "password789",
    ),
  ];

  void _showAddManagerBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddManagerBottomSheet(
        onManagerAdded: (manager) {
          setState(() {
            managers.add(manager);
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgGrey,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 10),
            customHeader(label: "Managers", icon: Icons.people_outline),
            Expanded(
              child: ListView.builder(
                itemCount: managers.length,
                itemBuilder: (context, index) {
                  final manager = managers[index];
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
                            setState(() {
                              managers.removeAt(index);
                            });
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddManagerBottomSheet,
        backgroundColor: kBlue,
        child: Icon(Icons.add, color: kWhite),
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
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _addManager() {
    if (_formKey.currentState!.validate()) {
      final manager = Manager(
        fullName: _fullNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        emailAddress: _emailController.text.trim(),
        password: _passwordController.text,
      );

      widget.onManagerAdded(manager);
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Manager added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
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
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                Text(
                  'Add New Manager',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
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
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _addManager,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kBlue,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Add Manager',
                          style: TextStyle(
                            color: Colors.white,
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

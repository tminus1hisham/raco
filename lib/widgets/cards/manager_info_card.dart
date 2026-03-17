import 'package:atom/config/constants.dart';
import 'package:flutter/material.dart';

class ManagerInfoCard extends StatelessWidget {
  final String fullName;
  final String phoneNumber;
  final String emailAddress;
  final VoidCallback onPressed;
  final VoidCallback? onDelete;

  const ManagerInfoCard({
    super.key,
    required this.fullName,
    required this.phoneNumber,
    required this.emailAddress,
    required this.onPressed,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 10),
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.circular(kRadiusLG),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: kBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(kRadiusSM),
                    ),
                    child: Icon(Icons.person_outline, color: kBlue, size: 20),
                  ),

                  SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: kBlack,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          phoneNumber,
                          style: TextStyle(
                            fontSize: 14,
                            color: kGrey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (onDelete != null)
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: kRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(kRadiusSM),
                      ),
                      child: IconButton(
                        onPressed: onDelete,
                        icon: Icon(Icons.delete_outline),
                        color: kRed,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:atom/config/constants.dart';
import 'package:flutter/material.dart';

class CarInfoCard extends StatelessWidget {
  final String issuedBy;
  final String date;
  final String command;
  final String status;

  const CarInfoCard({
    super.key,
    required this.issuedBy,
    required this.date,
    required this.status,
    required this.command,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 10),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(kRadiusLG),
          boxShadow: [kShadowMD],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      command,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: kBlack,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      issuedBy,
                      style: TextStyle(
                        fontSize: 14,
                        color: kGrey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: status == "success"
                            ? kSuccessGreen.withValues(alpha: 0.1)
                            : kRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(kRadiusPill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: status == "success"
                                  ? kSuccessGreen
                                  : kRed,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            status,
                            style: TextStyle(
                              color: status == "success"
                                  ? kSuccessGreen
                                  : kRed,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 14,
                        color: kGrey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

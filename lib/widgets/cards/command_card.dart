import 'package:atom/config/app_theme.dart';
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
    final col = context.col;
    final statusColor = status == "success" ? kSuccessGreen : kRed;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Container(
        decoration: BoxDecoration(
          color: col.surface,
          borderRadius: BorderRadius.circular(kRadiusMD),
          boxShadow: [kShadowSM],
          border: Border.all(color: statusColor.withValues(alpha: 0.15)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(kRadiusMD),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: statusColor),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Icon(
                            Icons.terminal_rounded,
                            color: statusColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                command,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: col.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  Icon(
                                    Icons.person_outline_rounded,
                                    size: 12,
                                    color: col.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    issuedBy,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: col.textSecondary,
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 12,
                                    color: col.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    date,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: col.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: statusColor.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                status,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

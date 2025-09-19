import 'package:atom/config/constants.dart';
import 'package:flutter/material.dart';

class SelectableCarCard extends StatelessWidget {
  final Car car;
  final bool isSelected;
  final VoidCallback onCardTap;
  final ValueChanged<bool?> onCheckboxChanged;

  const SelectableCarCard({
    super.key,
    required this.car,
    required this.isSelected,
    required this.onCardTap,
    required this.onCheckboxChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? kBlue : Colors.transparent,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onCardTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.only(top: 10, bottom: 10, right: 10),
            child: Row(
              children: [
                Checkbox(
                  value: isSelected,
                  activeColor: kBlue,
                  onChanged: onCheckboxChanged,
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        car.licensePlate,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        car.carName,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Status Badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: car.isAssigned
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: car.isAssigned ? Colors.green : Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 6),
                      Text(
                        car.isAssigned ? 'Assigned' : 'Available',
                        style: TextStyle(
                          color: car.isAssigned ? Colors.green : Colors.orange,
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
      ),
    );
  }
}

class Car {
  final String id;
  final String licensePlate;
  final String carName;
  final bool isAssigned;

  Car({
    required this.id,
    required this.licensePlate,
    required this.carName,
    required this.isAssigned,
  });
}

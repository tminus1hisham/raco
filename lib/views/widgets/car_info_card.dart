import 'package:atom/config/constants.dart';
import 'package:flutter/material.dart';

class CarInfoCard extends StatelessWidget {
  final String carModel;
  final String licensePlate;
  final IconData carIcon;
  final int batteryLevel;
  final bool showFuelIcon;
  final List<StatCardData> stats;

  const CarInfoCard({
    super.key,
    required this.carModel,
    required this.licensePlate,
    this.carIcon = Icons.directions_car_rounded,
    this.batteryLevel = 6,
    this.showFuelIcon = true,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 10),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: kBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(carIcon, color: kBlue.withOpacity(0.9), size: 30),
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      carModel,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      licensePlate,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
                Spacer(),
                Row(
                  children: [
                    // Battery bars
                    Row(
                      children: List.generate(
                        6,
                        (index) => Container(
                          width: 8,
                          height: 16,
                          margin: EdgeInsets.only(right: 2),
                          decoration: BoxDecoration(
                            color: index < batteryLevel
                                ? kBlue
                                : Colors.grey[300]!,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    if (showFuelIcon)
                      Icon(Icons.local_gas_station, color: kBlue),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: stats
                  .map(
                    (stat) => Expanded(
                      child: Container(
                        margin: EdgeInsets.only(
                          right: stat == stats.last ? 0 : 8,
                        ),
                        child: _buildStatCard(
                          icon: stat.icon,
                          value: stat.value,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({required IconData icon, required String value}) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBlue.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: kBlue),
          SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: kBlue,
            ),
          ),
        ],
      ),
    );
  }
}

class StatCardData {
  final IconData icon;
  final String value;

  StatCardData({required this.icon, required this.value});
}

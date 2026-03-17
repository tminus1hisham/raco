import 'package:atom/config/constants.dart';
import 'package:atom/widgets/custom_header.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class DriverBehaviour extends StatefulWidget {
  const DriverBehaviour({super.key});

  @override
  State<DriverBehaviour> createState() => _DriverBehaviourState();
}

class _DriverBehaviourState extends State<DriverBehaviour> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgGrey,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 10),
              customHeader(
                label: "Driver Behaviour",
                icon: Icons.directions_car,
                showBackButton: true,
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              SizedBox(height: 10),
              _buildSectionHeader("Status"),
              _buildVehicleCard(
                child: Column(
                  children: [
                    _buildVehicleItem(
                      title: 'Driver Behaviour',
                      subtitle: 'safe',
                    ),
                    _buildDivider(),
                    _buildVehicleItem(title: 'Score', subtitle: '78/100'),
                  ],
                ),
              ),
              SizedBox(height: 10),
              _buildSectionHeader("Metrics"),
              _buildVehicleCard(
                child: Column(
                  children: [
                    _buildVehicleItem(title: 'Overspeed', subtitle: '4 Events'),
                    _buildDivider(),
                    _buildVehicleItem(
                      title: 'Harsh Braking',
                      subtitle: '12 Events',
                    ),
                    _buildDivider(),
                    _buildVehicleItem(
                      title: 'Rapid Acceleration',
                      subtitle: '6 Events',
                    ),
                    _buildDivider(),
                    _buildVehicleItem(title: 'Idling', subtitle: '12 mins'),
                  ],
                ),
              ),
              SizedBox(height: 10),
              _buildSectionHeader("Trend"),
              _buildVehicleCard(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Driver Behaviour Score (Last 7 Days)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: kGrey,
                        ),
                      ),
                      SizedBox(height: 20),
                      Container(
                        height: 200,
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: 20,
                              getDrawingHorizontalLine: (value) {
                                return FlLine(
                                  color: kDivider,
                                  strokeWidth: 1,
                                );
                              },
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 30,
                                  interval: 1,
                                  getTitlesWidget:
                                      (double value, TitleMeta meta) {
                                        const style = TextStyle(
                                          color: kGrey,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12,
                                        );
                                        Widget text;
                                        switch (value.toInt()) {
                                          case 0:
                                            text = Text('Wed', style: style);
                                            break;
                                          case 1:
                                            text = Text('Thu', style: style);
                                            break;
                                          case 2:
                                            text = Text('Fri', style: style);
                                            break;
                                          case 3:
                                            text = Text('Sat', style: style);
                                            break;
                                          case 4:
                                            text = Text('Sun', style: style);
                                            break;
                                          case 5:
                                            text = Text('Mon', style: style);
                                            break;
                                          case 6:
                                            text = Text('Tue', style: style);
                                            break;
                                          default:
                                            text = Text('', style: style);
                                            break;
                                        }
                                        return SideTitleWidget(
                                          axisSide: meta.axisSide,
                                          child: text,
                                        );
                                      },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                axisNameWidget: Text(
                                  'Score',
                                  style: TextStyle(
                                    color: kGrey,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 20,
                                  reservedSize: 42,
                                  getTitlesWidget:
                                      (double value, TitleMeta meta) {
                                        return Text(
                                          value.toInt().toString(),
                                          style: TextStyle(
                                            color: kGrey,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 12,
                                          ),
                                        );
                                      },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            minX: 0,
                            maxX: 6,
                            minY: 0,
                            maxY: 100,
                            lineBarsData: [
                              LineChartBarData(
                                spots: [
                                  FlSpot(0, 88), // Wed
                                  FlSpot(1, 84), // Thu
                                  FlSpot(2, 80), // Fri
                                  FlSpot(3, 76), // Sat
                                  FlSpot(4, 78), // Sun
                                  FlSpot(5, 70), // Mon
                                  FlSpot(6, 68), // Tue
                                ],
                                isCurved: true,
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF4285F4),
                                    Color(0xFF4285F4),
                                  ],
                                ),
                                barWidth: 3,
                                isStrokeCapRound: true,
                                dotData: FlDotData(
                                  show: true,
                                  getDotPainter:
                                      (spot, percent, barData, index) =>
                                          FlDotCirclePainter(
                                            radius: 4,
                                            color: Color(0xFF4285F4),
                                            strokeWidth: 2,
                                            strokeColor: kWhite,
                                          ),
                                ),
                                belowBarData: BarAreaData(
                                  show: true,
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF4285F4).withValues(alpha: 0.1),
                                      Color(0xFF4285F4).withValues(alpha: 0.05),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 30),
                      Text(
                        'Risky Events Per Day',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: kGrey,
                        ),
                      ),
                      SizedBox(height: 20),
                      Container(
                        height: 200,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: 6,
                            barTouchData: BarTouchData(enabled: false),
                            titlesData: FlTitlesData(
                              show: true,
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 30,
                                  getTitlesWidget:
                                      (double value, TitleMeta meta) {
                                        const style = TextStyle(
                                          color: kGrey,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12,
                                        );
                                        Widget text;
                                        switch (value.toInt()) {
                                          case 0:
                                            text = Text('Wed', style: style);
                                            break;
                                          case 1:
                                            text = Text('Thu', style: style);
                                            break;
                                          case 2:
                                            text = Text('Fri', style: style);
                                            break;
                                          case 3:
                                            text = Text('Sat', style: style);
                                            break;
                                          case 4:
                                            text = Text('Sun', style: style);
                                            break;
                                          case 5:
                                            text = Text('Mon', style: style);
                                            break;
                                          case 6:
                                            text = Text('Tue', style: style);
                                            break;
                                          default:
                                            text = Text('', style: style);
                                            break;
                                        }
                                        return SideTitleWidget(
                                          axisSide: meta.axisSide,
                                          child: text,
                                        );
                                      },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                axisNameWidget: Text(
                                  'Events',
                                  style: TextStyle(
                                    color: kGrey,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 2,
                                  reservedSize: 42,
                                  getTitlesWidget:
                                      (double value, TitleMeta meta) {
                                        return Text(
                                          value.toInt().toString(),
                                          style: TextStyle(
                                            color: kGrey,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 12,
                                          ),
                                        );
                                      },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: 2,
                              getDrawingHorizontalLine: (value) {
                                return FlLine(
                                  color: kDivider,
                                  strokeWidth: 1,
                                );
                              },
                            ),
                            barGroups: [
                              _buildBarGroup(0, 0.5, 0.5, 0), // Wed
                              _buildBarGroup(1, 1.5, 0.5, 0), // Thu
                              _buildBarGroup(2, 2, 1, 0.5), // Fri
                              _buildBarGroup(3, 1, 1, 0.5), // Sat
                              _buildBarGroup(4, 1.5, 0.5, 0), // Sun
                              _buildBarGroup(5, 2, 1, 0.5), // Mon
                              _buildBarGroup(6, 2.5, 1, 0.5), // Tue
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildLegendItem('Overspeed', Color(0xFFFF5722)),
                          SizedBox(width: 20),
                          _buildLegendItem('Harsh Braking', Color(0xFFF57C00)),
                          SizedBox(width: 20),
                          _buildLegendItem('Rapid Acc', Color(0xFFFFB74D)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  BarChartGroupData _buildBarGroup(
    int x,
    double overspeed,
    double harshBraking,
    double rapidAcceleration,
  ) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: overspeed + harshBraking + rapidAcceleration,
          color: Colors.transparent,
          width: 16,
          borderRadius: BorderRadius.circular(4),
          rodStackItems: [
            BarChartRodStackItem(0, overspeed, Color(0xFFFF5722)),
            BarChartRodStackItem(
              overspeed,
              overspeed + harshBraking,
              Color(0xFFF57C00),
            ),
            BarChartRodStackItem(
              overspeed + harshBraking,
              overspeed + harshBraking + rapidAcceleration,
              Color(0xFFFFB74D),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(String title, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: kGrey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleCard({required Widget child, VoidCallback? onTap}) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(kRadiusMD),
        boxShadow: [kShadowSM],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(kRadiusMD),
        child: child,
      ),
    );
  }

  Widget _buildVehicleItem({required String title, required String subtitle}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: kGrey,
            ),
          ),
          SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: kBlack,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: kGrey,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(height: 1, color: kDivider);
  }
}

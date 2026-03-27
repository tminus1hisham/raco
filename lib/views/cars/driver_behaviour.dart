import 'package:atom/config/app_theme.dart';
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
    final col = context.col;
    return Scaffold(
      backgroundColor: col.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              customHeader(
                label: "Driver Behaviour",
                icon: Icons.directions_car,
                showBackButton: true,
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 10),
              _buildSectionHeader(
                col: col,
                title: 'Status',
                icon: Icons.shield_outlined,
                color: kSuccessGreen,
              ),
              _buildCard(
                col: col,
                children: [
                  _buildItem(
                    col: col,
                    icon: Icons.sentiment_satisfied_alt_rounded,
                    iconColor: kSuccessGreen,
                    label: 'Driver Behaviour',
                    value: 'Safe',
                    valueColor: kSuccessGreen,
                  ),
                  _buildDivider(col),
                  _buildItem(
                    col: col,
                    icon: Icons.star_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    label: 'Safety Score',
                    value: '78 / 100',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildSectionHeader(
                col: col,
                title: 'Metrics',
                icon: Icons.analytics_outlined,
                color: kBlue,
              ),
              _buildCard(
                col: col,
                children: [
                  _buildItem(
                    col: col,
                    icon: Icons.speed_rounded,
                    iconColor: kRed,
                    label: 'Overspeed',
                    value: '4 Events',
                    valueColor: kRed,
                  ),
                  _buildDivider(col),
                  _buildItem(
                    col: col,
                    icon: Icons.warning_amber_rounded,
                    iconColor: Colors.orange,
                    label: 'Harsh Braking',
                    value: '12 Events',
                    valueColor: Colors.orange,
                  ),
                  _buildDivider(col),
                  _buildItem(
                    col: col,
                    icon: Icons.bolt_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    label: 'Rapid Acceleration',
                    value: '6 Events',
                    valueColor: const Color(0xFFF59E0B),
                  ),
                  _buildDivider(col),
                  _buildItem(
                    col: col,
                    icon: Icons.hourglass_empty_rounded,
                    iconColor: kBlue,
                    label: 'Idling',
                    value: '12 mins',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildSectionHeader(
                col: col,
                title: 'Trend',
                icon: Icons.show_chart_rounded,
                color: const Color(0xFF6366F1),
              ),
              _buildCard(
                col: col,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Driver Behaviour Score (Last 7 Days)',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: col.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 200,
                          child: LineChart(
                            LineChartData(
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                horizontalInterval: 20,
                                getDrawingHorizontalLine: (value) {
                                  return FlLine(
                                    color: col.divider,
                                    strokeWidth: 1,
                                  );
                                },
                              ),
                              titlesData: FlTitlesData(
                                show: true,
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 30,
                                    interval: 1,
                                    getTitlesWidget:
                                        (double value, TitleMeta meta) {
                                          final style = TextStyle(
                                            color: col.textSecondary,
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
                                      color: col.textSecondary,
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
                                              color: col.textSecondary,
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
                                  spots: const [
                                    FlSpot(0, 88),
                                    FlSpot(1, 84),
                                    FlSpot(2, 80),
                                    FlSpot(3, 76),
                                    FlSpot(4, 78),
                                    FlSpot(5, 70),
                                    FlSpot(6, 68),
                                  ],
                                  isCurved: true,
                                  gradient: const LinearGradient(
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
                                              color: const Color(0xFF4285F4),
                                              strokeWidth: 2,
                                              strokeColor: col.surface,
                                            ),
                                  ),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0x1A4285F4),
                                        Color(0x0D4285F4),
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
                        const SizedBox(height: 30),
                        Text(
                          'Risky Events Per Day',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: col.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 200,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: 6,
                              barTouchData: BarTouchData(enabled: false),
                              titlesData: FlTitlesData(
                                show: true,
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 30,
                                    getTitlesWidget:
                                        (double value, TitleMeta meta) {
                                          final style = TextStyle(
                                            color: col.textSecondary,
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
                                      color: col.textSecondary,
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
                                              color: col.textSecondary,
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
                                    color: col.divider,
                                    strokeWidth: 1,
                                  );
                                },
                              ),
                              barGroups: [
                                _buildBarGroup(0, 0.5, 0.5, 0),
                                _buildBarGroup(1, 1.5, 0.5, 0),
                                _buildBarGroup(2, 2, 1, 0.5),
                                _buildBarGroup(3, 1, 1, 0.5),
                                _buildBarGroup(4, 1.5, 0.5, 0),
                                _buildBarGroup(5, 2, 1, 0.5),
                                _buildBarGroup(6, 2.5, 1, 0.5),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildLegendItem(
                              'Overspeed',
                              const Color(0xFFFF5722),
                              col,
                            ),
                            const SizedBox(width: 20),
                            _buildLegendItem(
                              'Harsh Braking',
                              const Color(0xFFF57C00),
                              col,
                            ),
                            const SizedBox(width: 20),
                            _buildLegendItem(
                              'Rapid Acc',
                              const Color(0xFFFFB74D),
                              col,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
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
            BarChartRodStackItem(0, overspeed, const Color(0xFFFF5722)),
            BarChartRodStackItem(
              overspeed,
              overspeed + harshBraking,
              const Color(0xFFF57C00),
            ),
            BarChartRodStackItem(
              overspeed + harshBraking,
              overspeed + harshBraking + rapidAcceleration,
              const Color(0xFFFFB74D),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(String title, Color color, AppColors col) {
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
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: col.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader({
    required AppColors col,
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: col.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required AppColors col, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: col.surface,
        borderRadius: BorderRadius.circular(kRadiusMD),
        boxShadow: [kShadowSM],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(kRadiusMD),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildItem({
    required AppColors col,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: col.textSecondary,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 3),
                if (valueColor != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: valueColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: valueColor.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: valueColor,
                      ),
                    ),
                  )
                else
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: col.textPrimary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(AppColors col) {
    return Container(
      height: 1,
      margin: const EdgeInsets.only(left: 70),
      color: col.divider,
    );
  }
}

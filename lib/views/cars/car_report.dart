import 'dart:convert';

import 'package:atom/config/constants.dart';
import 'package:atom/widgets/custom_header.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CarReports extends StatefulWidget {
  final String? vehicleId;
  final String? vehicleName;
  final String? vehiclePlate;

  const CarReports({
    Key? key,
    this.vehicleId,
    this.vehicleName,
    this.vehiclePlate,
  }) : super(key: key);

  @override
  _CarReportsState createState() => _CarReportsState();
}

class _CarReportsState extends State<CarReports> {
  VehicleData? _vehicleData;
  DateTime? _startDate;
  DateTime? _endDate;

  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');

  @override
  void initState() {
    super.initState();
    _loadVehicleData();
  }

  void _loadVehicleData() {
    _vehicleData = _getSingleVehicleData();
  }

  VehicleData _getSingleVehicleData() {
    const sampleJson = '''
    {
      "id": "v1",
      "name": "Isuzu NQR",
      "plate": "KDF 001A",
      "date": "2025-09-01",
      "violations": {
        "overspeed": 12,
        "tamper": 2,
        "geofence": 1,
        "harshBraking": 5,
        "rapidAcceleration": 3,
        "idleTime": 8
      }
    }
    ''';

    final Map<String, dynamic> parsed = json.decode(sampleJson);
    return VehicleData.fromJson(parsed);
  }

  Future<void> _pickStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now().subtract(Duration(days: 30)),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: kBlue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _pickEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: kBlue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  List<ViolationBarData> getViolationsData() {
    if (_vehicleData == null) return [];

    final violations = _vehicleData!.violations;
    final map = <String, double>{
      'Overspeed': violations.overspeed.toDouble(),
      'Tamper': violations.tamper.toDouble(),
      'Geofence': violations.geofence.toDouble(),
      'Harsh Brake': violations.harshBraking.toDouble(),
      'Rapid Accel': violations.rapidAcceleration.toDouble(),
      'Idle Time': violations.idleTime.toDouble(),
    };

    return map.entries
        .map((e) => ViolationBarData(e.key, e.value))
        .where((d) => d.value > 0)
        .toList();
  }

  Widget _buildDatePickerButton({
    required String label,
    required DateTime? selectedDate,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        height: 80,
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.1),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selectedDate != null
                      ? kBlue.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: selectedDate != null ? kBlue : Colors.grey[600],
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          selectedDate != null
                              ? _dateFormat.format(selectedDate)
                              : 'Select date',
                          style: TextStyle(
                            fontSize: 14,
                            color: selectedDate != null
                                ? Colors.black87
                                : Colors.grey[500],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final violations = getViolationsData();

    return Scaffold(
      backgroundColor: kBgGrey,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10),
            customHeader(label: "Report", icon: Icons.assessment_outlined),

            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: ListView(
                  children: [
                    SizedBox(height: 10),
                    Row(
                      children: [
                        _buildDatePickerButton(
                          label: 'Start Date',
                          selectedDate: _startDate,
                          onTap: () => _pickStartDate(context),
                          icon: Icons.calendar_today_outlined,
                        ),
                        SizedBox(width: 12),
                        _buildDatePickerButton(
                          label: 'End Date',
                          selectedDate: _endDate,
                          onTap: () => _pickEndDate(context),
                          icon: Icons.event_outlined,
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Container(
                      decoration: BoxDecoration(
                        color: kWhite,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            spreadRadius: 0,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.bar_chart, color: kBlue, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Violations Overview',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 260,
                              child: violations.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.check_circle_outline,
                                            size: 48,
                                            color: Colors.green,
                                          ),
                                          SizedBox(height: 12),
                                          Text(
                                            'No violations found',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : BarChart(
                                      BarChartData(
                                        alignment:
                                            BarChartAlignment.spaceAround,
                                        maxY:
                                            (violations.isEmpty
                                                    ? 10.0
                                                    : (violations
                                                              .map(
                                                                (d) => d.value,
                                                              )
                                                              .reduce(
                                                                (a, b) => a > b
                                                                    ? a
                                                                    : b,
                                                              ) *
                                                          1.2))
                                                .clamp(10.0, double.infinity),
                                        titlesData: FlTitlesData(
                                          bottomTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              getTitlesWidget: (value, meta) {
                                                final idx = value.toInt();
                                                if (idx < violations.length) {
                                                  return Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          top: 6,
                                                        ),
                                                    child: Text(
                                                      violations[idx].category,
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  );
                                                }
                                                return const SizedBox.shrink();
                                              },
                                            ),
                                          ),
                                          leftTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                            ),
                                          ),
                                          topTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: false,
                                            ),
                                          ),
                                          rightTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: false,
                                            ),
                                          ),
                                        ),
                                        borderData: FlBorderData(show: false),
                                        barGroups: violations
                                            .asMap()
                                            .entries
                                            .map((e) {
                                              final idx = e.key;
                                              final d = e.value;
                                              return BarChartGroupData(
                                                x: idx,
                                                barRods: [
                                                  BarChartRodData(
                                                    toY: d.value,
                                                    width: 20,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                    color: violationColor(
                                                      d.category,
                                                    ),
                                                  ),
                                                ],
                                              );
                                            })
                                            .toList(),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Pie chart
                    if (violations.isNotEmpty) ...[
                      Container(
                        decoration: BoxDecoration(
                          color: kWhite,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              spreadRadius: 0,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.pie_chart, color: kBlue, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Violations Distribution',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                height: 220,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: PieChart(
                                        PieChartData(
                                          sections: violations.map((d) {
                                            return PieChartSectionData(
                                              value: d.value,
                                              title: d.value.toInt().toString(),
                                              radius: 70,
                                              titleStyle: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              color: violationColor(d.category),
                                            );
                                          }).toList(),
                                          centerSpaceRadius: 28,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: violations.map((d) {
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 6,
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 14,
                                                height: 14,
                                                decoration: BoxDecoration(
                                                  color: violationColor(
                                                    d.category,
                                                  ),
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '${d.category} (${d.value.toInt()})',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color violationColor(String category) {
    switch (category.toLowerCase()) {
      case 'overspeed':
        return Colors.red;
      case 'tamper':
        return Colors.orange;
      case 'geofence':
        return Colors.purple;
      case 'harsh brake':
        return Colors.yellow.shade700;
      case 'rapid accel':
        return Colors.green;
      case 'idle time':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

// Models (unchanged)
class VehicleData {
  final String id;
  final String name;
  final String plate;
  final DateTime date;
  final ViolationData violations;

  VehicleData({
    required this.id,
    required this.name,
    required this.plate,
    required this.date,
    required this.violations,
  });

  factory VehicleData.fromJson(Map<String, dynamic> j) => VehicleData(
    id: j['id'],
    name: j['name'],
    plate: j['plate'],
    date: DateTime.parse(j['date']),
    violations: ViolationData.fromJson(j['violations'] ?? {}),
  );
}

class ViolationData {
  final int overspeed;
  final int tamper;
  final int geofence;
  final int harshBraking;
  final int rapidAcceleration;
  final int idleTime;

  ViolationData({
    required this.overspeed,
    required this.tamper,
    required this.geofence,
    required this.harshBraking,
    required this.rapidAcceleration,
    required this.idleTime,
  });

  factory ViolationData.fromJson(Map<String, dynamic> j) => ViolationData(
    overspeed: (j['overspeed'] ?? 0).toInt(),
    tamper: (j['tamper'] ?? 0).toInt(),
    geofence: (j['geofence'] ?? 0).toInt(),
    harshBraking: (j['harshBraking'] ?? 0).toInt(),
    rapidAcceleration: (j['rapidAcceleration'] ?? 0).toInt(),
    idleTime: (j['idleTime'] ?? 0).toInt(),
  );
}

class ViolationBarData {
  final String category;
  final double value;

  ViolationBarData(this.category, this.value);
}

import 'dart:convert';

import 'package:atom/config/constants.dart';
import 'package:atom/widgets/custom_header.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CarReports extends StatefulWidget {
  const CarReports({Key? key}) : super(key: key);

  @override
  _CarReportsState createState() => _CarReportsState();
}

class _CarReportsState extends State<CarReports> {
  late Future<List<VehicleData>> _futureData;
  DateTime? _startDate;
  DateTime? _endDate;

  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    _futureData = fetchVehiclesFromJson();
  }

  Future<void> _pickStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
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
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<List<VehicleData>> fetchVehiclesFromJson() async {
    const sampleJson = '''
    {
      "vehicles": [
        {
          "id": "v1",
          "name": "Truck A",
          "plate": "KAA-001A",
          "date": "2025-09-01",
          "violations": {
            "overspeed": 12,
            "tamper": 2,
            "geofence": 1,
            "harshBraking": 5,
            "rapidAcceleration": 3,
            "idleTime": 8
          }
        },
      ]
    }
    ''';

    await Future.delayed(const Duration(milliseconds: 300));
    final Map<String, dynamic> parsed = json.decode(sampleJson);
    final List vehicles = parsed['vehicles'] ?? [];
    return vehicles.map((v) => VehicleData.fromJson(v)).toList();
  }

  List<ViolationBarData> aggregateViolations(List<VehicleData> vehicles) {
    final map = <String, double>{
      'Overspeed': 0,
      'Tamper': 0,
      'Geofence': 0,
      'Harsh Brake': 0,
      'Rapid Accel': 0,
      'Idle Time': 0,
    };
    for (var v in vehicles) {
      map['Overspeed'] = map['Overspeed']! + v.violations.overspeed;
      map['Tamper'] = map['Tamper']! + v.violations.tamper;
      map['Geofence'] = map['Geofence']! + v.violations.geofence;
      map['Harsh Brake'] = map['Harsh Brake']! + v.violations.harshBraking;
      map['Rapid Accel'] = map['Rapid Accel']! + v.violations.rapidAcceleration;
      map['Idle Time'] = map['Idle Time']! + v.violations.idleTime;
    }
    return map.entries
        .map((e) => ViolationBarData(e.key, e.value))
        .where((d) => d.value > 0)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgGrey,
      body: SafeArea(
        child: FutureBuilder<List<VehicleData>>(
          future: _futureData,
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final allVehicles = snap.data!;

            // Apply date filter
            final filtered = allVehicles.where((v) {
              if (_startDate != null && v.date.isBefore(_startDate!)) {
                return false;
              }
              if (_endDate != null && v.date.isAfter(_endDate!)) {
                return false;
              }
              return true;
            }).toList();

            final violations = aggregateViolations(filtered);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 10),
                customHeader(label: "Reports", icon: Icons.file_copy_outlined),
                SizedBox(height: 20),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15),
                    child: ListView(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton(
                              onPressed: () => _pickStartDate(context),
                              child: Text(
                                _startDate == null
                                    ? "Select Start Date"
                                    : "From: ${_dateFormat.format(_startDate!)}",
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => _pickEndDate(context),
                              child: Text(
                                _endDate == null
                                    ? "Select End Date"
                                    : "To: ${_dateFormat.format(_endDate!)}",
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Violations bar chart
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Violations Overview',
                                  style: TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 260,
                                  child: BarChart(
                                    BarChartData(
                                      alignment: BarChartAlignment.spaceAround,
                                      maxY:
                                          (violations.isEmpty
                                                  ? 10.0
                                                  : (violations
                                                            .map((d) => d.value)
                                                            .reduce(
                                                              (a, b) =>
                                                                  a > b ? a : b,
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
                                      barGroups: violations.asMap().entries.map(
                                        (e) {
                                          final idx = e.key;
                                          final d = e.value;
                                          return BarChartGroupData(
                                            x: idx,
                                            barRods: [
                                              BarChartRodData(
                                                toY: d.value,
                                                width: 20,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                color: violationColor(
                                                  d.category,
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ).toList(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Pie chart
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Violations Distribution',
                                  style: TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 12),
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
                                                title: d.value
                                                    .toInt()
                                                    .toString(),
                                                radius: 70,
                                                titleStyle: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                color: violationColor(
                                                  d.category,
                                                ),
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
                    ),
                  ),
                ),
              ],
            );
          },
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

// Models
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

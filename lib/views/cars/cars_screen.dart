import 'package:atom/config/app_theme.dart';
import 'package:atom/config/constants.dart';
import 'package:atom/controllers/device_controller.dart';
import 'package:atom/controllers/renew_certificate_controller.dart';
import 'package:atom/models/vehicle_model.dart';
import 'package:atom/views/cars/selected_car_screen.dart';
import 'package:atom/widgets/cards/compact_car_list_item.dart';
import 'package:atom/widgets/shimmer_loading.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class CarsScreen extends StatefulWidget {
  const CarsScreen({super.key});

  @override
  State<CarsScreen> createState() => _CarsScreenState();
}

class _CarsScreenState extends State<CarsScreen> {
  final DeviceController _controller = Get.put(DeviceController());
  final RenewCertificateController _renewCertificateController = Get.put(
    RenewCertificateController(),
  );

  String _searchQuery = "";
  String _selectedFilter = "All"; // All, Online, Offline, Inactivated
  bool _sortAscending = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.fetchDevices();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Device> get _filteredDevices {
    var devices = _controller.devicesModel.value?.devices ?? [];

    if (_searchQuery.isNotEmpty) {
      devices = devices
          .where((d) =>
              d.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              d.numberPlate.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              d.deviceId.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    if (_selectedFilter == "Online") {
      devices = devices.where((d) => d.isDeviceOnline).toList();
    } else if (_selectedFilter == "Offline") {
      devices = devices.where((d) => !d.isDeviceOnline && d.certificateActiveStatus).toList();
    } else if (_selectedFilter == "Inactivated") {
      devices = devices.where((d) => !d.certificateActiveStatus).toList();
    }

    devices.sort((a, b) {
      String nameA = a.name.isNotEmpty ? a.name : a.numberPlate;
      String nameB = b.name.isNotEmpty ? b.name : b.numberPlate;
      return _sortAscending
          ? nameA.compareTo(nameB)
          : nameB.compareTo(nameA);
    });

    return devices;
  }

  Widget _buildFilterChip(String label, int count, String filterValue) {
    bool isSelected = _selectedFilter == filterValue;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = filterValue),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? kBlue : context.col.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? kWhite : context.col.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              count.toString(),
              style: TextStyle(
                color: isSelected ? kWhite : context.col.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final model = _controller.devicesModel.value;
      int allCount = model?.totalDevices ?? 0;
      int onlineCount = model?.onlineDevices ?? 0;
      int offlineCount = model?.devices.where((d) => !d.isDeviceOnline && d.certificateActiveStatus).length ?? 0;
      int inactivatedCount = model?.devices.where((d) => !d.certificateActiveStatus).length ?? 0;

      var devices = _filteredDevices;
      
      Map<String, List<Device>> grouped = {};
      for (var d in devices) {
        String g = (d.group.isEmpty) ? "Default" : d.group;
        if (!grouped.containsKey(g)) grouped[g] = [];
        grouped[g]!.add(d);
      }

      return Stack(
        children: [
          Scaffold(
            backgroundColor: context.col.bg,
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                setState(() {
                  _sortAscending = !_sortAscending;
                });
              },
              backgroundColor: context.col.surface,
              elevation: 4,
              child: Icon(
                _sortAscending ? Icons.sort_by_alpha : Icons.sort,
                color: context.col.textPrimary,
              ),
            ),
            body: SafeArea(
              child: Column(
                children: [
                  // App Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 03, vertical: 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          // children: [
                          //   GestureDetector(
                          //     onTap: () => Navigator.maybePop(context),
                          //     child: Icon(Icons.arrow_back_ios, color: context.col.textPrimary),
                          //   ),
                          //   const SizedBox(width: 10),
                          //   Text(
                          //     "Demo[$allCount/$onlineCount]",
                          //     style: TextStyle(
                          //       fontSize: 18,
                          //       fontWeight: FontWeight.bold,
                          //       color: context.col.textPrimary,
                          //     ),
                          //   ),
                          // ],
                        ),
                        // Icon(CupertinoIcons.person, color: context.col.textPrimary),
                      ],
                    ),
                  ),
                  
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: context.col.surface,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TextField(
                              controller: _searchController,
                              style: TextStyle(color: context.col.textPrimary),
                              onChanged: (v) => setState(() => _searchQuery = v),
                              decoration: InputDecoration(
                                hintText: "Device name, IMEI (last 6 digits)",
                                hintStyle: TextStyle(color: context.col.textSecondary, fontSize: 13),
                                prefixIcon: Icon(Icons.search, color: context.col.textSecondary),
                                suffixIcon: Icon(Icons.qr_code_scanner, color: context.col.textSecondary),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: kBlue,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextButton(
                            onPressed: () {
                               FocusScope.of(context).unfocus();
                            },
                            child: const Text("Search", style: TextStyle(color: kWhite, fontSize: 14)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      children: [
                        _buildFilterChip("All", allCount, "All"),
                        _buildFilterChip("Online", onlineCount, "Online"),
                        _buildFilterChip("Offline", offlineCount, "Offline"),
                        _buildFilterChip("Inactivated", inactivatedCount, "Inactivated"),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // List Configuration
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => _controller.fetchDevices(),
                      color: kBlue,
                      child: _controller.isLoading.value && model == null
                          ? const ShimmerList(itemCount: 6, cardHeight: 70)
                          : ListView(
                              padding: const EdgeInsets.only(bottom: 80), // For FAB
                              children: grouped.entries.map((entry) {
                                return ExpansionTile(
                                  initiallyExpanded: true,
                                  shape: const Border(),
                                  iconColor: context.col.textPrimary,
                                  collapsedIconColor: context.col.textPrimary,
                                  title: Text(
                                    "${entry.key} (${entry.value.length})",
                                    style: TextStyle(
                                      color: context.col.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  children: entry.value.map((d) {
                                    return CompactCarListItem(
                                      device: d,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => SelectedCarScreen(
                                              devices: d,
                                              carModel: d.make,
                                              licensePlate: d.numberPlate,
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  }).toList(),
                                );
                              }).toList(),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_renewCertificateController.isLoading.value) ...[
            Container(
              color: kBlack.withValues(alpha: 0.3),
              child: Center(
                child: LoadingAnimationWidget.fourRotatingDots(
                  color: kBlue,
                  size: 50,
                ),
              ),
            ),
          ],
        ],
      );
    });
  }
}

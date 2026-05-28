import 'package:atom/config/app_theme.dart';
import 'package:atom/config/constants.dart';
import 'package:atom/controllers/device_controller.dart';
import 'package:atom/controllers/renew_certificate_controller.dart';
import 'package:atom/models/vehicle_model.dart';
import 'package:atom/views/cars/selected_car_screen.dart';
import 'package:atom/widgets/cards/compact_car_list_item.dart';
import 'package:atom/widgets/shimmer_loading.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

enum _VehicleSortMode { speed, alpha }

class CarsScreen extends StatefulWidget {
  final bool showSearch;

  const CarsScreen({super.key, this.showSearch = false});

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
  _VehicleSortMode _sortMode = _VehicleSortMode.speed;
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

  @override
  void didUpdateWidget(covariant CarsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showSearch && !widget.showSearch && _searchQuery.isNotEmpty) {
      _searchController.clear();
      setState(() => _searchQuery = "");
    }
  }

  double _speedFor(Device device) {
    return double.tryParse(
          device.speed.replaceAll(RegExp(r'[^0-9.]'), ''),
        ) ??
        0;
  }

  String _sortNameFor(Device device) {
    final label = device.numberPlate.trim().isNotEmpty
        ? device.numberPlate.trim()
        : device.name.trim();
    return label.toLowerCase();
  }

  List<Device> get _filteredDevices {
    var devices = List<Device>.from(
      _controller.devicesModel.value?.devices ?? [],
    );

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      devices = devices
          .where(
            (d) =>
                d.name.toLowerCase().contains(query) ||
                d.numberPlate.toLowerCase().contains(query) ||
                d.deviceId.toLowerCase().contains(query),
          )
          .toList();
    }

    if (_selectedFilter == "Online") {
      devices = devices.where((d) => d.isDeviceOnline).toList();
    } else if (_selectedFilter == "Offline") {
      devices = devices
          .where((d) => !d.isDeviceOnline && d.certificateActiveStatus)
          .toList();
    } else if (_selectedFilter == "Inactivated") {
      devices = devices.where((d) => !d.certificateActiveStatus).toList();
    }

    devices.sort((a, b) {
      if (_sortMode == _VehicleSortMode.alpha) {
        final byName = _sortNameFor(a).compareTo(_sortNameFor(b));
        if (byName != 0) return byName;
        return _speedFor(b).compareTo(_speedFor(a));
      }

      final bySpeed = _speedFor(b).compareTo(_speedFor(a));
      if (bySpeed != 0) return bySpeed;
      return _sortNameFor(a).compareTo(_sortNameFor(b));
    });

    return devices;
  }

  Widget _buildFilterTile(String label, int count, String filterValue) {
    bool isSelected = _selectedFilter == filterValue;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = filterValue),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF416BFF) : context.col.inputFill,
          borderRadius: BorderRadius.circular(kRadiusSM),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF416BFF)
                : context.col.border.withValues(alpha: 0.16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  color: isSelected ? kWhite : context.col.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  height: 1.0,
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              count.toString(),
              style: TextStyle(
                color: isSelected ? kWhite : context.col.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 0.95,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterStrip({
    required int allCount,
    required int onlineCount,
    required int offlineCount,
    required int inactivatedCount,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Row(
        children: [
          Expanded(child: _buildFilterTile("All", allCount, "All")),
          const SizedBox(width: 8),
          Expanded(child: _buildFilterTile("Online", onlineCount, "Online")),
          const SizedBox(width: 8),
          Expanded(child: _buildFilterTile("Offline", offlineCount, "Offline")),
          const SizedBox(width: 8),
          Expanded(
            child: _buildFilterTile(
              "Inactive",
              inactivatedCount,
              "Inactivated",
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: !widget.showSearch
          ? const SizedBox.shrink()
          : Padding(
              key: const ValueKey('vehicle-list-search'),
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: context.col.inputFill,
                  borderRadius: BorderRadius.circular(kRadiusSM),
                  border: Border.all(
                    color: context.col.border.withValues(alpha: 0.18),
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: context.col.textPrimary),
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: "Search vehicle, plate, or device ID",
                    hintStyle: TextStyle(
                      color: context.col.textSecondary,
                      fontSize: 12,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: context.col.textSecondary,
                    ),
                    suffixIcon: _searchQuery.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            icon: Icon(
                              Icons.close_rounded,
                              color: context.col.textSecondary,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = "");
                            },
                          ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 9),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 72),
      children: [
        Icon(
          Icons.directions_car_filled_outlined,
          size: 42,
          color: context.col.textSecondary,
        ),
        const SizedBox(height: 12),
        Text(
          "No vehicles found",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: context.col.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Try another filter or search term.",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: context.col.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSortFab() {
    final showingSpeed = _sortMode == _VehicleSortMode.speed;
    return FloatingActionButton(
      tooltip: showingSpeed ? 'Sort A-Z' : 'Sort by speed',
      onPressed: () {
        setState(() {
          _sortMode = showingSpeed
              ? _VehicleSortMode.alpha
              : _VehicleSortMode.speed;
        });
      },
      backgroundColor: context.col.surface,
      elevation: 8,
      shape: const CircleBorder(),
      child: showingSpeed
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'A',
                  style: TextStyle(
                    color: context.col.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    height: 0.9,
                  ),
                ),
                Text(
                  'Z',
                  style: TextStyle(
                    color: context.col.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    height: 0.9,
                  ),
                ),
                Icon(Icons.format_list_bulleted_rounded,
                    color: context.col.textPrimary, size: 20),
              ],
            )
          : const Icon(Icons.speed_rounded, color: kBlue, size: 26),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final model = _controller.devicesModel.value;
      int allCount = model?.totalDevices ?? 0;
      int onlineCount = model?.onlineDevices ?? 0;
      int offlineCount =
          model?.devices
              .where((d) => !d.isDeviceOnline && d.certificateActiveStatus)
              .length ??
          0;
      int inactivatedCount =
          model?.devices.where((d) => !d.certificateActiveStatus).length ?? 0;

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
            backgroundColor: context.col.surface,
            floatingActionButton: _buildSortFab(),
            body: SafeArea(
              child: Column(
                children: [
                  _buildFilterStrip(
                    allCount: allCount,
                    onlineCount: onlineCount,
                    offlineCount: offlineCount,
                    inactivatedCount: inactivatedCount,
                  ),
                  _buildSearchField(),

                  // List Configuration
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => _controller.fetchDevices(),
                      color: kBlue,
                      child: _controller.isLoading.value && model == null
                          ? const ShimmerList(itemCount: 6, cardHeight: 70)
                          : grouped.isEmpty
                          ? _buildEmptyState()
                          : ListView(
                              padding: const EdgeInsets.only(
                                bottom: 88,
                              ),
                              children: grouped.entries.map((entry) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    dividerColor: Colors.transparent,
                                  ),
                                  child: ExpansionTile(
                                    initiallyExpanded: true,
                                    dense: true,
                                    visualDensity: VisualDensity.compact,
                                    minTileHeight: 38,
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                    tilePadding: const EdgeInsets.only(
                                      left: 14,
                                      right: 18,
                                    ),
                                    childrenPadding: EdgeInsets.zero,
                                    shape: const Border(),
                                    collapsedShape: const Border(),
                                    iconColor: context.col.textSecondary,
                                    collapsedIconColor:
                                        context.col.textSecondary,
                                    title: RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: entry.key,
                                            style: TextStyle(
                                              color: context.col.textPrimary,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 14,
                                            ),
                                          ),
                                          TextSpan(
                                            text: "  (${entry.value.length})",
                                            style: TextStyle(
                                              color: context.col.textSecondary,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    children: entry.value.map((d) {
                                      return CompactCarListItem(
                                        device: d,
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  SelectedCarScreen(
                                                    devices: d,
                                                    carModel: d.make,
                                                    licensePlate:
                                                        d.numberPlate,
                                                  ),
                                            ),
                                          );
                                        },
                                      );
                                    }).toList(),
                                  ),
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

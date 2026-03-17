import 'package:atom/config/constants.dart';
import 'package:atom/controllers/device_controller.dart';
import 'package:atom/widgets/buttons/custom_button.dart';
import 'package:atom/widgets/cards/manager_car_card.dart';
import 'package:atom/widgets/custom_header.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ManagerCarListScreen extends StatefulWidget {
  @override
  State<ManagerCarListScreen> createState() => _ManagerCarListScreenState();
}

class _ManagerCarListScreenState extends State<ManagerCarListScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<Car> _allCars = [];
  List<Car> _assignedCars = [];
  Set<String> _selectedCarIds = {};
  bool _selectAllMode = false;
  String _filter = 'all';

  final DeviceController _controller = Get.find<DeviceController>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    Future.delayed(Duration.zero, () {
      final devices = _controller.devicesModel.value?.devices ?? [];

      setState(() {
        _allCars = devices.map((d) {
          return Car(
            id: d.id.toString(),
            licensePlate: d.numberPlate,
            carName: d.name,
            isAssigned: d.isDeviceOnline,
          );
        }).toList();

        _assignedCars = _allCars.where((car) => car.isAssigned).toList();
      });
    });
  }

  List<Car> get _currentCars {
    return _tabController.index == 0 ? _assignedCars : _allCars;
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectAllMode) {
        // If in select all mode, deselect all
        _selectedCarIds.clear();
        _selectAllMode = false;
      } else {
        // Select all current visible cars
        _selectedCarIds = _currentCars.map((car) => car.id).toSet();
        _selectAllMode = true;
      }
    });
  }

  void _toggleCarSelection(String carId) {
    setState(() {
      if (_selectedCarIds.contains(carId)) {
        _selectedCarIds.remove(carId);
      } else {
        _selectedCarIds.add(carId);
      }

      _selectAllMode = _selectedCarIds.length == _currentCars.length;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgGrey,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 10),
            customHeader(
              label: "Vehicles",
              icon: Icons.directions_car,
              showBackButton: true,
              onPressed: () {
                Navigator.pop(context);
              },
            ),

            SizedBox(height: 10),
            Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: kBlue,
                      borderRadius: BorderRadius.circular(kRadiusSM),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: kWhite,
                    unselectedLabelColor: kGrey,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                    tabs: [
                      Tab(text: 'Assigned (${_assignedCars.length})'),
                      Tab(text: 'All (${_allCars.length})'),
                    ],
                    onTap: (index) {
                      setState(() {
                        _selectedCarIds.clear();
                        _selectAllMode = false;
                      });
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: _toggleSelectAll,
                        icon: Icon(
                          _selectAllMode ? Icons.clear : Icons.select_all,
                          size: 18,
                          color: kBlue,
                        ),
                        label: Text(
                          _selectAllMode ? 'Clear' : 'Select All',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: kBlue,
                          ),
                        ),
                      ),

                      if (_selectedCarIds.isNotEmpty)
                        Chip(
                          label: Text(
                            '${_selectedCarIds.length} selected',
                            style: TextStyle(
                              color: kBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          backgroundColor: kWhite,
                        ),

                      DropdownButton<String>(
                        value: _filter,
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All')),
                          DropdownMenuItem(
                            value: 'assigned',
                            child: Text('Assigned'),
                          ),
                          DropdownMenuItem(
                            value: 'unassigned',
                            child: Text('Unassigned'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _filter = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 10),

            // Car List
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCarList(_assignedCars),
                  _buildCarList(_allCars),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _selectedCarIds.isNotEmpty
          ? Container(
              margin: const EdgeInsets.only(left: 20, right: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: CustomButton(
                      callBackFunction: () {},
                      label: "Assign",
                      backgroundColor: kBlue,
                      txtColor: kWhite,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: CustomButton(
                      callBackFunction: () {},
                      label: "Un Assign",
                      backgroundColor: kRed,
                      txtColor: kWhite,
                    ),
                  ),
                ],
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildCarList(List<Car> cars) {
    List<Car> filteredCars = cars;
    if (_filter == 'assigned') {
      filteredCars = cars.where((c) => c.isAssigned).toList();
    } else if (_filter == 'unassigned') {
      filteredCars = cars.where((c) => !c.isAssigned).toList();
    }

    if (filteredCars.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_car_outlined,
              size: 64,
              color: kLightGrey,
            ),
            const SizedBox(height: 16),
            Text(
              'No cars available',
              style: TextStyle(
                fontSize: 18,
                color: kGrey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: filteredCars.length,
      itemBuilder: (context, index) {
        final car = filteredCars[index];
        final isSelected = _selectedCarIds.contains(car.id);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: SelectableCarCard(
                onCheckboxChanged: (_) => _toggleCarSelection(car.id),
                car: car,
                isSelected: isSelected,
                onCardTap: () => _toggleCarSelection(car.id),
              ),
            ),
          ],
        );
      },
    );
  }
}

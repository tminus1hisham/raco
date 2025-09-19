import 'package:atom/config/constants.dart';
import 'package:atom/widgets/buttons/custom_button.dart';
import 'package:atom/widgets/cards/manager_car_card.dart';
import 'package:atom/widgets/custom_header.dart';
import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeCars();
  }

  void _initializeCars() {
    _allCars = [
      Car(
        id: '1',
        licensePlate: 'KDF 001A',
        carName: 'BMW X6',
        isAssigned: true,
      ),
      Car(
        id: '2',
        licensePlate: 'KBB 002B',
        carName: 'Isuzu NQR',
        isAssigned: false,
      ),
      Car(
        id: '3',
        licensePlate: 'KCC 003C',
        carName: 'Toyota Prado',
        isAssigned: true,
      ),
      Car(
        id: '4',
        licensePlate: 'KDD 004D',
        carName: 'Mercedes Benz',
        isAssigned: false,
      ),
      Car(
        id: '5',
        licensePlate: 'KEE 005E',
        carName: 'Ford Ranger',
        isAssigned: true,
      ),
      Car(
        id: '6',
        licensePlate: 'KFF 006F',
        carName: 'Nissan Navara',
        isAssigned: false,
      ),
    ];

    _assignedCars = _allCars.where((car) => car.isAssigned).toList();
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
            customHeader(label: "My Fleet", icon: Icons.directions_car),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: kBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey[600],
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
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _toggleSelectAll,
                      icon: Icon(
                        _selectAllMode ? Icons.deselect : Icons.select_all,
                        size: 18,
                      ),
                      label: Text(
                        _selectAllMode ? 'Clear' : 'Select All',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectAllMode ? Colors.orange : kBlue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  if (_selectedCarIds.isNotEmpty) ...[
                    SizedBox(width: 12),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_selectedCarIds.length} Selected',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
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
    if (cars.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_car_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'No cars available',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 20),
      itemCount: cars.length,
      itemBuilder: (context, index) {
        final car = cars[index];
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

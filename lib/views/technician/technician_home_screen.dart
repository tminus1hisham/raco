import 'package:atom/views/technician/create_device.dart';
import 'package:atom/widgets/custom_header.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:bluetooth_classic/bluetooth_classic.dart';
import 'package:bluetooth_classic/models/device.dart';

class TechnicianHomeScreen extends StatefulWidget {
  const TechnicianHomeScreen({super.key});

  @override
  State<TechnicianHomeScreen> createState() => _TechnicianHomeScreenState();
}

class _TechnicianHomeScreenState extends State<TechnicianHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            customHeader(label: "Technician", icon: Icons.work),
            const SizedBox(height: 30),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.95,
                  children: [
                    buildCard(
                      icon: Icons.add_circle_outline,
                      label: "Create Device",
                      color: Colors.blue,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => TechnicianScreen()),
                        );
                      },
                    ),
                    buildCard(
                      icon: Icons.bluetooth_searching,
                      label: "Connect Device",
                      color: Colors.teal,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ConnectDeviceScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 40, color: color),
              ),
              const SizedBox(height: 16),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ConnectDeviceScreen extends StatefulWidget {
  const ConnectDeviceScreen({super.key});

  @override
  State<ConnectDeviceScreen> createState() => _ConnectDeviceScreenState();
}

class _ConnectDeviceScreenState extends State<ConnectDeviceScreen> {
  final BluetoothClassic _bluetooth = BluetoothClassic();
  List<Device> _devices = [];
  List<Device> _pairedDevices = [];
  bool _isScanning = false;
  bool _isConnecting = false;
  String _receivedData = '';
  Device? _selectedDevice;
  StreamSubscription<Uint8List>? _dataSubscription;
  StreamSubscription<Device>? _discoverySubscription;
  bool _isConnected = false;

  // Common UUID for Serial Port Profile (SPP)
  static const String serialUuid = "00001101-0000-1000-8000-00805f9b34fb";

  @override
  void initState() {
    super.initState();
    _initializeBluetooth();
  }

  @override
  void dispose() {
    _dataSubscription?.cancel();
    _discoverySubscription?.cancel();
    _stopScanning();
    super.dispose();
  }

  Future<void> _initializeBluetooth() async {
    try {
      await _bluetooth.initPermissions();
      await _getPairedDevices();
    } catch (e) {
      _showError('Initialization error: $e');
    }
  }

  Future<void> _getPairedDevices() async {
    try {
      final devices = await _bluetooth.getPairedDevices();
      setState(() {
        _pairedDevices = devices;
        _devices = [...devices]; // Start with paired devices
      });
    } catch (e) {
      _showError('Failed to get paired devices: $e');
    }
  }

  Future<void> _startScanning() async {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
      _devices.clear();
    });

    try {
      // Listen for discovered devices
      _discoverySubscription?.cancel();
      _discoverySubscription = _bluetooth.onDeviceDiscovered().listen((device) {
        if (!_devices.any((d) => d.address == device.address)) {
          setState(() {
            if ((device.name ?? '').contains("Speed")) {
              _devices.add(device);
            }
          });
        }
      });

      // Start scanning
      await _bluetooth.startScan();

      // Auto-stop after 15 seconds
      await Future.delayed(const Duration(seconds: 15));
      await _stopScanning();

      setState(() {
        _isScanning = false;
      });
    } catch (e) {
      setState(() {
        _isScanning = false;
      });
      _showError('Scan failed: $e');
    }
  }

  Future<void> _stopScanning() async {
    try {
      await _bluetooth.stopScan();
      _discoverySubscription?.cancel();
      _discoverySubscription = null;
    } catch (e) {
      _showError('Stop scan error: $e');
    }
  }

  Future<void> _connectToDevice(Device device) async {
    if (_isConnecting) return;

    setState(() {
      _isConnecting = true;
      _selectedDevice = device;
    });

    try {
      // Connect to the device using SPP UUID
      await _bluetooth.connect(device.address, serialUuid);

      setState(() {
        _isConnecting = false;
        _isConnected = true;
      });

      _showSuccess('Connected to ${device.name ?? device.address}');

      // Start listening for incoming data
      _startListeningForData();
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _selectedDevice = null;
        _isConnected = false;
      });
      _showError('Connection failed: $e');
    }
  }

  Future<void> _disconnectDevice() async {
    try {
      await _bluetooth.disconnect();
      setState(() {
        _selectedDevice = null;
        _isConnected = false;
        _receivedData = '';
      });
      _dataSubscription?.cancel();
      _dataSubscription = null;
      _showSuccess('Disconnected');
    } catch (e) {
      _showError('Disconnect failed: $e');
    }
  }

  void _startListeningForData() {
    _dataSubscription?.cancel();
    _dataSubscription = _bluetooth.onDeviceDataReceived().listen((
      Uint8List data,
    ) {
      // Convert Uint8List to String
      final String receivedString = String.fromCharCodes(data);
      setState(() {
        _receivedData += receivedString;
      });
      debugPrint('Received data: $receivedString');
    });
  }

  Future<void> _sendCommand(String command) async {
    if (!_isConnected || _selectedDevice == null) {
      _showError('No device connected');
      return;
    }

    try {
      await _bluetooth.write(command);
      _showSuccess('Command sent: $command');
    } catch (e) {
      _showError('Failed to send command: $e');
    }
  }

  Future<void> _retrieveDataFromDevice() async {
    await _sendCommand('GetHeader');
  }

  void _clearReceivedData() {
    setState(() {
      _receivedData = '';
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildDeviceCard(Device device, bool isConnected, bool isConnecting) {
    final deviceName = device.name ?? 'Unknown Device';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: isConnected
            ? Border.all(color: Colors.deepPurple, width: 2)
            : null,
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isConnected
                ? Colors.deepPurple.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.bluetooth,
            color: isConnected ? Colors.deepPurple : Colors.grey,
          ),
        ),
        title: Text(
          deviceName,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isConnected ? Colors.deepPurple : Colors.grey[800],
          ),
        ),
        subtitle: Text(
          device.address,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            fontFamily: 'Monospace',
          ),
        ),
        trailing: isConnecting
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                ),
              )
            : ElevatedButton(
                onPressed: isConnected
                    ? _disconnectDevice
                    : () => _connectToDevice(device),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isConnected
                      ? Colors.redAccent
                      : Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                child: Text(isConnected ? 'Disconnect' : 'Connect'),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Connect Device"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          ),
        ),
        child: Column(
          children: [
            // Status and Controls Section
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // Connection Status
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isConnected
                              ? Icons.bluetooth_connected
                              : Icons.bluetooth_disabled,
                          color: Colors.white,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isConnected ? 'Connected' : 'Not Connected',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                _isConnected
                                    ? 'Connected to ${_selectedDevice?.name ?? _selectedDevice?.address ?? "Unknown"}'
                                    : 'Tap scan to find devices',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_isConnected)
                          IconButton(
                            onPressed: _disconnectDevice,
                            icon: const Icon(
                              Icons.link_off,
                              color: Colors.white,
                            ),
                            tooltip: 'Disconnect',
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Scan Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isScanning ? null : _startScanning,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                        shadowColor: Colors.black26,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isScanning)
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.deepPurple,
                                ),
                              ),
                            )
                          else
                            const Icon(Icons.search),
                          const SizedBox(width: 10),
                          Text(
                            _isScanning ? 'Scanning...' : 'Scan for Devices',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Received Data Section
                  if (_receivedData.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Received Data:',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: _clearReceivedData,
                                    icon: const Icon(
                                      Icons.clear_all,
                                      color: Colors.white,
                                    ),
                                    tooltip: 'Clear',
                                  ),
                                  IconButton(
                                    onPressed: _retrieveDataFromDevice,
                                    icon: const Icon(
                                      Icons.refresh,
                                      color: Colors.white,
                                    ),
                                    tooltip: 'Get Data',
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            height: 120,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: SingleChildScrollView(
                              child: Text(
                                _receivedData,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Monospace',
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Devices List Section
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 20,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Available Devices (${_devices.length})',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _getPairedDevices,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Refresh Paired'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple.withOpacity(
                                0.1,
                              ),
                              foregroundColor: Colors.deepPurple,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _devices.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.bluetooth_disabled,
                                    size: 80,
                                    color: Colors.grey[300],
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'No devices found',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[500],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Tap the scan button to discover nearby devices',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[400],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _devices.length,
                              itemBuilder: (context, index) {
                                final device = _devices[index];
                                final isConnected =
                                    _isConnected &&
                                    _selectedDevice?.address == device.address;
                                final isConnecting =
                                    _isConnecting &&
                                    _selectedDevice?.address == device.address;

                                return _buildDeviceCard(
                                  device,
                                  isConnected,
                                  isConnecting,
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _isConnected
          ? FloatingActionButton.extended(
              onPressed: _retrieveDataFromDevice,
              icon: const Icon(Icons.download),
              label: const Text('Get Data'),
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }
}

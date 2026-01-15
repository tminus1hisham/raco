import 'dart:async';
import 'dart:convert';
import 'package:atom/config/constants.dart';
import 'package:atom/services/local_storage_service.dart';
import 'package:atom/widgets/custom_header.dart';
import 'package:flutter/material.dart';
import 'package:atom/models/company_model.dart';
import 'package:atom/services/api_service.dart';
import 'package:bluetooth_classic/bluetooth_classic.dart' as bt_classic;
import 'package:atom/models/register_device_model.dart';
import 'package:bluetooth_classic/models/device.dart' as bt_device;
import 'package:flutter_bluetooth_classic_serial/flutter_bluetooth_classic.dart'
    as bt_serial;

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
  final GlobalKey<FormState> _registrationFormKey = GlobalKey<FormState>();

  // Company search and selection
  List<Map<String, dynamic>> _allCompanies = [];
  List<Map<String, dynamic>> _filteredCompanies = [];
  bool _showCompanySuggestions = false;
  bool _isLoadingCompanies = false;
  String _companySearchQuery = '';
  FocusNode _companyFocusNode = FocusNode();
  FocusNode _companyPhoneFocusNode = FocusNode();

  // Form controllers
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _companyPhoneController = TextEditingController();
  final TextEditingController _technicianIdController = TextEditingController();
  final TextEditingController _technicianNameController =
      TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _regController = TextEditingController();
  final TextEditingController _chassisController = TextEditingController();
  final TextEditingController _makeController = TextEditingController();
  final TextEditingController _certNoController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _serialController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _agentController = TextEditingController();
  final TextEditingController _agentIDController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _agentPhoneController = TextEditingController();
  final TextEditingController _businessRegController = TextEditingController();
  final TextEditingController _groupController = TextEditingController();

  Map<String, dynamic> _deviceData = {};
  bool _showRegistrationForm = false;

  // Use bluetooth_classic for scanning
  final bt_classic.BluetoothClassic _bluetoothClassic =
      bt_classic.BluetoothClassic();

  // Use flutter_bluetooth_classic_serial for connection and data
  late bt_serial.FlutterBluetoothClassic _bluetoothSerial;

  List<bt_device.Device> _devices = [];
  List<bt_device.Device> _pairedDevices = [];
  bool _isScanning = false;
  Map<String, bool> _connectingDevices =
      {}; // Track connecting state per device
  String _receivedData = '';
  bt_device.Device? _selectedDevice;
  bool _isConnected = false;
  bool _isBluetoothEnabled = false;

  // Stream subscriptions for scanning
  StreamSubscription<bt_device.Device>? _discoverySubscription;
  Timer? _scanTimeoutTimer;

  // Stream subscriptions for serial connection
  StreamSubscription<bt_serial.BluetoothConnectionState>?
  _connectionSubscription;
  StreamSubscription<bt_serial.BluetoothData>? _dataSubscription;
  StreamSubscription<bt_serial.BluetoothState>? _stateSubscription;

  // Buffer for accumulating JSON data
  StringBuffer _jsonBuffer = StringBuffer();
  Timer? _jsonCompletionTimer;

  @override
  void initState() {
    super.initState();
    _bluetoothSerial = bt_serial.FlutterBluetoothClassic();
    _initializeBluetooth();
    _loadStorageData();

    _loadAllCompanies(); // Add this line

    // Initialize focus nodes
    _companyFocusNode = FocusNode();
    _companyPhoneFocusNode = FocusNode();
  }

  Future<void> _loadAllCompanies() async {
    try {
      setState(() {
        _isLoadingCompanies = true;
      });

      // Use your ApiService to fetch companies
      final CompanyModel companyModel = await ApiService.fetchCompanies();

      // Since your API returns a raw list, we need to handle it
      // First check if companyModel.data is populated from the API response
      if (companyModel.data.isNotEmpty) {
        setState(() {
          // Map the Company objects from your model to the format needed for filtering
          _allCompanies = companyModel.data.map<Map<String, dynamic>>((
            company,
          ) {
            return {
              'name': company.fullName,
              'phone': company.phoneNumber,
              'email': '',
              'address': '',
              'businessReg': '',
            };
          }).toList();

          _isLoadingCompanies = false;
        });

        debugPrint('Loaded ${_allCompanies.length} companies from API');
      } else {
        debugPrint('No companies loaded from API');
        setState(() {
          _isLoadingCompanies = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading companies: $e');
      setState(() {
        _isLoadingCompanies = false;
      });

      _showError('Failed to load companies: $e');
    }
  }

  void _filterCompanies(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredCompanies = [];
        _showCompanySuggestions = false;
        _companySearchQuery = query;
      });
      return;
    }

    final queryLower = query.toLowerCase();

    setState(() {
      _companySearchQuery = query;
      _filteredCompanies = _allCompanies.where((company) {
        final name = company['name']?.toLowerCase() ?? '';
        final phone = company['phone']?.toLowerCase() ?? '';
        final email = company['email']?.toLowerCase() ?? '';

        return name.contains(queryLower) ||
            phone.contains(queryLower) ||
            email.contains(queryLower);
      }).toList();

      _showCompanySuggestions =
          query.length >= 2 && _filteredCompanies.isNotEmpty;
    });
  }

  void _selectCompany(Map<String, dynamic> company) {
    setState(() {
      _companyController.text = company['name'] ?? '';
      _companyPhoneController.text = company['phone'] ?? '';

      // Optionally fill other fields if available and empty
      if (company['email'] != null &&
          company['email'].isNotEmpty &&
          _emailController.text.isEmpty) {
        _emailController.text = company['email']!;
      }

      if (company['businessReg'] != null &&
          company['businessReg'].isNotEmpty &&
          _businessRegController.text.isEmpty) {
        _businessRegController.text = company['businessReg']!;
      }

      if (company['address'] != null &&
          company['address'].isNotEmpty &&
          _locationController.text.isEmpty) {
        _locationController.text = company['address']!;
      }

      _filteredCompanies = [];
      _showCompanySuggestions = false;
    });

    // Move focus to next field
    _companyPhoneFocusNode.requestFocus();
  }

  Future<void> _loadStorageData() async {
    try {
      // Load all storage data at once
      final technicianId = await StorageService.getData('userDbId');
      final technicianName = await StorageService.getData('userName');
      final agentName = await StorageService.getData('agentName');
      final agentId = await StorageService.getData('agentId');
      final agentLocation = await StorageService.getData('agentLocation');
      final agentEmail = await StorageService.getData('agentEmail');
      final agentPhone = await StorageService.getData('agentPhone');
      final businessReg = await StorageService.getData('businessReg');

      _technicianIdController.text = technicianId ?? '';
      _technicianNameController.text = technicianName ?? '';

      _agentController.text = agentName ?? '';
      _agentIDController.text = agentId ?? '';
      _locationController.text = agentLocation ?? '';
      _emailController.text = agentEmail ?? '';
      _agentPhoneController.text = agentPhone ?? '';
      _businessRegController.text = businessReg ?? '';
    } catch (e) {
      debugPrint('Error loading storage data: $e');
    }
  }

  @override
  void dispose() {
    _discoverySubscription?.cancel();
    _scanTimeoutTimer?.cancel();
    _connectionSubscription?.cancel();
    _dataSubscription?.cancel();
    _stateSubscription?.cancel();
    _jsonCompletionTimer?.cancel();
    _stopScanning();
    _bluetoothSerial.disconnect();

    // Dispose focus nodes
    _companyFocusNode.dispose();
    _companyPhoneFocusNode.dispose();

    super.dispose();
  }

  Future<void> _initializeBluetooth() async {
    try {
      // Initialize both packages
      await _bluetoothClassic.initPermissions();

      // Check Bluetooth status using serial package (more reliable)
      bool isSupported = await _bluetoothSerial.isBluetoothSupported();
      if (!isSupported) {
        _showError('Bluetooth is not supported on this device');
        return;
      }

      bool isEnabled = await _bluetoothSerial.isBluetoothEnabled();
      setState(() {
        _isBluetoothEnabled = isEnabled;
      });

      if (isEnabled) {
        _setupSerialListeners();
        await _loadPairedDevices();
      } else {
        _showError('Please enable Bluetooth to continue');
      }
    } catch (e) {
      _showError('Initialization error: $e');
    }
  }

  Future<void> _saveCompany() async {
    final companyName = _companyController.text.trim();
    final companyPhone = _companyPhoneController.text.trim();

    if (companyName.isEmpty || companyPhone.isEmpty) return;

    try {
      // Get existing saved companies
      final savedCompaniesJson = await StorageService.getData(
        'saved_companies',
      );
      List<Map<String, dynamic>> savedCompanies = [];

      if (savedCompaniesJson != null && savedCompaniesJson.isNotEmpty) {
        try {
          final List<dynamic> companiesList = json.decode(savedCompaniesJson);
          savedCompanies = companiesList.map<Map<String, dynamic>>((company) {
            return Map<String, dynamic>.from(company);
          }).toList();
        } catch (e) {
          debugPrint('Error parsing saved companies: $e');
        }
      }

      // Check if company already exists
      final existingIndex = savedCompanies.indexWhere(
        (company) =>
            company['name']?.toString().toLowerCase() ==
            companyName.toLowerCase(),
      );

      if (existingIndex >= 0) {
        // Update existing company
        savedCompanies[existingIndex] = {
          'name': companyName,
          'phone': companyPhone,
          'lastUsed': DateTime.now().toIso8601String(),
        };
      } else {
        // Add new company
        savedCompanies.add({
          'name': companyName,
          'phone': companyPhone,
          'lastUsed': DateTime.now().toIso8601String(),
        });
      }

      // Sort by last used (most recent first)
      savedCompanies.sort((a, b) {
        final aTime = DateTime.parse(a['lastUsed'] ?? '2000-01-01');
        final bTime = DateTime.parse(b['lastUsed'] ?? '2000-01-01');
        return bTime.compareTo(aTime);
      });

      // Keep only last 20 companies
      if (savedCompanies.length > 20) {
        savedCompanies = savedCompanies.sublist(0, 20);
      }

      debugPrint('Company saved: $companyName');
    } catch (e) {
      debugPrint('Error saving company: $e');
    }
  }

  void _setupSerialListeners() {
    // Listen for Bluetooth state changes from serial package
    _stateSubscription = _bluetoothSerial.onStateChanged.listen((state) {
      setState(() {
        _isBluetoothEnabled = state.isEnabled;
      });
    });

    // Listen for connection changes from serial package
    _connectionSubscription = _bluetoothSerial.onConnectionChanged.listen((
      connectionState,
    ) {
      if (connectionState.isConnected) {
        setState(() {
          // Clear all connecting states
          _connectingDevices.clear();
          _isConnected = true;
        });

        _showSuccess('Connected to device');

        // Start listening for data
        _startListeningForData();
      } else {
        // Disconnected
        setState(() {
          _connectingDevices.clear();
          _isConnected = false;
          _selectedDevice = null;
          _receivedData = '';
          _jsonBuffer.clear();
        });

        if (connectionState.status.toLowerCase().contains('error')) {
          _showError('Connection error: ${connectionState.status}');
        }
      }
    });
  }

  Future<void> _loadPairedDevices() async {
    try {
      List<bt_device.Device> devices = await _bluetoothClassic
          .getPairedDevices();
      setState(() {
        _pairedDevices = devices;
        _devices = _getFilteredDevices();
      });
    } catch (e) {
      _showError('Failed to load paired devices: $e');
    }
  }

  List<bt_device.Device> _getFilteredDevices() {
    // Filter to only show Atom Speed devices
    return _pairedDevices.where((device) {
      final name = device.name?.toLowerCase() ?? '';
      return name.contains('atom speed');
    }).toList();
  }

  Future<void> _startScanning() async {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
    });

    try {
      // Listen for discovered devices using bluetooth_classic package
      _discoverySubscription?.cancel();
      _discoverySubscription = _bluetoothClassic.onDeviceDiscovered().listen((
        device,
      ) {
        final deviceName = device.name?.toLowerCase() ?? '';

        // Check if device name contains "atom speed" (case-insensitive)
        if (deviceName.contains('atom speed')) {
          if (!_devices.any((d) => d.address == device.address)) {
            setState(() {
              _devices.add(device);
            });
          }
        }
      });

      // Start scanning with bluetooth_classic package
      await _bluetoothClassic.startScan();

      // Auto-stop after 15 seconds
      _scanTimeoutTimer?.cancel();
      _scanTimeoutTimer = Timer(const Duration(seconds: 15), () async {
        await _stopScanning();
        setState(() {
          _isScanning = false;
        });
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
      await _bluetoothClassic.stopScan();
      _discoverySubscription?.cancel();
      _discoverySubscription = null;
      _scanTimeoutTimer?.cancel();
    } catch (e) {
      _showError('Stop scan error: $e');
    }
  }

  Future<void> _connectToDevice(bt_device.Device device) async {
    if (_isConnected || _connectingDevices[device.address] == true) return;

    setState(() {
      _connectingDevices[device.address] = true;
      _selectedDevice = device;
    });

    try {
      // Use flutter_bluetooth_classic_serial package for connection
      bool success = await _bluetoothSerial.connect(device.address);
      if (!success) {
        setState(() {
          _connectingDevices.remove(device.address);
          _selectedDevice = null;
        });
        _showError('Failed to connect to ${device.name}');
      }
    } catch (e) {
      setState(() {
        _connectingDevices.remove(device.address);
        _selectedDevice = null;
      });
      _showError('Connection error: $e');
    }
  }

  Future<void> _disconnectDevice() async {
    try {
      await _bluetoothSerial.disconnect();
      _showSuccess('Disconnected');
    } catch (e) {
      _showError('Disconnect error: $e');
    }
  }

  void _startListeningForData() {
    _dataSubscription?.cancel();
    _jsonBuffer.clear();

    _dataSubscription = _bluetoothSerial.onDataReceived.listen((data) {
      final chunk = data.asString();
      debugPrint('Received chunk: "$chunk"');

      // Add chunk to buffer
      _jsonBuffer.write(chunk);
      final bufferString = _jsonBuffer.toString();

      // Try to parse as JSON
      _tryParseJsonBuffer(bufferString);
    });
  }

  void _tryParseJsonBuffer(String bufferString) {
    // Cancel any existing timer
    _jsonCompletionTimer?.cancel();

    // Check if we have complete JSON (matching braces)
    final openBraces = '{'.allMatches(bufferString).length;
    final closeBraces = '}'.allMatches(bufferString).length;

    if (openBraces > 0 && openBraces == closeBraces) {
      // We have complete JSON - process it
      _processCompleteJson(bufferString);
    } else if (openBraces > 0 && bufferString.contains('{')) {
      // We have opening brace but no closing - wait for more data
      _jsonCompletionTimer = Timer(const Duration(milliseconds: 100), () {
        if (_jsonBuffer.isNotEmpty) {
          final currentBuffer = _jsonBuffer.toString();
          final currentOpenBraces = '{'.allMatches(currentBuffer).length;
          final currentCloseBraces = '}'.allMatches(currentBuffer).length;

          if (currentOpenBraces > 0 &&
              currentOpenBraces == currentCloseBraces) {
            _processCompleteJson(currentBuffer);
          }
        }
      });
    }
  }

  void _processCompleteJson(String bufferString) {
    try {
      // Extract JSON from first { to last }
      final startIndex = bufferString.indexOf('{');
      final endIndex = bufferString.lastIndexOf('}');

      if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
        final jsonString = bufferString.substring(startIndex, endIndex + 1);
        debugPrint('Complete JSON extracted: $jsonString');

        // Parse JSON
        final jsonData = json.decode(jsonString);
        debugPrint('Parsed JSON: $jsonData');

        // Store the parsed data
        setState(() {
          _deviceData = jsonData;
          _receivedData =
              '${DateTime.now().toString()}\n${JsonEncoder.withIndent('  ').convert(jsonData)}\n\n${_receivedData}';
        });

        _prepopulateFormData();

        // Clear buffer
        _jsonBuffer.clear();

        // Add any remaining text after JSON back to buffer
        if (endIndex + 1 < bufferString.length) {
          final remaining = bufferString.substring(endIndex + 1);
          _jsonBuffer.write(remaining);
        }

        // Show success message and navigate to technician screen
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _navigateToTechnicianScreen();
        });
      }
    } catch (e) {
      debugPrint('JSON parsing error: $e');
      // If parsing fails, show raw data
      setState(() {
        _receivedData = 'Raw data: $bufferString\n${_receivedData}';
      });
    }
  }

  void _navigateToTechnicianScreen() {
    setState(() {
      _showRegistrationForm = true; // Show modal instead of navigating
    });
  }

  String _getMonthName(int month) {
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return monthNames[month - 1];
  }

  void _prepopulateFormData() {
    if (_deviceData.isNotEmpty) {
      // Map your JSON data to form fields
      _certNoController.text = _deviceData['LimiterID']?.toString() ?? '';
      _serialController.text = _deviceData['MnfSerial']?.toString() ?? '';
      _dateController.text =
          _deviceData['date']?.toString() ??
          "${_getMonthName(DateTime.now().month)} ${DateTime.now().day}, ${DateTime.now().year}";
      // Add mappings for all other fields...
    }
  }

  Future<void> _sendCommand(String command) async {
    if (!_isConnected) {
      _showError('No device connected');
      return;
    }

    try {
      bool success = await _bluetoothSerial.sendString(command);
      if (success) {
        _showSuccess('Command sent: $command');
        debugPrint('Sent command: $command');
      } else {
        _showError('Failed to send command');
      }
    } catch (e) {
      _showError('Send error: $e');
    }
  }

  Future<void> _retrieveDataFromDevice() async {
    await _sendCommand('GetORCAid>');
  }

  Future<void> _registerDevice() async {
    if (!_registrationFormKey.currentState!.validate()) {
      return;
    }

    try {
      // Show loading
      _showLoading('Registering device...');
      setState(() {
        _showRegistrationForm = false;
      });

      // Prepare the registration data
      Map<String, dynamic> registrationData = {
        "company": _companyController.text.trim(),
        "companyPhone": _companyPhoneController.text.trim(),
        "technicianId": int.tryParse(_technicianIdController.text.trim()) ?? 0,
        "technicianName": _technicianNameController.text.trim(),
        "Name": _nameController.text.trim(),
        "ID": _idController.text.trim(),
        "Phone": _phoneController.text.trim(),
        "reg": _regController.text.trim(),
        "chassis": _chassisController.text.trim(),
        "make": _makeController.text.trim(),
        "CertNo": _certNoController.text.trim(),
        "Type": "Orca",
        "serial": _serialController.text.trim(),
        "date": _dateController.text.trim(),
        "agent": _agentController.text.trim(),
        "agentID": _agentIDController.text.trim(),
        "location": _locationController.text.trim(),
        "email": _emailController.text.trim(),
        "agentPhone": _agentPhoneController.text.trim(),
        "businessReg": _businessRegController.text.trim(),
        "group": _groupController.text.trim() ?? 'NONE',
      };

      debugPrint('Registration data: $registrationData');

      // Make API call
      final response = await ApiService.registerDevice(registrationData);

      debugPrint('Registration response: $response');

      // Hide loading
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Check response
      if (response['success'] == true) {

        // Send Command To Device
        await _sendCommand(jsonEncode(registrationData));

        // Show success message
        _showSuccess('Device registered successfully!');


        // Close the modal
        setState(() {
          _showRegistrationForm = false;
        });

        // Optionally: Clear form or show success dialog
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showRegistrationSuccessDialog(response);
        });
      } else {
        // Show error from API
        final errorMessage = response['message'] ?? 'Registration failed';
        _showError(errorMessage);
      }
    } catch (e) {
      // Hide loading
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      debugPrint('Registration error: $e');

      // Extract error message from exception
      String errorMessage = 'Registration failed';

      if (e is Map<String, dynamic>) {
        // If exception is a Map (from API response)
        errorMessage = e['message'] ?? e['error'] ?? errorMessage;
      } else if (e is String) {
        // If exception is a String
        errorMessage = e;
      } else if (e is Exception || e is Error) {
        // If exception is an Exception or Error object
        errorMessage = e.toString();

        // Try to extract more specific message
        final match = RegExp(r'Exception:\s*(.+)$').firstMatch(errorMessage);
        if (match != null && match.groupCount >= 1) {
          errorMessage = match.group(1) ?? errorMessage;
        }
      }

      // Show the error message
      _showError(errorMessage);

      // Keep modal open so user can fix errors
      // Don't set _showRegistrationForm = false
    }
  }

  void _clearReceivedData() {
    setState(() {
      _receivedData = '';
      _jsonBuffer.clear();
    });
  }

  void _showLoading(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: const TextStyle(fontSize: 14)),
            ),
          ],
        ),
        backgroundColor: kBlue,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 30),
      ),
    );
  }

  void _showRegistrationSuccessDialog(Map<String, dynamic> response) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Registration Successful'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Device has been registered successfully!'),
            const SizedBox(height: 16),
            if (response['deviceId'] != null)
              Text('Device ID: ${response['deviceId']}'),
            if (response['certificateNumber'] != null)
              Text('Certificate: ${response['certificateNumber']}'),
            if (response['registrationNumber'] != null)
              Text('Registration: ${response['registrationNumber']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Optionally clear form or navigate
              _clearForm();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _clearForm() {
    // Clear only the fields that should be cleared
    // Don't clear technician and agent fields from storage
    _nameController.clear();
    _idController.clear();
    _phoneController.clear();
    _regController.clear();
    _chassisController.clear();
    _makeController.clear();
    _groupController.clear();

    // Keep device data fields (they're read-only anyway)
    // _certNoController - keep (from device)
    // _serialController - keep (from device)
    // _dateController - keep

    // Keep company fields in case they want to register another device
    // _companyController - keep
    // _companyPhoneController - keep

    // Keep agent fields (from storage)
    // _agentController - keep
    // _agentIDController - keep
    // _locationController - keep
    // _emailController - keep
    // _agentPhoneController - keep
    // _businessRegController - keep
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildDeviceCard(bt_device.Device device, bool isConnected) {
    final deviceName = device.name ?? 'Unknown Device';
    final isConnecting = _connectingDevices[device.address] == true;

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
        border: isConnected ? Border.all(color: kBlue, width: 2) : null,
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isConnected
                ? kBlue.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.bluetooth,
            color: isConnected ? kBlue : Colors.grey,
          ),
        ),
        title: Text(
          deviceName,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isConnected ? kBlue : Colors.grey[800],
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
        trailing: SizedBox(
          width: 120,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isConnecting)
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(kBlue),
                  ),
                )
              else if (isConnected)
                ElevatedButton(
                  onPressed: _disconnectDevice,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  child: const Text('Disconnect'),
                )
              else
                ElevatedButton(
                  onPressed: () => _connectToDevice(device),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  child: const Text('Connect'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegistrationForm() {
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: kBlue,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.developer_board,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Device Registration',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: () {
                      setState(() {
                        _showRegistrationForm = false;
                      });
                    },
                  ),
                ],
              ),
            ),

            // Form content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _registrationFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Bluetooth Info Banner
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: kBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: kBlue.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.bluetooth_connected,
                              color: kBlue,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Device data loaded from Bluetooth connection',
                                style: TextStyle(
                                  color: kBlue,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Company Information Section
                      // Company Information Section
                      Text(
                        'Company Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: kBlue,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Company Name with Autocomplete
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _companyController,
                            focusNode: _companyFocusNode,
                            decoration: InputDecoration(
                              labelText: 'Company Name *',
                              hintText: _isLoadingCompanies
                                  ? 'Loading companies...'
                                  : 'Start typing to search ${_allCompanies.length} companies...',
                              prefixIcon: Icon(Icons.business),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              suffixIcon: _isLoadingCompanies
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              kBlue,
                                            ),
                                      ),
                                    )
                                  : _companyController.text.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(Icons.clear, size: 20),
                                      onPressed: () {
                                        setState(() {
                                          _companyController.clear();
                                          _companyPhoneController.clear();
                                          _filteredCompanies = [];
                                          _showCompanySuggestions = false;
                                        });
                                      },
                                    )
                                  : null,
                            ),
                            onChanged: (value) {
                              _filterCompanies(value);
                            },
                            onTapOutside: (event) {
                              // Hide suggestions when tapping outside
                              Future.delayed(Duration(milliseconds: 200), () {
                                if (mounted) {
                                  setState(() {
                                    _showCompanySuggestions = false;
                                  });
                                }
                              });
                            },
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return "Company name is required";
                              }
                              return null;
                            },
                          ),

                          // Company Suggestions Dropdown
                          if (_showCompanySuggestions &&
                              _filteredCompanies.isNotEmpty)
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              margin: EdgeInsets.only(top: 4),
                              constraints: BoxConstraints(maxHeight: 200),
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: _filteredCompanies.length,
                                itemBuilder: (context, index) {
                                  final company = _filteredCompanies[index];
                                  return Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () => _selectCompany(company),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.business,
                                                  size: 18,
                                                  color: kBlue,
                                                ),
                                                SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    company['name'] ?? '',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (company['phone'] != null &&
                                                company['phone'].isNotEmpty)
                                              Padding(
                                                padding: EdgeInsets.only(
                                                  left: 26,
                                                  top: 4,
                                                ),
                                                child: Text(
                                                  company['phone']!,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              ),
                                            if (company['email'] != null &&
                                                company['email'].isNotEmpty)
                                              Padding(
                                                padding: EdgeInsets.only(
                                                  left: 26,
                                                  top: 2,
                                                ),
                                                child: Text(
                                                  company['email']!,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                          // No results found message
                          if (_companySearchQuery.length >= 2 &&
                              _filteredCompanies.isEmpty &&
                              !_isLoadingCompanies)
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              margin: EdgeInsets.only(top: 4),
                              child: Text(
                                'No existing company found with "$_companySearchQuery". You can enter a new company.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Company Phone
                      TextFormField(
                        controller: _companyPhoneController,
                        focusNode: _companyPhoneFocusNode,
                        decoration: InputDecoration(
                          labelText: 'Company Phone *',
                          hintText: 'Company phone number',
                          prefixIcon: Icon(Icons.phone),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Company phone is required";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Technician Information Section
                      Text(
                        'Technician Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: kBlue,
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _technicianIdController,
                        decoration: InputDecoration(
                          labelText: 'Technician ID',
                          hintText: 'Enter technician ID',
                          prefixIcon: Icon(Icons.badge),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        readOnly: _technicianIdController.text.isNotEmpty,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Technician ID is required";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _technicianNameController,
                        decoration: InputDecoration(
                          labelText: 'Technician Name',
                          hintText: 'Enter technician name',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        readOnly: _technicianNameController.text.isNotEmpty,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Technician name is required";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Device Owner Information Section
                      Text(
                        'Device Owner Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: kBlue,
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Owner Name',
                          hintText: 'Enter owner name',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Owner name is required";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _idController,
                        decoration: InputDecoration(
                          labelText: 'Owner ID',
                          hintText: 'Enter owner ID',
                          prefixIcon: Icon(Icons.perm_identity),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Owner ID is required";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          labelText: 'Owner Phone',
                          hintText: 'Enter owner phone number',
                          prefixIcon: Icon(Icons.phone_android),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Owner phone is required";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Vehicle Information Section
                      Text(
                        'Vehicle Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: kBlue,
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _regController,
                        decoration: InputDecoration(
                          labelText: 'Registration Number',
                          hintText: 'Enter vehicle registration number',
                          prefixIcon: Icon(Icons.confirmation_number),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Registration number is required";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _chassisController,
                        decoration: InputDecoration(
                          labelText: 'Chassis Number',
                          hintText: 'Enter chassis number',
                          prefixIcon: Icon(Icons.directions_car),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Chassis number is required";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _makeController,
                        decoration: InputDecoration(
                          labelText: 'Vehicle Make',
                          hintText: 'Enter vehicle make (e.g., Toyota, Honda)',
                          prefixIcon: Icon(Icons.directions_car_filled),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Vehicle make is required";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Device Information Section
                      Text(
                        'Device Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: kBlue,
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _certNoController,
                        decoration: InputDecoration(
                          labelText: 'Certificate Number',
                          hintText: 'Enter certificate number',
                          prefixIcon: Icon(Icons.verified),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        readOnly: _certNoController.text.isNotEmpty,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Certificate number is required";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _serialController,
                        decoration: InputDecoration(
                          labelText: 'Device Serial Number',
                          hintText: 'Enter device serial number',
                          prefixIcon: Icon(Icons.numbers),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        readOnly: _serialController.text.isNotEmpty,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Serial number is required";
                          }
                          return null;
                        },
                      ),
                      if (_serialController.text.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0, top: 4),
                          child: Text(
                            'Populated from device data',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _dateController,
                        decoration: InputDecoration(
                          labelText: 'Date',
                          hintText: 'Enter date (e.g., Nov 10, 2025)',
                          prefixIcon: Icon(Icons.calendar_today),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        readOnly: _dateController.text.isNotEmpty,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Date is required";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Agent Information Section
                      Text(
                        'Agent Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: kBlue,
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _agentController,
                        decoration: InputDecoration(
                          labelText: 'Agent Name',
                          hintText: 'Enter agent name',
                          prefixIcon: Icon(Icons.person_add),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        readOnly: _agentController.text.isNotEmpty,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Agent name is required";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _agentIDController,
                        decoration: InputDecoration(
                          labelText: 'Agent ID',
                          hintText: 'Enter agent ID',
                          prefixIcon: Icon(Icons.badge_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        readOnly: _agentIDController.text.isNotEmpty,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Agent ID is required";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _locationController,
                        decoration: InputDecoration(
                          labelText: 'Location',
                          hintText: 'Enter location',
                          prefixIcon: Icon(Icons.location_on),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        readOnly: _locationController.text.isNotEmpty,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Location is required";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          hintText: 'Enter email address',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        readOnly: _emailController.text.isNotEmpty,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Email is required";
                          }
                          if (!RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          ).hasMatch(value)) {
                            return "Enter a valid email address";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _agentPhoneController,
                        decoration: InputDecoration(
                          labelText: 'Agent Phone',
                          hintText: 'Enter agent phone number',
                          prefixIcon: Icon(Icons.phone_iphone),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        readOnly: _agentPhoneController.text.isNotEmpty,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Agent phone is required";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _businessRegController,
                        decoration: InputDecoration(
                          labelText: 'Business Registration',
                          hintText: 'Enter business registration number',
                          prefixIcon: Icon(Icons.app_registration),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        readOnly: _businessRegController.text.isNotEmpty,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Business registration is required";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _groupController,
                        decoration: InputDecoration(
                          labelText: 'Group',
                          hintText: 'Enter group name',
                          prefixIcon: Icon(Icons.group),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Group is required";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Register Button
                      ElevatedButton(
                        onPressed: _registerDevice,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Register Device',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    if (!_isBluetoothEnabled) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Connect Device"),
          backgroundColor: kBlue,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.bluetooth_disabled,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              const Text(
                'Bluetooth Disabled',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please enable Bluetooth to scan for devices',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _initializeBluetooth,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: const Text('Enable Bluetooth'),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text("Connect Device"),
            backgroundColor: kBlue,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              if (_isScanning)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Scanning...',
                        style: TextStyle(fontSize: 14, color: Colors.white),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [kBlue, kBlue],
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
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
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
                                    _isConnected
                                        ? 'Connected'
                                        : 'Not Connected',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    _isConnected
                                        ? 'Connected to ${_selectedDevice?.name ?? "Unknown"}'
                                        : 'Tap scan to find Atom Speed devices',
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

                      // Scan Button with improved UI
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _isScanning ? null : _startScanning,
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_isScanning)
                                    SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              kBlue,
                                            ),
                                      ),
                                    )
                                  else
                                    Icon(Icons.search, color: kBlue, size: 24),
                                  const SizedBox(width: 12),
                                  Text(
                                    _isScanning
                                        ? 'Scanning for Atom Speed devices...'
                                        : 'Scan for Atom Speed Devices',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: _isScanning
                                          ? kBlue.withOpacity(0.7)
                                          : kBlue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Scan status indicator
                      if (_isScanning)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            'Found ${_devices.length} Atom Speed device(s)',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Atom Speed Devices',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: kBlue,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_devices.length} device(s) found',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              ElevatedButton.icon(
                                onPressed: _loadPairedDevices,
                                icon: const Icon(Icons.refresh, size: 20),
                                label: const Text('Refresh'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kBlue.withOpacity(0.1),
                                  foregroundColor: kBlue,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
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
                                        'No Atom Speed devices found',
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
                                      if (!_isScanning)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 20,
                                          ),
                                          child: ElevatedButton(
                                            onPressed: _startScanning,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: kBlue,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 24,
                                                    vertical: 12,
                                                  ),
                                            ),
                                            child: const Text('Start Scanning'),
                                          ),
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
                                        _selectedDevice?.address ==
                                            device.address;

                                    return _buildDeviceCard(
                                      device,
                                      isConnected,
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
                  label: const Text('Get Device Data'),
                  backgroundColor: kBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                  elevation: 4,
                )
              : null,
        ),

        // Registration Form Modal Overlay
        if (_showRegistrationForm) ...[
          // Semi-transparent background overlay
          GestureDetector(
            onTap: () {
              setState(() {
                _showRegistrationForm = false;
              });
            },
            child: Container(
              color: Colors.black.withOpacity(0.5),
              width: double.infinity,
              height: double.infinity,
            ),
          ),

          // Registration Form Dialog
          Center(child: _buildRegistrationForm()),
        ],
      ],
    );
  }
}

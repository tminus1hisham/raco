import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:atom/config/app_theme.dart';
import 'package:atom/config/constants.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:atom/services/local_storage_service.dart';
import 'package:atom/widgets/custom_header.dart';
import 'package:flutter/material.dart';
import 'package:atom/models/company_model.dart';
import 'package:atom/services/api_service.dart';
import 'package:atom/models/register_device_model.dart';
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
    final col = context.col;
    return Scaffold(
      backgroundColor: col.bg,
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
                      color: kBlue,
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
    final col = context.col;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(kRadiusPill),
        child: Container(
          decoration: BoxDecoration(
            color: col.surface,
            borderRadius: BorderRadius.circular(kRadiusPill),
            boxShadow: [
              BoxShadow(
                color: kGrey.withValues(alpha: 0.1),
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
                  color: color.withValues(alpha: 0.1),
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
                  color: col.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class ConnectDeviceScreen extends StatefulWidget {
  const ConnectDeviceScreen({super.key});

  @override
  State<ConnectDeviceScreen> createState() => _ConnectDeviceScreenState();
}

class _ConnectDeviceScreenState extends State<ConnectDeviceScreen> {
  final GlobalKey<FormState> _registrationFormKey = GlobalKey<FormState>();

  TextEditingController _frequencyController = TextEditingController(text: '0');
  FocusNode _frequencyFocusNode = FocusNode();

  static const int MAX_FREQUENCY = 5000;
  static const int MIN_FREQUENCY = 1;

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
  final TextEditingController _technicianPhoneController =
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

  String? _selectedGroup;
  static const List<String> _groupOptions = ['PUBLIC', 'PRIVATE'];

  Map<String, dynamic> _deviceData = {};
  bool _showRegistrationForm = false;
  bool _showHeaderDetailsPopup = false;
  bool _isRoutingDevicePayload = false;
  bool _awaitingOrcaId = false;
  bool _pendingPostResetFlow = false;
  Map<String, String> _resolvedHeaderDetails = {};

  late bt_serial.FlutterBluetoothClassic _bluetoothSerial;

  List<bt_serial.BluetoothDevice> _devices = [];
  List<bt_serial.BluetoothDevice> _pairedDevices = [];
  bool _isScanning = false;
  Map<String, bool> _connectingDevices =
      {}; // Track connecting state per device
  String _receivedData = '';
  bt_serial.BluetoothDevice? _selectedDevice;
  bool _isConnected = false;
  bool _isBluetoothEnabled = false;

  // Stream subscriptions for scanning
  StreamSubscription<bt_serial.BluetoothDevice>? _discoverySubscription;
  Timer? _scanTimeoutTimer;

  // Stream subscriptions for serial connection
  StreamSubscription<bt_serial.BluetoothConnectionState>?
  _connectionSubscription;
  StreamSubscription<bt_serial.BluetoothData>? _dataSubscription;
  StreamSubscription<bt_serial.BluetoothState>? _stateSubscription;

  // Buffer for accumulating JSON data
  StringBuffer _jsonBuffer = StringBuffer();
  Timer? _jsonCompletionTimer;
  StringBuffer _orcaIdBuffer = StringBuffer();
  Timer? _orcaIdCompletionTimer;
  Timer? _orcaIdTimeoutTimer;

  // Calibration state
  bool _showCalibrationModal = false;
  String _selectedFrequency = '30'; // Default frequency
  bool _isCalibrating = false;
  bool _isFuelCalibrationMode = false; // Track if we're in fuel calibration

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

  void _updateFrequencyController() {
    if (_frequencyController.text != _selectedFrequency) {
      _frequencyController.text = _selectedFrequency;
    }
  }

  void _clearDeviceSpecificFields() {
    _certNoController.clear();
    _typeController.clear();
    _serialController.clear();
    _dateController.clear();
  }

  void _resetDeviceSessionData() {
    _jsonCompletionTimer?.cancel();
    _clearPendingOrcaIdResponse();
    _deviceData = {};
    _receivedData = '';
    _jsonBuffer.clear();
    _showRegistrationForm = false;
    _showHeaderDetailsPopup = false;
    _isRoutingDevicePayload = false;
    _resolvedHeaderDetails = {};
    _clearForm();
    _clearDeviceSpecificFields();
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

      debugPrint('loadCompanies error: $e');
      _showError('Failed to load companies. Please try again.');
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
      final technicianPhone = await StorageService.getData('phone');
      final agentName = await StorageService.getData('agentName');
      final agentId = await StorageService.getData('agentId');
      final agentLocation = await StorageService.getData('agentLocation');
      final agentEmail = await StorageService.getData('agentEmail');
      final agentPhone = await StorageService.getData('agentPhone');
      final businessReg = await StorageService.getData('businessReg');

      _technicianIdController.text = technicianId ?? '';
      _technicianNameController.text = technicianName ?? '';
      _technicianPhoneController.text = technicianPhone ?? '';

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
    _clearPendingOrcaIdResponse();
    _stopScanning();
    _bluetoothSerial.disconnect();

    // Dispose focus nodes
    _companyFocusNode.dispose();
    _companyPhoneFocusNode.dispose();

    super.dispose();
  }

  Future<void> _initializeBluetooth() async {
    try {
      bool isSupported = await _bluetoothSerial.isBluetoothSupported();
      if (!isSupported) {
        _showError('Bluetooth is not supported on this device');
        return;
      }

      bool isEnabled = await _bluetoothSerial.isBluetoothEnabled();
      setState(() {
        _isBluetoothEnabled = isEnabled;
      });

      _setupSerialListeners();
      if (isEnabled) {
        await _loadPairedDevices();
      } else {
        if (mounted) _showBluetoothDisabledDialog();
      }
    } catch (e) {
      debugPrint('Bluetooth init error: $e');
      _showError('Failed to initialize Bluetooth.');
    }
  }

  void _showBluetoothDisabledDialog() {
    final col = context.col;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadiusLG),
        ),
        backgroundColor: col.surface,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: kBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.bluetooth_disabled_rounded,
                  size: 36,
                  color: kBlue,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Bluetooth is Off',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: col.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Turn on Bluetooth to discover and connect to ATOM devices.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: col.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.bluetooth_rounded, size: 18),
                  label: const Text('Enable Bluetooth'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kBlue,
                    foregroundColor: kWhite,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(kRadiusMD),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _enableBluetooth();
                  },
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Retry'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kBlue,
                    side: const BorderSide(color: kBlue, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(kRadiusMD),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _initializeBluetooth();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _enableBluetooth() async {
    try {
      if (Platform.isAndroid) {
        final enabled = await _bluetoothSerial.enableBluetooth();
        if (enabled && mounted) {
          await _loadPairedDevices();
        }
      } else {
        // iOS cannot programmatically enable Bluetooth — open settings instead
        final uri = Uri.parse('App-prefs:Bluetooth');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      debugPrint('Enable Bluetooth error: $e');
      _showError('Failed to enable Bluetooth.');
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
    // Listen for Bluetooth adapter state changes
    _stateSubscription = _bluetoothSerial.onStateChanged.listen((state) {
      if (state.isEnabled && !_isBluetoothEnabled && mounted) {
        setState(() => _isBluetoothEnabled = true);
        _loadPairedDevices();
      } else if (!state.isEnabled && _isBluetoothEnabled && mounted) {
        setState(() => _isBluetoothEnabled = false);
        _showBluetoothDisabledDialog();
      }
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

        // Automatically request device data after a short settling delay
        Future.delayed(const Duration(milliseconds: 600), () {
          if (!mounted || !_isConnected) return;
          _retrieveDataFromDevice();
          if (_pendingPostResetFlow) {
            setState(() => _pendingPostResetFlow = false);
          }
        });
      } else {
        // Disconnected
        setState(() {
          _connectingDevices.clear();
          _isConnected = false;
          _selectedDevice = null;
          _resetDeviceSessionData();
        });

        if (connectionState.status.toLowerCase().contains('error')) {
          debugPrint('Connection error: ${connectionState.status}');
          _showError('Connection error. Please try again.');
        }
      }
    });
  }

  Future<void> _loadPairedDevices() async {
    try {
      List<bt_serial.BluetoothDevice> devices = await _bluetoothSerial
          .getPairedDevices();
      setState(() {
        _pairedDevices = devices;
        _devices = _getFilteredDevices();
      });
    } catch (e) {
      debugPrint('Load paired devices error: $e');
      _showError('Failed to load paired devices.');
    }
  }

  List<bt_serial.BluetoothDevice> _getFilteredDevices() {
    return _pairedDevices.where((device) {
      return device.name.toLowerCase().contains('atom speed');
    }).toList();
  }

  Future<void> _startScanning() async {
    if (_isScanning) return;
    if (!_isBluetoothEnabled) {
      _showBluetoothDisabledDialog();
      return;
    }

    setState(() {
      _isScanning = true;
      // Start with paired Atom Speed devices; scan appends newly discovered ones.
      _devices = _getFilteredDevices();
    });

    try {
      _discoverySubscription?.cancel();
      _discoverySubscription = _bluetoothSerial.onDeviceDiscovered.listen((
        device,
      ) {
        // Only show Atom Speed devices (paired or not).
        if (device.name.toLowerCase().contains('atom speed')) {
          if (!_devices.any((d) => d.address == device.address)) {
            setState(() {
              _devices.add(device);
            });
          }
        }
      });

      await _bluetoothSerial.startDiscovery();

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
      debugPrint('Scan failed: $e');
      _showError('Scan failed. Please try again.');
    }
  }

  Future<void> _stopScanning() async {
    try {
      await _bluetoothSerial.stopDiscovery();
      _discoverySubscription?.cancel();
      _discoverySubscription = null;
      _scanTimeoutTimer?.cancel();
    } catch (e) {
      debugPrint('Stop scan error: $e');
    }
  }

  Future<void> _connectToDevice(bt_serial.BluetoothDevice device) async {
    if (_isConnected || _connectingDevices[device.address] == true) return;

    setState(() {
      _resetDeviceSessionData();
      _connectingDevices[device.address] = true;
      _selectedDevice = device;
    });

    try {
      // For unpaired devices Android will surface the system pairing dialog
      // when connect() is called — no need to leave the app.
      bool success = await _bluetoothSerial.connect(device.address);
      if (!success) {
        setState(() {
          _connectingDevices.remove(device.address);
          _selectedDevice = null;
        });
        if (!device.paired) {
          // Pairing may not have completed — prompt the user to open settings
          _showPairInSettingsDialog(device);
          _showError('Failed to connect to ${device.name}');
        }
      }
    } catch (e) {
      setState(() {
        _connectingDevices.remove(device.address);
        _selectedDevice = null;
      });
      debugPrint('Connection error: $e');
      _showError('Could not connect to device.');
    }
  }

  void _showPairInSettingsDialog(bt_serial.BluetoothDevice device) {
    final col = context.col;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadiusLG),
        ),
        backgroundColor: col.surface,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: kBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.bluetooth_searching_rounded,
                  size: 36,
                  color: kBlue,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Pairing Required',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: col.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Could not pair with "${device.name}" automatically. Please pair it via Bluetooth settings, then return and connect.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: col.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.settings_bluetooth_rounded, size: 18),
                  label: const Text('Open Bluetooth Settings'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kBlue,
                    foregroundColor: kWhite,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(kRadiusMD),
                    ),
                  ),
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    final uri = Platform.isAndroid
                        ? Uri.parse('android.settings.BLUETOOTH_SETTINGS')
                        : Uri.parse('App-prefs:Bluetooth');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: col.textPrimary,
                    side: BorderSide(color: col.border),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(kRadiusMD),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _disconnectDevice() async {
    try {
      final success = await _bluetoothSerial.disconnect();
      if (success) {
        setState(() {
          _resetDeviceSessionData();
          _isConnected = false;
          _selectedDevice = null;
          _connectingDevices.clear();
        });
        _dataSubscription?.cancel();
        _dataSubscription = null;
        _showSuccess('Disconnected');
      } else {
        _showError('Failed to disconnect');
      }
    } catch (e) {
      debugPrint('Disconnect error: $e');
      _showError('Failed to disconnect.');
    }
  }

  void _startListeningForData() {
    _dataSubscription?.cancel();
    _jsonBuffer.clear();

    _dataSubscription = _bluetoothSerial.onDataReceived.listen((data) {
      String chunk;
      try {
        chunk = data.asString();
      } catch (e) {
        debugPrint(
          'Non-UTF8 chunk received (awaitingOrcaId=$_awaitingOrcaId) — skipping. Error: $e',
        );
        return;
      }
      chunk = chunk.trim();
      debugPrint('Received chunk (awaitingOrcaId=$_awaitingOrcaId): "$chunk"');

      if (_awaitingOrcaId && chunk.isNotEmpty) {
        _handleOrcaIdChunk(chunk);
        /*
          // JSON response — populate all available fields from it
          // Plain text response — treat the whole string as the serial number
        }
        */
        return;
      }

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
        final decodedJson = json.decode(jsonString);
        if (decodedJson is! Map<String, dynamic>) {
          throw const FormatException('Expected a JSON object');
        }

        final jsonData = Map<String, dynamic>.from(decodedJson);
        final resolvedDetails = _resolveHeaderDetails(jsonData);
        final isHeaderPayload = _looksLikeHeaderPayload(resolvedDetails);
        debugPrint('Parsed JSON: $jsonData');

        // Store the parsed data
        setState(() {
          if (isHeaderPayload) {
            _deviceData = jsonData;
            _resolvedHeaderDetails = resolvedDetails;
          }
          _receivedData =
              '${DateTime.now().toString()}\n${JsonEncoder.withIndent('  ').convert(jsonData)}\n\n${_receivedData}';
        });

        if (isHeaderPayload) {
          _prepopulateFormData(resolvedDetails);
          _saveLastDeviceToPrefs(jsonData, resolvedDetails);
        }

        // Clear buffer
        _jsonBuffer.clear();

        // Add any remaining text after JSON back to buffer
        if (endIndex + 1 < bufferString.length) {
          final remaining = bufferString.substring(endIndex + 1);
          _jsonBuffer.write(remaining);
        }

        if (isHeaderPayload &&
            !_showRegistrationForm &&
            !_showHeaderDetailsPopup &&
            !_isRoutingDevicePayload) {
          _isRoutingDevicePayload = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _routeToDeviceFlow(resolvedDetails);
            }
            _isRoutingDevicePayload = false;
          });
        }
      }
    } catch (e) {
      debugPrint('JSON parsing error: $e');
      // If parsing fails, show raw data
      setState(() {
        _receivedData = 'Raw data: $bufferString\n${_receivedData}';
      });
    }
  }

  void _handleOrcaIdChunk(String chunk) {
    debugPrint('GetOrcaid response chunk: "$chunk"');
    setState(() {
      _receivedData =
          '${DateTime.now()}\n[GetOrcaid Response]\n$chunk\n\n$_receivedData';
    });

    if (_orcaIdBuffer.isNotEmpty) {
      _orcaIdBuffer.write('\n');
    }
    _orcaIdBuffer.write(chunk);

    final bufferedResponse = _orcaIdBuffer.toString();
    final orcaIdData = _extractOrcaIdResponseData(bufferedResponse);
    final hasBalancedJson = _hasBalancedJsonPayload(bufferedResponse);
    final hasCertificateNumber =
        _normalizeDeviceValue(orcaIdData?['LimiterID']).isNotEmpty;
    final hasSerialNumber =
        _normalizeDeviceValue(orcaIdData?['MnfSerial']).isNotEmpty;

    if (orcaIdData != null &&
        (hasBalancedJson || (hasCertificateNumber && hasSerialNumber))) {
      _flushOrcaIdBuffer(finalizePartial: true);
      return;
    }

    _orcaIdCompletionTimer?.cancel();
    _orcaIdCompletionTimer = Timer(const Duration(milliseconds: 400), () {
      _flushOrcaIdBuffer();
    });
  }

  void _flushOrcaIdBuffer({
    bool finalizePartial = false,
    bool allowSerialFallback = false,
  }) {
    final rawResponse = _orcaIdBuffer.toString().trim();
    if (rawResponse.isEmpty) return;

    final orcaIdData = _extractOrcaIdResponseData(rawResponse);
    final hasBalancedJson = _hasBalancedJsonPayload(rawResponse);
    final hasCertificateNumber =
        _normalizeDeviceValue(orcaIdData?['LimiterID']).isNotEmpty;
    final hasSerialNumber =
        _normalizeDeviceValue(orcaIdData?['MnfSerial']).isNotEmpty;
    final hasBothMappedFields = hasCertificateNumber && hasSerialNumber;

    if (orcaIdData != null &&
        (hasBalancedJson || hasBothMappedFields || finalizePartial)) {
      _applyOrcaIdResponse(orcaIdData);
      return;
    }

    if (allowSerialFallback) {
      _finalizePlainOrcaIdResponse(rawResponse);
    }
  }

  bool _hasBalancedJsonPayload(String value) {
    if (!value.contains('{')) return false;
    final openBraces = '{'.allMatches(value).length;
    final closeBraces = '}'.allMatches(value).length;
    return openBraces > 0 && openBraces == closeBraces;
  }

  void _clearPendingOrcaIdResponse() {
    _orcaIdCompletionTimer?.cancel();
    _orcaIdCompletionTimer = null;
    _orcaIdTimeoutTimer?.cancel();
    _orcaIdTimeoutTimer = null;
    _orcaIdBuffer.clear();
  }

  void _applyOrcaIdResponse(Map<String, dynamic> orcaIdData) {
    final mergedDeviceData = <String, dynamic>{..._deviceData, ...orcaIdData};
    final resolvedDetails = _resolveHeaderDetails(mergedDeviceData);

    _clearPendingOrcaIdResponse();
    setState(() {
      _awaitingOrcaId = false;
      _deviceData = mergedDeviceData;
      _resolvedHeaderDetails = resolvedDetails;
    });

    _prepopulateFormData(resolvedDetails);
    unawaited(_saveLastDeviceToPrefs(mergedDeviceData, resolvedDetails));
  }

  void _finalizePlainOrcaIdResponse(String rawResponse) {
    final resolvedValue = _normalizeDeviceValue(rawResponse);
    _clearPendingOrcaIdResponse();

    setState(() {
      _awaitingOrcaId = false;
      if (resolvedValue.isNotEmpty && _serialController.text.trim().isEmpty) {
        _serialController.text = resolvedValue;
      }
    });
  }

  Map<String, dynamic>? _extractOrcaIdResponseData(String rawResponse) {
    if (rawResponse.contains('{')) {
      try {
        final startIndex = rawResponse.indexOf('{');
        final endIndex = rawResponse.lastIndexOf('}');
        if (startIndex != -1 && endIndex > startIndex) {
          final decodedJson = json.decode(
            rawResponse.substring(startIndex, endIndex + 1),
          );
          if (decodedJson is Map<String, dynamic>) {
            return Map<String, dynamic>.from(decodedJson);
          }
        }
      } catch (e) {
        debugPrint('GetOrcaid JSON parse error: $e');
      }
    }

    final certificateNumber = _extractTaggedDeviceValue(rawResponse, const [
      'LimiterID',
      'limiterID',
      'limiterId',
      'LimiterId',
    ]);
    final deviceId = _extractTaggedDeviceValue(rawResponse, const [
      'deviceId',
      'DeviceId',
      'deviceID',
      'DeviceID',
      'device_id',
      'ORCAid',
      'OrcaId',
      'orcaId',
      'ORCAID',
    ]);
    final serialNumber = _extractTaggedDeviceValue(rawResponse, const [
      'MnfSerial',
      'mnfSerial',
      'MNFSerial',
    ]);

    if (certificateNumber.isEmpty && deviceId.isEmpty && serialNumber.isEmpty) {
      return null;
    }

    return {
      if (certificateNumber.isNotEmpty) 'LimiterID': certificateNumber,
      if (deviceId.isNotEmpty) 'deviceId': deviceId,
      if (serialNumber.isNotEmpty) 'MnfSerial': serialNumber,
    };
  }

  String _extractTaggedDeviceValue(String source, List<String> keys) {
    for (final key in keys) {
      final match = RegExp(
        "(?:^|[^A-Za-z0-9_])${RegExp.escape(key)}\\s*[:=]\\s*(.+?)(?=(?:\\s+[A-Za-z][A-Za-z0-9_]*\\s*[:=])|[,;\\r\\n]|\$)",
        caseSensitive: false,
        dotAll: true,
      ).firstMatch(source);

      final value = _stripWrappingQuotes(match?.group(1) ?? '');
      if (value.isNotEmpty) {
        return value;
      }
    }

    return '';
  }

  String _stripWrappingQuotes(String value) {
    final trimmed = _normalizeDeviceValue(value);
    if (trimmed.length < 2) return trimmed;

    final startsWithDoubleQuote = trimmed.startsWith('"');
    final endsWithDoubleQuote = trimmed.endsWith('"');
    final startsWithSingleQuote = trimmed.startsWith("'");
    final endsWithSingleQuote = trimmed.endsWith("'");

    if ((startsWithDoubleQuote && endsWithDoubleQuote) ||
        (startsWithSingleQuote && endsWithSingleQuote)) {
      return trimmed.substring(1, trimmed.length - 1).trim();
    }

    return trimmed;
  }

  String _normalizeDeviceValue(dynamic value) {
    if (value == null) return '';

    final text = value.toString().trim();
    if (text.isEmpty) return '';

    const invalidValues = {'null', 'undefined', 'n/a', 'na'};
    if (invalidValues.contains(text.toLowerCase())) {
      return '';
    }

    return text;
  }

  String _resolveDeviceValue(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      if (!data.containsKey(key)) continue;

      final value = _normalizeDeviceValue(data[key]);
      if (value.isNotEmpty) {
        return value;
      }
    }

    final lowerCaseData = <String, dynamic>{};
    data.forEach((key, value) {
      lowerCaseData[key.toLowerCase()] = value;
    });

    for (final key in keys) {
      final value = _normalizeDeviceValue(lowerCaseData[key.toLowerCase()]);
      if (value.isNotEmpty) {
        return value;
      }
    }

    return '';
  }

  String _resolveDeviceId(Map<String, dynamic> data) {
    return _resolveDeviceValue(data, const [
      'deviceId',
      'DeviceId',
      'deviceID',
      'DeviceID',
      'device_id',
      'HeaderID',
      'headerId',
      'HeaderId',
      'headerID',
      'LimiterID',
      'limiterID',
      'limiterId',
      'LimiterId',
      'certificateNumber',
      'CertNo',
      'certNo',
      'ORCAid',
      'OrcaId',
      'orcaId',
      'ORCAID',
    ]);
  }

  String _resolveHeaderId(Map<String, dynamic> data) {
    return _resolveDeviceValue(data, const [
      'HeaderID',
      'headerId',
      'LimiterID',
      'limiterID',
      'limiterId',
      'CertNo',
      'certificateNumber',
      'certNo',
    ]);
  }

  Map<String, String> _resolveHeaderDetails(Map<String, dynamic> data) {
    final today =
        "${_getMonthName(DateTime.now().month)} ${DateTime.now().day}, ${DateTime.now().year}";

    return {
      'headerId': _resolveHeaderId(data),
      'certificateNumber': _resolveDeviceValue(data, const [
        'LimiterID',
        'limiterID',
        'limiterId',
      ]),
      'serialNumber': _resolveDeviceValue(data, const [
        'MnfSerial',
        'mnfSerial',
        'MNFSerial',
      ]),
      'company': _resolveDeviceValue(data, const [
        'company',
        'Company',
        'companyName',
        'fleetCompany',
      ]),
      'companyPhone': _resolveDeviceValue(data, const [
        'companyPhone',
        'CompanyPhone',
        'company_phone',
      ]),
      'ownerName': _resolveDeviceValue(data, const [
        'Name',
        'name',
        'ownerName',
        'OwnerName',
      ]),
      'ownerId': _resolveDeviceValue(data, const [
        'ID',
        'id',
        'ownerId',
        'OwnerID',
      ]),
      'ownerPhone': _resolveDeviceValue(data, const [
        'Phone',
        'phone',
        'ownerPhone',
        'OwnerPhone',
        'phoneNumber',
      ]),
      'registrationNumber': _resolveDeviceValue(data, const [
        'reg',
        'Reg',
        'registrationNumber',
        'RegistrationNumber',
        'vehicleRegistration',
        'numberPlate',
        'Rg',
      ]),
      'chassisNumber': _resolveDeviceValue(data, const [
        'chassis',
        'Chassis',
        'chassisNumber',
        'chassis_number',
      ]),
      'make': _resolveDeviceValue(data, const ['make', 'Make', 'vehicleMake']),
      'type': _resolveDeviceValue(data, const ['Type', 'type']).isNotEmpty
          ? _resolveDeviceValue(data, const ['Type', 'type'])
          : 'Orca',
      'date': _resolveDeviceValue(data, const ['date', 'Date']).isNotEmpty
          ? _resolveDeviceValue(data, const ['date', 'Date'])
          : today,
      'agentName': _resolveDeviceValue(data, const [
        'agent',
        'Agent',
        'agentName',
      ]),
      'agentId': _resolveDeviceValue(data, const [
        'agentID',
        'AgentID',
        'agentId',
      ]),
      'location': _resolveDeviceValue(data, const [
        'location',
        'Location',
        'address',
      ]),
      'email': _resolveDeviceValue(data, const [
        'email',
        'Email',
        'emailAddress',
      ]),
      'agentPhone': _resolveDeviceValue(data, const [
        'agentPhone',
        'AgentPhone',
        'agent_phone',
      ]),
      'businessReg': _resolveDeviceValue(data, const [
        'businessReg',
        'BusinessReg',
        'businessRegistration',
      ]),
      'group': _resolveDeviceValue(data, const ['group', 'Group', 'groupName']),
    };
  }

  bool _looksLikeHeaderPayload(Map<String, String> details) {
    const headerSignals = [
      'headerId',
      'certificateNumber',
      'serialNumber',
      'company',
      'ownerName',
      'registrationNumber',
    ];

    return headerSignals.any((key) => details[key]?.isNotEmpty == true);
  }

  bool _hasCompleteHeaderDetails(Map<String, String> details) {
    const requiredKeys = [
      'company',
      'ownerName',
      'registrationNumber',
      'serialNumber',
      'certificateNumber',
    ];

    return requiredKeys.every((key) => details[key]?.isNotEmpty == true);
  }

  void _setControllerValue(
    TextEditingController controller,
    String value, {
    bool overwrite = true,
  }) {
    if (value.isEmpty) return;
    if (overwrite || controller.text.trim().isEmpty) {
      controller.text = value;
    }
  }

  void _routeToDeviceFlow(Map<String, String> resolvedDetails) {
    if (!_looksLikeHeaderPayload(resolvedDetails)) {
      return;
    }

    final serial = resolvedDetails['serialNumber'] ?? '';
    final company = resolvedDetails['company'] ?? '';
    final reg = resolvedDetails['registrationNumber'] ?? '';
    final missingFields = serial.isEmpty || company.isEmpty || reg.isEmpty;
    final hasCompleteHeaderDetails = _hasCompleteHeaderDetails(resolvedDetails);
    final hasHeader = resolvedDetails['headerId']?.isNotEmpty == true;

    if (missingFields || !hasCompleteHeaderDetails) {
      _getDeviceId();
    }

    setState(() {
      _resolvedHeaderDetails = resolvedDetails;
      _showHeaderDetailsPopup = hasHeader;
      _showRegistrationForm = !hasHeader;
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

  void _prepopulateFormData([Map<String, String>? resolvedDetails]) {
    final details =
        resolvedDetails ??
        (_deviceData.isNotEmpty ? _resolveHeaderDetails(_deviceData) : null);

    if (details == null || details.isEmpty) return;

    _setControllerValue(_companyController, details['company'] ?? '');
    _setControllerValue(_companyPhoneController, details['companyPhone'] ?? '');
    _setControllerValue(_nameController, details['ownerName'] ?? '');
    _setControllerValue(_idController, details['ownerId'] ?? '');
    _setControllerValue(_phoneController, details['ownerPhone'] ?? '');
    _setControllerValue(_regController, details['registrationNumber'] ?? '');
    _setControllerValue(_chassisController, details['chassisNumber'] ?? '');
    _setControllerValue(_makeController, details['make'] ?? '');
    _setControllerValue(_certNoController, details['certificateNumber'] ?? '');
    _setControllerValue(_typeController, details['type'] ?? '');
    _setControllerValue(_serialController, details['serialNumber'] ?? '');
    _setControllerValue(_dateController, details['date'] ?? '');
    _setControllerValue(_agentController, details['agentName'] ?? '');
    _setControllerValue(_agentIDController, details['agentId'] ?? '');
    _setControllerValue(_locationController, details['location'] ?? '');
    _setControllerValue(_emailController, details['email'] ?? '');
    _setControllerValue(_agentPhoneController, details['agentPhone'] ?? '');
    _setControllerValue(_businessRegController, details['businessReg'] ?? '');
    _setControllerValue(_groupController, details['group'] ?? '');
  }

  Future<void> _saveLastDeviceToPrefs(
    Map<String, dynamic> jsonData,
    Map<String, String> resolvedDetails,
  ) async {
    try {
      final deviceId = _resolveDeviceId(jsonData);
      final serial = resolvedDetails['serialNumber'] ?? '';
      final numberPlate = resolvedDetails['registrationNumber'] ?? '';

      if (deviceId.isEmpty) {
        await StorageService.removeData('lastDevice_id');
      }

      await StorageService.storeData({
        if (deviceId.isNotEmpty) 'lastDevice_id': deviceId,
        if (serial.isNotEmpty) 'lastDevice_serial': serial,
        if (numberPlate.isNotEmpty) 'lastDevice_numberPlate': numberPlate,
      });
      debugPrint(
        'Saved last device to prefs: '
        'deviceId=$deviceId, serial=$serial, numberPlate=$numberPlate',
      );
    } catch (e) {
      debugPrint('Error saving last device to prefs: $e');
    }
  }

  Future<void> _sendCommand(String command) async {
    if (!_isConnected) {
      _showError('No device connected');
      return;
    }

    try {
      bool success = await _bluetoothSerial.sendString(command);
      debugPrint('Sent command: $command (success=$success)');
      if (!success) {
        _showError('Failed to send command to device.');
      }
    } catch (e) {
      debugPrint('Send command error for "$command": $e');
      _showError('Failed to send command to device.');
    }
  }

  Future<void> _getDeviceId() async {
    debugPrint('_getDeviceId called — sending GetOrcaid>');
    _clearPendingOrcaIdResponse();
    setState(() => _awaitingOrcaId = true);
    await _sendCommand('GetORCAid>');
    // Give the device time to stream the ORCA response before falling back.
    _orcaIdTimeoutTimer = Timer(const Duration(seconds: 5), () {
      if (_awaitingOrcaId) {
        debugPrint('GetOrcaid> — no response received after 3s');
        _flushOrcaIdBuffer(
          finalizePartial: true,
          allowSerialFallback: true,
        );
        if (_awaitingOrcaId) {
          setState(() => _awaitingOrcaId = false);
        }
      }
    });
  }

  Future<void> _retrieveDataFromDevice({bool restartFlow = false}) async {
    if (!_isConnected) {
      _showError('No device connected');
      return;
    }

    if (restartFlow) {
      setState(() {
        _resetDeviceSessionData();
      });
    }

    await _sendCommand('Get Header>');
    // If no header is found within 2.5s, fall back to GetOrcaid>
    Timer(const Duration(milliseconds: 2500), () {
      debugPrint(
        'Header check timer: connected=$_isConnected, '
        'hasHeader=$_hasHeader, deviceDataEmpty=${_deviceData.isEmpty}',
      );
      if (mounted && _isConnected && !_hasHeader) {
        debugPrint('No header found — calling GetOrcaid>');
        // No header on device — open the registration form immediately so the
        // technician sees it right away, then fetch the serial in the background.
        final now = DateTime.now();
        setState(() {
          _showRegistrationForm = true;
          if (_dateController.text.trim().isEmpty) {
            _dateController.text =
                '${_getMonthName(now.month)} ${now.day}, ${now.year}';
          }
        });
        _getDeviceId();
      } else {
        debugPrint('Header already present — skipping GetOrcaid>');
      }
    });
  }

  /// Returns true when the connected device already has a speed header
  /// programmed (i.e., a non-empty LimiterID in its data).
  String get _headerId => _resolveHeaderId(_deviceData);
  bool get _hasHeader => _headerId.isNotEmpty;

  Future<void> _resetDeviceHeader() async {
    if (!_isConnected) {
      _showError('No device connected');
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final col = context.col;
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kRadiusLG),
          ),
          backgroundColor: col.surface,
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: kRed.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.restart_alt_rounded,
                    size: 36,
                    color: kRed,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Reset Speed Header?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: col.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This will clear the existing speed header from the device. The device will need to be recalibrated afterwards.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: col.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      await _sendCommand('ResetHdr>');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kRed,
                      foregroundColor: kWhite,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(kRadiusMD),
                      ),
                    ),
                    child: const Text(
                      'Yes, Reset Header',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: col.textPrimary,
                      side: BorderSide(color: col.border),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(kRadiusMD),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleResetDevicePressed() async {
    if (!_isConnected) {
      _showError('No device connected');
      return;
    }

    String serial = _resolveDeviceValue(_deviceData, const [
      'MnfSerial',
      'mnfSerial',
      'MNFSerial',
      'serial',
      'Serial',
    ]);

    if (serial.isEmpty) {
      serial = _normalizeDeviceValue(_resolvedHeaderDetails['serialNumber']);
    }

    if (serial.isEmpty) {
      final savedSerial = await StorageService.getData('lastDevice_serial');
      if (savedSerial is String) {
        serial = _normalizeDeviceValue(savedSerial);
      }
    }

    if (serial.isEmpty) {
      _showError(
        'Device serial number unavailable. Run Get Device Data first.',
      );
      return;
    }

    debugPrint('[ResetDevice] checking registration by serial: $serial');

    _showLoading('Checking device registration...');
    Map<String, dynamic>? registration;
    try {
      registration = await ApiService.checkDeviceRegistration(serial);
    } catch (e) {
      debugPrint('[ResetDevice] registration check error: $e');
      if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showError('Could not verify device with the server. Please try again.');
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (registration != null) {
      debugPrint('[ResetDevice] registered — opening reason popup');
      _showResetConfirmDialog();
    } else {
      debugPrint('[ResetDevice] not registered — opening Factory> confirm');
      _showFactoryResetConfirmDialog();
    }
  }

  void _showFactoryResetConfirmDialog() {
    final col = context.col;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadiusLG),
        ),
        backgroundColor: col.surface,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: kRed.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.restart_alt_rounded,
                  size: 36,
                  color: kRed,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Reset Device?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: col.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This device is not registered on the server. Are you sure you want to send the reset command to the device?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: col.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    setState(() => _pendingPostResetFlow = true);
                    _showLoading('Resetting device...');
                    try {
                      await _sendCommand('Factory>');
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      _showSuccess('Device reset successfully.');
                    } catch (e) {
                      debugPrint('Factory> send error: $e');
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      _showError('Failed to reset device. Please try again.');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kRed,
                    foregroundColor: kWhite,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(kRadiusMD),
                    ),
                  ),
                  child: const Text(
                    'Yes',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: col.textPrimary,
                    side: BorderSide(color: col.border),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(kRadiusMD),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitDeviceDeleteRequest(String reason) async {
    debugPrint('[ResetRequest] submit pressed. reason="$reason"');
    _showLoading('Submitting reset request...');
    try {
      String serial = _resolvedHeaderDetails['serialNumber']?.isNotEmpty == true
          ? _resolvedHeaderDetails['serialNumber']!
          : _resolveDeviceValue(_deviceData, const [
              'MnfSerial',
              'serial',
              'Serial',
              'deviceSerial',
              'imei',
            ]);
      String numberPlate =
          _resolvedHeaderDetails['registrationNumber']?.isNotEmpty == true
              ? _resolvedHeaderDetails['registrationNumber']!
              : _resolveDeviceValue(_deviceData, const [
                  'reg',
                  'Reg',
                  'numberPlate',
                  'Rg',
                ]);
      String deviceId = _resolveDeviceId(_deviceData);
      if (deviceId.isEmpty) {
        deviceId = _normalizeDeviceValue(_resolvedHeaderDetails['headerId']);
      }
      if (deviceId.isEmpty) {
        deviceId = _normalizeDeviceValue(
          _resolvedHeaderDetails['certificateNumber'],
        );
      }

      // Fall back to last-connected device saved in prefs
      if (serial.isEmpty || numberPlate.isEmpty || deviceId.isEmpty) {
        final savedSerial = await StorageService.getData('lastDevice_serial');
        final savedPlate = await StorageService.getData('lastDevice_numberPlate');
        final savedId = await StorageService.getData('lastDevice_id');
        if (serial.isEmpty && savedSerial is String) {
          serial = _normalizeDeviceValue(savedSerial);
        }
        if (numberPlate.isEmpty && savedPlate is String) {
          numberPlate = _normalizeDeviceValue(savedPlate);
        }
        if (deviceId.isEmpty && savedId is String) {
          deviceId = _normalizeDeviceValue(savedId);
        }
      }

      if (deviceId.isEmpty) {
        throw Exception(
          'Device ID was not found in the current device data or shared prefs. '
          'Run Get Header> again before resetting.',
        );
      }

      // Mark that the next reconnect is post-reset so GetOrcaid fires automatically
      setState(() => _pendingPostResetFlow = true);

      final technicianPhone = _technicianPhoneController.text.trim();
      debugPrint(
        '[ResetRequest] resolved payload — '
        'deviceId="$deviceId", serial="$serial", numberPlate="$numberPlate", '
        'requestedBy="${_technicianNameController.text.trim()}" '
        '(phone="$technicianPhone"), reason="$reason"',
      );

      // Registered device: only log the reset request to the server.
      // The factory reset command is NOT sent to the device here.
      debugPrint('[ResetRequest] POSTing to createDeviceDeleteRequest...');
      await ApiService.submitDeviceDeleteRequest(
        deviceId: deviceId,
        deviceSerialNumber: serial,
        requestedByFullname: _technicianNameController.text.trim(),
        requestedByPhoneNumber: technicianPhone,
        requestedByRole: 'Technician',
        reason: reason,
        previousNumberPlate: numberPlate,
      );
      debugPrint('[ResetRequest] server accepted the request');

      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showSuccess('Reset request submitted.');
    } catch (e, st) {
      debugPrint('[ResetRequest] failed: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showError('Could not submit reset request. Please try again.');
    }
  }

  void _showResetConfirmDialog() {
    debugPrint('[ResetRequest] opening reason popup (registered path)');
    final col = context.col;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final reasonController = TextEditingController();
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final hasReason = reasonController.text.trim().isNotEmpty;
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(kRadiusLG),
              ),
              backgroundColor: col.surface,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 40,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: kRed.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.warning_rounded,
                        size: 28,
                        color: kRed,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Reset Device?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: col.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'This will submit a reset request for this ORCA device. This action cannot be undone.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: col.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: reasonController,
                      maxLines: 2,
                      onChanged: (_) => setDialogState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Reason for reset *',
                        hintText: 'Enter the reason for resetting this device',
                        alignLabelWithHint: true,
                        filled: true,
                        fillColor: col.bg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(kRadiusMD),
                          borderSide: BorderSide(color: col.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(kRadiusMD),
                          borderSide: BorderSide(color: col.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(kRadiusMD),
                          borderSide:
                              const BorderSide(color: kRed, width: 1.5),
                        ),
                        labelStyle: TextStyle(color: col.textSecondary),
                        hintStyle: TextStyle(
                          color: col.textSecondary.withValues(alpha: 0.6),
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: hasReason
                            ? () {
                                final reason = reasonController.text.trim();
                                Navigator.of(ctx).pop();
                                _submitDeviceDeleteRequest(reason);
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kRed,
                          foregroundColor: kWhite,
                          disabledBackgroundColor:
                              kRed.withValues(alpha: 0.3),
                          disabledForegroundColor:
                              kWhite.withValues(alpha: 0.5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(kRadiusMD),
                          ),
                        ),
                        child: const Text(
                          'Submit request',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: col.textPrimary,
                          side: BorderSide(color: col.border),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(kRadiusMD),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Future<void> _resetDevice() async {
  //   await _sendCommand('Reset>');
  // }

  Future<void> _prepareCalibration() async {
    if (!_isConnected) {
      _showError('No device connected');
      return;
    }

    // Show loading
    _showLoading('Preparing device for calibration...');

    try {
      // Initialize Calibration//  Initialize Speed Calibration
      String command = 'SpdInit>';

      debugPrint('Sending calibration preparation command: $command');

      await _sendCommand('SpdInit>');

      _showCalibrationModalPopup();
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      debugPrint('Calibration preparation error: $e');
      _showError('Failed to prepare calibration.');
    }
  }

  // Calibration methods
  void _showCalibrationModalPopup() {
    // Always sync controller with current selected frequency
    _frequencyController.text = _selectedFrequency;

    setState(() {
      _showCalibrationModal = true;
      _isFuelCalibrationMode = false;
    });

    // Focus on input field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _frequencyFocusNode.requestFocus();
      // Place cursor at the end
      _frequencyController.selection = TextSelection.fromPosition(
        TextPosition(offset: _frequencyController.text.length),
      );
    });
  }

  void _incrementFrequency() {
    setState(() {
      int currentFreq = int.tryParse(_selectedFrequency) ?? 30;
      if (currentFreq < MAX_FREQUENCY) {
        currentFreq++;
        _selectedFrequency = currentFreq.toString();
        _frequencyController.text = currentFreq.toString();
        // Keep cursor at end
        _frequencyController.selection = TextSelection.fromPosition(
          TextPosition(offset: _frequencyController.text.length),
        );
      } else {
        _showError('Maximum frequency is ${MAX_FREQUENCY}Hz');
      }
    });
  }

  void _decrementFrequency() {
    setState(() {
      int currentFreq = int.tryParse(_selectedFrequency) ?? 30;
      if (currentFreq > MIN_FREQUENCY) {
        currentFreq--;
        _selectedFrequency = currentFreq.toString();
        _frequencyController.text = currentFreq.toString();
        // Keep cursor at end
        _frequencyController.selection = TextSelection.fromPosition(
          TextPosition(offset: _frequencyController.text.length),
        );
      } else {
        _showError('Minimum frequency is ${MIN_FREQUENCY}Hz');
      }
    });
  }

  Future<void> _calibrateSpeed() async {
    if (!_isConnected) {
      _showError('No device connected');
      return;
    }

    setState(() {
      _isCalibrating = true;
    });

    try {
      // Format the calibration command
      String command = '{"Cal":"Callibrate"}>';

      await _sendCommand(command);

      _showSuccess('Speed calibration started at ${_selectedFrequency}Hz');

      // Wait a bit for calibration to complete
      await Future.delayed(Duration(seconds: 2));

      // Send stop command
      await _sendCommand("StopSpeed>");

      setState(() {
        _isCalibrating = false;
      });

      // Show calibration success modal
      _showCalibrationSuccessModal();
    } catch (e) {
      debugPrint('Calibration error: $e');
      _showError('Calibration failed. Please try again.');
      setState(() {
        _isCalibrating = false;
      });
    }
  }

  void _showCalibrationSuccessModal() {
    final col = context.col;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadiusLG),
        ),
        backgroundColor: col.surface,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: kSuccessGreen.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 44,
                  color: kSuccessGreen,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Calibration Successful',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: col.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Speed calibration completed successfully.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: col.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: kBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(kRadiusMD),
                  border: Border.all(color: kBlue.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.speed_rounded, size: 16, color: kBlue),
                        const SizedBox(width: 6),
                        Text(
                          'Calibrated Frequency',
                          style: TextStyle(
                            fontSize: 12,
                            color: col.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$_selectedFrequency Hz',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: kBlue,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    setState(() {
                      _showCalibrationModal = false;
                      _isFuelCalibrationMode = false;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kSuccessGreen,
                    foregroundColor: kWhite,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(kRadiusMD),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendFrequencyToDevice() async {
    if (!_isConnected) {
      _showError('No device connected');
      return;
    }

    setState(() {
      _isCalibrating = true;
    });

    try {
      // Format the frequency command
      // Adjust the command format based on your device protocol
      String command = '{"Spd":$_selectedFrequency}>';

      debugPrint('Sending frequency command: $command');

      bool success = await _bluetoothSerial.sendString(command);

      if (success) {
        _showSuccess('Frequency ${_selectedFrequency}Hz sent to device');
        // You might want to update deviceData or show confirmation
      } else {
        _showError('Failed to send frequency to device');
      }
    } catch (e) {
      debugPrint('Send frequency error: $e');
      _showError('Failed to send frequency to device.');
    } finally {
      setState(() {
        _isCalibrating = false;
      });
    }
  }

  Future<void> _calibrateFuel() async {
    if (!_isConnected) {
      _showError('No device connected');
      return;
    }

    setState(() {
      _isCalibrating = true;
    });

    try {
      // Format the fuel calibration command
      // Assuming the device expects a command like: "CAL_FUEL:1"
      String command = 'CAL_FUEL:1>'; // 1 for calibrate, 0 for stop

      bool success = await _bluetoothSerial.sendString(command);

      if (success) {
        _showSuccess('Fuel calibration started...');

        // Wait a bit for calibration to complete
        await Future.delayed(Duration(seconds: 5));

        // Send stop calibration command
        await _bluetoothSerial.sendString('CAL_FUEL:0>');

        _showSuccess('Fuel calibration complete!');

        setState(() {
          _isCalibrating = false;
          _showCalibrationModal = false; // Close modal after fuel calibration
        });
      } else {
        _showError('Failed to send fuel calibration command');
        setState(() {
          _isCalibrating = false;
        });
      }
    } catch (e) {
      debugPrint('Fuel calibration error: $e');
      _showError('Fuel calibration failed.');
      setState(() {
        _isCalibrating = false;
      });
    }
  }

  Widget _buildCalibrationModal() {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadiusLG),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isFuelCalibrationMode
                      ? 'Fuel Calibration'
                      : 'Speed Calibration',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kBlue,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 20),
                  onPressed: () {
                    setState(() {
                      _showCalibrationModal = false;
                      _isCalibrating = false;
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            if (!_isFuelCalibrationMode)
              // Speed Calibration UI
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Selected Frequency Display
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: kBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(kRadiusMD),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Selected Frequency',
                          style: TextStyle(
                            color: context.col.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$_selectedFrequency Hz',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: kBlue,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Derived from device data',
                          style: TextStyle(
                            color: context.col.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Frequency Input and Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Decrement Button
                      ElevatedButton(
                        onPressed: _decrementFrequency,
                        style: ElevatedButton.styleFrom(
                          shape: CircleBorder(),
                          padding: const EdgeInsets.all(12),
                          backgroundColor: kBlue.withValues(alpha: 0.1),
                          foregroundColor: kBlue,
                          minimumSize: Size(48, 48),
                        ),
                        child: Icon(Icons.remove, size: 24),
                      ),

                      const SizedBox(width: 16),

                      // Frequency Input - FIXED with proper constraints
                      SizedBox(
                        width: 110,
                        height: 56,
                        child: TextFormField(
                          controller: _frequencyController,
                          focusNode: _frequencyFocusNode,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(kRadiusSM),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 12,
                            ),
                          ),
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              final intValue = int.tryParse(value);
                              if (intValue != null) {
                                if (intValue >= MIN_FREQUENCY &&
                                    intValue <= MAX_FREQUENCY) {
                                  setState(() {
                                    _selectedFrequency = value;
                                  });
                                } else if (intValue > MAX_FREQUENCY) {
                                  _showError(
                                    'Maximum frequency is ${MAX_FREQUENCY}Hz',
                                  );
                                  setState(() {
                                    _selectedFrequency = MAX_FREQUENCY
                                        .toString();
                                    _frequencyController.text = MAX_FREQUENCY
                                        .toString();
                                  });
                                } else if (intValue < MIN_FREQUENCY) {
                                  _showError(
                                    'Minimum frequency is ${MIN_FREQUENCY}Hz',
                                  );
                                  setState(() {
                                    _selectedFrequency = MIN_FREQUENCY
                                        .toString();
                                    _frequencyController.text = MIN_FREQUENCY
                                        .toString();
                                  });
                                }
                              }
                            }
                          },
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Increment Button
                      ElevatedButton(
                        onPressed: _incrementFrequency,
                        style: ElevatedButton.styleFrom(
                          shape: CircleBorder(),
                          padding: const EdgeInsets.all(12),
                          backgroundColor: kBlue.withValues(alpha: 0.1),
                          foregroundColor: kBlue,
                          minimumSize: Size(48, 48),
                        ),
                        child: Icon(Icons.add, size: 24),
                      ),
                    ],
                  ),

                  // Frequency range info
                  const SizedBox(height: 12),

                  Text(
                    'Adjust frequency (${MIN_FREQUENCY}-${MAX_FREQUENCY}Hz, 1Hz steps)',
                    style: TextStyle(
                      color: context.col.textSecondary,
                      fontSize: 12,
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isCalibrating
                            ? null
                            : _sendFrequencyToDevice,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kSuccessGreen,
                          foregroundColor: kWhite,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(kRadiusSM),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.send, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Send ${_selectedFrequency}Hz to Device',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Calibrate Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isCalibrating ? null : _calibrateSpeed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kBlue,
                        foregroundColor: kWhite,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(kRadiusSM),
                        ),
                      ),
                      child: _isCalibrating
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      kWhite,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text('Calibrating...'),
                              ],
                            )
                          : Text(
                              'Calibrate Speed',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              )
            else
              // Fuel Calibration UI
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Fuel Calibration Instructions
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(kRadiusMD),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_gas_station,
                          size: 48,
                          color: Colors.orange,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Fuel Calibration',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Speed calibration is complete. You can now calibrate the fuel sensor.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: context.col.textSecondary),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Calibrate Fuel Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isCalibrating ? null : _calibrateFuel,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: kWhite,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(kRadiusSM),
                        ),
                      ),
                      child: _isCalibrating
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      kWhite,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text('Calibrating Fuel...'),
                              ],
                            )
                          : Text(
                              'Calibrate Fuel',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Back to Speed Calibration Button
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isFuelCalibrationMode = false;
                      });
                    },
                    child: Text(
                      'Back to Speed Calibration',
                      style: TextStyle(color: kBlue),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
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
        final errorMessage =
            response['message'] ?? response['error'] ?? 'Registration failed';
        final statusCode = response['statusCode'] as int? ?? 0;

        final isDuplicate =
            statusCode == 409 ||
            errorMessage.toLowerCase().contains('already exist') ||
            errorMessage.toLowerCase().contains('already registered') ||
            errorMessage.toLowerCase().contains('duplicate') ||
            errorMessage.toLowerCase().contains('conflict');

        if (isDuplicate) {
          _showErrorDialog(
            title: 'Already Registered',
            message:
                'This serial number is already registered in the system.\n\nPlease verify the company name, serial number, and number plate before trying again.',
            icon: Icons.domain_disabled_rounded,
            iconColor: Colors.orange,
          );
        } else {
          _showErrorDialog(title: 'Registration Failed', message: errorMessage);
        }
      }
    } catch (e) {
      // Hide loading
      if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();

      debugPrint('Registration error: $e');

      String errorMessage = 'An unexpected error occurred. Please try again.';

      if (e is String) {
        errorMessage = e;
      } else if (e is Exception || e is Error) {
        errorMessage = e.toString();
        final match = RegExp(r'Exception:\s*(.+)$').firstMatch(errorMessage);
        if (match != null && match.groupCount >= 1) {
          errorMessage = match.group(1) ?? errorMessage;
        }
      }

      _showErrorDialog(title: 'Registration Failed', message: errorMessage);
    }
  }

  void _clearReceivedData() {
    setState(() {
      _receivedData = '';
      _jsonBuffer.clear();
    });
  }

  final bool isReceivedDataHidden = true;

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
                valueColor: AlwaysStoppedAnimation<Color>(kWhite),
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
    final col = context.col;

    final details = <_DetailRow>[
      if (response['deviceId'] != null)
        _DetailRow(
          icon: Icons.device_hub_rounded,
          label: 'Device ID',
          value: '${response['deviceId']}',
        ),
      if (response['certificateNumber'] != null)
        _DetailRow(
          icon: Icons.verified_rounded,
          label: 'Certificate No.',
          value: '${response['certificateNumber']}',
        ),
      if (response['registrationNumber'] != null)
        _DetailRow(
          icon: Icons.pin_rounded,
          label: 'Registration No.',
          value: '${response['registrationNumber']}',
        ),
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadiusLG),
        ),
        backgroundColor: col.surface,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: kSuccessGreen.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.how_to_reg_rounded,
                  size: 44,
                  color: kSuccessGreen,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Registration Successful',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: col.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'The device has been registered successfully.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: col.textSecondary,
                  height: 1.5,
                ),
              ),
              if (details.isNotEmpty) ...[
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: kSuccessGreen.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(kRadiusMD),
                    border: Border.all(
                      color: kSuccessGreen.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: details
                        .map(
                          (d) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              children: [
                                Icon(d.icon, size: 16, color: kSuccessGreen),
                                const SizedBox(width: 10),
                                Text(
                                  d.label,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: col.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  d.value,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: col.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _clearForm();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kSuccessGreen,
                    foregroundColor: kWhite,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(kRadiusMD),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
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
        backgroundColor: kRed,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showErrorDialog({
    required String title,
    required String message,
    IconData icon = Icons.error_outline_rounded,
    Color iconColor = kRed,
  }) {
    if (!mounted) return;
    final col = context.col;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadiusLG),
        ),
        backgroundColor: col.surface,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 36, color: iconColor),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: col.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: col.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: iconColor,
                    foregroundColor: kWhite,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(kRadiusMD),
                    ),
                  ),
                  child: const Text('OK', style: TextStyle(fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: kSuccessGreen,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildDeviceCard(bt_serial.BluetoothDevice device, bool isConnected) {
    final deviceName = device.name.isNotEmpty ? device.name : 'Unknown Device';
    final isConnecting = _connectingDevices[device.address] == true;
    final isPaired = device.paired;
    final col = context.col;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: col.surface,
        borderRadius: BorderRadius.circular(kRadiusMD),
        boxShadow: [
          BoxShadow(
            color: kGrey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: isConnected
            ? Border.all(color: kBlue, width: 2)
            : !isPaired
            ? Border.all(
                color: Colors.orange.withValues(alpha: 0.6),
                width: 1.5,
              )
            : null,
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isConnected
                ? kBlue.withValues(alpha: 0.1)
                : kGrey.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.bluetooth, color: isConnected ? kBlue : kGrey),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                deviceName,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isConnected ? kBlue : col.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!isPaired) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.5),
                  ),
                ),
                child: const Text(
                  'New',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          device.address,
          style: TextStyle(
            color: col.textSecondary,
            fontSize: 12,
            fontFamily: 'Monospace',
          ),
        ),
        trailing: SizedBox(
          width: 130,
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
                    backgroundColor: kRed,
                    foregroundColor: kWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(kRadiusSM),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                  ),
                  child: const Text('Disconnect'),
                )
              else
                ElevatedButton(
                  onPressed: () => _connectToDevice(device),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPaired ? kBlue : Colors.orange,
                    foregroundColor: kWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(kRadiusSM),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  ),
                  child: Text(isPaired ? 'Connect' : 'Pair & Connect'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _closeHeaderDetailsPopup({bool openRegistrationForm = false}) {
    setState(() {
      _showHeaderDetailsPopup = false;
      _showRegistrationForm = openRegistrationForm;
    });
  }

  Widget _buildHeaderDetailsPopup() {
    final details = _resolvedHeaderDetails.isNotEmpty
        ? _resolvedHeaderDetails
        : _resolveHeaderDetails(_deviceData);
    final col = context.col;

    Widget buildRow(_DetailRow row) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: col.inputFill,
          borderRadius: BorderRadius.circular(kRadiusMD),
          border: Border.all(color: col.border),
        ),
        child: Row(
          children: [
            Icon(row.icon, size: 18, color: kBlue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.label,
                    style: TextStyle(
                      fontSize: 12,
                      color: col.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    row.value,
                    style: TextStyle(
                      fontSize: 14,
                      color: col.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    Widget buildSection(String title, List<_DetailRow> rows) {
      if (rows.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: kBlue,
            ),
          ),
          const SizedBox(height: 8),
          ...rows.map(buildRow),
          const SizedBox(height: 8),
        ],
      );
    }

    final companyRows = <_DetailRow>[
      if ((details['company'] ?? '').isNotEmpty)
        _DetailRow(
          icon: Icons.business_rounded,
          label: 'Company Name',
          value: details['company']!,
        ),
      if ((details['companyPhone'] ?? '').isNotEmpty)
        _DetailRow(
          icon: Icons.phone,
          label: 'Company Phone',
          value: details['companyPhone']!,
        ),
    ];

    final technicianRows = <_DetailRow>[
      if (_technicianIdController.text.isNotEmpty)
        _DetailRow(
          icon: Icons.badge,
          label: 'Technician ID',
          value: _technicianIdController.text,
        ),
      if (_technicianNameController.text.isNotEmpty)
        _DetailRow(
          icon: Icons.person,
          label: 'Technician Name',
          value: _technicianNameController.text,
        ),
    ];

    final ownerRows = <_DetailRow>[
      if ((details['ownerName'] ?? '').isNotEmpty)
        _DetailRow(
          icon: Icons.person_outline,
          label: 'Owner Name',
          value: details['ownerName']!,
        ),
      if ((details['ownerId'] ?? '').isNotEmpty)
        _DetailRow(
          icon: Icons.perm_identity,
          label: 'Owner ID',
          value: details['ownerId']!,
        ),
      if ((details['ownerPhone'] ?? '').isNotEmpty)
        _DetailRow(
          icon: Icons.phone_android,
          label: 'Owner Phone',
          value: details['ownerPhone']!,
        ),
    ];

    final vehicleRows = <_DetailRow>[
      if ((details['registrationNumber'] ?? '').isNotEmpty)
        _DetailRow(
          icon: Icons.pin_rounded,
          label: 'Number Plate',
          value: details['registrationNumber']!,
        ),
      if ((details['chassisNumber'] ?? '').isNotEmpty)
        _DetailRow(
          icon: Icons.directions_car_rounded,
          label: 'Chassis Number',
          value: details['chassisNumber']!,
        ),
      if ((details['make'] ?? '').isNotEmpty)
        _DetailRow(
          icon: Icons.precision_manufacturing_rounded,
          label: 'Vehicle Make',
          value: details['make']!,
        ),
    ];

    final deviceRows = <_DetailRow>[
      if ((details['headerId'] ?? '').isNotEmpty &&
          details['headerId'] != details['certificateNumber'])
        _DetailRow(
          icon: Icons.badge_rounded,
          label: 'Header ID',
          value: details['headerId']!,
        ),
      if ((details['certificateNumber'] ?? '').isNotEmpty)
        _DetailRow(
          icon: Icons.verified_rounded,
          label: 'Certificate No.',
          value: details['certificateNumber']!,
        ),
      if ((details['serialNumber'] ?? '').isNotEmpty)
        _DetailRow(
          icon: Icons.memory_rounded,
          label: 'Device Serial Number',
          value: details['serialNumber']!,
        ),
      if ((details['date'] ?? '').isNotEmpty)
        _DetailRow(
          icon: Icons.calendar_today_rounded,
          label: 'Date',
          value: details['date']!,
        ),
    ];

    final agentRows = <_DetailRow>[
      if ((details['agentName'] ?? '').isNotEmpty)
        _DetailRow(
          icon: Icons.support_agent_rounded,
          label: 'Agent Name',
          value: details['agentName']!,
        ),
      if ((details['agentId'] ?? '').isNotEmpty)
        _DetailRow(
          icon: Icons.badge_outlined,
          label: 'Agent ID',
          value: details['agentId']!,
        ),
      if ((details['location'] ?? '').isNotEmpty)
        _DetailRow(
          icon: Icons.location_on,
          label: 'Location',
          value: details['location']!,
        ),
      if ((details['email'] ?? '').isNotEmpty)
        _DetailRow(icon: Icons.email, label: 'Email', value: details['email']!),
      if ((details['agentPhone'] ?? '').isNotEmpty)
        _DetailRow(
          icon: Icons.phone_iphone,
          label: 'Agent Phone',
          value: details['agentPhone']!,
        ),
      if ((details['businessReg'] ?? '').isNotEmpty)
        _DetailRow(
          icon: Icons.app_registration,
          label: 'Business Registration',
          value: details['businessReg']!,
        ),
      if ((details['group'] ?? '').isNotEmpty)
        _DetailRow(icon: Icons.group, label: 'Group', value: details['group']!),
    ];

    final hasAnyData =
        companyRows.isNotEmpty ||
        technicianRows.isNotEmpty ||
        ownerRows.isNotEmpty ||
        vehicleRows.isNotEmpty ||
        deviceRows.isNotEmpty ||
        agentRows.isNotEmpty;

    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadiusPill),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.82,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: kBlue,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.description_rounded,
                    color: kWhite,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Header Details',
                      style: TextStyle(
                        color: kWhite,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: kWhite, size: 24),
                    onPressed: () => _closeHeaderDetailsPopup(),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: kBlue.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(kRadiusMD),
                        border: Border.all(
                          color: kBlue.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline_rounded,
                            color: kBlue,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'The connected device already has header details, so the app is showing them first.',
                              style: TextStyle(
                                color: col.textPrimary,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (!hasAnyData)
                      Text(
                        'No header details were found in this payload.',
                        style: TextStyle(
                          color: col.textSecondary,
                          fontSize: 14,
                        ),
                      )
                    else ...[
                      buildSection('Company Information', companyRows),
                      buildSection('Technician Information', technicianRows),
                      buildSection('Device Owner Information', ownerRows),
                      buildSection('Vehicle Information', vehicleRows),
                      buildSection('Device Information', deviceRows),
                      buildSection('Agent Information', agentRows),
                    ],
                    // const SizedBox(height: 8),
                    // OutlinedButton(
                    //   onPressed: () =>
                    //       _closeHeaderDetailsPopup(openRegistrationForm: true),
                    //   style: OutlinedButton.styleFrom(
                    //     foregroundColor: kBlue,
                    //     side: const BorderSide(color: kBlue),
                    //     padding: const EdgeInsets.symmetric(vertical: 14),
                    //     shape: RoundedRectangleBorder(
                    //       borderRadius: BorderRadius.circular(kRadiusMD),
                    //     ),
                    //   ),
                    //   child: const Text('Open Registration Form'),
                    // ),
                    const SizedBox(height: 3),
                    ElevatedButton(
                      onPressed: () => _closeHeaderDetailsPopup(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kBlue,
                        foregroundColor: kWhite,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(kRadiusMD),
                        ),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
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

  Widget _buildRegistrationForm() {
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadiusPill),
      ),
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
                  const Icon(Icons.developer_board, color: kWhite, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Device Registration',
                      style: TextStyle(
                        color: kWhite,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: kWhite, size: 24),
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
                          color: kBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(kRadiusSM),
                          border: Border.all(
                            color: kBlue.withValues(alpha: 0.3),
                          ),
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
                                borderRadius: BorderRadius.circular(kRadiusSM),
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
                                color: context.col.surface,
                                borderRadius: BorderRadius.circular(kRadiusSM),
                                border: Border.all(color: context.col.border),
                                boxShadow: [
                                  BoxShadow(
                                    color: kBlack.withValues(alpha: 0.1),
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
                                                    color: context
                                                        .col
                                                        .textSecondary,
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
                                                    color: context
                                                        .col
                                                        .textSecondary,
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
                                color: context.col.inputFill,
                                borderRadius: BorderRadius.circular(kRadiusSM),
                                border: Border.all(color: context.col.divider),
                              ),
                              margin: EdgeInsets.only(top: 4),
                              child: Text(
                                'No existing company found with "$_companySearchQuery". You can enter a new company.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.col.textSecondary,
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
                            borderRadius: BorderRadius.circular(kRadiusSM),
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
                            borderRadius: BorderRadius.circular(kRadiusSM),
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
                            borderRadius: BorderRadius.circular(kRadiusSM),
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
                            borderRadius: BorderRadius.circular(kRadiusSM),
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
                            borderRadius: BorderRadius.circular(kRadiusSM),
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
                            borderRadius: BorderRadius.circular(kRadiusSM),
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
                          labelText: 'Number Plate',
                          hintText: 'Enter vehicle Number Plate',
                          prefixIcon: Icon(Icons.confirmation_number),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(kRadiusSM),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Number plate is required";
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
                            borderRadius: BorderRadius.circular(kRadiusSM),
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
                            borderRadius: BorderRadius.circular(kRadiusSM),
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
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Certificate Number',
                          hintText: 'Certificate',
                          prefixIcon: const Icon(Icons.verified),
                          suffixIcon: const Icon(
                            Icons.lock_outline,
                            size: 18,
                          ),
                          filled: true,
                          fillColor: context.col.bg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(kRadiusSM),
                          ),
                          disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(kRadiusSM),
                            borderSide: BorderSide(
                              color: context.col.border,
                            ),
                          ),
                        ),
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
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Device Serial Number',
                          hintText: 'Serial',
                          prefixIcon: const Icon(Icons.numbers),
                          suffixIcon: const Icon(
                            Icons.lock_outline,
                            size: 18,
                          ),
                          filled: true,
                          fillColor: context.col.bg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(kRadiusSM),
                          ),
                          disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(kRadiusSM),
                            borderSide: BorderSide(
                              color: context.col.border,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Serial number is required";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _dateController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Date',
                          hintText: 'Populated from device',
                          prefixIcon: const Icon(Icons.calendar_today),
                          suffixIcon: const Icon(
                            Icons.lock_outline,
                            size: 18,
                          ),
                          filled: true,
                          fillColor: context.col.bg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(kRadiusSM),
                          ),
                          disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(kRadiusSM),
                            borderSide: BorderSide(
                              color: context.col.border,
                            ),
                          ),
                        ),
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
                            borderRadius: BorderRadius.circular(kRadiusSM),
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
                            borderRadius: BorderRadius.circular(kRadiusSM),
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
                            borderRadius: BorderRadius.circular(kRadiusSM),
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
                            borderRadius: BorderRadius.circular(kRadiusSM),
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
                            borderRadius: BorderRadius.circular(kRadiusSM),
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
                            borderRadius: BorderRadius.circular(kRadiusSM),
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

                      DropdownButtonFormField<String>(
                        value: _selectedGroup,
                        decoration: InputDecoration(
                          labelText: 'Group',
                          hintText: 'Select group',
                          prefixIcon: Icon(Icons.group),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(kRadiusSM),
                          ),
                        ),
                        items: _groupOptions
                            .map(
                              (g) => DropdownMenuItem<String>(
                                value: g,
                                child: Text(g),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedGroup = value;
                            _groupController.text = value ?? '';
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
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
                          foregroundColor: kWhite,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(kRadiusSM),
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
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool fullWidth = false,
  }) {
    final child = Container(
      width: fullWidth ? double.infinity : null,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(kRadiusMD),
        boxShadow: [
          BoxShadow(
            color: kBlack.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(kRadiusMD),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: kWhite, size: 22),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: kWhite,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return child;
  }

  @override
  Widget build(BuildContext context) {
    final col = context.col;

    return Stack(
      children: [
        Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            title: const Text("Connect Device"),
            backgroundColor: kBlue,
            foregroundColor: kWhite,
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
                          valueColor: AlwaysStoppedAnimation<Color>(kWhite),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Scanning...',
                        style: TextStyle(fontSize: 14, color: kWhite),
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
                          color: kWhite.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(kRadiusLG),
                          border: Border.all(
                            color: kWhite.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isConnected
                                  ? Icons.bluetooth_connected
                                  : Icons.bluetooth_disabled,
                              color: kWhite,
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
                                      color: kWhite,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    _isConnected
                                        ? 'Connected to ${_selectedDevice?.name ?? "Unknown"}'
                                        : 'Tap scan to find Atom Speed devices',
                                    style: TextStyle(
                                      color: kWhite.withValues(alpha: 0.8),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_isConnected)
                              IconButton(
                                onPressed: _disconnectDevice,
                                icon: const Icon(Icons.link_off, color: kWhite),
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
                          color: col.surface,
                          borderRadius: BorderRadius.circular(kRadiusMD),
                          boxShadow: [
                            BoxShadow(
                              color: kBlack.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _isScanning ? null : _startScanning,
                            borderRadius: BorderRadius.circular(kRadiusMD),
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
                                          ? kBlue.withValues(alpha: 0.7)
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
                            style: const TextStyle(color: kWhite, fontSize: 14),
                          ),
                        ),

                      // Calibration / header buttons (only show when connected)
                      if (_isConnected && _deviceData.isNotEmpty)
                        Column(
                          children: [
                            const SizedBox(height: 20),
                            if (_hasHeader) ...[
                              // Device already has a header — offer reset OR recalibrate
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: kWhite.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(
                                    kRadiusMD,
                                  ),
                                  border: Border.all(
                                    color: kWhite.withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle_outline,
                                      color: kWhite,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Header already set (ID: $_headerId)',
                                        style: const TextStyle(
                                          color: kWhite,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  // Reset header button
                                  // Expanded(
                                  //   child: _buildActionButton(
                                  //     icon: Icons.restart_alt_rounded,
                                  //     label: 'Reset Header',
                                  //     color: kRed,
                                  //     onTap: _resetDeviceHeader,
                                  //   ),
                                  // ),
                                  // const SizedBox(width: 12),
                                  // Recalibrate speed button
                                  Expanded(
                                    child: _buildActionButton(
                                      icon: Icons.speed,
                                      label: 'Calibrate Speed',
                                      color: Colors.orange,
                                      onTap: _prepareCalibration,
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
                              // No header yet — show the standard calibrate button
                              _buildActionButton(
                                icon: Icons.speed,
                                label: 'Calibrate Device',
                                color: Colors.orange,
                                onTap: _prepareCalibration,
                                fullWidth: true,
                              ),
                            ],
                          ],
                        ),

                      // Received Data Section
                      if (_receivedData.isNotEmpty &&
                          isReceivedDataHidden == false) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: kWhite.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(kRadiusLG),
                            border: Border.all(
                              color: kWhite.withValues(alpha: 0.3),
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
                                      color: kWhite,
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
                                          color: kWhite,
                                        ),
                                        tooltip: 'Clear',
                                      ),
                                      IconButton(
                                        onPressed: () => _retrieveDataFromDevice(
                                          restartFlow: true,
                                        ),
                                        icon: const Icon(
                                          Icons.refresh,
                                          color: kWhite,
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
                                  color: kBlack.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(
                                    kRadiusMD,
                                  ),
                                ),
                                child: SingleChildScrollView(
                                  child: Text(
                                    _receivedData,
                                    style: const TextStyle(
                                      color: kWhite,
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
                    decoration: BoxDecoration(
                      color: col.surface,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: kBlack.withValues(alpha: 0.26),
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
                                      color: col.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              ElevatedButton.icon(
                                onPressed: _loadPairedDevices,
                                icon: const Icon(Icons.refresh, size: 20),
                                label: const Text('Refresh'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kBlue.withValues(alpha: 0.1),
                                  foregroundColor: kBlue,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      kRadiusSM,
                                    ),
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
                                        color: col.textSecondary,
                                      ),
                                      const SizedBox(height: 20),
                                      Text(
                                        'No Atom Speed devices found',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: col.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Tap the scan button to discover nearby devices',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: col.textSecondary,
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
                                              foregroundColor: kWhite,
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
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          floatingActionButton: _isConnected
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton.extended(
                      heroTag: 'reset',
                      onPressed: _handleResetDevicePressed,
                      icon: const Icon(Icons.restart_alt),
                      label: const Text('Reset Device'),
                      backgroundColor: kRed,
                      foregroundColor: kWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(kRadiusPill),
                      ),
                      elevation: 4,
                    ),
                    const SizedBox(width: 12),
                    FloatingActionButton.extended(
                      heroTag: 'getData',
                      onPressed: () =>
                          _retrieveDataFromDevice(restartFlow: true),
                      icon: const Icon(Icons.download),
                      label: const Text('Get Device Data'),
                      backgroundColor: kBlue,
                      foregroundColor: kWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(kRadiusPill),
                      ),
                      elevation: 4,
                    ),
                  ],
                )
              : null,
        ),

        // Header Details Modal Overlay
        if (_showHeaderDetailsPopup) ...[
          GestureDetector(
            onTap: () => _closeHeaderDetailsPopup(),
            child: Container(
              color: kBlack.withValues(alpha: 0.5),
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          Center(child: _buildHeaderDetailsPopup()),
        ] else if (_showRegistrationForm) ...[
          // Semi-transparent background overlay
          GestureDetector(
            onTap: () {
              setState(() {
                _showRegistrationForm = false;
              });
            },
            child: Container(
              color: kBlack.withValues(alpha: 0.5),
              width: double.infinity,
              height: double.infinity,
            ),
          ),

          // Registration Form Dialog
          Center(child: _buildRegistrationForm()),
        ],

        // Calibration Modal Overlay
        if (_showCalibrationModal) ...[
          // Semi-transparent background overlay
          GestureDetector(
            onTap: () {
              if (!_isCalibrating) {
                setState(() {
                  _showCalibrationModal = false;
                });
              }
            },
            child: Container(
              color: kBlack.withValues(alpha: 0.5),
              width: double.infinity,
              height: double.infinity,
            ),
          ),

          // Calibration Dialog
          Center(child: _buildCalibrationModal()),
        ],
      ],
    );
  }
}

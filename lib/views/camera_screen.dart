import 'package:atom/config/constants.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraCaptureScreen extends StatefulWidget {
  final CameraLensDirection preferredCamera;

  const CameraCaptureScreen({
    super.key,
    this.preferredCamera = CameraLensDirection.back,
  });

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  CameraDescription? _selectedCamera;
  CameraLensDirection _currentCameraDirection = CameraLensDirection.back;
  bool _isSwitchingCamera = false;
  double _previewAspectRatio = 1.0;

  @override
  void initState() {
    super.initState();
    _currentCameraDirection = widget.preferredCamera;
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();

      _selectedCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == _currentCameraDirection,
        orElse: () => cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first,
        ),
      );

      await _controller?.dispose();

      _controller = CameraController(
        _selectedCamera!,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      _initializeControllerFuture = _controller!.initialize().then((_) {
        if (!mounted) return;
        setState(() {
          _isSwitchingCamera = false;
          _previewAspectRatio = _controller!.value.aspectRatio;
        });
      });

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Error initializing camera: $e");
      if (mounted)
        setState(() {
          _isSwitchingCamera = false;
        });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;

      if (!mounted) return;

      if (_controller == null || !_controller!.value.isInitialized) {
        throw Exception('Camera controller not initialized');
      }

      final image = await _controller!.takePicture();

      // SAFEGUARD: double-check mounted before using context
      if (!mounted) return;

      if (Navigator.canPop(context)) {
        Navigator.pop(context, image);
      }
    } catch (e) {
      debugPrint("Error taking picture: $e");

      if (!mounted) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error taking picture: ${e.toString()}')),
          );
        }
      });
    }
  }

  Future<void> _switchCamera() async {
    if (_isSwitchingCamera) return;

    setState(() {
      _isSwitchingCamera = true;
    });

    try {
      _currentCameraDirection =
          _currentCameraDirection == CameraLensDirection.back
          ? CameraLensDirection.front
          : CameraLensDirection.back;

      await _initializeCamera();
    } catch (e) {
      debugPrint("Error switching camera: $e");
      if (mounted) {
        setState(() {
          _isSwitchingCamera = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error switching camera: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBlack,
      body: Stack(
        children: [
          // Centered camera preview
          if (_controller != null && _initializeControllerFuture != null)
            FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (_controller != null && _controller!.value.isInitialized) {
                    return Center(
                      child: AspectRatio(
                        aspectRatio: _previewAspectRatio * 0.5,
                        child: CameraPreview(_controller!),
                      ),
                    );
                  } else {
                    return const Center(child: Text('Camera not initialized'));
                  }
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),

          // Camera switch button
          Positioned(
            bottom: 70,
            right: 20,
            child: IconButton(
              icon: Icon(Icons.cameraswitch, color: kWhite, size: 30),
              onPressed: _isSwitchingCamera ? null : _switchCamera,
            ),
          ),

          // Capture button
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _takePicture,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: kWhite,
                    shape: BoxShape.circle,
                    border: Border.all(color: kLightGrey, width: 4),
                  ),
                ),
              ),
            ),
          ),

          // Loading indicator when switching cameras
          if (_isSwitchingCamera)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}

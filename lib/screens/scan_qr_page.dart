// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class ScanQrPage extends StatefulWidget {
  const ScanQrPage({super.key});

  @override
  State<ScanQrPage> createState() => _ScanQrPageState();
}

class _ScanQrPageState extends State<ScanQrPage> with SingleTickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController();
  bool _isScanning = false;
  bool _isFlashOn = false;
  bool _isFrontCamera = false;
  bool _isProcessing = false;
  bool _hasPermission = false;
  bool _permissionChecked = false;
  
  // Animation properties
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  // Color scheme to match previous screens
  final Color _primaryColor = const Color(0xFF5C6BC0); // Indigo
  final Color _accentColor = const Color(0xFF42A5F5); // Blue
  final Color _errorColor = const Color(0xFFEF5350); // Red
  
  final ImagePicker _picker = ImagePicker();
  
  @override
  void initState() {
    super.initState();
    _checkPermission();
    
    // Set up the animation for the scanner overlay
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    
    _animation = Tween<double>(begin: 0, end: 300).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.linear)
    )..addListener(() {
      setState(() {});
    });
    
    _animationController.repeat(reverse: true);
    
    // Set system UI overlay style for better visual integration
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }
  
  Future<void> _checkPermission() async {
    final cameraStatus = await Permission.camera.status;
    setState(() {
      _hasPermission = cameraStatus.isGranted;
      _permissionChecked = true;
    });
    
    if (!_hasPermission) {
      final result = await Permission.camera.request();
      setState(() {
        _hasPermission = result.isGranted;
      });
    }
  }
  
  void _onDetect(BarcodeCapture capture) async {
    if (_isScanning || _isProcessing) return;
    setState(() {
      _isScanning = true;
      _isProcessing = true;
    });
    
    final code = capture.barcodes.first.rawValue;
    if (code != null) {
      HapticFeedback.mediumImpact();
      await _processScan(code);
    } else {
      setState(() {
        _isScanning = false;
        _isProcessing = false;
      });
    }
  }
  
  Future<void> _pickFromGallery() async {
    try {
      setState(() => _isProcessing = true);
      
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final BarcodeCapture? result = await _controller.analyzeImage(image.path);
        if (result != null && result.barcodes.isNotEmpty) {
          final String? code = result.barcodes.first.rawValue;
          if (code != null) {
            await _processScan(code);
            return;
          }
        }
        _showErrorMessage('No QR code found in the selected image');
      }
    } catch (e) {
      _showErrorMessage('Error processing image: ${e.toString().split('\n').first}');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
  
  Future<void> _processScan(String code) async {
    try {
      // Stop camera to conserve battery
      await _controller.stop();
      
      bool isPrescription = code.startsWith('pres-');
      if (!isPrescription) {
        _showInvalidCodeError();
        return;
      }
      
      final payload = code.split('-').length > 1 ? code.split('-')[1] : '';
      if (payload.isEmpty) {
        _showInvalidCodeError();
        return;
      }
      
      // Show loading state
      _showProcessingOverlay();
      
      final success = await _sendToBackend(payload);
      if (success) {
        await _showSuccessOverlay();
        Navigator.pushReplacementNamed(context, '/homePage');
      } else {
        _showErrorMessage('Failed to save prescription. Please try again.');
        await _controller.start();
        setState(() {
          _isScanning = false;
          _isProcessing = false;
        });
      }
    } catch (e) {
      _showErrorMessage('Error: ${e.toString().split('\n').first}');
      await _controller.start();
      setState(() {
        _isScanning = false;
        _isProcessing = false;
      });
    }
  }
  
  void _showInvalidCodeError() {
    _showErrorMessage('This QR code is not a valid prescription code');
    _controller.start();
    setState(() {
      _isScanning = false;
      _isProcessing = false;
    });
  }
  
  void _showErrorMessage(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: _errorColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
  
  void _showProcessingOverlay() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const ProcessingDialog(),
    );
  }
  
  Future<void> _showSuccessOverlay() async {
    Navigator.pop(context); // Dismiss the processing dialog
    
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const SuccessDialog(),
    );
  }
  
  Future<String?> _getAuthToken() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return user.getIdToken(true);
  }
  
  Future<bool> _sendToBackend(String code) async {
    try {
      final token = await _getAuthToken();
      if (token == null) return false;
      
      final uri = Uri.parse(
        'https://fastapi-app-production-6e30.up.railway.app/recievedPrescription',
      );
      final resp = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'prescription_id': code}),
      );
      
      return resp.statusCode == 200 || resp.statusCode == 201;
    } catch (e) {
      debugPrint('Error sending to backend: $e');
      return false;
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    if (!_permissionChecked) {
      return _buildLoadingScreen();
    }
    
    if (!_hasPermission) {
      return _buildPermissionDeniedScreen();
    }
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Scanner view
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          
          // Darkened overlay with transparent scanner area
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.5),
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Center(
                  child: Container(
                    height: 300,
                    width: 300,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Scanner border and animation
          Center(
            child: Container(
              height: 300,
              width: 300,
              decoration: BoxDecoration(
                border: Border.all(color: _primaryColor, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  // Animated scanner line
                  Positioned(
                    top: _animation.value,
                    child: Container(
                      height: 3,
                      width: 300,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _primaryColor.withOpacity(0),
                            _accentColor,
                            _primaryColor.withOpacity(0),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _accentColor.withOpacity(0.5),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Corner decorations
                  _buildCorner(top: 0, left: 0, isTopLeft: true),
                  _buildCorner(top: 0, right: 0, isTopRight: true),
                  _buildCorner(bottom: 0, left: 0, isBottomLeft: true),
                  _buildCorner(bottom: 0, right: 0, isBottomRight: true),
                ],
              ),
            ),
          ),
          
          // Top app bar with back button
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              leading: BackButton(
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                'Scan Prescription QR',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
            ),
          ),
          
          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 180,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Position the QR code within the frame',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildControlButton(
                        icon: Icons.flip_camera_ios,
                        label: _isFrontCamera ? 'Back Camera' : 'Front Camera',
                        onPressed: () {
                          _controller.switchCamera();
                          setState(() {
                            _isFrontCamera = !_isFrontCamera;
                          });
                        },
                      ),
                      _buildControlButton(
                        icon: _isFlashOn ? Icons.flash_on : Icons.flash_off,
                        label: _isFlashOn ? 'Flash Off' : 'Flash On',
                        onPressed: () {
                          _controller.toggleTorch();
                          setState(() {
                            _isFlashOn = !_isFlashOn;
                          });
                        },
                      ),
                      _buildControlButton(
                        icon: Icons.photo_library,
                        label: 'Gallery',
                        onPressed: _isProcessing ? null : _pickFromGallery,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCorner({
    double? top,
    double? bottom,
    double? left,
    double? right,
    bool isTopLeft = false,
    bool isTopRight = false,
    bool isBottomLeft = false,
    bool isBottomRight = false,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          border: Border(
            top: isTopLeft || isTopRight
                ? BorderSide(color: _primaryColor, width: 3)
                : BorderSide.none,
            bottom: isBottomLeft || isBottomRight
                ? BorderSide(color: _primaryColor, width: 3)
                : BorderSide.none,
            left: isTopLeft || isBottomLeft
                ? BorderSide(color: _primaryColor, width: 3)
                : BorderSide.none,
            right: isTopRight || isBottomRight
                ? BorderSide(color: _primaryColor, width: 3)
                : BorderSide.none,
          ),
          borderRadius: BorderRadius.only(
            topLeft: isTopLeft ? const Radius.circular(16) : Radius.zero,
            topRight: isTopRight ? const Radius.circular(16) : Radius.zero,
            bottomLeft: isBottomLeft ? const Radius.circular(16) : Radius.zero,
            bottomRight: isBottomRight ? const Radius.circular(16) : Radius.zero,
          ),
        ),
      ),
    );
  }
  
  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
  
  Widget _buildLoadingScreen() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
  
  Widget _buildPermissionDeniedScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(
          onPressed: () => Navigator.pop(context),
          color: Colors.white,
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.camera_alt_outlined,
                size: 80,
                color: Colors.white.withOpacity(0.8),
              ),
              const SizedBox(height: 24),
              const Text(
                'Camera Permission Required',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Please grant camera permission to scan QR codes.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () async {
                  await openAppSettings();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text('Open Settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProcessingDialog extends StatelessWidget {
  const ProcessingDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text(
                'Processing Prescription...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Please wait while we verify the QR code',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SuccessDialog extends StatefulWidget {
  const SuccessDialog({super.key});

  @override
  State<SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<SuccessDialog> {
  @override
  void initState() {
    super.initState();
    // Auto-dismiss after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                color: Color(0xFF4CAF50),
                size: 50,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Success!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Prescription saved successfully',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
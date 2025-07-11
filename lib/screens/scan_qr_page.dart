// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:mobile_scanner/mobile_scanner.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:intl/intl.dart';

// void main() {
//   runApp(const MaterialApp(home: ScanQrPage()));
// }

// class ScanQrPage extends StatefulWidget {
//   const ScanQrPage({super.key});

//   @override
//   State<ScanQrPage> createState() => _ScanQrPageState();
// }

// class _ScanQrPageState extends State<ScanQrPage>
//     with SingleTickerProviderStateMixin {
//   final MobileScannerController _controller = MobileScannerController();
//   late AnimationController _animationController;
//   bool _isScanning = false;
//   bool _isFlashOn = false;
//   String _currentDateTime = '';
//   late Timer _timer;

//   @override
//   void initState() {
//     super.initState();
//     _animationController = AnimationController(
//       duration: const Duration(milliseconds: 2000),
//       vsync: this,
//     )..repeat(reverse: true);

//     // Update time every second
//     _updateDateTime();
//     _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       _updateDateTime();
//     });
//   }

//   void _updateDateTime() {
//     setState(() {
//       _currentDateTime = DateFormat(
//         'yyyy-MM-dd HH:mm:ss',
//       ).format(DateTime.now().toUtc());
//     });
//   }

//   void _toggleFlash() {
//     _controller.toggleTorch();
//     setState(() {
//       _isFlashOn = !_isFlashOn;
//     });
//   }

//   void _pickFromGallery() async {
//     final ImagePicker picker = ImagePicker();
//     final XFile? image = await picker.pickImage(source: ImageSource.gallery);

//     if (image != null) {
//       final BarcodeCapture? result = await _controller.analyzeImage(image.path);
//       if (result != null && result.barcodes.isNotEmpty) {
//         final String? code = result.barcodes.first.rawValue;
//         if (code != null && mounted) {
//           _showSuccessfulScan(code);
//         }
//       } else if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('No QR code found in image.')),
//         );
//       }
//     }
//   }

//   void _showSuccessfulScan(String code) {
//     if (code.startsWith('USERID-')) {
//       final scannedUserId = code.substring('USERID-'.length);
//       Navigator.pushReplacementNamed(context, '/profilePage', arguments: {'userId': scannedUserId});
//       return;
//     }

//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             const Icon(Icons.check_circle, color: Colors.white),
//             const SizedBox(width: 8),
//             Expanded(
//               child: Text(
//                 'QR Code Scanned: $code',
//                 overflow: TextOverflow.ellipsis,
//               ),
//             ),
//           ],
//         ),
//         backgroundColor: Colors.green,
//         duration: const Duration(seconds: 2),
//       ),
//     );

//     showDialog(
//       context: context,
//       builder:
//           (context) => AlertDialog(
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(16),
//             ),
//             title: const Row(
//               children: [
//                 Icon(Icons.qr_code, color: Colors.blue),
//                 SizedBox(width: 8),
//                 Text('QR Code Found'),
//               ],
//             ),
//             content: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 SelectableText(code),
//               ],
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.of(context).pop(),
//                 child: const Text('OK'),
//               ),
//             ],
//           ),
//     );
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     _animationController.dispose();
//     _timer.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         title: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text('Scan QR Code', style: TextStyle(color: Colors.white)),
//             Text(
//               _currentDateTime,
//               style: TextStyle(
//                 color: Colors.white.withOpacity(0.7),
//                 fontSize: 12,
//               ),
//             ),
//           ],
//         ),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
//           onPressed: () => Navigator.pop(context),
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.photo_library, color: Colors.white),
//             tooltip: 'Scan from Gallery',
//             onPressed: _pickFromGallery,
//           ),
//           IconButton(
//             icon: Icon(
//               _isFlashOn ? Icons.flash_on : Icons.flash_off,
//               color: _isFlashOn ? Colors.yellow : Colors.white,
//             ),
//             tooltip: 'Toggle Flash',
//             onPressed: _toggleFlash,
//           ),
//         ],
//       ),
//       body: Stack(
//         alignment: Alignment.center,
//         children: [
//           MobileScanner(
//             controller: _controller,
//             onDetect: (BarcodeCapture capture) {
//               if (!_isScanning) {
//                 _isScanning = true;
//                 final List<Barcode> barcodes = capture.barcodes;
//                 if (barcodes.isNotEmpty) {
//                   final String? code = barcodes.first.rawValue;
//                   if (code != null) {
//                     _showSuccessfulScan(code);
//                   }
//                 }
//                 Future.delayed(const Duration(seconds: 2), () {
//                   _isScanning = false;
//                 });
//               }
//             },
//           ),
//           CustomPaint(
//             painter: ScannerOverlay(animation: _animationController),
//             child: Container(),
//           ),
//           Positioned(
//             bottom: 40,
//             child: Container(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//               decoration: BoxDecoration(
//                 color: Colors.black54,
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Column(
//                 children: [
//                   const Text(
//                     'Align QR code within the frame',
//                     style: TextStyle(color: Colors.white, fontSize: 16),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }


// class ScannerOverlay extends CustomPainter {
//   final Animation<double> animation;

//   ScannerOverlay({required this.animation}) : super(repaint: animation);

//   @override
//   void paint(Canvas canvas, Size size) {
//     final double frameSize = 300;
//     final Rect scanRect = Rect.fromCenter(
//       center: Offset(size.width / 2, size.height / 2),
//       width: frameSize,
//       height: frameSize,
//     );

//     final Paint borderPaint = Paint()
//       ..color = Colors.white
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 4;

//     final double scanLineY = scanRect.top + (scanRect.height * animation.value);

//     // Glow (shadow) paint for scanning line
//     final Paint shadowPaint = Paint()
//       ..color = Colors.blue.withOpacity(0.3)
//       ..strokeWidth = 4.0
//       ..style = PaintingStyle.stroke
//       ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

//     // Gradient scanning line paint
//     final Paint scanLinePaint = Paint()
//       ..shader = const LinearGradient(
//         begin: Alignment.topCenter,
//         end: Alignment.bottomCenter,
//         colors: [
//           Color(0x000000FF),
//           Color(0xFF00BFFF),
//           Color(0x000000FF),
//         ],
//         stops: [0.0, 0.5, 1.0],
//       ).createShader(Rect.fromLTWH(scanRect.left, scanLineY - 10, scanRect.width, 20))
//       ..strokeWidth = 2.5
//       ..style = PaintingStyle.stroke;

//     final double cornerLength = 30;

//     // Draw corners
//     void drawCorner(Offset start, Offset dx, Offset dy) {
//       canvas.drawLine(start, start + dx, borderPaint);
//       canvas.drawLine(start, start + dy, borderPaint);
//     }

//     drawCorner(scanRect.topLeft, Offset(cornerLength, 0), Offset(0, cornerLength));
//     drawCorner(scanRect.topRight, Offset(-cornerLength, 0), Offset(0, cornerLength));
//     drawCorner(scanRect.bottomLeft, Offset(cornerLength, 0), Offset(0, -cornerLength));
//     drawCorner(scanRect.bottomRight, Offset(-cornerLength, 0), Offset(0, -cornerLength));

//     // Draw scanning glow line (behind main line)
//     canvas.drawLine(
//       Offset(scanRect.left, scanLineY),
//       Offset(scanRect.right, scanLineY),
//       shadowPaint,
//     );

//     // Draw scanning gradient line (on top)
//     canvas.drawLine(
//       Offset(scanRect.left, scanLineY),
//       Offset(scanRect.right, scanLineY),
//       scanLinePaint,
//     );
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
// }


// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple QR Scanner',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ScanQrPage(),
    );
  }
}

class ScanQrPage extends StatefulWidget {
  const ScanQrPage({super.key});

  @override
  State<ScanQrPage> createState() => _ScanQrPageState();
}

class _ScanQrPageState extends State<ScanQrPage> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isScanning = false;
  final ImagePicker _picker = ImagePicker();

  
  void _onDetect(BarcodeCapture capture) async {
    if (_isScanning) return;
    _isScanning = true;
    await _controller.stop();

    final code = capture.barcodes.first.rawValue;
    if (code != null) {
      await _processScan(code);
    } else {
      await _controller.start();
      setState(() => _isScanning = false);
    }
  }


  Future<void> _pickFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final BarcodeCapture? result = await _controller.analyzeImage(image.path);
      if (result != null && result.barcodes.isNotEmpty) {
        final String? code = result.barcodes.first.rawValue;
        if (code != null) {
          _processScan(code);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No QR code found in image.')),
        );
      }
    }
  }


  Future<void> _processScan(String code) async {
    // 1. Stop camera so no more buffers pile up
    await _controller.stop();

    bool isPrescription = code.startsWith('pres-');
    String message;
    if (!isPrescription) {
      message = 'Not a prescription code';
    } else {
      final payload = code.split('-').length > 1 ? code.split('-')[1] : '';
      final success = await _sendToBackend(payload);
      message = success
        ? 'Prescription saved successfully!'
        : 'Failed to save prescription.';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 1)),
    );

    Navigator.pushReplacementNamed(context, '/homePage');

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
        print('Error sending to backend: $e');
      return false;
    }
  }



  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simple QR Scanner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library),
            tooltip: 'Scan from Gallery',
            onPressed: _pickFromGallery,
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          Center(
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 5),
                color: const Color.fromARGB(0, 0, 0, 0)           ),
            ),
          ),
        ],
      ),
    );
  }
}

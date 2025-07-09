import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MaterialApp(home: ScanQrPage()));
}

class ScanQrPage extends StatefulWidget {
  const ScanQrPage({super.key});

  @override
  State<ScanQrPage> createState() => _ScanQrPageState();
}

class _ScanQrPageState extends State<ScanQrPage>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController();
  late AnimationController _animationController;
  bool _isScanning = false;
  bool _isFlashOn = false;
  String _currentDateTime = '';
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    // Update time every second
    _updateDateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateDateTime();
    });
  }

  void _updateDateTime() {
    setState(() {
      _currentDateTime = DateFormat(
        'yyyy-MM-dd HH:mm:ss',
      ).format(DateTime.now().toUtc());
    });
  }

  void _toggleFlash() {
    _controller.toggleTorch();
    setState(() {
      _isFlashOn = !_isFlashOn;
    });
  }

  void _pickFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final BarcodeCapture? result = await _controller.analyzeImage(image.path);
      if (result != null && result.barcodes.isNotEmpty) {
        final String? code = result.barcodes.first.rawValue;
        if (code != null && mounted) {
          _showSuccessfulScan(code);
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No QR code found in image.')),
        );
      }
    }
  }

  void _showSuccessfulScan(String code) {
    if (code.startsWith('USERID-')) {
      final scannedUserId = code.substring('USERID-'.length);
      Navigator.pushReplacementNamed(context, '/profilePage', arguments: {'userId': scannedUserId});
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'QR Code Scanned: $code',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.qr_code, color: Colors.blue),
                SizedBox(width: 8),
                Text('QR Code Found'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(code),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Scan QR Code', style: TextStyle(color: Colors.white)),
            Text(
              _currentDateTime,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library, color: Colors.white),
            tooltip: 'Scan from Gallery',
            onPressed: _pickFromGallery,
          ),
          IconButton(
            icon: Icon(
              _isFlashOn ? Icons.flash_on : Icons.flash_off,
              color: _isFlashOn ? Colors.yellow : Colors.white,
            ),
            tooltip: 'Toggle Flash',
            onPressed: _toggleFlash,
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (BarcodeCapture capture) {
              if (!_isScanning) {
                _isScanning = true;
                final List<Barcode> barcodes = capture.barcodes;
                if (barcodes.isNotEmpty) {
                  final String? code = barcodes.first.rawValue;
                  if (code != null) {
                    _showSuccessfulScan(code);
                  }
                }
                Future.delayed(const Duration(seconds: 2), () {
                  _isScanning = false;
                });
              }
            },
          ),
          CustomPaint(
            painter: ScannerOverlay(animation: _animationController),
            child: Container(),
          ),
          Positioned(
            bottom: 40,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Text(
                    'Align QR code within the frame',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  // Text(
                  //   'User: Clear20-22',
                  //   style: TextStyle(
                  //     color: Colors.white.withOpacity(0.7),
                  //     fontSize: 12,
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class ScannerOverlay extends CustomPainter {
  final Animation<double> animation;

  ScannerOverlay({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final double frameSize = 300;
    final Rect scanRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: frameSize,
      height: frameSize,
    );

    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final double scanLineY = scanRect.top + (scanRect.height * animation.value);

    // Glow (shadow) paint for scanning line
    final Paint shadowPaint = Paint()
      ..color = Colors.blue.withOpacity(0.3)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    // Gradient scanning line paint
    final Paint scanLinePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0x000000FF),
          Color(0xFF00BFFF),
          Color(0x000000FF),
        ],
        stops: [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(scanRect.left, scanLineY - 10, scanRect.width, 20))
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final double cornerLength = 30;

    // Draw corners
    void drawCorner(Offset start, Offset dx, Offset dy) {
      canvas.drawLine(start, start + dx, borderPaint);
      canvas.drawLine(start, start + dy, borderPaint);
    }

    drawCorner(scanRect.topLeft, Offset(cornerLength, 0), Offset(0, cornerLength));
    drawCorner(scanRect.topRight, Offset(-cornerLength, 0), Offset(0, cornerLength));
    drawCorner(scanRect.bottomLeft, Offset(cornerLength, 0), Offset(0, -cornerLength));
    drawCorner(scanRect.bottomRight, Offset(-cornerLength, 0), Offset(0, -cornerLength));

    // Draw scanning glow line (behind main line)
    canvas.drawLine(
      Offset(scanRect.left, scanLineY),
      Offset(scanRect.right, scanLineY),
      shadowPaint,
    );

    // Draw scanning gradient line (on top)
    canvas.drawLine(
      Offset(scanRect.left, scanLineY),
      Offset(scanRect.right, scanLineY),
      scanLinePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

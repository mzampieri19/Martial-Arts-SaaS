import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRCheckInPage extends StatefulWidget {
  const QRCheckInPage({super.key});

  @override
  State<QRCheckInPage> createState() => _QRCheckInPageState();
}

class _QRCheckInPageState extends State<QRCheckInPage> {
  final MobileScannerController controller = MobileScannerController();
  bool isProcessing = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void handleQRCodeDetect(BarcodeCapture capture) {
    if (isProcessing) return;
    if (capture.barcodes.isEmpty) return;

    final String? maybeCode = capture.barcodes.first.rawValue;
    if (maybeCode == null || maybeCode.isEmpty) return;
    final String code = maybeCode;
    print('QR Code detected: $code');

    setState(() => isProcessing = true);

    // TODO: Process the QR code - validate class and check user in
    // For now, just show the detected code
    _showQRResult(code);
  }

  void _showQRResult(String qrData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QR Code Detected'),
        content: Text('Data: $qrData'),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => isProcessing = false);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    ).then((_) => setState(() => isProcessing = false));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Check In',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Camera preview
          MobileScanner(
            controller: controller,
            onDetect: handleQRCodeDetect,
          ),

          // Overlay with scanning box
          _buildOverlay(context),

          // Processing indicator
          if (isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOverlay(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scanArea = size.width * 0.7;
    final topPosition = size.height * 0.4;
    final leftPosition = (size.width - scanArea) / 2;

    return Stack(
      children: [
        // Dimmed background
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
                ),
              ),
              // Transparent scanning box
              Positioned(
                top: topPosition,
                left: leftPosition,
                child: Container(
                  width: scanArea,
                  height: scanArea,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Scanning box border
        Positioned(
          top: topPosition,
          left: leftPosition,
          child: Container(
            width: scanArea,
            height: scanArea,
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color(0xFFDD886C),
                width: 3,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                // Corner decorations
                _buildCorner(Icons.qr_code_scanner_rounded, 0, 0),
                _buildCorner(Icons.qr_code_scanner_rounded, 0, 1),
                _buildCorner(Icons.qr_code_scanner_rounded, 1, 0),
                _buildCorner(Icons.qr_code_scanner_rounded, 1, 1),
              ],
            ),
          ),
        ),

        // Instructions text
        Positioned(
          top: topPosition - 80,
          left: 0,
          right: 0,
          child: const Center(
            child: Text(
              'Position QR code inside the frame',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                shadows: [
                  Shadow(
                    color: Colors.black54,
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCorner(IconData icon, int x, int y) {
    return Positioned(
      top: y == 0 ? -8 : null,
      bottom: y == 1 ? -8 : null,
      left: x == 0 ? -8 : null,
      right: x == 1 ? -8 : null,
      child: Icon(
        icon,
        color: const Color(0xFFDD886C),
        size: 32,
      ),
    );
  }
}


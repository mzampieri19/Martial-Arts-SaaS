import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

    // Process the QR code - extract join_token and check user in
    _processQRCode(code);
  }

  /// Extract join_token from QR code URL and check user into the class
  Future<void> _processQRCode(String qrData) async {
    try {
      // Parse the join_token from the URL
      // Expected format: "martialartsapp://checkin/{join_token}"
      String? joinToken;
      
      if (qrData.startsWith('martialartsapp://checkin/')) {
        joinToken = qrData.replaceFirst('martialartsapp://checkin/', '').trim();
      } else if (qrData.contains('checkin/')) {
        // Alternative parsing if URL format is slightly different
        final parts = qrData.split('checkin/');
        if (parts.length > 1) {
          joinToken = parts[1].trim();
        }
      } else {
        // If it's just a UUID, assume it's the join_token directly
        joinToken = qrData.trim();
      }

      if (joinToken == null || joinToken.isEmpty) {
        _showError('Invalid QR code format');
        return;
      }

      print('Extracted join_token: $joinToken');

      // Get current user
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) {
        _showError('Please log in to check in');
        return;
      }

      // First, find the class by join_token
      final classResponse = await supabase
          .from('classes')
          .select('id, class_name')
          .eq('join_token', joinToken)
          .maybeSingle();

      if (classResponse == null) {
        _showError('Invalid QR code. Class not found.');
        return;
      }

      final classId = classResponse['id'] as int;
      final className = classResponse['class_name'] as String? ?? 'the class';

      print('Found class: $className (ID: $classId)');

      // Try to insert attendance record
      try {
        await supabase.from('user_class_attendance').insert({
          'user_id': user.id,
          'class_id': classId,
          'attended_at': DateTime.now().toIso8601String(),
        });

        _showSuccess('Successfully checked in to $className!');
      } catch (e) {
        final errorString = e.toString();
        print('Check-in error: $errorString');
        
        // Check if it's a duplicate key error (already checked in)
        if (errorString.contains('duplicate') || 
            errorString.contains('unique') ||
            errorString.contains('already exists') ||
            errorString.contains('unique_user_class_date')) {
          _showError('No - You have already checked in to $className today');
        } else {
          _showError('Error checking in: ${e.toString()}');
        }
      }
    } catch (e) {
      print('Error processing QR code: $e');
      _showError('Error checking in: ${e.toString()}');
    }
  }

  void _showSuccess(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 24),
            SizedBox(width: 8),
            Text('Success'),
          ],
        ),
        content: Text(message),
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
    ).then((_) {
      setState(() => isProcessing = false);
      // Navigate back after successful check-in
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    });
  }

  void _showError(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Text(error),
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


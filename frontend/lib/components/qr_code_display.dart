import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Widget to display a QR code for class check-in
class QRCodeDisplay extends StatelessWidget {
  final String joinToken;
  final String? className;
  final double size;

  const QRCodeDisplay({
    super.key,
    required this.joinToken,
    this.className,
    this.size = 250,
  });

  /// Generate the URL/string that will be encoded in the QR code
  /// Format: "martialartsapp://checkin/{join_token}"
  String get _qrData => 'martialartsapp://checkin/$joinToken';

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: size + 100, // Add padding for container
        ),
        child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          if (className != null) ...[
            Text(
              'Check-in QR Code',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              className!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
          ],
          // QR Code
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey[300]!,
                width: 2,
              ),
            ),
            child: QrImageView(
              data: _qrData,
              version: QrVersions.auto,
              size: size,
              backgroundColor: Colors.white,
              errorCorrectionLevel: QrErrorCorrectLevel.M,
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Scan this code to check in',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          // Display the token (for debugging/sharing)
          SelectableText(
            joinToken,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: Colors.grey[500],
                  fontSize: 10,
                ),
            textAlign: TextAlign.center,
          ),
          ],
        ),
        ),
      ),
    );
  }
}

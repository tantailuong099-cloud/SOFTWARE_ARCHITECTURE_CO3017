import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QRCodeWidget extends StatelessWidget {
  // Version 40-L capacity for the byte mode used by qr_flutter.
  static const _maxPayloadBytes = 2953;

  final String data;
  final double size;

  const QRCodeWidget({super.key, required this.data, this.size = 200});

  @override
  Widget build(BuildContext context) {
    const unavailable = Center(child: Text('Unable to display QR'));
    final canEncode =
        data.trim().isNotEmpty && utf8.encode(data).length <= _maxPayloadBytes;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: !canEncode
          ? unavailable
          : QrImageView(
              data: data,
              size: size,
              // Reserve at least four quiet modules even for a version 1 QR.
              padding: EdgeInsets.all(size * 0.14),
              errorStateBuilder: (_, _) => unavailable,
            ),
    );
  }
}

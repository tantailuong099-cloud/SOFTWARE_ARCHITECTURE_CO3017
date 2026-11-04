import 'package:flutter/material.dart';

/// A robust, dependency-free 2D QR-matrix visualization widget
class QRCodeWidget extends StatelessWidget {
  final String data;
  final double size;

  const QRCodeWidget({
    super.key,
    required this.data,
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CustomPaint(
        size: Size(size, size),
        painter: _QRPainter(data),
      ),
    );
  }
}

class _QRPainter extends CustomPainter {
  final String data;

  _QRPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill;

    const int gridSize = 21; // Standard QR matrix grid 21x21
    final cellSize = size.width / gridSize;

    // Deterministic pseudo-random pattern derived from data string
    final hash = data.hashCode;

    // 1. Draw 3 Finder Patterns (Top-Left, Top-Right, Bottom-Left)
    _drawFinderPattern(canvas, 0, 0, cellSize, paint);
    _drawFinderPattern(canvas, (gridSize - 7) * cellSize, 0, cellSize, paint);
    _drawFinderPattern(canvas, 0, (gridSize - 7) * cellSize, cellSize, paint);

    // 2. Draw data cells based on string content hash
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        // Skip finder pattern zones
        if ((r < 8 && c < 8) ||
            (r < 8 && c >= gridSize - 8) ||
            (r >= gridSize - 8 && c < 8)) {
          continue;
        }

        // Generate deterministic bit
        final bit = ((hash ^ (r * 31 + c * 17)) % 3) == 0;
        if (bit) {
          canvas.drawRect(
            Rect.fromLTWH(c * cellSize, r * cellSize, cellSize, cellSize),
            paint,
          );
        }
      }
    }
  }

  void _drawFinderPattern(
      Canvas canvas, double x, double y, double cellSize, Paint paint) {
    // Outer 7x7 box
    canvas.drawRect(
      Rect.fromLTWH(x, y, cellSize * 7, cellSize * 7),
      paint,
    );
    // Inner white 5x5 box
    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(x + cellSize, y + cellSize, cellSize * 5, cellSize * 5),
      whitePaint,
    );
    // Center black 3x3 box
    canvas.drawRect(
      Rect.fromLTWH(
          x + cellSize * 2, y + cellSize * 2, cellSize * 3, cellSize * 3),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _QRPainter oldDelegate) =>
      oldDelegate.data != data;
}

import 'package:flutter/material.dart';

class QRViewfinder extends StatefulWidget {
  final bool isScanning;

  const QRViewfinder({super.key, this.isScanning = true});

  @override
  State<QRViewfinder> createState() => _QRViewfinderState();
}

class _QRViewfinderState extends State<QRViewfinder>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.1, end: 0.9).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      height: 240,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
          width: 2,
        ),
      ),
      child: Stack(
        children: [
          // Corner markers
          Positioned(top: 8, left: 8, child: _corner(0)),
          Positioned(top: 8, right: 8, child: _corner(1)),
          Positioned(bottom: 8, left: 8, child: _corner(2)),
          Positioned(bottom: 8, right: 8, child: _corner(3)),

          // Center QR Icon
          Center(
            child: Icon(
              Icons.qr_code_2_rounded,
              size: 100,
              color: Colors.black.withOpacity(0.12),
            ),
          ),

          // Animated laser scanner bar
          if (widget.isScanning)
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Align(
                  alignment: Alignment(0, (_animation.value - 0.5) * 2),
                  child: Container(
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Theme.of(context).colorScheme.primary,
                          Colors.transparent,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.6),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _corner(int index) {
    // 0: top-left, 1: top-right, 2: bottom-left, 3: bottom-right
    const length = 22.0;
    const thickness = 4.0;
    const color = Color(0xFF1E88E5);

    return Container(
      width: length,
      height: length,
      decoration: BoxDecoration(
        border: Border(
          top: index == 0 || index == 1
              ? const BorderSide(color: color, width: thickness)
              : BorderSide.none,
          bottom: index == 2 || index == 3
              ? const BorderSide(color: color, width: thickness)
              : BorderSide.none,
          left: index == 0 || index == 2
              ? const BorderSide(color: color, width: thickness)
              : BorderSide.none,
          right: index == 1 || index == 3
              ? const BorderSide(color: color, width: thickness)
              : BorderSide.none,
        ),
      ),
    );
  }
}

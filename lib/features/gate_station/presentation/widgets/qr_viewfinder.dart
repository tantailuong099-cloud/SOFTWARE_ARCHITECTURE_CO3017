import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRViewfinder extends StatefulWidget {
  final bool isScanning;
  final void Function(String payload)? onScanned;

  const QRViewfinder({
    super.key,
    this.isScanning = true,
    this.onScanned,
  });

  @override
  State<QRViewfinder> createState() => _QRViewfinderState();
}

class _QRViewfinderState extends State<QRViewfinder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _animation;
  late final MobileScannerController _scannerController;

  bool _isCameraActive = true;
  String? _lastScannedPayload;
  DateTime? _lastScannedTime;

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

    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      detectionTimeoutMs: 200,
      facing: CameraFacing.front,
      formats: const [BarcodeFormat.qrCode],
      autoStart: true,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (!widget.isScanning || !_isCameraActive) return;
    for (final barcode in capture.barcodes) {
      final payload = barcode.rawValue;
      if (payload != null && payload.trim().isNotEmpty) {
        final now = DateTime.now();
        // Debounce: tránh gửi trùng lặp cùng 1 mã QR liên tục trong 2.5 giây
        if (_lastScannedPayload == payload &&
            _lastScannedTime != null &&
            now.difference(_lastScannedTime!).inMilliseconds < 2500) {
          return;
        }
        _lastScannedPayload = payload;
        _lastScannedTime = now;

        HapticFeedback.mediumImpact();
        widget.onScanned?.call(payload.trim());
        break;
      }
    }
  }

  Future<void> _toggleCamera() async {
    if (_isCameraActive) {
      await _scannerController.stop();
    } else {
      await _scannerController.start();
    }
    if (!mounted) return;
    setState(() {
      _isCameraActive = !_isCameraActive;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Camera Toolbar Controls
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Bật / tắt Camera
              IconButton(
                icon: Icon(
                  _isCameraActive ? Icons.videocam : Icons.videocam_off,
                  color: _isCameraActive ? Colors.green.shade700 : Colors.grey,
                  size: 20,
                ),
                tooltip: _isCameraActive ? 'Tắt camera' : 'Bật camera',
                onPressed: _toggleCamera,
              ),

              // Đổi Camera (Trước / Sau trên điện thoại, hoặc các webcam laptop)
              IconButton(
                icon: const Icon(Icons.flip_camera_ios, size: 20),
                tooltip: 'Đổi camera / Webcam',
                onPressed: _isCameraActive
                    ? () => _scannerController.switchCamera()
                    : null,
              ),

              // Bật / tắt đèn Flash (nếu thiết bị hỗ trợ)
              IconButton(
                icon: const Icon(Icons.flash_on, size: 20),
                tooltip: 'Bật / Tắt đèn Flash',
                onPressed: _isCameraActive
                    ? () => _scannerController.toggleTorch()
                    : null,
              ),
            ],
          ),
        ),

        // Khung quét Camera Viewfinder Box
        Container(
          width: 280,
          height: 280,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Live Camera Stream
                if (_isCameraActive)
                  MobileScanner(
                    controller: _scannerController,
                    onDetect: _onDetect,
                    fit: BoxFit.cover,
                    placeholderBuilder: (context) => Center(
                      child: CircularProgressIndicator(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    errorBuilder: (context, error) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.videocam_off_rounded,
                              size: 44,
                              color: Colors.amber.shade400,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Chưa cấp quyền Camera / Webcam',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Vui lòng cấp quyền camera trong trình duyệt hoặc thiết bị để quét trực tiếp.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () => _scannerController.start(),
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text('Thử lại'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.amberAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    color: Colors.grey.shade900,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.videocam_off,
                            size: 48,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Camera đang tắt',
                            style: TextStyle(color: Colors.grey.shade400),
                          ),
                          TextButton(
                            onPressed: _toggleCamera,
                            child: const Text('Bật lại camera'),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Corner markers (4 góc kính ngắm)
                Positioned(top: 8, left: 8, child: _corner(0)),
                Positioned(top: 8, right: 8, child: _corner(1)),
                Positioned(bottom: 8, left: 8, child: _corner(2)),
                Positioned(bottom: 8, right: 8, child: _corner(3)),

                // Animated laser scanner bar
                if (widget.isScanning && _isCameraActive)
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
                                    .withOpacity(0.8),
                                blurRadius: 10,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Hướng dẫn người dùng
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.center_focus_weak, size: 14, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(
              'Đưa mã QR trước camera điện thoại hoặc webcam laptop',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ],
        ),
      ],
    );
  }

  Widget _corner(int index) {
    // 0: top-left, 1: top-right, 2: bottom-left, 3: bottom-right
    const length = 24.0;
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

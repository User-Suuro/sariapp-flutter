import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../utils/scanner_sound.dart';

class CheckoutScannerPage extends StatefulWidget {
  final List<Map<String, dynamic>> dbProducts;
  const CheckoutScannerPage({super.key, required this.dbProducts});

  @override
  State<CheckoutScannerPage> createState() => _CheckoutScannerPageState();
}

class _CheckoutScannerPageState extends State<CheckoutScannerPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final TextEditingController _barcodeInputController = TextEditingController();
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  // Maps barcode string -> quantity scanned
  final Map<String, int> _scannedQuantities = {};
  
  // Track last scan for rate limiting the same barcode
  String? _lastScannedBarcode;
  DateTime? _lastScannedTime;

  // Temporary status message for user feedback (e.g. "Coke added!")
  String? _feedbackMessage;
  num _feedbackAnimValue = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0, end: 280).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    _barcodeInputController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  // Find a product from list by barcode
  Map<String, dynamic>? _findProductByBarcode(String barcode) {
    for (final p in widget.dbProducts) {
      final barcodes = p['product_barcode'];
      if (barcodes is List) {
        for (final bc in barcodes) {
          if (bc['id'].toString().trim() == barcode.trim()) {
            return p;
          }
        }
      } else if (barcodes is Map) {
        if (barcodes['id'].toString().trim() == barcode.trim()) {
          return p;
        }
      }
    }
    return null;
  }

  void _processBarcode(String barcodeStr, {bool isSimulation = false}) {
    final cleanCode = barcodeStr.trim();
    if (cleanCode.isEmpty) return;

    // Rate-limiting debounce: the same barcode scanned within 1.5 seconds is ignored
    if (!isSimulation && _lastScannedBarcode == cleanCode && _lastScannedTime != null) {
      final difference = DateTime.now().difference(_lastScannedTime!);
      if (difference.inMilliseconds < 1500) {
        return; // Skip duplicate scan in split second
      }
    }

    _lastScannedBarcode = cleanCode;
    _lastScannedTime = DateTime.now();

    final product = _findProductByBarcode(cleanCode);

    if (product == null) {
      _showFeedback('Scanned "$cleanCode" - Product not found!');
      return;
    }

    final String name = (product['name'] ?? 'Unknown Item').toString().toUpperCase();
    final int maxStock = product['qty'] ?? 0;

    setState(() {
      final int currentCount = _scannedQuantities[cleanCode] ?? 0;
      if (currentCount >= maxStock) {
        _showFeedback('Cannot scan more: "$name" stock limit reached!');
      } else {
        _scannedQuantities[cleanCode] = currentCount + 1;
        _showFeedback('ADDED: $name (Qty: ${currentCount + 1})');
        ScannerSound.playBeep();
      }
    });
  }

  void _showFeedback(String msg) {
    setState(() {
      _feedbackMessage = msg;
    });
    // Visual auto-clear feedback message after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _feedbackMessage == msg) {
        setState(() {
          _feedbackMessage = null;
        });
      }
    });
  }

  void _showManualInputDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'ENTER BARCODE FOR SALE',
          style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        content: TextField(
          controller: _barcodeInputController,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Enter numerical code...',
            hintStyle: GoogleFonts.inter(color: Colors.grey),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.black)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'CANCEL',
              style: GoogleFonts.inter(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
          TextButton(
            onPressed: () {
              final code = _barcodeInputController.text.trim();
              Navigator.of(context).pop();
              _barcodeInputController.clear();
              if (code.isNotEmpty) {
                _processBarcode(code, isSimulation: true);
              }
            },
            child: Text(
              'ADD',
              style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showSimulationSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SIMULATE CHECKOUT SCAN (TAP MULTIPLE TIMES)',
                style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14),
              ),
              const SizedBox(height: 12),
              if (widget.dbProducts.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    'No products loaded on checkout.',
                    style: GoogleFonts.inter(color: Colors.grey, fontSize: 13),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: widget.dbProducts.length,
                    itemBuilder: (context, index) {
                      final p = widget.dbProducts[index];
                      final name = (p['name'] ?? 'Unknown Product').toString().toUpperCase();
                      final barcodes = p['product_barcode'];
                      String? barcodeId;
                      if (barcodes is List && barcodes.isNotEmpty) {
                        barcodeId = barcodes[0]['id']?.toString();
                      } else if (barcodes is Map) {
                        barcodeId = barcodes['id']?.toString();
                      }

                      if (barcodeId == null) return const SizedBox.shrink();

                      final qtyScanned = _scannedQuantities[barcodeId] ?? 0;
                      final stock = p['qty'] ?? 0;

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          name,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Text(
                          'Barcode: $barcodeId | Max Stock: $stock',
                          style: GoogleFonts.inter(fontSize: 12),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (qtyScanned > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'x$qtyScanned',
                                  style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            const SizedBox(width: 8),
                            const Icon(Icons.add_circle, color: Colors.black),
                          ],
                        ),
                        onTap: () {
                          // Tap multiple times to simulate multiple items scanning
                          _processBarcode(barcodeId!, isSimulation: true);
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _finishScanning() {
    Navigator.of(context).pop(_scannedQuantities);
  }

  @override
  Widget build(BuildContext context) {
    int totalScannedCount = _scannedQuantities.values.fold(0, (sum, count) => sum + count);

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'CHECKOUT SCANNER',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Live mobile camera feed mapping
          Positioned.fill(
            child: MobileScanner(
              controller: _scannerController,
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                if (barcodes.isNotEmpty) {
                  final String? code = barcodes.first.rawValue;
                  if (code != null) {
                    _processBarcode(code);
                  }
                }
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFF1A1A1A),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.videocam_off, color: Colors.white54, size: 40),
                        const SizedBox(height: 16),
                        Text(
                          'Camera access not active or not allowed.',
                          style: GoogleFonts.inter(color: Colors.white60, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Camera scanner alignment guides
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.white.withOpacity(0.5),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        return Positioned(
                          top: _animation.value,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 2,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.0),
                                  Colors.white,
                                  Colors.white.withOpacity(0.0),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    _buildCorner(0, 0, top: true, left: true),
                    _buildCorner(280, 0, top: true, right: true),
                    _buildCorner(0, 280, bottom: true, left: true),
                    _buildCorner(280, 280, bottom: true, right: true),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Continuous Scan Active',
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // Top Floating Alert Prompt (Flashes when item is scanned successfully)
          if (_feedbackMessage != null)
            Positioned(
              top: 100,
              left: 24,
              right: 24,
              child: AnimatedOpacity(
                opacity: 1.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.black, width: 2.0),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black,
                        offset: Offset(4, 4),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: Colors.green),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _feedbackMessage!,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Scrollable scanned items preview feed at the bottom
          Positioned(
            bottom: 140,
            left: 24,
            right: 24,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.85),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24),
              ),
              child: _scannedQuantities.isEmpty
                  ? Center(
                      child: Text(
                        'No Scanned Items Yet',
                        style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: _scannedQuantities.length,
                      itemBuilder: (context, index) {
                        final barcode = _scannedQuantities.keys.elementAt(index);
                        final qty = _scannedQuantities[barcode]!;
                        final product = _findProductByBarcode(barcode);
                        final name = product != null ? product['name'].toString().toUpperCase() : 'Unknown Product';
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white30,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'x$qty',
                                  style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),

          // Bottom Action Panel
          Positioned(
            bottom: 50,
            left: 24,
            right: 24,
            child: Row(
              children: [
                _buildMiniActionButton(
                  Icons.keyboard_outlined,
                  'Man.',
                  _showManualInputDialog,
                ),
                const SizedBox(width: 12),
                _buildMiniActionButton(
                  Icons.smart_toy_outlined,
                  'Sim.',
                  _showSimulationSheet,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _finishScanning,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'DONE SCANNING',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w800, letterSpacing: 0.5),
                          ),
                          const SizedBox(width: 8),
                          if (totalScannedCount > 0)
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '$totalScannedCount',
                                style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorner(
    double x,
    double y, {
    bool top = false,
    bool bottom = false,
    bool left = false,
    bool right = false,
  }) {
    return Positioned(
      top: top ? 0 : null,
      bottom: bottom ? 0 : null,
      left: left ? 0 : null,
      right: right ? 0 : null,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          border: Border(
            top: top ? const BorderSide(color: Colors.white, width: 4) : BorderSide.none,
            bottom: bottom ? const BorderSide(color: Colors.white, width: 4) : BorderSide.none,
            left: left ? const BorderSide(color: Colors.white, width: 4) : BorderSide.none,
            right: right ? const BorderSide(color: Colors.white, width: 4) : BorderSide.none,
          ),
          borderRadius: BorderRadius.only(
            topLeft: top && left ? const Radius.circular(20) : Radius.zero,
            topRight: top && right ? const Radius.circular(20) : Radius.zero,
            bottomLeft: bottom && left ? const Radius.circular(20) : Radius.zero,
            bottomRight: bottom && right ? const Radius.circular(20) : Radius.zero,
          ),
        ),
      ),
    );
  }

  Widget _buildMiniActionButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

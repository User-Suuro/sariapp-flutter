import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'edit_product.dart';
import '../../utils/scanner_sound.dart';

class RestockScannerPage extends StatefulWidget {
  const RestockScannerPage({super.key});

  @override
  State<RestockScannerPage> createState() => _RestockScannerPageState();
}

class _RestockScannerPageState extends State<RestockScannerPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final TextEditingController _barcodeInputController = TextEditingController();
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  bool _isSearching = false;
  List<Map<String, dynamic>> _registeredBarcodes = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0, end: 280).animate(_controller);
    _loadRegisteredBarcodes();
  }

  @override
  void dispose() {
    _controller.dispose();
    _barcodeInputController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _loadRegisteredBarcodes() async {
    try {
      final data = await Supabase.instance.client
          .from('product_barcode')
          .select('id, products(name)');
      if (mounted) {
        setState(() {
          _registeredBarcodes = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (_) {}
  }

  Future<void> _processBarcode(String barcodeStr) async {
    final cleanCode = barcodeStr.trim();
    if (cleanCode.isEmpty) return;

    setState(() {
      _isSearching = true;
    });

    try {
      final supabase = Supabase.instance.client;

      final barcodeData = await supabase
          .from('product_barcode')
          .select('product_id, products(*)')
          .eq('id', cleanCode)
          .maybeSingle();

      if (barcodeData == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Barcode "$cleanCode" not found in inventory!'),
              backgroundColor: const Color(0xFFBA1A1A),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        final product = barcodeData['products'];
        if (product != null && mounted) {
          ScannerSound.playBeep();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => EditProductPage(product: product),
            ),
          );
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Matching product data is empty!'),
                backgroundColor: Color(0xFFBA1A1A),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error looking up barcode: $e'),
            backgroundColor: const Color(0xFFBA1A1A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  void _showManualInputDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'ENTER BARCODE',
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
                _processBarcode(code);
              }
            },
            child: Text(
              'LOOKUP',
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
                'REGISTERED BARCODES (SIMULATION)',
                style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14),
              ),
              const SizedBox(height: 12),
              if (_registeredBarcodes.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    'No barcodes found in database.',
                    style: GoogleFonts.inter(color: Colors.grey, fontSize: 13),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _registeredBarcodes.length,
                    itemBuilder: (context, index) {
                      final item = _registeredBarcodes[index];
                      final barcodeId = item['id'].toString();
                      final products = item['products'];
                      final prodName = products != null
                          ? products['name'].toString().toUpperCase()
                          : 'UNKNOWN PRODUCT';
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          prodName,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Text(
                          'Barcode: $barcodeId',
                          style: GoogleFonts.inter(fontSize: 12),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                        onTap: () {
                          Navigator.of(context).pop();
                          _processBarcode(barcodeId);
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

  @override
  Widget build(BuildContext context) {
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
          'RESTOCK SCANNER',
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
          // Real Mobile Scanner from camera hardware
          Positioned.fill(
            child: MobileScanner(
              controller: _scannerController,
              onDetect: (capture) {
                if (_isSearching) return;
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
          if (_isSearching)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            )
          else
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
                  const SizedBox(height: 48),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Align barcode inside the box to scan',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildActionButton(
                  Icons.keyboard_outlined,
                  'Enter Code',
                  _showManualInputDialog,
                ),
                const SizedBox(width: 40),
                _buildActionButton(
                  Icons.smart_toy_outlined,
                  'Simulate Scan',
                  _showSimulationSheet,
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

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

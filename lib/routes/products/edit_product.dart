import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProductPage extends StatefulWidget {
  final Map<String, dynamic>? product;
  const EditProductPage({super.key, this.product});

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final _quantityController = TextEditingController(text: '24');
  late int _currentStock;
  late int _currentPrice;
  bool _isFlashing = false;
  Map<String, dynamic>? _fallbackProduct;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _currentStock = widget.product!['qty'] ?? 0;
      _currentPrice = widget.product!['price'] ?? 0;
    } else {
      _currentStock = 0;
      _currentPrice = 0;
      _loadFallbackProduct();
    }
  }

  Future<void> _loadFallbackProduct() async {
    try {
      final data = await Supabase.instance.client
          .from('products')
          .select('*, product_barcode(id)')
          .limit(1);
      if (data.isNotEmpty && mounted) {
        setState(() {
          _fallbackProduct = data.first;
          _currentStock = _fallbackProduct!['qty'] ?? 0;
          _currentStock = _fallbackProduct!['price'] ?? 0;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _triggerFlashAndUpdate() async {
    final qtyText = _quantityController.text;
    final qty = int.tryParse(qtyText) ?? 0;
    if (qty <= 0) return;

    setState(() {
      _isFlashing = true;
    });

    try {
      final targetProduct = widget.product ?? _fallbackProduct;
      if (targetProduct == null) {
        throw Exception('No product loaded to restock.');
      }
      final newQty = _currentStock + qty;
      await Supabase.instance.client
          .from('products')
          .update({'qty': newQty})
          .eq('id', targetProduct['id']);

      if (mounted) {
        setState(() {
          _currentStock = newQty;
          _quantityController.text = '0';
        });
      }

      await Future.delayed(const Duration(milliseconds: 100));

      if (mounted) {
        setState(() {
          _isFlashing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'INVENTORY UPDATED SUCCESSFULLY',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.black,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isFlashing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ERROR UPDATING STOCK: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isFlashing ? Colors.black : const Color(0xFFF9F9F9),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56.0),
        child: Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.black, width: 2.0)),
          ),
          child: AppBar(
            backgroundColor: const Color(0xFFF9F9F9),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              'EDIT PRODUCT',
              style: GoogleFonts.inter(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ),
      ),
      body: _isFlashing
          ? const SizedBox.expand()
          : SingleChildScrollView(
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 24.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Scan Barcode Button

                      // Product Summary Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9F9F9),
                          border: Border.all(color: Colors.black, width: 2.0),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SELECTED ITEM',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF5D5F5F),
                                letterSpacing: 2.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              () {
                                final targetProduct =
                                    widget.product ?? _fallbackProduct;
                                return targetProduct != null
                                    ? (targetProduct['name'] ?? '').toString()
                                    : 'LOADING...';
                              }(),
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.qr_code,
                                  color: Color(0xFF5D5F5F),
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  () {
                                    final targetProduct =
                                        widget.product ?? _fallbackProduct;
                                    if (targetProduct == null)
                                      return 'LOADING...';
                                    final barcodes =
                                        targetProduct['product_barcode'];
                                    if (barcodes is List &&
                                        barcodes.isNotEmpty) {
                                      return barcodes[0]['id']?.toString() ??
                                          'NO BARCODE';
                                    } else if (barcodes is Map) {
                                      return barcodes['id']?.toString() ??
                                          'NO BARCODE';
                                    }
                                    return 'NO BARCODE';
                                  }(),
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    color: const Color(0xFF5D5F5F),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F3F3),
                          border: Border.all(color: Colors.black, width: 2.0),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'PRICING',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              '$_currentPrice php',
                              style: GoogleFonts.inter(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Current Stock read-only display
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F3F3),
                          border: Border.all(color: Colors.black, width: 2.0),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'MANUAL STOCK',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              '$_currentStock pcs',
                              style: GoogleFonts.inter(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F3F3),
                          border: Border.all(color: Colors.black, width: 2.0),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'BARCODE STOCK',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              '$_currentStock pcs',
                              style: GoogleFonts.inter(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

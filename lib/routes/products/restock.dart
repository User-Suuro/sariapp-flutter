import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RestockPage extends StatefulWidget {
  final Map<String, dynamic>? product;
  const RestockPage({super.key, this.product});

  @override
  State<RestockPage> createState() => _RestockPageState();
}

class _RestockPageState extends State<RestockPage> {
  final _quantityController = TextEditingController(text: '24');
  late int _currentStock;
  bool _isFlashing = false;
  Map<String, dynamic>? _fallbackProduct;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _currentStock = widget.product!['qty'] ?? 0;
    } else {
      _currentStock = 0;
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
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: _isFlashing ? Colors.white : Colors.black,
                width: 2.0,
              ),
            ),
          ),
          child: AppBar(
            backgroundColor: _isFlashing ? Colors.black : const Color(0xFFF9F9F9),
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: _isFlashing ? Colors.white : Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              'RESTOCK',
              style: GoogleFonts.inter(
                color: _isFlashing ? Colors.white : Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Icon(
                  Icons.account_circle,
                  color: _isFlashing ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
      body: _isFlashing
          ? const SizedBox.expand()
          : SingleChildScrollView(
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Scan Barcode Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Barcode scanner starting...'),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: Colors.black,
                              ),
                            );
                          },
                          icon: const Icon(Icons.qr_code_scanner, color: Colors.black),
                          label: Text(
                            'SCAN BARCODE',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: Colors.black,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF9F9F9),
                            foregroundColor: Colors.black,
                            elevation: 0,
                            side: const BorderSide(color: Colors.black, width: 2.0),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      
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
                                final targetProduct = widget.product ?? _fallbackProduct;
                                return targetProduct != null ? (targetProduct['name'] ?? '').toString() : 'LOADING...';
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
                                const Icon(Icons.qr_code, color: Color(0xFF5D5F5F), size: 18),
                                const SizedBox(width: 4),
                                Text(
                                  () {
                                    final targetProduct = widget.product ?? _fallbackProduct;
                                    if (targetProduct == null) return 'LOADING...';
                                    final barcodes = targetProduct['product_barcode'];
                                    if (barcodes is List && barcodes.isNotEmpty) {
                                      return barcodes[0]['id']?.toString() ?? 'NO BARCODE';
                                    } else if (barcodes is Map) {
                                      return barcodes['id']?.toString() ?? 'NO BARCODE';
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
                              'CURRENT STOCK',
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

                      // Quantitative Input for Received Quantity
                      Text(
                        'QUANTITY RECEIVED',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                        decoration: const InputDecoration(
                          hintText: '0',
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.black, width: 2.0),
                            borderRadius: BorderRadius.zero,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.black, width: 4.0),
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                        onChanged: (val) {
                          final num = int.tryParse(val) ?? 0;
                          if (num < 0) {
                            _quantityController.text = '0';
                            _quantityController.selection = TextSelection.fromPosition(
                              const TextPosition(offset: 1),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 32),

                      // Store shelf architectural illustration
                      Container(
                        height: 160,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black, width: 2.0),
                        ),
                        child: ColorFiltered(
                          colorFilter: const ColorFilter.matrix(<double>[
                            0.2126, 0.7152, 0.0722, 0, 0,
                            0.2126, 0.7152, 0.0722, 0, 0,
                            0.2126, 0.7152, 0.0722, 0, 0,
                            0,      0,      0,      1, 0,
                          ]),
                          child: Image.network(
                            'https://lh3.googleusercontent.com/aida-public/AB6AXuBEeYmamUMUe3YacQDkRFGsq8_rnKiEqaSeMoeWyhggMCSLmhKloPTUtnK4k_VUG-GG1X0uA01-4sI__bINv8P1wNTBO4KewNZcYm8CzIT9m5O7wongoVhQdIXAHuklhyra--psKNN1cx_kSfwhxjUEATJyUIGeb7ol8hd9nsp33d5XQNBVSWt3xzicZKfTzl99WVYVoIGyOVr_-ZhdccTJvMJsOrCYAeEFYqJW2Koyf35unM_LWfA6ZWuSR665mixQ0WY34UXEr0js',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      bottomNavigationBar: _isFlashing
          ? null
          : Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF9F9F9),
                border: Border(
                  top: BorderSide(color: Colors.black, width: 2.0),
                ),
              ),
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _triggerFlashAndUpdate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.sync, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        'UPDATE STOCK',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
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

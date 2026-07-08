import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'checkout_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/notifications_helper.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  List<Map<String, dynamic>> _dbProducts = [];
  bool _isLoadingProducts = true;
  String _dialogSearchQuery = '';
  Map<String, dynamic>? _selectedDialogProduct;
  int _dialogQty = 1;

  final List<Map<String, dynamic>> _cartItems = [];
  bool _isSavingCheckout = false;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    try {
      final data = await Supabase.instance.client
          .from('products')
          .select('*, product_barcode(id)');
      if (mounted) {
        setState(() {
          _dbProducts = List<Map<String, dynamic>>.from(data);
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingProducts = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading products: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _completeSale() async {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cart is empty!'),
          backgroundColor: Colors.black,
        ),
      );
      return;
    }

    setState(() {
      _isSavingCheckout = true;
    });

    try {
      final double total = _cartItems.fold(0, (sum, item) => sum + (item['price'] * item['qty']));

      // 1. Insert Checkout
      dynamic checkoutId;
      try {
        final checkoutRes = await Supabase.instance.client
            .from('checkout')
            .insert({
              'total_sale': total,
            })
            .select('id')
            .single();
        checkoutId = checkoutRes['id'];
      } catch (err) {
        final errStr = err.toString();
        if (errStr.contains('checkout') && (errStr.contains('does not exist') || errStr.contains('42P01'))) {
          final checkoutRes = await Supabase.instance.client
              .from('checkout')
              .insert({
                'total_sale': total,
              })
              .select('id')
              .single();
          checkoutId = checkoutRes['id'];
        } else {
          rethrow;
        }
      }

      // 2. Insert Sales
      try {
        final List<Map<String, dynamic>> sales = _cartItems.map((item) {
          return {
            'checkout_id': checkoutId,
            'product_barcode': item['barcode'],
            'qty_item': item['qty'],
            'total_price': item['price'] * item['qty'],
          };
        }).toList();

        await Supabase.instance.client.from('sale').insert(sales);
      } catch (err) {
        final errStr = err.toString();
        if (errStr.contains('checkout_id') || errStr.contains('column') || errStr.contains('42703')) {
          final List<Map<String, dynamic>> salesWithTypo = _cartItems.map((item) {
            return {
              'checkout_id': checkoutId,
              'product_barcode': item['barcode'],
              'qty_item': item['qty'],
              'total_price': item['price'] * item['qty'],
            };
          }).toList();
          await Supabase.instance.client.from('sale').insert(salesWithTypo);
        } else {
          rethrow;
        }
      }

      // Check if low stock notifications are enabled
      final prefs = await SharedPreferences.getInstance();
      final bool lowStockEnabled = prefs.getBool('low_stock_alerts') ?? true;

      // 3. Update stock levels
      for (final item in _cartItems) {
        final product = item['product'];
        final int currentStock = product['qty'] ?? 0;
        final int soldQty = item['qty'] as int;
        final int newStock = currentStock - soldQty;

        await Supabase.instance.client
            .from('products')
            .update({'qty': newStock})
            .eq('id', product['id']);

        if (lowStockEnabled) {
          final int threshold = product['min_stock'] ?? 10;
          if (newStock <= threshold) {
            final String name = (product['name'] ?? 'Unknown Item').toString().toUpperCase();
            await NotificationsHelper.showNotification(
              title: 'LOW STOCK WARNING!',
              body: '$name is running low ($newStock left).',
            );
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SALE COMPLETED SUCCESSFULLY'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.black,
          ),
        );
        setState(() {
          _cartItems.clear();
        });
        _fetchProducts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving checkout: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingCheckout = false;
        });
      }
    }
  }

  void _showAddProductDialog() {
    if (_isLoadingProducts) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait, loading products...')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final List<Map<String, dynamic>> filtered = _dbProducts.where((p) {
              final name = (p['name'] ?? '').toString().toLowerCase();
              final query = _dialogSearchQuery.toLowerCase();
              return name.contains(query);
            }).toList();

            return AlertDialog(
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              backgroundColor: const Color(0xFFF9F9F9),
              title: Text(
                'ADD ITEM MANUALLY',
                style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              content: SizedBox(
                width: 320,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      onChanged: (val) {
                        setStateDialog(() {
                          _dialogSearchQuery = val;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search product...',
                        hintStyle: GoogleFonts.inter(color: Colors.grey),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black, width: 2.0),
                          borderRadius: BorderRadius.zero,
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black, width: 2.0),
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_selectedDialogProduct == null) ...[
                      Text(
                        'SELECT PRODUCT:',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 200,
                        child: filtered.isEmpty
                            ? Center(
                                child: Text(
                                  'NO ITEMS FOUND',
                                  style: GoogleFonts.inter(color: Colors.grey, fontSize: 12),
                                ),
                              )
                            : ListView.builder(
                                itemCount: filtered.length,
                                itemBuilder: (ctx, idx) {
                                  final p = filtered[idx];
                                  final name = (p['name'] ?? '').toString().toUpperCase();
                                  final double sellingPrice = (p['price_sale'] as num?)?.toDouble() ?? 
                                                              (p['price'] as num?)?.toDouble() ?? 0.0;
                                  final int stock = p['qty'] ?? 0;
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(
                                      name,
                                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
                                    ),
                                    subtitle: Text(
                                      '₱${sellingPrice.toStringAsFixed(2)} | Stock: $stock',
                                      style: GoogleFonts.inter(fontSize: 12),
                                    ),
                                    onTap: () {
                                      setStateDialog(() {
                                        _selectedDialogProduct = p;
                                        _dialogQty = 1;
                                      });
                                    },
                                  );
                                },
                              ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.black, width: 2.0),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (_selectedDialogProduct!['name'] ?? '').toString().toUpperCase(),
                              style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Price: ₱${((_selectedDialogProduct!['price_sale'] as num?)?.toDouble() ?? (_selectedDialogProduct!['price'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)}',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12),
                            ),
                            Text(
                              'Stock: ${_selectedDialogProduct!['qty'] ?? 0}',
                              style: GoogleFonts.inter(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('QTY:', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () {
                                  if (_dialogQty > 1) {
                                    setStateDialog(() {
                                      _dialogQty--;
                                    });
                                  }
                                },
                              ),
                              Text(
                                '$_dialogQty',
                                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () {
                                  final int maxStock = _selectedDialogProduct!['qty'] ?? 0;
                                  if (_dialogQty < maxStock) {
                                    setStateDialog(() {
                                      _dialogQty++;
                                    });
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Cannot exceed available stock!'),
                                        duration: Duration(seconds: 1),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          setStateDialog(() {
                            _selectedDialogProduct = null;
                          });
                        },
                        child: Text(
                          'CHANGE PRODUCT',
                          style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _dialogSearchQuery = '';
                    _selectedDialogProduct = null;
                    Navigator.of(context).pop();
                  },
                  child: Text('CANCEL', style: GoogleFonts.inter(color: Colors.black)),
                ),
                ElevatedButton(
                  onPressed: _selectedDialogProduct == null
                      ? null
                      : () {
                          final double sellingPrice = (_selectedDialogProduct!['price_sale'] as num?)?.toDouble() ?? 
                                                     (_selectedDialogProduct!['price'] as num?)?.toDouble() ?? 0.0;
                          final String name = (_selectedDialogProduct!['name'] ?? '').toString();
                          final barcodes = _selectedDialogProduct!['product_barcode'];
                          String? barcodeStr;
                          if (barcodes is List && barcodes.isNotEmpty) {
                            barcodeStr = barcodes[0]['id']?.toString();
                          } else if (barcodes is Map) {
                            barcodeStr = barcodes['id']?.toString();
                          }

                          setState(() {
                            final existingIndex = _cartItems.indexWhere((item) => 
                              item['product']['id'] == _selectedDialogProduct!['id']);
                            if (existingIndex != -1) {
                              final int availableStock = _selectedDialogProduct!['qty'] ?? 0;
                              final int currentQtyInCart = _cartItems[existingIndex]['qty'] as int;
                              final int combinedQty = currentQtyInCart + _dialogQty;
                              if (combinedQty <= availableStock) {
                                _cartItems[existingIndex]['qty'] = combinedQty;
                              } else {
                                _cartItems[existingIndex]['qty'] = availableStock;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Cart quantity capped to maximum available stock.'),
                                  ),
                                );
                              }
                            } else {
                              _cartItems.add({
                                'name': name.toUpperCase(),
                                'price': sellingPrice,
                                'qty': _dialogQty,
                                'product': _selectedDialogProduct,
                                'barcode': barcodeStr,
                              });
                            }
                          });

                          _dialogSearchQuery = '';
                          _selectedDialogProduct = null;
                          Navigator.of(context).pop();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  ),
                  child: Text('ADD TO CART', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double total = _cartItems.fold(0, (sum, item) => sum + (item['price'] * item['qty']));
    int totalItems = _cartItems.fold(0, (sum, item) => sum + (item['qty'] as int));
    
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: Column(
        children: [
          // Operation Buttons Row (Scan & Add Box)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildOperationButton(
                    label: 'SCAN PRODUCT',
                    icon: Icons.barcode_reader,
                    isPrimary: true,
                    onTap: () async {
                      if (_isLoadingProducts) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please wait, loading products...')),
                        );
                        return;
                      }
                      final Map<String, int>? scanned = await Navigator.push<Map<String, int>>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CheckoutScannerPage(dbProducts: _dbProducts),
                        ),
                      );
                      if (scanned != null && scanned.isNotEmpty) {
                        setState(() {
                          scanned.forEach((barcode, qty) {
                            Map<String, dynamic>? targetProd;
                            for (final p in _dbProducts) {
                              final barcodes = p['product_barcode'];
                              if (barcodes is List) {
                                for (final bc in barcodes) {
                                  if (bc['id'].toString().trim() == barcode.trim()) {
                                    targetProd = p;
                                    break;
                                  }
                                }
                              } else if (barcodes is Map) {
                                if (barcodes['id'].toString().trim() == barcode.trim()) {
                                  targetProd = p;
                                }
                              }
                              if (targetProd != null) break;
                            }

                            if (targetProd != null) {
                              final double sellingPrice = (targetProd!['price_sale'] as num?)?.toDouble() ?? 
                                                         (targetProd!['price'] as num?)?.toDouble() ?? 0.0;
                              final String name = (targetProd!['name'] ?? '').toString();
                              final int availableStock = targetProd!['qty'] ?? 0;

                              final existingIndex = _cartItems.indexWhere((item) => 
                                item['product']['id'] == targetProd!['id']);

                              if (existingIndex != -1) {
                                final int currentQtyInCart = _cartItems[existingIndex]['qty'] as int;
                                final int combinedQty = currentQtyInCart + qty;
                                if (combinedQty <= availableStock) {
                                  _cartItems[existingIndex]['qty'] = combinedQty;
                                } else {
                                  _cartItems[existingIndex]['qty'] = availableStock;
                                }
                              } else {
                                final int clampedQty = qty <= availableStock ? qty : availableStock;
                                if (clampedQty > 0) {
                                  _cartItems.add({
                                    'name': name.toUpperCase(),
                                    'price': sellingPrice,
                                    'qty': clampedQty,
                                    'product': targetProd,
                                    'barcode': barcode,
                                  });
                                }
                              }
                            }
                          });
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _showAddProductDialog,
                  child: Container(
                    height: 56,
                    width: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black, width: 2.0),
                    ),
                    child: const Icon(Icons.add, color: Colors.black, size: 24),
                  ),
                ),
              ],
            ),
          ),

          // Cart Items List
          Expanded(
            child: _cartItems.isEmpty
                ? Center(
                    child: Text(
                      'CART IS EMPTY',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: _cartItems.length,
                    itemBuilder: (context, index) {
                      final item = _cartItems[index];
                      return _buildCartItem(item, index);
                    },
                  ),
          ),

          // Footer Summary
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TOTAL ITEMS: $totalItems',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          Text(
                            'GRAND TOTAL',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '₱${total.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _isSavingCheckout
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.black),
                        )
                      : _buildOperationButton(
                          label: 'COMPLETE SALE',
                          icon: Icons.check_circle_outline,
                          isPrimary: true,
                          onTap: _completeSale,
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'],
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                Text(
                  '₱${(item['price'] * item['qty']).toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          
          // Quantity Controls
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF9F9F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 16),
                  onPressed: () {
                    setState(() {
                      if (item['qty'] > 1) item['qty']--;
                    });
                  },
                ),
                Text(
                  '${item['qty']}',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 16),
                  onPressed: () {
                    final int maxStock = item['product']?['qty'] ?? 9999;
                    if (item['qty'] < maxStock) {
                      setState(() {
                        item['qty']++;
                      });
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Cannot exceed available stock!'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          
          // Delete Button
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBA1A1A).withValues(alpha: 0.2)),
            ),
            child: IconButton(
              icon: const Icon(Icons.delete_outline, color: Color(0xFFBA1A1A), size: 20),
              onPressed: () {
                setState(() {
                  _cartItems.removeAt(index);
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationButton({
    required String label,
    required IconData icon,
    required bool isPrimary,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isPrimary ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isPrimary ? null : Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isPrimary ? Colors.white : Colors.black, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: isPrimary ? Colors.white : Colors.black,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

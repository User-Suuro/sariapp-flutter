import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'product_form.dart';
import 'edit_product.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _products = [];
  bool _isLoading = true;
  String _searchQuery = '';
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final data = await Supabase.instance.client
          .from('products')
          .select('*, product_barcode(id)');
      setState(() {
        _products = data;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading products: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.black,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter by name or barcode
    final filteredProducts = _products.where((product) {
      final name = (product['name'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      final matchesName = name.contains(query);

      bool matchesBarcode = false;
      final barcodes = product['product_barcode'];
      if (barcodes is List) {
        matchesBarcode = barcodes.any((bc) {
          final bcId = (bc['id'] ?? '').toString().toLowerCase();
          return bcId.contains(query);
        });
      } else if (barcodes is Map) {
        final bcId = (barcodes['id'] ?? '').toString().toLowerCase();
        matchesBarcode = bcId.contains(query);
      }

      return matchesName || matchesBarcode;
    }).toList();

    // Sort by stock quantity
    filteredProducts.sort((a, b) {
      final int qtyA = a['qty'] ?? 0;
      final int qtyB = b['qty'] ?? 0;
      return _sortAscending ? qtyA.compareTo(qtyB) : qtyB.compareTo(qtyA);
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: Column(
        children: [
          // Quick Search Section
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'QUICK SEARCH',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade500,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.trim();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search by name or barcode...',
                      hintStyle: GoogleFonts.inter(color: Colors.grey.shade400),
                      border: InputBorder.none,
                      icon: const Icon(Icons.search, color: Colors.black),
                      suffixIcon: IconButton(
                        icon: const Icon(
                          Icons.qr_code_scanner,
                          color: Colors.black,
                        ),
                        onPressed: () {},
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Alignment Info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'INVENTORY ITEMS (${filteredProducts.length})',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _sortAscending = !_sortAscending;
                    });
                  },
                  icon: const Icon(Icons.sort, size: 16, color: Colors.black),
                  label: Text(
                    'SORT BY: ${_sortAscending ? "STOCK LOW" : "STOCK HIGH"}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Product List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.black),
                  )
                : filteredProducts.isEmpty
                ? Center(
                    child: Text(
                      'NO PRODUCTS FOUND',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      return _buildProductItem(
                        context,
                        product: filteredProducts[index],
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final added = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProductForm()),
          );
          if (added == true) {
            _fetchProducts();
          }
        },
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildProductItem(
    BuildContext context, {
    required Map<String, dynamic> product,
  }) {
    final String name = (product['name'] ?? '').toString().toUpperCase();
    final int stock = product['qty'] ?? 0;
    final double sellingPrice =
        (product['price_sale'] as num?)?.toDouble() ??
        (product['price'] as num?)?.toDouble() ??
        0.0;
    final double costPrice = (product['price'] as num?)?.toDouble() ?? 0.0;

    // Use min_stock/alert_at/alertAt if defined, otherwise defaults
    final int alertAt = product['min_stock'] ?? product['alert_at'] ?? product['alertAt'] ?? 10;
    final bool isCritical = stock <= 3;
    final bool isLow = stock <= alertAt && stock > 3;

    Color stockColor = Colors.grey.shade600;
    String stockLabel = '$stock PCS';

    if (isCritical) {
      stockColor = const Color(0xFFBA1A1A);
      stockLabel = '$stock PCS (CRITICAL)';
    } else if (isLow) {
      stockColor = const Color(0xFFBA1A1A).withValues(alpha: 0.7);
      stockLabel = '$stock PCS (LOW)';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCritical
              ? const Color(0xFFBA1A1A).withValues(alpha: 0.2)
              : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      stockLabel,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: stockColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '₱${sellingPrice.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    if (costPrice > 0 && costPrice != sellingPrice) ...[
                      const SizedBox(width: 8),
                      Text(
                        'Cost: ₱${costPrice.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.grey),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProductPage(product: product),
                ),
              );
              _fetchProducts();
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              size: 20,
              color: Colors.grey,
            ),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('DELETE PRODUCT'),
                  content: Text('Are you sure you want to delete $name?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('CANCEL'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('DELETE'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                try {
                  await Supabase.instance.client
                      .from('products')
                      .delete()
                      .eq('id', product['id']);
                  _fetchProducts();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error deleting: $e')),
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

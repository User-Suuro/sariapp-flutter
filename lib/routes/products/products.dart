import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'product_form.dart';

class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
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
                    decoration: InputDecoration(
                      hintText: 'Search by name or barcode...',
                      hintStyle: GoogleFonts.inter(color: Colors.grey.shade400),
                      border: InputBorder.none,
                      icon: const Icon(Icons.search, color: Colors.black),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.qr_code_scanner, color: Colors.black),
                        onPressed: () {},
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Inventory Summary & Sort
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'INVENTORY ITEMS (124)',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.sort, size: 16, color: Colors.black),
                  label: Text(
                    'SORT BY: STOCK LOW',
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
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _buildProductItem(
                  name: 'CANNED SARDINES (LIGO)',
                  stock: 48,
                  price: 24.50,
                  isLow: false,
                ),
                _buildProductItem(
                  name: 'INSTANT NOODLES (LUCKY ME)',
                  stock: 8,
                  price: 12.00,
                  isLow: true,
                ),
                 _buildProductItem(
                  name: 'DETERGENT BAR (TIDE)',
                  stock: 3,
                  price: 15.00,
                  isCritical: true,
                ),
                _buildProductItem(
                  name: 'COOKING OIL (500ML)',
                  stock: 12,
                  price: 45.00,
                  isLow: false,
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () {},
                    child: Text(
                      'LOAD MORE PRODUCTS',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProductForm()),
          );
        },
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildProductItem({
    required String name,
    required int stock,
    required double price,
    bool isLow = false,
    bool isCritical = false,
  }) {
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
        border: Border.all(color: isCritical ? const Color(0xFFBA1A1A).withValues(alpha: 0.2) : Colors.grey.shade200),
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
                      '₱${price.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.grey),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

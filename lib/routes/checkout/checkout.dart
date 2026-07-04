import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  // Mock cart items
  final List<Map<String, dynamic>> _cartItems = [
    {'name': 'LUCKY ME! PANCIT CANTON', 'price': 14.00, 'qty': 3},
    {'name': 'CANNED SARDINES (LIGO)', 'price': 24.50, 'qty': 1},
    {'name': 'DETERGENT BAR (TIDE)', 'price': 15.00, 'qty': 2},
  ];

  @override
  Widget build(BuildContext context) {
    double total = _cartItems.fold(0, (sum, item) => sum + (item['price'] * item['qty']));
    int totalItems = _cartItems.fold(0, (sum, item) => sum + (item['qty'] as int));
    
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: Column(
        children: [
          // Scan Product Button
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: _buildOperationButton(
              label: 'SCAN PRODUCT',
              icon: Icons.barcode_reader,
              isPrimary: true,
            ),
          ),

          // Cart Items List
          Expanded(
            child: ListView.builder(
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
                  _buildOperationButton(
                    label: 'COMPLETE SALE',
                    icon: Icons.check_circle_outline,
                    isPrimary: true,
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
                    setState(() {
                      item['qty']++;
                    });
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
              onPressed: () {},
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
  }) {
    return Container(
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
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../products/product_form.dart';
import '../products/restock_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardPage extends StatefulWidget {
  final Function(int)? onTapTab;
  const DashboardPage({super.key, this.onTapTab});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _isLoading = true;
  String _storeName = "Maria's Variety Store";

  int _totalProducts = 0;
  double _inventoryValue = 0.0;
  double _todaySales = 0.0;
  int _lowStockItems = 0;

  @override
  void initState() {
    super.initState();
    _loadStoreName();
    _fetchDashboardData();
  }

  Future<void> _loadStoreName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString('store_name');
      if (name != null && name.trim().isNotEmpty) {
        setState(() {
          _storeName = name.trim();
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchDashboardData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      await _loadStoreName();
      final supabase = Supabase.instance.client;

      // 1. Fetch products
      final productsData = await supabase.from('products').select('*');
      final products = List<Map<String, dynamic>>.from(productsData);

      _totalProducts = products.length;

      double valueSum = 0.0;
      int lowStockCount = 0;

      for (final p in products) {
        final int qty = (p['qty'] as num?)?.toInt() ?? 0;
        final double costPrice = (p['price'] as num?)?.toDouble() ?? 0.0;
        valueSum += costPrice * qty;

        final int alertAt = (p['min_stock'] as num?)?.toInt() ?? 10;
        if (qty <= alertAt) {
          lowStockCount++;
        }
      }

      _inventoryValue = valueSum;
      _lowStockItems = lowStockCount;

      // 2. Fetch today's sales
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      final salesData = await supabase
          .from('checkout')
          .select('total_sale')
          .gte('created_at', startOfToday.toUtc().toIso8601String());

      double salesSum = 0.0;
      for (final sale in salesData) {
        salesSum += (sale['total_sale'] as num?)?.toDouble() ?? 0.0;
      }
      _todaySales = salesSum;
    } catch (e) {
      debugPrint('Dashboard data fetch error: $e');
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
    return RefreshIndicator(
      onRefresh: _fetchDashboardData,
      color: Colors.black,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting Section
            Text(
              'WELCOME BACK,',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _storeName,
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 32),

            // Stat Cards Grid (2x2)
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                _buildStatCard(
                  title: 'Total Products',
                  value: _isLoading ? '...' : '$_totalProducts',
                  icon: Icons.inventory_2_outlined,
                  backgroundColor: const Color(0xFFEEEEEE),
                  textColor: Colors.black,
                ),
                _buildStatCard(
                  title: 'Inv. Value',
                  value: _isLoading
                      ? '...'
                      : '₱${_inventoryValue.toStringAsFixed(0)}',
                  icon: Icons.account_balance_wallet_outlined,
                  backgroundColor: const Color(0xFFEEEEEE),
                  textColor: Colors.black,
                ),
                _buildStatCard(
                  title: 'Today\'s Sales',
                  value: _isLoading
                      ? '...'
                      : '₱${_todaySales.toStringAsFixed(0)}',
                  icon: Icons.trending_up,
                  backgroundColor: Colors.black,
                  textColor: Colors.white,
                  isHighlighted: true,
                ),
                _buildStatCard(
                  title: 'Low Stock',
                  value: _isLoading ? '...' : '$_lowStockItems Items',
                  icon: Icons.error_outline,
                  backgroundColor: const Color(0xFFEEEEEE),
                  textColor: const Color(0xFFBA1A1A),
                  iconColor: const Color(0xFFBA1A1A),
                  borderColor: const Color(0xFFBA1A1A).withOpacity(0.3),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Store Operations Section
            Text(
              'Store Operations',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            _buildOperationButton(
              label: 'Scan Product',
              icon: Icons.barcode_reader,
              isPrimary: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RestockScannerPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildOperationButton(
                    label: 'Add New Product',
                    icon: Icons.add_circle_outline,
                    isPrimary: false,
                    onTap: () async {
                      final added = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProductForm(),
                        ),
                      );
                      if (added == true) {
                        _fetchDashboardData();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildOperationButton(
                    label: 'Restock Inventory',
                    icon: Icons.history,
                    isPrimary: false,
                    onTap: () {
                      widget.onTapTab?.call(1); // Navigates to Products tab
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Monthly Insight Section
            Text(
              'Monthly Insight',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            _buildInsightCard(tip: 'Keep your best-sellers at eye level.'),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color backgroundColor,
    required Color textColor,
    Color? iconColor,
    Color? borderColor,
    bool isHighlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
        border: borderColor != null
            ? Border.all(color: borderColor, width: 1)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: iconColor ?? textColor, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: textColor.withOpacity(isHighlighted ? 0.7 : 0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOperationButton({
    required String label,
    required IconData icon,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: isPrimary ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isPrimary ? null : Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isPrimary ? Colors.white : Colors.black,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isPrimary ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightCard({required String tip}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.black,
        border: Border.all(color: Colors.black, width: 2.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.lightbulb, color: Colors.yellow, size: 28),
            const SizedBox(height: 12),
            Text(
              'Daily Tip',
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              tip,
              style: GoogleFonts.inter(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

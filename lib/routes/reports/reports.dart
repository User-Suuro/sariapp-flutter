import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  String _selectedPeriod = 'Weekly'; // Default tab
  bool _isLoading = true;

  // Raw Database Results
  List<Map<String, dynamic>> _checkouts = [];
  final Map<String, Map<String, dynamic>> _barcodeToProduct = {};

  // Computed metric variables
  double _totalRevenue = 0.0;
  double _totalProfit = 0.0;
  double _roiPercent = 0.0;
  int _ordersCount = 0;
  double _avgOrder = 0.0;

  // Chart data
  List<double> _chartValues = List.filled(7, 0.0);
  List<String> _chartLabels = [];

  // Top products
  List<Map<String, dynamic>> _topProducts = [];

  @override
  void initState() {
    super.initState();
    _fetchReportData();
  }

  Future<void> _fetchReportData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final supabase = Supabase.instance.client;

      // 1. Fetch metadata products to lookup barcode to cost price mapping
      final productsData = await supabase.from('products').select('*, product_barcode(id)');
      _barcodeToProduct.clear();
      for (final p in productsData) {
        final barcodes = p['product_barcode'];
        if (barcodes is List) {
          for (final b in barcodes) {
            _barcodeToProduct[b['id'].toString()] = p;
          }
        } else if (barcodes is Map) {
          _barcodeToProduct[barcodes['id'].toString()] = p;
        }
      }

      // 2. Fetch past 30 days checkouts with nested sales
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final startOfRange = DateTime(thirtyDaysAgo.year, thirtyDaysAgo.month, thirtyDaysAgo.day);
      final checkoutData = await supabase
          .from('checkout')
          .select('*, sale(*)')
          .gte('created_at', startOfRange.toUtc().toIso8601String());

      _checkouts = List<Map<String, dynamic>>.from(checkoutData);

      _calculateMetrics();
    } catch (e) {
      debugPrint('Error loading reports: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _calculateMetrics() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    
    DateTime filterStartDate;
    if (_selectedPeriod == 'Today') {
      filterStartDate = todayStart;
    } else if (_selectedPeriod == 'Weekly') {
      filterStartDate = todayStart.subtract(const Duration(days: 6));
    } else {
      filterStartDate = todayStart.subtract(const Duration(days: 29));
    }

    // Filter checkouts in memory
    final periodCheckouts = _checkouts.where((c) {
      final String? rawDate = c['created_at'];
      if (rawDate == null) return false;
      final cDate = DateTime.parse(rawDate).toLocal();
      return cDate.isAfter(filterStartDate) || cDate.isAtSameMomentAs(filterStartDate);
    }).toList();

    _ordersCount = periodCheckouts.length;

    double revenueSum = 0.0;
    double cogsSum = 0.0;

    // Top selling calculations
    final Map<String, int> productQtySold = {};
    final Map<String, double> productRevSold = {};

    for (final c in periodCheckouts) {
      revenueSum += (c['total_sale'] as num?)?.toDouble() ?? 0.0;

      final sales = c['sale'];
      if (sales is List) {
        for (final s in sales) {
          final int qty = (s['qty_item'] as num?)?.toInt() ?? 0;
          final double priceSale = (s['total_price'] as num?)?.toDouble() ?? 0.0;
          final String barcode = (s['product_barcode'] ?? '').toString();

          // Lookup cost price
          final prod = _barcodeToProduct[barcode];
          final double costPrice = (prod?['price'] as num?)?.toDouble() ?? 0.0;
          cogsSum += costPrice * qty;

          if (barcode.isNotEmpty) {
            productQtySold[barcode] = (productQtySold[barcode] ?? 0) + qty;
            productRevSold[barcode] = (productRevSold[barcode] ?? 0.0) + priceSale;
          }
        }
      }
    }

    _totalRevenue = revenueSum;
    _totalProfit = _totalRevenue - cogsSum;
    _roiPercent = cogsSum > 0 ? (_totalProfit / cogsSum) * 100 : 0.0;
    _avgOrder = _ordersCount > 0 ? _totalRevenue / _ordersCount : 0.0;

    // Build Top Products ranking list
    final List<Map<String, dynamic>> productRanking = [];
    productQtySold.forEach((barcode, qty) {
      final prod = _barcodeToProduct[barcode];
      final String name = prod != null ? (prod['name'] ?? '').toString() : 'BARCODE:$barcode';
      final double totalValue = productRevSold[barcode] ?? 0.0;
      productRanking.add({
        'name': name,
        'qty': qty,
        'value': totalValue,
      });
    });
    productRanking.sort((a, b) => (b['qty'] as int).compareTo(a['qty'] as int));
    _topProducts = productRanking.take(3).toList();

    // Prepare chart bars based on selected period
    _chartValues = List.filled(7, 0.0);
    _chartLabels = [];

    if (_selectedPeriod == 'Today') {
      _chartLabels = ['8A', '10A', '12P', '2P', '4P', '6P', '8P'];
      final List<int> hours = [8, 10, 12, 14, 16, 18, 20];
      for (final c in periodCheckouts) {
        final date = DateTime.parse(c['created_at']).toLocal();
        if (date.year == now.year && date.month == now.month && date.day == now.day) {
          final hour = date.hour;
          final double val = (c['total_sale'] as num?)?.toDouble() ?? 0.0;
          int targetIdx = 0;
          int minDiff = 999;
          for (int i = 0; i < hours.length; i++) {
            final diff = (hour - hours[i]).abs();
            if (diff < minDiff) {
              minDiff = diff;
              targetIdx = i;
            }
          }
          _chartValues[targetIdx] += val;
        }
      }
    } else if (_selectedPeriod == 'Weekly') {
      final List<DateTime> last7Days = [];
      for (int i = 6; i >= 0; i--) {
        last7Days.add(todayStart.subtract(Duration(days: i)));
      }

      final List<String> weekdayNames = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
      for (int i = 0; i < 7; i++) {
        final d = last7Days[i];
        _chartLabels.add(weekdayNames[d.weekday - 1]);

        double daySales = 0.0;
        for (final c in periodCheckouts) {
          final cDate = DateTime.parse(c['created_at']).toLocal();
          if (cDate.year == d.year && cDate.month == d.month && cDate.day == d.day) {
            daySales += (c['total_sale'] as num?)?.toDouble() ?? 0.0;
          }
        }
        _chartValues[i] = daySales;
      }
    } else {
      _chartLabels = ['D4', 'D8', 'D12', 'D16', 'D20', 'D24', 'D28'];
      for (final c in periodCheckouts) {
        final cDate = DateTime.parse(c['created_at']).toLocal();
        final daysAgo = now.difference(cDate).inDays;
        final int bucket = (daysAgo / 4).floor();
        if (bucket >= 0 && bucket < 7) {
          _chartValues[6 - bucket] += (c['total_sale'] as num?)?.toDouble() ?? 0.0;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F9),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'SALES REPORTS',
          style: GoogleFonts.inter(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black, size: 20),
            onPressed: _fetchReportData,
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.black, size: 20),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPeriodSelector(),
                  const SizedBox(height: 24),
                  
                  // Primary Metric
                  _buildMainMetricCard(
                    'Total Revenue',
                    '₱${_totalRevenue.toStringAsFixed(2)}',
                    'Net Profit: ₱${_totalProfit.toStringAsFixed(2)} (ROI: ${_roiPercent.toStringAsFixed(1)}%)',
                  ),
                  const SizedBox(height: 16),
                  
                  // Metric Grid
                  Row(
                    children: [
                      Expanded(child: _buildSmallMetricCard('Orders', '$_ordersCount', Icons.shopping_bag_outlined)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildSmallMetricCard('Avg Order', '₱${_avgOrder.toStringAsFixed(2)}', Icons.analytics_outlined)),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  Text(
                    'Sales Performance',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Chart
                  _buildChartPlaceholder(),
                  
                  const SizedBox(height: 32),
                  _buildSectionHeader('Top Selling Products'),
                  const SizedBox(height: 12),
                  if (_topProducts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'NO ITEMS SOLD YET',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  else
                    ..._topProducts.map((p) => _buildProductItem(
                          p['name'],
                          '₱${(p['value'] as double).toStringAsFixed(2)}',
                          '${p['qty']} sold',
                        )),
                ],
              ),
            ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildPeriodTab('Today', _selectedPeriod == 'Today'),
          _buildPeriodTab('Weekly', _selectedPeriod == 'Weekly'),
          _buildPeriodTab('Monthly', _selectedPeriod == 'Monthly'),
        ],
      ),
    );
  }

  Widget _buildPeriodTab(String label, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPeriod = label;
            _calculateMetrics();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.black : Colors.grey.shade600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainMetricCard(String label, String value, String trend) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              trend,
              style: GoogleFonts.inter(
                color: const Color(0xFF4CAF50),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallMetricCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey.shade400, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartPlaceholder() {
    final double maxVal = _chartValues.fold(0.0, (m, element) => element > m ? element : m);

    return Container(
      height: 200,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (index) {
          final double val = _chartValues[index];
          final double factor = maxVal > 0 ? val / maxVal : 0.0;
          final double heightFactor = factor.clamp(0.0, 1.0);

          return Expanded(
            child: Tooltip(
              message: '₱${val.toStringAsFixed(2)}',
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: 24,
                        height: 120 * heightFactor,
                        decoration: BoxDecoration(
                          color: heightFactor > 0.8 ? Colors.black : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _chartLabels.isNotEmpty && index < _chartLabels.length ? _chartLabels[index] : '',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: Colors.grey.shade500,
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _buildProductItem(String name, String value, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              color: Colors.grey.shade400,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

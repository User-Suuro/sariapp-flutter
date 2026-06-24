import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

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
            icon: const Icon(Icons.share_outlined, color: Colors.black, size: 20),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPeriodSelector(),
            const SizedBox(height: 24),
            
            // Primary Metric
            _buildMainMetricCard('Total Revenue', '₱142,500.00', '+12.5% from last month'),
            const SizedBox(height: 16),
            
            // Metric Grid
            Row(
              children: [
                Expanded(child: _buildSmallMetricCard('Orders', '1,240', Icons.shopping_bag_outlined)),
                const SizedBox(width: 16),
                Expanded(child: _buildSmallMetricCard('Avg Order', '₱115.00', Icons.analytics_outlined)),
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
            
            // Professional Chart Placeholder
            _buildChartPlaceholder(),
            
            const SizedBox(height: 32),
            _buildSectionHeader('Top Selling Products'),
            const SizedBox(height: 12),
            _buildProductItem('Kopiko Lucky Day', '₱2,400.00', '120 sold'),
            _buildProductItem('Bear Brand 320g', '₱1,850.00', '85 sold'),
            _buildProductItem('Skyflakes 10s', '₱940.00', '64 sold'),
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
          _buildPeriodTab('Today', false),
          _buildPeriodTab('Weekly', true),
          _buildPeriodTab('Monthly', false),
        ],
      ),
    );
  }

  Widget _buildPeriodTab(String label, bool isSelected) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))] : null,
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
            style: GoogleFonts.inter(color: Colors.white.withOpacity(0.6), fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Text(
              trend,
              style: GoogleFonts.inter(color: const Color(0xFF4CAF50), fontSize: 12, fontWeight: FontWeight.w600),
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
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildChartPlaceholder() {
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
          final heights = [0.4, 0.7, 0.5, 0.9, 0.6, 0.8, 0.4];
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 24,
                height: 120 * heights[index],
                decoration: BoxDecoration(
                  color: index == 3 ? Colors.black : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                ['M', 'T', 'W', 'T', 'F', 'S', 'S'][index],
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey),
              ),
            ],
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
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.inventory_2_outlined, color: Colors.grey.shade400, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black)),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Text(value, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.black)),
        ],
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
            "Maria's Variety Store",
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
                value: '142',
                icon: Icons.inventory_2_outlined,
                backgroundColor: const Color(0xFFEEEEEE),
                textColor: Colors.black,
              ),
              _buildStatCard(
                title: 'Inv. Value',
                value: '₱24,500',
                icon: Icons.account_balance_wallet_outlined,
                backgroundColor: const Color(0xFFEEEEEE),
                textColor: Colors.black,
              ),
              _buildStatCard(
                title: 'Today\'s Sales',
                value: '₱3,240',
                icon: Icons.trending_up,
                backgroundColor: Colors.black,
                textColor: Colors.white,
                isHighlighted: true,
              ),
              _buildStatCard(
                title: 'Low Stock',
                value: '5 Items',
                icon: Icons.error_outline,
                backgroundColor: const Color(0xFFEEEEEE),
                textColor: const Color(0xFFBA1A1A),
                iconColor: const Color(0xFFBA1A1A),
                borderColor: const Color(0xFFBA1A1A).withValues(alpha: 0.3),
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
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildOperationButton(
                  label: 'Add New Product',
                  icon: Icons.add_circle_outline,
                  isPrimary: false,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildOperationButton(
                  label: 'Restock Inventory',
                  icon: Icons.history,
                  isPrimary: false,
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
          _buildInsightCard(
            tip: 'Keep your best-sellers at eye level.',
          ),
          const SizedBox(height: 24),
        ],
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
        border: borderColor != null ? Border.all(color: borderColor, width: 1) : null,
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
                  color: textColor.withValues(alpha: isHighlighted ? 0.7 : 0.6),
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
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: isPrimary ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isPrimary ? null : Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isPrimary ? Colors.white : Colors.black, size: 20),
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
    );
  }

  Widget _buildInsightCard({required String tip}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.grey.shade200,
        image: const DecorationImage(
          image: NetworkImage('https://images.unsplash.com/photo-1534452285072-8e90f4bd54ed?q=80&w=600'), // Placeholder for store shelf
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black54, BlendMode.darken),
        ),
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

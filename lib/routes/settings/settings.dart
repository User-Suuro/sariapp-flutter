import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F9),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'SETTINGS',
          style: GoogleFonts.inter(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserCard(),
            const SizedBox(height: 32),
            
            _buildSectionHeader('Store Configuration'),
            _buildSettingsGroup([
              _buildSettingItem(Icons.storefront_outlined, 'Store Profile', 'Business name, address, tax ID'),
              _buildSettingItem(Icons.inventory_2_outlined, 'Inventory Settings', 'Thresholds, categories, units'),
              _buildSettingItem(Icons.receipt_long_outlined, 'Tax & Receipts', 'VAT, service fee, receipt footer'),
            ]),
            
            const SizedBox(height: 24),
            _buildSectionHeader('Preferences'),
            _buildSettingsGroup([
              _buildSettingItem(Icons.notifications_none_outlined, 'Notifications', 'Sales alerts, stock warnings'),
              _buildSettingItem(Icons.language_outlined, 'Language & Region', 'English, PHP (₱)'),
              _buildSettingItem(Icons.dark_mode_outlined, 'Appearance', 'Light Mode'),
            ]),
            
            const SizedBox(height: 24),
            _buildSectionHeader('Support & Legal'),
            _buildSettingsGroup([
              _buildSettingItem(Icons.help_outline_rounded, 'Help Center', 'Guides, FAQs, contact support'),
              _buildSettingItem(Icons.info_outline_rounded, 'Terms & Privacy', 'Our legal policies'),
            ]),
            
            const SizedBox(height: 48),
            _buildBranding(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_outline, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mark\'s Sari-Sari',
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                ),
                Text(
                  'Premium Subscription',
                  style: GoogleFonts.inter(color: Colors.white.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white, size: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Colors.grey.shade500,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingItem(IconData icon, String title, String subtitle) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: Colors.black87, size: 22),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500),
      ),
      trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
      onTap: () {},
    );
  }

  Widget _buildBranding() {
    return Center(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.auto_awesome_outlined, size: 16, color: Colors.black),
              const SizedBox(width: 8),
              Text(
                'SariApp',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Version 2.4.0 (Stable Build)',
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () {},
            child: Text(
              'Sign Out',
              style: GoogleFonts.inter(color: const Color(0xFFBA1A1A), fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}


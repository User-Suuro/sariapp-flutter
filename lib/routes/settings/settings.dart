import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  final VoidCallback onBack;

  const SettingsPage({super.key, required this.onBack});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _storeNameController =
      TextEditingController(text: "Aling Nena's Sari-Sari");
  final TextEditingController _addressController = TextEditingController(
      text: "123 Balagtas St., Barangay 405, Sampaloc, Manila");

  bool _lowStockAlerts = true;
  bool _dailySalesSummary = false;
  int _globalReorderPoint = 10;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _storeNameController.text =
            prefs.getString('store_name') ?? "Aling Nena's Sari-Sari";
        _addressController.text =
            prefs.getString('store_address') ?? "123 Balagtas St., Barangay 405, Sampaloc, Manila";
        _lowStockAlerts = prefs.getBool('low_stock_alerts') ?? true;
        _dailySalesSummary = prefs.getBool('daily_sales_summary') ?? false;
        _globalReorderPoint = prefs.getInt('global_reorder_point') ?? 10;
      });
    } catch (_) {}
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('store_name', _storeNameController.text.trim());
      await prefs.setString('store_address', _addressController.text.trim());
      await prefs.setBool('low_stock_alerts', _lowStockAlerts);
      await prefs.setBool('daily_sales_summary', _dailySalesSummary);
      await prefs.setInt('global_reorder_point', _globalReorderPoint);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.black,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56.0),
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.black,
                width: 2.0,
              ),
            ),
          ),
          child: AppBar(
            backgroundColor: const Color(0xFFF9F9F9),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: widget.onBack,
            ),
            title: Text(
              'Settings',
              style: GoogleFonts.inter(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.save, color: Colors.black),
                onPressed: _saveSettings,
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 672),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Store Profile'),
                _buildStoreProfileCard(),
                const SizedBox(height: 32),
                _buildSectionHeader('Notification Settings'),
                _buildNotificationSettingsCard(),
                const SizedBox(height: 32),
                _buildSectionHeader('Inventory Thresholds'),
                _buildInventoryThresholdsCard(),
                const SizedBox(height: 32),
                _buildSectionHeader('Data Management'),
                _buildDataManagementCard(),
                const SizedBox(height: 32),
                _buildSectionHeader('Help & Support'),
                _buildHelpSupportCard(),
                const SizedBox(height: 32),
                _buildAboutCard(),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF4C4546),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildStoreProfileCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 2.0),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'STORE NAME',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _storeNameController,
            style: GoogleFonts.inter(fontSize: 16, color: Colors.black),
            decoration: const InputDecoration(
              hintText: 'Enter store name',
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.black, width: 2.0),
                borderRadius: BorderRadius.zero,
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.black, width: 2.0),
                borderRadius: BorderRadius.zero,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'ADDRESS',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _addressController,
            maxLines: 2,
            minLines: 2,
            style: GoogleFonts.inter(fontSize: 16, color: Colors.black),
            decoration: const InputDecoration(
              hintText: 'Enter store address',
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.black, width: 2.0),
                borderRadius: BorderRadius.zero,
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.black, width: 2.0),
                borderRadius: BorderRadius.zero,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _saveSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              child: Text(
                'UPDATE PROFILE',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrutalistToggle({required bool value, required ValueChanged<bool> onChanged}) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        width: 48,
        height: 24,
        decoration: BoxDecoration(
          color: value ? Colors.black : Colors.white,
          border: Border.all(color: Colors.black, width: 2.0),
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 150),
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 16,
                height: 16,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                color: value ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSettingsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 2.0),
      ),
      child: Column(
        children: [
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Low stock alerts',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                ),
                _buildBrutalistToggle(
                  value: _lowStockAlerts,
                  onChanged: (val) {
                    setState(() {
                      _lowStockAlerts = val;
                    });
                  },
                ),
              ],
            ),
          ),
          Container(height: 2, color: Colors.black),
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daily Sales Summary',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                ),
                _buildBrutalistToggle(
                  value: _dailySalesSummary,
                  onChanged: (val) {
                    setState(() {
                      _dailySalesSummary = val;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryThresholdsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 2.0),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Global Reorder Point',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 2.0),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (_globalReorderPoint > 0) {
                          setState(() {
                            _globalReorderPoint--;
                          });
                        }
                      },
                      child: Container(
                        width: 48,
                        height: 40,
                        color: const Color(0xFFEEEEEE),
                        alignment: Alignment.center,
                        child: const Text(
                          '-',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    Container(width: 2, height: 40, color: Colors.black),
                    Container(
                      width: 56,
                      height: 40,
                      alignment: Alignment.center,
                      child: Text(
                        '$_globalReorderPoint',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Container(width: 2, height: 40, color: Colors.black),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _globalReorderPoint++;
                        });
                      },
                      child: Container(
                        width: 48,
                        height: 40,
                        color: const Color(0xFFEEEEEE),
                        alignment: Alignment.center,
                        child: const Text(
                          '+',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'You will be notified when items reach this quantity.',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              fontStyle: FontStyle.italic,
              color: const Color(0xFF4C4546),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataManagementCard() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: Colors.white,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              title: Text(
                'CONFIRM CLEAR',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.black),
              ),
              content: Text(
                'Are you sure you want to clear all history? This action is irreversible.',
                style: GoogleFonts.inter(color: Colors.black),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'CANCEL',
                    style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('All history cleared.'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Color(0xFFBA1A1A),
                      ),
                    );
                  },
                  child: Text(
                    'CLEAR',
                    style: GoogleFonts.inter(color: const Color(0xFFBA1A1A), fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFBA1A1A), width: 2.0),
          foregroundColor: const Color(0xFFBA1A1A),
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
        ),
        icon: const Icon(Icons.delete_forever, color: Color(0xFFBA1A1A)),
        label: Text(
          'CLEAR ALL HISTORY',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildHelpSupportCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 2.0),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.help_outline, color: Colors.black, size: 24),
            title: Text(
              'User Guide',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.black),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Opening User Guide...'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Colors.black,
                ),
              );
            },
          ),
          Container(height: 2, color: Colors.black),
          ListTile(
            leading: const Icon(Icons.support_agent, color: Colors.black, size: 24),
            title: Text(
              'Contact Support',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.black),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Connecting to Support...'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Colors.black,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFDCDDDD),
        border: Border.all(color: Colors.black, width: 2.0),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'SARIAPP',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.0,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Version 2.4.0 (Stable Build)',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'The architect of your small business growth.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              fontStyle: FontStyle.italic,
              color: const Color(0xFF4C4546),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.terminal, color: Color(0xFF7E7576), size: 24),
              SizedBox(width: 32),
              Icon(Icons.architecture, color: Color(0xFF7E7576), size: 24),
              SizedBox(width: 32),
              Icon(Icons.inventory_2_outlined, color: Color(0xFF7E7576), size: 24),
            ],
          ),
        ],
      ),
    );
  }
}

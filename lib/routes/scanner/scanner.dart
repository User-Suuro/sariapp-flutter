import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0, end: 280).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'SCAN BARCODE',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background simulation for camera view
          Container(
            width: double.infinity,
            height: double.infinity,
            color: const Color(0xFF1A1A1A),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    // The scanning frame
                    Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    // Animated scanning line
                    AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        return Positioned(
                          top: _animation.value,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 2,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.0),
                                  Colors.white,
                                  Colors.white.withOpacity(0.0),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    // Corner accents
                    _buildCorner(0, 0, top: true, left: true),
                    _buildCorner(280, 0, top: true, right: true),
                    _buildCorner(0, 280, bottom: true, left: true),
                    _buildCorner(280, 280, bottom: true, right: true),
                  ],
                ),
                const SizedBox(height: 48),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Place the barcode within the frame to automatically scan and update inventory.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Bottom controls
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildActionButton(Icons.flash_off_rounded, 'Flash'),
                const SizedBox(width: 40),
                _buildActionButton(Icons.keyboard_outlined, 'Enter Code'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorner(double x, double y, {bool top = false, bool bottom = false, bool left = false, bool right = false}) {
    return Positioned(
      top: top ? 0 : null,
      bottom: bottom ? 0 : null,
      left: left ? 0 : null,
      right: right ? 0 : null,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          border: Border(
            top: top ? const BorderSide(color: Colors.white, width: 4) : BorderSide.none,
            bottom: bottom ? const BorderSide(color: Colors.white, width: 4) : BorderSide.none,
            left: left ? const BorderSide(color: Colors.white, width: 4) : BorderSide.none,
            right: right ? const BorderSide(color: Colors.white, width: 4) : BorderSide.none,
          ),
          borderRadius: BorderRadius.only(
            topLeft: top && left ? const Radius.circular(20) : Radius.zero,
            topRight: top && right ? const Radius.circular(20) : Radius.zero,
            bottomLeft: bottom && left ? const Radius.circular(20) : Radius.zero,
            bottomRight: bottom && right ? const Radius.circular(20) : Radius.zero,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}


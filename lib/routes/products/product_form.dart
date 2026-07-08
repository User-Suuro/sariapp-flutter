import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sariapp/utils/validator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductForm extends StatefulWidget {
  const ProductForm({super.key});

  @override
  State<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {
  final _formKey = GlobalKey<FormState>();

  final _barcodeController = TextEditingController();
  final _nameController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();  
  final _alertAtController = TextEditingController(text: '10');

  int _initialStock = 0;
  String _selectedCategory = 'CANNED GOODS';
  bool _isLoading = false;

  @override
  void dispose() {
    _barcodeController.dispose();
    _nameController.dispose();
    _costPriceController.dispose();
    _sellingPriceController.dispose();
    _alertAtController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration({
    required String hintText,
    Widget? prefix,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefix: prefix,
      hintStyle: GoogleFonts.inter(
        color: Colors.grey.shade400,
        fontSize: 14,
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey.shade300, width: 2.0),
        borderRadius: BorderRadius.zero,
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.black, width: 2.0),
        borderRadius: BorderRadius.zero,
      ),
      errorBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFFBA1A1A), width: 2.0),
        borderRadius: BorderRadius.zero,
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFFBA1A1A), width: 2.0),
        borderRadius: BorderRadius.zero,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      errorStyle: GoogleFonts.inter(
        color: const Color(0xFFBA1A1A),
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Colors.black,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildQuantitySelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 2.0),
      ),
      height: 56,
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (_initialStock > 0) {
                setState(() {
                  _initialStock--;
                });
              }
            },
            child: Container(
              width: 48,
              height: double.infinity,
              color: const Color(0xFFEEEEEE),
              alignment: Alignment.center,
              child: const Icon(Icons.remove, color: Colors.black),
            ),
          ),
          Container(width: 2, color: Colors.black),
          Expanded(
            child: Center(
              child: Text(
                '$_initialStock',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          Container(width: 2, color: Colors.black),
          GestureDetector(
            onTap: () {
              setState(() {
                _initialStock++;
              });
            },
            child: Container(
              width: 48,
              height: double.infinity,
              color: const Color(0xFFEEEEEE),
              alignment: Alignment.center,
              child: const Icon(Icons.add, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    final categories = ['CANNED GOODS', 'BEVERAGES', 'SNACKS', 'DAIRY'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Category'),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...categories.map((cat) {
              final isSelected = _selectedCategory == cat;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategory = cat;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.black : Colors.white,
                    border: Border.all(color: Colors.black, width: 2.0),
                  ),
                  child: Text(
                    cat,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              );
            }),
            GestureDetector(
              onTap: () {
                // Add new category
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Category creation helper coming soon!'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.black,
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black, width: 2.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add, size: 16, color: Colors.black),
                    const SizedBox(width: 4),
                    Text(
                      'NEW',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        )
      ],
    );
  }

  String? _validatePrice(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final number = double.tryParse(value);
    if (number == null) {
      return '$fieldName must be a valid number';
    }
    if (number < 0) {
      return '$fieldName cannot be negative';
    }
    return null;
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final name = _nameController.text.trim();
      final qty = _initialStock;
      final costPrice = double.tryParse(_costPriceController.text) ?? 0.0;
      final sellingPrice = double.tryParse(_sellingPriceController.text) ?? 0.0;
      final category = _selectedCategory;
      final alertAt = int.tryParse(_alertAtController.text) ?? 10;

      // Insert product and query returned id
      final response = await Supabase.instance.client.from('products').insert({
        'name': name,
        'desc': 'No description',
        'qty': qty,
        'price': costPrice,
        'price_sale': sellingPrice,
        'category': category,
        'min_stock': alertAt,
      }).select('id').single();

      final insertedId = response['id'];

      final barcodeStr = _barcodeController.text.trim();
      if (barcodeStr.isNotEmpty) {
        await Supabase.instance.client.from('product_barcode').insert({
          'id': barcodeStr,
          'product_id': insertedId,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product saved successfully'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.black,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving product: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
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
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              'ADD PRODUCT',
              style: GoogleFonts.inter(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.help_outline, color: Colors.black),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Enter barcode and details to add a new product.'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Colors.black,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 672),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Barcode scanner helper starting...'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: Colors.black,
                          ),
                        );
                      },
                      icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                      label: Text(
                        'SCAN BARCODE',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 32),
                      child: Text(
                        'Use camera to identify product quickly',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF5D5F5F),
                        ),
                      ),
                    ),
                  ),
                  _buildFieldLabel('Barcode Number'),
                  TextFormField(
                    controller: _barcodeController,
                    style: GoogleFonts.inter(fontSize: 16, color: Colors.black),
                    decoration: _inputDecoration(hintText: '000000000000'),
                  ),
                  const SizedBox(height: 24),
                  _buildFieldLabel('Product Name'),
                  TextFormField(
                    controller: _nameController,
                    style: GoogleFonts.inter(fontSize: 16, color: Colors.black),
                    decoration: _inputDecoration(hintText: 'e.g. Instant Noodles (Spicy)'),
                    validator: Validators.compose([
                      Validators.required('Product Name'),
                      Validators.minLength(3),
                    ]),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel('Cost Price'),
                            TextFormField(
                              controller: _costPriceController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: GoogleFonts.inter(fontSize: 16, color: Colors.black),
                              decoration: _inputDecoration(
                                hintText: '0.00',
                                prefix: Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Text(
                                    '₱',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              validator: (val) => _validatePrice(val, 'Cost Price'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel('Selling Price'),
                            TextFormField(
                              controller: _sellingPriceController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: GoogleFonts.inter(fontSize: 16, color: Colors.black),
                              decoration: _inputDecoration(
                                hintText: '0.00',
                                prefix: Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Text(
                                    '₱',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              validator: (val) => _validatePrice(val, 'Selling Price'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel('Initial Stock'),
                            _buildQuantitySelector(),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel('Alert At'),
                            TextFormField(
                              controller: _alertAtController,
                              keyboardType: TextInputType.number,
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                              textAlign: TextAlign.center,
                              decoration: _inputDecoration(hintText: '10'),
                              validator: Validators.compose([
                                Validators.required('Alert At'),
                                Validators.nonNegativeInteger(),
                              ]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildCategoryChips(),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF9F9F9),
          border: Border(
            top: BorderSide(color: Colors.black, width: 2.0),
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveProduct,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              disabledForegroundColor: Colors.grey.shade500,
              elevation: 0,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'SAVE PRODUCT',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.save, color: Colors.white),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}


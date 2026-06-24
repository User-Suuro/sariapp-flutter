import 'package:flutter/material.dart';
import 'package:sariapp/utils/validator.dart';

class ProductForm extends StatefulWidget {
  const ProductForm({super.key});

  @override
  State<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _qtyController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      prefixIcon: Icon(icon),
    );
  }

  void _saveProduct() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final product = {
      'name': _nameController.text.trim(),
      'desc': _descController.text.trim(),
      'qty': int.parse(_qtyController.text),
    };

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Product saved successfully')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Product')),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Product Information',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),

                        const SizedBox(height: 24),

                        TextFormField(
                          controller: _nameController,
                          decoration: _inputDecoration(
                            label: 'Product Name',
                            icon: Icons.inventory_2,
                          ),
                          validator: Validators.compose([
                            Validators.required('Product Name'),
                            Validators.minLength(3),
                          ]),
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _descController,
                          maxLines: 4,
                          decoration: _inputDecoration(
                            label: 'Description',
                            icon: Icons.description,
                          ).copyWith(alignLabelWithHint: true),
                          validator: Validators.compose([
                            Validators.minLength(3),
                          ]),
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _qtyController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration(
                            label: 'Initial Quantity',
                            icon: Icons.numbers,
                          ),
                          validator: Validators.compose([
                            Validators.required('Quantity'),
                            Validators.nonNegativeInteger(),
                          ]),
                        ),

                        const SizedBox(height: 24),

                        FilledButton.icon(
                          onPressed: _saveProduct,
                          icon: const Icon(Icons.save),
                          label: const Text('Save Product'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

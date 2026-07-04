import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sariapp/utils/validator.dart';
import 'package:image_picker/image_picker.dart';

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

  final _imagePicker = ImagePicker();
  File? _selectedImage;
  String? _imagePath;

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
      'image': _imagePath,
    };

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Product saved successfully')));
  }

  Future<void> _pickImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image == null) return;

    setState(() {
      _selectedImage = File(image.path);
      _imagePath = image.path;
    });

    _formKey.currentState?.validate();
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

                        const SizedBox(height: 16),

                        // Image Pickers
                        FormField<String>(
                          validator: Validators.compose([
                            Validators.required('Product Image'),
                          ]),
                          initialValue: _imagePath,
                          builder: (field) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                InkWell(
                                  onTap: () async {
                                    await _pickImage();
                                    field.didChange(_imagePath);
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    height: 180,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: field.hasError
                                            ? Colors.red
                                            : Colors.grey,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: _selectedImage == null
                                        ? const Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.add_a_photo, size: 48),
                                              SizedBox(height: 8),
                                              Text(
                                                "Tap to select product image",
                                              ),
                                            ],
                                          )
                                        : ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Image.file(
                                              _selectedImage!,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                  ),
                                ),
                                if (field.hasError)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: 8,
                                      left: 12,
                                    ),
                                    child: Text(
                                      field.errorText!,
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
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

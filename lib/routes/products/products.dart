import 'package:flutter/material.dart';
import 'product_form.dart';

class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Center(child: Text('Products Page')),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProductForm()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

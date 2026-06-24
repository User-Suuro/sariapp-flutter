import 'package:flutter/material.dart';

import 'dashboard/dashboard.dart';
import 'products/products.dart';
import 'checkout/checkout.dart';
import 'settings/settings.dart';

class Root extends StatelessWidget {
  const Root({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sari App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyRootPage(title: 'Sari App'),
    );
  }
}

class MyRootPage extends StatefulWidget {
  const MyRootPage({super.key, required this.title});

  final String title;

  @override
  State<MyRootPage> createState() => _MyRootPageState();
}

class _MyRootPageState extends State<MyRootPage> {
  int _selectedIndex = 0;

  // Updates the UI when a bottom navigation item is tapped
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = <Widget>[
      const DashboardPage(),
      const ProductsPage(),
      const CheckoutPage(),
      const SettingsPage(),
    ];

    final titles = ['Dashboard', 'Products', 'Checkout', 'Settings'];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(titles[_selectedIndex]),
      ),

      body: pages[_selectedIndex],

      //BottomNavigationBar
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.shelves), label: 'Products'),
          BottomNavigationBarItem(
            icon: Icon(Icons.barcode_reader),
            label: 'Checkout',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

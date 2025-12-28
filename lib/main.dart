import 'package:flutter/material.dart';
import 'package:sales_buddy/db/database_helper.dart';

void main() {
  runApp(const MaterialApp(home: TestDbScreen()));
}

class TestDbScreen extends StatefulWidget {
  const TestDbScreen({super.key});

  @override
  State<TestDbScreen> createState() => _TestDbScreenState();
}

class _TestDbScreenState extends State<TestDbScreen> {
  String status = "බලාගෙන ඉන්නවා...";

  void testAddProduct() async {
    Map<String, dynamic> row = {
      'name': 'Munchee Cream Cracker',
      'buying_price': 100.0,
      'selling_price': 120.0,
      'stock': 50
    };

    final id = await DatabaseHelper.instance.addProduct(row);
    setState(() {
      status = "බඩුවක් ඇඩ් උනා! ID එක: $id";
    });
    print('Inserted row id: $id');
  }

  void testReadProducts() async {
    final allRows = await DatabaseHelper.instance.getAllProducts();
    setState(() {
      status = "ඩේටාබේස් එකේ තියෙන බඩු:\n$allRows";
    });
    print('Query all rows:');
    for (final row in allRows) {
      print(row);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Database Test")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                status,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: testAddProduct,
                child: const Text("1. Test Add Product (බඩු දාන්න)"),
              ),
              ElevatedButton(
                onPressed: testReadProducts,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text("2. Test Read Data (බඩු බලන්න)"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
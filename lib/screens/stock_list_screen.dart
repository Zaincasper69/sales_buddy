import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import 'add_product_screen.dart';

class StockListScreen extends StatefulWidget {
  const StockListScreen({super.key});

  @override
  State<StockListScreen> createState() => _StockListScreenState();
}

class _StockListScreenState extends State<StockListScreen> {
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshProductList();
  }

  void _refreshProductList() async {
    final data = await DatabaseHelper.instance.getAllProducts();
    setState(() {
      _products = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("බඩු ලැයිස්තුව (Stock)"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
              ? const Center(child: Text("තවම බඩු ඇතුලත් කර නැත.\nයට ඇති + ලකුණ ඔබා බඩු ඇතුලත් කරන්න.", textAlign: TextAlign.center))
              : ListView.builder(
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final item = _products[index];
                    final stock = item['stock'] as int;
                    final isLowStock = stock < 5;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      color: isLowStock ? Colors.red.shade50 : Colors.white,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isLowStock ? Colors.red : Colors.blueAccent,
                          child: Icon(Icons.inventory_2, color: Colors.white),
                        ),
                        title: Text(
                          item['name'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("විකුණන මිල: රු. ${item['selling_price']}"),

                            Text(
                              "තියෙන ප්‍රමාණය: $stock",
                              style: TextStyle(
                                color: isLowStock ? Colors.red : Colors.grey[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (isLowStock)
                              const Text("⚠️ ඉවර වෙන්න ළඟයි!", style: TextStyle(color: Colors.red, fontSize: 12)),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.grey),
                          onPressed: () {

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Delete කිරීම පසුව සාදමු...")),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {

          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddProductScreen()),
          );
          _refreshProductList(); 
        },
        label: const Text("අලුත් බඩුවක්"),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
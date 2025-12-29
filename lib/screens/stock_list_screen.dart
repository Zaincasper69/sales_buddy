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
  double _totalInventoryValue = 0;

  @override
  void initState() {
    super.initState();
    _refreshProductList();
  }

  void _refreshProductList() async {
    final data = await DatabaseHelper.instance.getAllProducts();
    
    double totalVal = 0;
    for (var item in data) {
      double bPrice = item['buying_price'];
      int stock = item['stock'];
      totalVal += (bPrice * stock);
    }

    setState(() {
      _products = data;
      _totalInventoryValue = totalVal;
      _isLoading = false;
    });
  }

  void _deleteItem(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("අයිටම් එක මකන්නද?"),
        content: const Text("මෙය ස්ටොක් එකෙන් ස්ථිරවම ඉවත් වනු ඇත."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("නෑ"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await DatabaseHelper.instance.deleteProduct(id);
              _refreshProductList();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("සාර්ථකව ඉවත් කරන ලදි!")),
                );
              }
            },
            child: const Text("ඔව්, මකන්න", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("බඩු ලැයිස්තුව (Stock)"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            color: Colors.orange.shade50,
            child: Column(
              children: [
                const Text(
                  "මුළු බඩු වටිනාකම (Total Value)",
                  style: TextStyle(fontSize: 16, color: Colors.brown),
                ),
                Text(
                  "Rs. ${_totalInventoryValue.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 24, 
                    fontWeight: FontWeight.bold, 
                    color: Colors.deepOrange
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: _isLoading
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
                                child: const Icon(Icons.inventory_2, color: Colors.white),
                              ),
                              title: Text(
                                item['name'],
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("ගාන: Rs. ${item['buying_price']} (Buy) | Rs. ${item['selling_price']} (Sell)"),
                                  Text(
                                    "Stock: $stock",
                                    style: TextStyle(
                                      color: isLowStock ? Colors.red : Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent),
                                onPressed: () => _deleteItem(item['id']),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
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
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';

class BillDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> sale;

  const BillDetailsScreen({super.key, required this.sale});

  @override
  State<BillDetailsScreen> createState() => _BillDetailsScreenState();
}

class _BillDetailsScreenState extends State<BillDetailsScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final data = await DatabaseHelper.instance.getSaleItems(widget.sale['id']);
    setState(() {
      _items = data;
      _isLoading = false;
    });
  }

  Future<void> _deleteBill() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("බිල මකන්නද?"),
        content: const Text("මෙම බිල සහ ඊට අදාල දත්ත සියල්ල මැකී යනු ඇත. ඔබට විශ්වාසද?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("නැත"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await DatabaseHelper.instance.deleteSale(widget.sale['id']);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('බිල සාර්ථකව මැකුවා! 🗑️'), backgroundColor: Colors.red),
                );
                Navigator.pop(context, true);
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
    final date = DateTime.parse(widget.sale['date']);
    final formattedDate = DateFormat('yyyy-MM-dd hh:mm a').format(date);

    final double totalAmount = double.parse(widget.sale['total_amount'].toString());
    final double netProfit = double.parse(widget.sale['net_profit'].toString());

    return Scaffold(
      appBar: AppBar(
        title: const Text("බිලේ විස්තර"),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _deleteBill,
            icon: const Icon(Icons.delete),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.purple.shade50,
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.sale['shop_name'] ?? "Unknown Shop",
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.purple),
                ),
                Text(formattedDate, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("මුළු එකතුව:", style: TextStyle(fontSize: 18)),
                    Text(
                      "Rs. ${totalAmount.toStringAsFixed(2)}",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("ලාභය:", style: TextStyle(fontSize: 16)),
                    Text(
                      "Rs. ${netProfit.toStringAsFixed(2)}",
                      style: TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.bold,
                        color: netProfit >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(thickness: 2, height: 1),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12.0),
            color: Colors.grey.shade200,
            child: const Text(
              "අලෙවි කළ බඩු ලැයිස්තුව (Items)", 
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty 
                  ? const Center(child: Text("අයිතම කිසිවක් නැත"))
                  : ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      final qty = int.parse(item['quantity'].toString());
                      final price = double.parse(item['price_per_unit'].toString());
                      final lineTotal = qty * price;

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        elevation: 2,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.purple.shade100,
                            child: const Icon(Icons.shopping_bag, color: Colors.purple),
                          ),
                          title: Text(item['product_name'], style: const TextStyle(fontWeight: FontWeight.w500)),
                          subtitle: Text("$qty x Rs. ${price.toStringAsFixed(2)}"),
                          trailing: Text(
                            "Rs. ${lineTotal.toStringAsFixed(2)}",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
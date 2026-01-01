import 'package:flutter/material.dart';
import '../db/database_helper.dart';

class ManageShopsScreen extends StatefulWidget {
  final int routeId;
  final String routeName;

  const ManageShopsScreen({super.key, required this.routeId, required this.routeName});

  @override
  State<ManageShopsScreen> createState() => _ManageShopsScreenState();
}

class _ManageShopsScreenState extends State<ManageShopsScreen> {
  List<Map<String, dynamic>> _shops = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadShops();
  }

  Future<void> _loadShops() async {
    final data = await DatabaseHelper.instance.getShopsByRoute(widget.routeId);
    setState(() {
      _shops = data;
      _isLoading = false;
    });
  }

  Future<void> _addShop() async {
    final TextEditingController shopController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("${widget.routeName} - අලුත් කඩයක්"),
        content: TextField(
          controller: shopController,
          decoration: const InputDecoration(
            labelText: "කඩේ නම (Shop Name)",
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.store)
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("අවලංගු කරන්න"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (shopController.text.isNotEmpty) {
                await DatabaseHelper.instance.addShop(shopController.text, widget.routeId);
                Navigator.pop(context);
                _loadShops();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('කඩය ඇතුලත් කරා! ✅'), backgroundColor: Colors.green),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
            child: const Text("සේව් කරන්න"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteShop(int id) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("කඩේ මකන්නද?"),
        content: const Text("මෙම කඩය ලිස්ට් එකෙන් ඉවත් වනු ඇත."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("නෑ")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await DatabaseHelper.instance.deleteShop(id);
              _loadShops();
            },
            child: const Text("ඔව්, මකන්න", style: TextStyle(color: Colors.red)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.routeName), 
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _shops.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.store_mall_directory, size: 80, color: Colors.grey.shade300),
                      const SizedBox(height: 10),
                      const Text("මෙම රූට් එකේ කඩ තවම නෑ.", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: _shops.length,
                  itemBuilder: (context, index) {
                    final shop = _shops[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.purple.shade50,
                          child: const Icon(Icons.store, color: Colors.purple),
                        ),
                        title: Text(shop['name'], style: const TextStyle(fontWeight: FontWeight.w500)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.grey),
                          onPressed: () => _deleteShop(shop['id']),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addShop,
        backgroundColor: Colors.purple,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("කඩයක් දාන්න", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
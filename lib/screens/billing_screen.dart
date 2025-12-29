import 'package:flutter/material.dart';
import '../db/database_helper.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _priceController = TextEditingController(); 

  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _cartItems = [];
  
  int? _selectedProductId; 
  Map<String, dynamic>? _selectedProductObj;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final data = await DatabaseHelper.instance.getAllProducts();
    setState(() {
      _allProducts = data;
    });
  }

  void _onProductSelect(int? id) {
    if (id == null) return;

    final product = _allProducts.firstWhere((element) => element['id'] == id);

    setState(() {
      _selectedProductId = id;
      _selectedProductObj = product;

      _priceController.text = product['selling_price'].toString();
      _qtyController.text = "1";
    });
  }

  void _addToCart() {
    if (_selectedProductObj == null || _qtyController.text.isEmpty || _priceController.text.isEmpty) return;

    final int qty = int.parse(_qtyController.text);
    final double sellingPrice = double.parse(_priceController.text);
    final double buyingPrice = _selectedProductObj!['buying_price'];
    final double subTotal = sellingPrice * qty;

    setState(() {
      _cartItems.add({
        'product_id': _selectedProductObj!['id'],
        'product_name': _selectedProductObj!['name'],
        'buying_price': buyingPrice,
        'selling_price': sellingPrice,
        'qty': qty,
        'sub_total': subTotal,
      });
      
      _selectedProductId = null;
      _selectedProductObj = null;
      _qtyController.clear();
      _priceController.clear();
    });
  }

  double _calculateTotal() {
    double total = 0;
    for (var item in _cartItems) {
      total += item['sub_total'];
    }
    return total;
  }

  Future<void> _saveSale() async {
    if (_shopNameController.text.isEmpty || _cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('කරුණාකර කඩේ නම සහ බඩු ඇතුලත් කරන්න!')),
      );
      return;
    }

    double totalAmount = _calculateTotal();
    
    double totalProfit = 0;
    for (var item in _cartItems) {
      double itemProfit = (item['selling_price'] - item['buying_price']) * item['qty'];
      totalProfit += itemProfit;
    }
    
    double netProfit = totalProfit;

    Map<String, dynamic> saleRow = {
      'shop_name': _shopNameController.text,
      'date': DateTime.now().toIso8601String(),
      'total_amount': totalAmount,
      'discount': 0.0,
      'net_profit': netProfit,
    };

    List<Map<String, dynamic>> saleItems = _cartItems.map((item) {
      return {
        'product_name': item['product_name'],
        'quantity': item['qty'],
        'price_per_unit': item['selling_price']
      };
    }).toList();

    await DatabaseHelper.instance.addSale(saleRow, saleItems);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('බිල සාර්ථකව සේව් කරා! ✅'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("අලුත් බිලක් (New Sale)"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _shopNameController,
              decoration: const InputDecoration(
                labelText: "කඩේ නම (Shop Name)",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.store),
              ),
            ),
            const SizedBox(height: 20),
            
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: "අයිටම් එක තෝරන්න",
                      border: InputBorder.none,
                    ),
                    isExpanded: true,
                    value: _selectedProductId,
                    items: _allProducts.map((product) {
                      return DropdownMenuItem<int>(
                        value: product['id'] as int,
                        child: Text(
                          product['name'],
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: _onProductSelect,
                  ),
                  
                  const Divider(),

                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "මිල (Price)",
                            prefixText: "Rs.",
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      
                      Expanded(
                        flex: 1,
                        child: TextField(
                          controller: _qtyController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "Qty",
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      
                      IconButton.filled(
                        onPressed: _addToCart,
                        icon: const Icon(Icons.add),
                        style: IconButton.styleFrom(backgroundColor: Colors.green),
                      )
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 10),
            const Divider(thickness: 2),
            
            Expanded(
              child: _cartItems.isEmpty
                  ? const Center(child: Text("තවම බඩු ඇතුලත් කර නැත", style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: _cartItems.length,
                      itemBuilder: (context, index) {
                        final item = _cartItems[index];
                        return Card(
                          color: Colors.white,
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          child: ListTile(
                            title: Text(item['product_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("${item['qty']} x Rs.${item['selling_price']}"),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "Rs. ${item['sub_total']}",
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      _cartItems.removeAt(index);
                                    });
                                  },
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("මුළු එකතුව (Total):", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(
                    "Rs. ${_calculateTotal()}",
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveSale,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text("බිල දාන්න (Complete Sale)", style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
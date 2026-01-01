import 'package:flutter/material.dart';
import '../db/database_helper.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _foundProducts = [];
  List<Map<String, dynamic>> _cartItems = [];
  
  List<Map<String, dynamic>> _routes = [];
  List<Map<String, dynamic>> _shops = [];

  int? _selectedRouteId;
  int? _selectedShopId;
  String? _selectedShopName;

  Map<String, dynamic>? _selectedProductObj;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final products = await DatabaseHelper.instance.getAllProducts();
    final routes = await DatabaseHelper.instance.getAllRoutes();
    
    setState(() {
      _allProducts = products;
      _foundProducts = products;
      _routes = routes;
    });
  }

  Future<void> _onRouteSelect(int? routeId) async {
    setState(() {
      _selectedRouteId = routeId;
      _selectedShopId = null;
      _selectedShopName = null;
      _shops = [];
    });

    if (routeId != null) {
      final shops = await DatabaseHelper.instance.getShopsByRoute(routeId);
      setState(() {
        _shops = shops;
      });
    }
  }

  void _onShopSelect(int? shopId) {
    if (shopId == null) {
      setState(() {
        _selectedShopId = null;
        _selectedShopName = null;
      });
      return;
    }

    final shop = _shops.firstWhere((element) => element['id'] == shopId);
    setState(() {
      _selectedShopId = shopId;
      _selectedShopName = shop['name'];
    });
  }

  void _runFilter(String enteredKeyword) {
    List<Map<String, dynamic>> results = [];
    if (enteredKeyword.isEmpty) {
      results = _allProducts;
    } else {
      results = _allProducts
          .where((product) =>
              product["name"]
                  .toString()
                  .toLowerCase()
                  .contains(enteredKeyword.toLowerCase()) ||
              product["code"]
                  .toString()
                  .toLowerCase()
                  .contains(enteredKeyword.toLowerCase()))
          .toList();
    }
    setState(() {
      _foundProducts = results;
    });
  }

  void _onProductSelect(Map<String, dynamic> product) {
    setState(() {
      _selectedProductObj = product;
      _priceController.text = product['selling_price'].toString();
      _qtyController.text = "1";
    });
  }

  void _resetSelection() {
    setState(() {
      _selectedProductObj = null;
      _qtyController.clear();
      _priceController.clear();
      _searchController.clear();
      _foundProducts = _allProducts;
    });
  }

  void _addToCart() {
    if (_selectedProductObj == null ||
        _qtyController.text.isEmpty ||
        _priceController.text.isEmpty) return;

    final int qty = int.parse(_qtyController.text);
    final double sellingPrice = double.parse(_priceController.text);
    final double buyingPrice = _selectedProductObj!['buying_price'];
    final double subTotal = sellingPrice * qty;

    int currentStock = _selectedProductObj!['stock'];
    if (qty > currentStock) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("ස්ටොක් එක මදි!"), backgroundColor: Colors.red));
      return;
    }

    setState(() {
      _cartItems.add({
        'product_id': _selectedProductObj!['id'],
        'product_name': _selectedProductObj!['name'],
        'buying_price': buyingPrice,
        'selling_price': sellingPrice,
        'qty': qty,
        'sub_total': subTotal,
      });

      _resetSelection();
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
    if (_selectedShopName == null || _cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('කරුණාකර කඩයක් තෝරන්න සහ බඩු ඇතුලත් කරන්න!')),
      );
      return;
    }

    double totalAmount = _calculateTotal();
    double totalProfit = 0;

    for (var item in _cartItems) {
      double itemProfit =
          (item['selling_price'] - item['buying_price']) * item['qty'];
      totalProfit += itemProfit;
    }

    Map<String, dynamic> saleRow = {
      'shop_name': _selectedShopName,
      'date': DateTime.now().toIso8601String(),
      'total_amount': totalAmount,
      'discount': 0.0,
      'net_profit': totalProfit,
    };

    List<Map<String, dynamic>> saleItems = _cartItems.map((item) {
      return {
        'product_id': item['product_id'],
        'product_name': item['product_name'],
        'quantity': item['qty'],
        'price_per_unit': item['selling_price']
      };
    }).toList();

    await DatabaseHelper.instance.addSale(saleRow, saleItems);
    
    final products = await DatabaseHelper.instance.getAllProducts();
    setState(() {
       _allProducts = products;
       _foundProducts = products;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('බිල සාර්ථකව සේව් කරා! ✅'),
            backgroundColor: Colors.green),
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
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(
                labelText: "මාර්ගය තෝරන්න (Select Route)",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.map),
              ),
              value: _selectedRouteId,
              items: _routes.map((route) {
                return DropdownMenuItem<int>(
                  value: route['id'],
                  child: Text(route['name']),
                );
              }).toList(),
              onChanged: _onRouteSelect,
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(
                labelText: "කඩය තෝරන්න (Select Shop)",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.store),
              ),
              value: _selectedShopId,
              items: _shops.map((shop) {
                return DropdownMenuItem<int>(
                  value: shop['id'],
                  child: Text(shop['name']),
                );
              }).toList(),
              onChanged: _shops.isEmpty ? null : _onShopSelect,
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  if (_selectedProductObj == null) ...[
                    TextField(
                      controller: _searchController,
                      onChanged: _runFilter,
                      decoration: const InputDecoration(
                        labelText: 'අයිටම් එක සොයන්න (Search Item)',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10),
                      ),
                    ),
                    const SizedBox(height: 5),
                    SizedBox(
                      height: 150,
                      child: _foundProducts.isNotEmpty
                          ? ListView.builder(
                              itemCount: _foundProducts.length,
                              itemBuilder: (context, index) {
                                final product = _foundProducts[index];
                                return Card(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: ListTile(
                                    dense: true,
                                    title: Text(product['name'],
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    subtitle: Text(
                                        "Code: ${product['code']} | Stock: ${product['stock']}"),
                                    trailing: Text(
                                        "Rs.${product['selling_price']}"),
                                    onTap: () => _onProductSelect(product),
                                  ),
                                );
                              },
                            )
                          : const Center(child: Text("ගැලපෙන අයිටම් නැත")),
                    ),
                  ] else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _selectedProductObj!['name'],
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          onPressed: _resetSelection,
                          icon: const Icon(Icons.close, color: Colors.red),
                        )
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        width: double.infinity,
                        decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: Colors.orange.shade200)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "ගත්ත මිල: Rs. ${_selectedProductObj!['buying_price']}",
                              style: TextStyle(
                                  color: Colors.brown[700],
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "ඇත (Stock): ${_selectedProductObj!['stock']}",
                              style: TextStyle(
                                color: (_selectedProductObj!['stock'] ?? 0) > 0
                                    ? Colors.green[800]
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _priceController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: const InputDecoration(
                              labelText: "මිල (Price)",
                              prefixText: "Rs.",
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
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
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton.filled(
                          onPressed: _addToCart,
                          icon: const Icon(Icons.add),
                          style: IconButton.styleFrom(
                              backgroundColor: Colors.green),
                        )
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Divider(thickness: 2),
            Expanded(
              child: _cartItems.isEmpty
                  ? const Center(
                      child: Text("තවම බඩු ඇතුලත් කර නැත",
                          style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: _cartItems.length,
                      itemBuilder: (context, index) {
                        final item = _cartItems[index];
                        return Card(
                          color: Colors.white,
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          child: ListTile(
                            title: Text(item['product_name'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    "${item['qty']} x Rs.${item['selling_price']}"),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "Rs. ${item['sub_total'].toStringAsFixed(2)}",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle,
                                      color: Colors.red),
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
                  const Text("මුළු එකතුව (Total):",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(
                    "Rs. ${_calculateTotal().toStringAsFixed(2)}",
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.green),
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
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text("බිල දාන්න (Complete Sale)",
                    style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
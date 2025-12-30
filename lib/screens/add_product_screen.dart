import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../db/database_helper.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _buyingPriceController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController();
  
  Future<void> _saveProduct() async {
    if (_nameController.text.isEmpty || _buyingPriceController.text.isEmpty || _qtyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('කරුණාකර සියලු විස්තර පුරවන්න! ⚠️'), backgroundColor: Colors.orange),
      );
      return;
    }

    try {
      final String name = _nameController.text;
      
      String priceText = _buyingPriceController.text.replaceAll(',', '.');
      final double price = double.parse(priceText);
      
      final int stock = int.parse(_qtyController.text);

      Map<String, dynamic> row = {
        'name': name,
        'code': '', 
        'buying_price': price,
        'selling_price': price, 
        'stock': stock 
      };

      await DatabaseHelper.instance.addProduct(row);

      _nameController.clear();
      _buyingPriceController.clear();
      _qtyController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('බඩුව සාර්ථකව ඇතුලත් කරා! ✅'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('මිල සඳහා නිවැරදි ඉලක්කම් භාවිතා කරන්න.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("අලුත් බඩු දාන්න"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView( 
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 10),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "බඩුවේ නම (Item Name)",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.shopping_bag),
                ),
              ),
              const SizedBox(height: 15),
              
              TextField(
                controller: _buyingPriceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')), 
                ],
                decoration: const InputDecoration(
                  labelText: "මිල (Price)",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.arrow_downward, color: Colors.red),
                  suffixText: "LKR"
                ),
              ),
              const SizedBox(height: 15),

              TextField(
                controller: _qtyController,
                keyboardType: TextInputType.number, 
                decoration: const InputDecoration(
                  labelText: "ප්‍රමාණය (Initial Stock)",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.inventory_2, color: Colors.orange),
                ),
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _saveProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text("සේව් කරන්න", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
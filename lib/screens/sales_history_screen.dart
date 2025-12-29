import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import 'bill_details_screen.dart';

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  List<Map<String, dynamic>> _sales = [];
  bool _isLoading = true;
  double _totalProfit = 0;
  double _totalSales = 0;

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  Future<void> _loadSales() async {
    final data = await DatabaseHelper.instance.getAllSales();
    
    double tProfit = 0;
    double tSales = 0;

    for (var sale in data) {
      tProfit += double.parse(sale['net_profit'].toString());
      tSales += double.parse(sale['total_amount'].toString());
    }

    setState(() {
      _sales = data;
      _totalProfit = tProfit;
      _totalSales = tSales;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("විකුණුම් ඉතිහාසය (History)"),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.purple.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text("මුළු ආදායම", style: TextStyle(fontSize: 16, color: Colors.grey)),
                    Text(
                      "Rs. ${_totalSales.toStringAsFixed(2)}",
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.purple),
                    ),
                  ],
                ),
                Container(height: 40, width: 1, color: Colors.grey),
                Column(
                  children: [
                    const Text("මුළු ලාභය", style: TextStyle(fontSize: 16, color: Colors.grey)),
                    Text(
                      "Rs. ${_totalProfit.toStringAsFixed(2)}",
                      style: TextStyle(
                        fontSize: 20, 
                        fontWeight: FontWeight.bold, 
                        color: _totalProfit >= 0 ? Colors.green : Colors.red
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _sales.isEmpty
                    ? const Center(child: Text("තවම විකුණුම් සිදුකර නැත"))
                    : ListView.builder(
                        itemCount: _sales.length,
                        itemBuilder: (context, index) {
                          final sale = _sales[index];
                          final date = DateTime.parse(sale['date']);
                          final formattedDate = DateFormat('yyyy-MM-dd hh:mm a').format(date);
                          final profit = double.parse(sale['net_profit'].toString());

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BillDetailsScreen(sale: sale),
                                ),
                              );
                            },
                            child: Card(
                              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.purple.shade100,
                                  child: const Icon(Icons.receipt_long, color: Colors.purple),
                                ),
                                title: Text(sale['shop_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(formattedDate),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "Rs. ${sale['total_amount']}",
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    Text(
                                      "Profit: Rs. ${sale['net_profit']}",
                                      style: TextStyle(
                                        color: profit >= 0 ? Colors.green : Colors.red,
                                        fontSize: 12
                                      ),
                                    ),
                                  ],
                                ),
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
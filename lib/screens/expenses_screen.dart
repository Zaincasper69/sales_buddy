import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../db/database_helper.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  List<Map<String, dynamic>> _expenses = [];
  double _totalExpenses = 0.0;
  bool _isLoading = true;

  final List<String> _categories = ['Petrol', 'Food', 'Vehicle Repair', 'Reload', 'Other'];
  String _selectedCategory = 'Petrol';

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    final String today = DateTime.now().toIso8601String().split('T')[0];
    final data = await DatabaseHelper.instance.getExpensesByDate(today);

    double total = 0;
    for (var item in data) {
      total += item['amount'];
    }

    setState(() {
      _expenses = data;
      _totalExpenses = total;
      _isLoading = false;
    });
  }

  Future<void> _addExpense() async {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController noteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("අලුත් වියදමක් (New Expense)", 
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.redAccent)),
            const SizedBox(height: 20),
            
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: "වියදම් වර්ගය (Category)",
                border: OutlineInputBorder(),
              ),
              items: _categories.map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedCategory = newValue!;
                });
              },
            ),
            const SizedBox(height: 15),

            // Amount Input
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')), 
              ],
              decoration: const InputDecoration(
                labelText: "මුදල (Amount)",
                prefixText: "Rs. ",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),

            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: "විස්තරය (Note - Optional)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  if (amountController.text.isNotEmpty) {
                    final double amount = double.parse(amountController.text);
                    
                    Map<String, dynamic> row = {
                      'category': _selectedCategory,
                      'amount': amount,
                      'note': noteController.text,
                      'date': DateTime.now().toIso8601String()
                    };

                    await DatabaseHelper.instance.addExpense(row);
                    Navigator.pop(context);
                    _loadExpenses(); 
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('වියදම ඇතුලත් කරා!'), backgroundColor: Colors.redAccent),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                child: const Text("සේව් කරන්න", style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteExpense(int id) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("මකන්නද?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("නෑ")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await DatabaseHelper.instance.deleteExpense(id);
              _loadExpenses();
            },
            child: const Text("ඔව්", style: TextStyle(color: Colors.red)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("වියදම් (Expenses)"),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: Colors.red.shade50,
            child: Column(
              children: [
                const Text("අද දවසේ මුළු වියදම", style: TextStyle(fontSize: 16, color: Colors.grey)),
                Text(
                  "Rs. ${_totalExpenses.toStringAsFixed(2)}",
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.red),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _expenses.isEmpty
                    ? const Center(child: Text("අද දවසේ වියදම් කිසිවක් නැත.", style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(10),
                        itemCount: _expenses.length,
                        itemBuilder: (context, index) {
                          final expense = _expenses[index];
                          return Card(
                            elevation: 2,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.red.shade100,
                                child: Icon(_getIcon(expense['category']), color: Colors.red),
                              ),
                              title: Text(expense['category'], style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(expense['note'] ?? ''),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text("Rs. ${expense['amount']}", 
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 20, color: Colors.grey),
                                    onPressed: () => _deleteExpense(expense['id']),
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addExpense,
        backgroundColor: Colors.redAccent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("වියදමක් දාන්න", style: TextStyle(color: Colors.white)),
      ),
    );
  }

  IconData _getIcon(String category) {
    switch (category) {
      case 'Petrol': return Icons.local_gas_station;
      case 'Food': return Icons.fastfood;
      case 'Vehicle Repair': return Icons.build;
      case 'Reload': return Icons.phone_android;
      default: return Icons.money_off;
    }
  }
}
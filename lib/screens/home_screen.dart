import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import 'stock_list_screen.dart';
import 'billing_screen.dart';
import 'sales_history_screen.dart';
import 'manage_routes_screen.dart';
import 'expenses_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _todaySales = 0.0;
  double _todayExpenses = 0.0;
  double _netCash = 0.0;
  
  List<Map<String, dynamic>> _routes = [];
  int? _selectedRouteId;
  
  int _totalShopsInRoute = 0;
  int _visitedShopsCount = 0;
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    
    String today = DateTime.now().toIso8601String().split('T')[0];

    final sales = await DatabaseHelper.instance.getAllSales();
    final expenses = await DatabaseHelper.instance.getExpensesByDate(today);
    final routes = await DatabaseHelper.instance.getAllRoutes();

    double salesSum = 0;
    List<String> billedShopNames = [];

    for (var sale in sales) {
      if (sale['date'].toString().startsWith(today)) {
        salesSum += double.parse(sale['total_amount'].toString());
        billedShopNames.add(sale['shop_name']); 
      }
    }

    double expenseSum = 0;
    for (var exp in expenses) {
      expenseSum += double.parse(exp['amount'].toString());
    }

    if (_selectedRouteId != null) {
      await _calculateRouteProgress(_selectedRouteId!, billedShopNames);
    }

    if (mounted) {
      setState(() {
        _todaySales = salesSum;
        _todayExpenses = expenseSum;
        _netCash = salesSum - expenseSum;
        _routes = routes;
        _isLoading = false;
      });
    }
  }

  Future<void> _calculateRouteProgress(int routeId, List<String> billedShopsToday) async {
    final shopsInRoute = await DatabaseHelper.instance.getShopsByRoute(routeId);
    
    int visited = 0;
    for (var shop in shopsInRoute) {
      if (billedShopsToday.contains(shop['name'])) {
        visited++;
      }
    }

    setState(() {
      _totalShopsInRoute = shopsInRoute.length;
      _visitedShopsCount = visited;
    });
  }

  Future<void> _onRouteSelected(int? routeId) async {
    if (routeId == null) return;
    
    setState(() {
      _selectedRouteId = routeId;
      _isLoading = true;
    });

    String today = DateTime.now().toIso8601String().split('T')[0];
    final sales = await DatabaseHelper.instance.getAllSales();
    
    List<String> billedShopNames = [];
    for (var sale in sales) {
      if (sale['date'].toString().startsWith(today)) {
        billedShopNames.add(sale['shop_name']);
      }
    }

    await _calculateRouteProgress(routeId, billedShopNames);
    
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sales Buddy 🏪"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "අද දවසේ සාරාංශය (Today's Summary)",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                        ),
                        const Divider(),
                        const SizedBox(height: 5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("විකුණුම් (Sales)", style: TextStyle(color: Colors.green)),
                                Text("Rs. ${_todaySales.toStringAsFixed(2)}", 
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text("වියදම් (Expenses)", style: TextStyle(color: Colors.red)),
                                Text("Rs. ${_todayExpenses.toStringAsFixed(2)}", 
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Expanded(
                                child: Text("අතේ ඇති මුදල (Net Cash):", 
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                              ),
                              Text("Rs. ${_netCash.toStringAsFixed(2)}", 
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 15),
                        const Divider(),
                        
                        DropdownButtonFormField<int>(
                          isExpanded: true, 
                          decoration: const InputDecoration(
                            labelText: "රූට් එක තෝරන්න (Select Route)", 
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            prefixIcon: Icon(Icons.map, color: Colors.orange),
                          ),
                          value: _selectedRouteId,
                          items: _routes.map((route) {
                            return DropdownMenuItem<int>(
                              value: route['id'],
                              child: Text(
                                route['name'],
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: _onRouteSelected,
                        ),

                        if (_selectedRouteId != null) ...[
                          const SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("ආවරණය කළ කඩ: $_visitedShopsCount / $_totalShopsInRoute", 
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text("${((_totalShopsInRoute == 0 ? 0 : _visitedShopsCount / _totalShopsInRoute) * 100).toStringAsFixed(0)}%", 
                                style: const TextStyle(color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 5),
                          LinearProgressIndicator(
                            value: _totalShopsInRoute == 0 ? 0 : _visitedShopsCount / _totalShopsInRoute,
                            backgroundColor: Colors.grey.shade200,
                            color: Colors.orange,
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ]
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),

                  _buildDashboardButton(
                    context,
                    icon: Icons.calculate,
                    title: "බිලක් දාන්න (New Sale)",
                    color: Colors.green,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const BillingScreen()),
                      );
                      _loadDashboardData();
                    },
                  ),
                  const SizedBox(height: 15),

                  _buildDashboardButton(
                    context,
                    icon: Icons.inventory_2,
                    title: "බඩු විස්තර (Stock List)",
                    color: Colors.orange,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const StockListScreen()),
                      );
                      _loadDashboardData();
                    },
                  ),
                  const SizedBox(height: 15),

                  _buildDashboardButton(
                    context,
                    icon: Icons.bar_chart,
                    title: "ආදායම බලන්න (History)",
                    color: Colors.purple,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SalesHistoryScreen()),
                      );
                      _loadDashboardData();
                    },
                  ),
                  const SizedBox(height: 15),

                  _buildDashboardButton(
                    context,
                    icon: Icons.map,
                    title: "මාර්ග/කඩ (Manage Routes)",
                    color: Colors.teal,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ManageRoutesScreen()),
                      );
                      _loadDashboardData();
                    },
                  ),
                  const SizedBox(height: 15),

                  _buildDashboardButton(
                    context,
                    icon: Icons.money_off,
                    title: "වියදම් (Expenses)",
                    color: Colors.redAccent,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ExpensesScreen()),
                      );
                      _loadDashboardData();
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildDashboardButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 70,
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 4,
        ),
        icon: Icon(icon, size: 30),
        label: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
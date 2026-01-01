import 'package:flutter/material.dart';
import 'stock_list_screen.dart';
import 'billing_screen.dart';
import 'sales_history_screen.dart';
import 'manage_routes_screen.dart';
import 'expenses_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sales Buddy 🏪"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              _buildDashboardButton(
                context,
                icon: Icons.calculate,
                title: "බිලක් දාන්න (New Sale)",
                color: Colors.green,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BillingScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              _buildDashboardButton(
                context,
                icon: Icons.inventory_2,
                title: "බඩු විස්තර (Stock List)",
                color: Colors.orange,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StockListScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              _buildDashboardButton(
                context,
                icon: Icons.bar_chart,
                title: "ආදායම බලන්න (History)",
                color: Colors.purple,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SalesHistoryScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              _buildDashboardButton(
                context,
                icon: Icons.map,
                title: "මාර්ග/කඩ (Manage Routes)",
                color: Colors.teal,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ManageRoutesScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              _buildDashboardButton(
                context,
                icon: Icons.money_off,
                title: "වියදම් (Expenses)",
                color: Colors.redAccent,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ExpensesScreen(),
                    ),
                  );
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
      height: 80,
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 5,
        ),
        icon: Icon(icon, size: 35),
        label: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
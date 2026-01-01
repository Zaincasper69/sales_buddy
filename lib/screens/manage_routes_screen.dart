import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import 'manage_shops_screen.dart'; 

class ManageRoutesScreen extends StatefulWidget {
  const ManageRoutesScreen({super.key});

  @override
  State<ManageRoutesScreen> createState() => _ManageRoutesScreenState();
}

class _ManageRoutesScreenState extends State<ManageRoutesScreen> {
  List<Map<String, dynamic>> _routes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    final data = await DatabaseHelper.instance.getAllRoutes();
    setState(() {
      _routes = data;
      _isLoading = false;
    });
  }

  Future<void> _addRoute() async {
    final TextEditingController routeController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("අලුත් මාර්ගයක් (New Route)"),
        content: TextField(
          controller: routeController,
          decoration: const InputDecoration(
            labelText: "මාර්ගයේ නම (Route Name)",
            border: OutlineInputBorder()
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("අවලංගු කරන්න"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (routeController.text.isNotEmpty) {
                await DatabaseHelper.instance.addRoute(routeController.text);
                Navigator.pop(context);
                _loadRoutes();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('මාර්ගය ඇතුලත් කරා! ✅'), backgroundColor: Colors.green),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
            child: const Text("සේව් කරන්න"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteRoute(int id) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("මකන්නද?"),
        content: const Text("මේ රූට් එක මැකුවොත් ඒකෙ තියෙන කඩ ලිස්ට් එකත් නැති වෙන්න පුලුවන්."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("නෑ")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await DatabaseHelper.instance.deleteRoute(id);
              _loadRoutes();
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
        title: const Text("මාර්ග කළමනාකරණය (Routes)"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _routes.isEmpty
              ? const Center(child: Text("තවම මාර්ග ඇතුලත් කර නැත.", style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: _routes.length,
                  itemBuilder: (context, index) {
                    final route = _routes[index];
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.teal.shade100,
                          child: const Icon(Icons.map, color: Colors.teal),
                        ),
                        title: Text(route['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () => _deleteRoute(route['id']),
                        ),
                        onTap: () {

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ManageShopsScreen(
                                routeId: route['id'],
                                routeName: route['name'],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addRoute,
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("අලුත් පාරක්", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
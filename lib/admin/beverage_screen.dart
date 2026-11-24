import 'package:flutter/material.dart';

class BeverageManagementPage extends StatefulWidget {
  const BeverageManagementPage({super.key});

  @override
  State<BeverageManagementPage> createState() => _BeverageManagementPageState();
}

class _BeverageManagementPageState extends State<BeverageManagementPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _sizeController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  final List<Map<String, dynamic>> _beverages = [
    {'name': 'Coke', 'size': 'Large', 'quantity': 50, 'price': 10},
    {'name': 'Mineral Water', 'size': 'Large', 'quantity': 1000, 'price': 5},
    {'name': 'MILO', 'size': 'Large', 'quantity': 100, 'price': 30},
    {'name': 'Ice Lemon Tea', 'size': 'Large', 'quantity': 1000, 'price': 10},
    {'name': 'Ice Lemon Tea', 'size': 'Regular', 'quantity': 1000, 'price': 8},
    {'name': 'MILO', 'size': 'Regular', 'quantity': 5, 'price': 16},
  ];

  void _addBeverage() {
    if (_nameController.text.isNotEmpty &&
        _sizeController.text.isNotEmpty &&
        _quantityController.text.isNotEmpty &&
        _priceController.text.isNotEmpty) {
      setState(() {
        _beverages.add({
          'name': _nameController.text.trim(),
          'size': _sizeController.text.trim(),
          'quantity': int.tryParse(_quantityController.text) ?? 0,
          'price': int.tryParse(_priceController.text) ?? 0,
        });
        _nameController.clear();
        _sizeController.clear();
        _quantityController.clear();
        _priceController.clear();
      });
    }
  }

  void _editBeverage(int index) {
    final beverage = _beverages[index];
    _nameController.text = beverage['name'];
    _sizeController.text = beverage['size'];
    _quantityController.text = beverage['quantity'].toString();
    _priceController.text = beverage['price'].toString();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Beverage'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: _sizeController, decoration: const InputDecoration(labelText: 'Size')),
            TextField(controller: _quantityController, decoration: const InputDecoration(labelText: 'Quantity'), keyboardType: TextInputType.number),
            TextField(controller: _priceController, decoration: const InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _beverages[index] = {
                  'name': _nameController.text.trim(),
                  'size': _sizeController.text.trim(),
                  'quantity': int.tryParse(_quantityController.text) ?? 0,
                  'price': int.tryParse(_priceController.text) ?? 0,
                };
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteBeverage(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Beverage'),
        content: Text('Are you sure you want to delete ${_beverages[index]['name']} (${_beverages[index]['size']})?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() => _beverages.removeAt(index));
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Beverages'), backgroundColor: Colors.black),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: TextField(controller: _nameController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Name', labelStyle: TextStyle(color: Colors.white54)))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: _sizeController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Size', labelStyle: TextStyle(color: Colors.white54)))),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: TextField(controller: _quantityController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Quantity', labelStyle: TextStyle(color: Colors.white54)), keyboardType: TextInputType.number)),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: _priceController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Price', labelStyle: TextStyle(color: Colors.white54)), keyboardType: TextInputType.number)),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _addBeverage,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
              child: const Text('Add Beverage'),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: _beverages.length,
                itemBuilder: (context, index) {
                  final b = _beverages[index];
                  return Card(
                    color: Colors.grey[900],
                    child: ListTile(
                      title: Text('${b['name']} (${b['size']})', style: const TextStyle(color: Colors.white)),
                      subtitle: Text('Qty: ${b['quantity']}, Price: RM${b['price']}', style: const TextStyle(color: Colors.white70)),
                      trailing: Wrap(
                        spacing: 12,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.amber),
                            onPressed: () => _editBeverage(index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteBeverage(index),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

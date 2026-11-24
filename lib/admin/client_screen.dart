import 'package:flutter/material.dart';

class ClientManagementPage extends StatelessWidget {
  const ClientManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final clients = [
      {
        'email': 'john@example.com',
        'rewards': 120,
        'username': 'john_doe',
        'birthday': '1990-05-10',
        'district': 'Cheras',
        'gender': 'Male',
        'position': 'Member',
      },
      // Add more dummy clients here
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Client Management'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: ListView.builder(
        itemCount: clients.length,
        itemBuilder: (context, index) {
          final client = clients[index];
          return Card(
            color: Colors.grey[900],
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(
                client['username'].toString(),
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                '${client['email']} • ${client['position']}',
                style: const TextStyle(color: Colors.white70),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.yellow),
                    onPressed: () {
                      // TODO: Handle edit
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () {
                      // TODO: Handle delete
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.pink,
        onPressed: () {
          // TODO: Navigate to AddClient form
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

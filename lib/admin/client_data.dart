import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

class ClientManagementScreen extends StatefulWidget {
  @override
  _ClientManagementScreenState createState() => _ClientManagementScreenState();
}

class _ClientManagementScreenState extends State<ClientManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _positionController = TextEditingController();
  final TextEditingController _rewardsController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();

  String? _selectedDistrict;
  String? _selectedGender;
  String? _selectedLanguage;

  String positionFilter = '';
  String searchText = '';
  List<Map<String, dynamic>> allClients = [];
  List<Map<String, dynamic>> filteredClients = [];

  final List<String> districtOptions = [
    "All States/Areas",
    "Klang Valley",
    "Johor",
    "Perak",
    "Pulau Pinang",
    "Sarawak",
    "Negeri Sembilan",
    "Terengganu",
  ];

  @override
  void initState() {
    super.initState();
    fetchClients();
  }

  Future<void> fetchClients() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('Client').get();
    final clients =
        snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();

    setState(() {
      allClients = clients;
      applyFilter();
    });
  }

  void applyFilter() {
    setState(() {
      filteredClients =
          allClients.where((client) {
            final matchesPosition =
                positionFilter.isEmpty || client['position'] == positionFilter;
            final matchesSearch =
                searchText.isEmpty ||
                client.values.any(
                  (value) => value.toString().toLowerCase().contains(
                    searchText.toLowerCase(),
                  ),
                );
            return matchesPosition && matchesSearch;
          }).toList();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _birthdayController.text = picked.toIso8601String().split("T").first;
      });
    }
  }

  Future<void> addClient() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final position = _positionController.text.trim();
    final rewards = int.tryParse(_rewardsController.text.trim()) ?? 0;
    final contact = _contactController.text.trim();
    final birthday = _birthdayController.text.trim();
    final district = _selectedDistrict ?? '';
    final gender = _selectedGender ?? '';
    final language = _selectedLanguage ?? '';
    final createdAt = Timestamp.now();

    if (username.isNotEmpty &&
        email.isNotEmpty &&
        position.isNotEmpty &&
        password.isNotEmpty) {
      try {
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);
        final uid = userCredential.user?.uid ?? const Uuid().v4();

        await FirebaseFirestore.instance.collection('Client').doc(uid).set({
          'UserName': username,
          'Email': email,
          'position': position,
          'Rewards': rewards,
          'Contact_Number': contact.isEmpty ? null : contact,
          'birthday': birthday,
          'district': district,
          'gender': gender,
          'language': language,
          'uid': uid,
          'createdAt': createdAt,
        });

        fetchClients();
        Navigator.pop(context);
        _usernameController.clear();
        _emailController.clear();
        _passwordController.clear();
        _positionController.clear();
        _rewardsController.clear();
        _contactController.clear();
        _birthdayController.clear();
        _selectedDistrict = null;
        _selectedGender = null;
        _selectedLanguage = null;
      } catch (e) {
        print("Error adding user: $e");
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to add user: $e")));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("All fields including password must be filled."),
        ),
      );
    }
  }

  void deleteClient(Map<String, dynamic> client) async {
    final uid = client['uid'];
    final docId = client['id'];

    final passwordController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Admin Authentication Required"),
            content: TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Please input admin password (password = 2409)',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context, passwordController.text);
                },
                child: Text("Confirm"),
              ),
            ],
          ),
    );

    if (result != '2409') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Incorrect admin password. Cannot delete user."),
        ),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('Client').doc(docId).delete();

      await FirebaseAuth.instance.currentUser!.delete();

      fetchClients();
      Navigator.pop(context);
    } catch (e) {
      print("Error deleting user: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to delete user: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Client Management")),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children:
                ['customer', 'manager', 'admin'].map((role) {
                  final isSelected = positionFilter == role;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        positionFilter = isSelected ? '' : role;
                        applyFilter();
                      });
                    },
                    child: Container(
                      width: 100,
                      height: 100,
                      margin: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.amber : Colors.black87,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.folder, color: Colors.white, size: 32),
                          SizedBox(height: 8),
                          Text(
                            role[0].toUpperCase() + role.substring(1),
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
          ),
          Padding(
            padding: EdgeInsets.all(8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search...',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    setState(() {
                      searchText = _searchController.text;
                      applyFilter();
                    });
                  },
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Username')),
                  DataColumn(label: Text('Email')),
                  DataColumn(label: Text('Position')),
                  DataColumn(label: Text('Rewards')),
                ],
                rows:
                    filteredClients.map((client) {
                      return DataRow(
                        cells: [
                          DataCell(Text(client['UserName'] ?? '')),
                          DataCell(Text(client['Email'] ?? '')),
                          DataCell(Text(client['position'] ?? '')),
                          DataCell(Text(client['Rewards'].toString())),
                        ],
                        onSelectChanged:
                            (_) => showDialog(
                              context: context,
                              builder:
                                  (_) => AlertDialog(
                                    title: Text("Client Details"),
                                    content: SingleChildScrollView(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children:
                                            client.entries
                                                .map(
                                                  (e) => Text(
                                                    "${e.key}: ${e.value}"
                                                        .trim(),
                                                  ),
                                                )
                                                .toList(),
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text("Close"),
                                      ),
                                      TextButton(
                                        onPressed: () => deleteClient(client),
                                        child: Text(
                                          "Delete",
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                            ),
                      );
                    }).toList(),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder:
                (_) => AlertDialog(
                  title: Text("Add New Client"),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: _usernameController,
                          decoration: InputDecoration(labelText: 'Username'),
                        ),
                        TextField(
                          controller: _emailController,
                          decoration: InputDecoration(labelText: 'Email'),
                        ),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(labelText: 'Password'),
                        ),
                        DropdownButtonFormField(
                          value: 'customer',
                          items:
                              ['customer', 'manager', 'admin']
                                  .map(
                                    (role) => DropdownMenuItem(
                                      value: role,
                                      child: Text(role),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (val) => _positionController.text = val!,
                          decoration: InputDecoration(labelText: 'Position'),
                        ),
                        TextField(
                          controller: _rewardsController,
                          decoration: InputDecoration(labelText: 'Rewards'),
                          keyboardType: TextInputType.number,
                        ),
                        TextField(
                          controller: _contactController,
                          decoration: InputDecoration(
                            labelText: 'Contact Number',
                          ),
                        ),
                        TextField(
                          controller: _birthdayController,
                          decoration: InputDecoration(labelText: 'Birthday'),
                          readOnly: true,
                          onTap: () => _selectDate(context),
                        ),
                        DropdownButtonFormField(
                          value: _selectedDistrict,
                          items:
                              districtOptions
                                  .map(
                                    (d) => DropdownMenuItem(
                                      value: d,
                                      child: Text(d),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (val) => setState(() => _selectedDistrict = val),
                          decoration: InputDecoration(labelText: 'District'),
                        ),
                        DropdownButtonFormField(
                          value: _selectedGender,
                          items:
                              ['Male', 'Female']
                                  .map(
                                    (g) => DropdownMenuItem(
                                      value: g,
                                      child: Text(g),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (val) => setState(() => _selectedGender = val),
                          decoration: InputDecoration(labelText: 'Gender'),
                        ),
                        DropdownButtonFormField(
                          value: _selectedLanguage,
                          items:
                              ['English', 'Chinese']
                                  .map(
                                    (l) => DropdownMenuItem(
                                      value: l,
                                      child: Text(l),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (val) => setState(() => _selectedLanguage = val),
                          decoration: InputDecoration(labelText: 'Language'),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("Cancel"),
                    ),
                    TextButton(onPressed: addClient, child: Text("Add")),
                  ],
                ),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

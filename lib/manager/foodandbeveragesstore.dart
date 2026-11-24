import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'foodandbevup.dart';
import 'foodandbev_edit_and_delete.dart';

class FBManagementScreen extends StatefulWidget {
  const FBManagementScreen({super.key});

  @override
  State<FBManagementScreen> createState() => _FBManagementPageState();
}

class _FBManagementPageState extends State<FBManagementScreen> {
  String selectedCategory = 'Food';
  String selectedTime = 'WEEKLY';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'F&B Management',
          style: TextStyle(color: Colors.yellow),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow),
              child: const Text("PDF", style: TextStyle(color: Colors.black)),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildTopTab("OVERALL", true),
                    _buildTopTab("SALES", false),
                    _buildTopTab("INVENTORY", false),
                  ],
                ),
                const SizedBox(height: 20),
                Column(
                  children: const [
                    Text(
                      "TODAY F&B Earn",
                      style: TextStyle(color: Colors.white70),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "RM 200",
                      style: TextStyle(color: Colors.yellow, fontSize: 48),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children:
                      ["DAILY", "WEEKLY", "MONTHLY"].map((label) {
                        final isSelected = label == selectedTime;
                        return ElevatedButton(
                          onPressed: () {
                            setState(() {
                              selectedTime = label;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isSelected ? Colors.yellow : Colors.grey[800],
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.yellow,
                            ),
                          ),
                        );
                      }).toList(),
                ),
                const SizedBox(height: 20),

                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "ALL INVENTORY",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    Row(
                      children: [
                        _buildSmallSwitchButton("Food"),
                        const SizedBox(width: 8),
                        _buildSmallSwitchButton("Beverages"),
                        const SizedBox(width: 8),
                        _buildSmallSwitchButton("Package"),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: _buildDataTable(
                    selectedCategory == 'Package'
                        ? 'FandBPackage'
                        : selectedCategory,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            bottom: 16,
            child: FloatingActionButton(
              backgroundColor: Colors.yellow,
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) {
                    return DraggableScrollableSheet(
                      initialChildSize: 0.85,
                      maxChildSize: 0.95,
                      minChildSize: 0.5,
                      expand: false,
                      builder: (_, scrollController) {
                        return Container(
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                          ),
                          child: InventoryInputScreen(
                            scrollController: scrollController,
                          ),
                        );
                      },
                    );
                  },
                );
              },
              child: const Icon(Icons.filter_alt, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopTab(String label, bool selected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? Colors.yellow : Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: selected ? Colors.black : Colors.white),
      ),
    );
  }

  Widget _buildSmallSwitchButton(String label) {
    final isSelected = selectedCategory == label;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          selectedCategory = label;
        });
      },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        textStyle: const TextStyle(fontSize: 12),
        backgroundColor: isSelected ? Colors.yellow : Colors.grey[800],
      ),
      child: Text(
        label,
        style: TextStyle(color: isSelected ? Colors.black : Colors.white),
      ),
    );
  }

  Widget _buildDataTable(String collectionName) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collectionName).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        final docs = snapshot.data!.docs;

        final columns =
            collectionName == 'FandBPackage'
                ? const [
                  "Name",
                  "Qty",
                  "Size",
                  "Status",
                  "Unit Price",
                  "Provider",
                  "Min Qty",
                ]
                : const [
                  "Name",
                  "Qty",
                  "Size",
                  "Status",
                  "Unit Price",
                  "Provider Price",
                  "Exp Date",
                ];

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(Colors.grey[850]),
            dataRowColor: MaterialStateProperty.all(Colors.black),
            columns:
                columns
                    .map(
                      (col) => DataColumn(
                        label: Text(
                          col,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    )
                    .toList(),
            rows:
                docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  final name =
                      data['package_name'] ??
                      data['foodname'] ??
                      data['bevname'] ??
                      '-';
                  final qty =
                      data['package_quantity'] ??
                      data['foodquantity'] ??
                      data['bevquantity'] ??
                      '-';
                  final size = data['size']?.toString() ?? '-';
                  final status = data['fbstatus']?.toString() ?? '-';
                  final unitPrice =
                      data['unit_price'] != null
                          ? 'RM ${data['unit_price']}'
                          : '-';

                  if (collectionName == 'FandBPackage') {
                    final providerFBData = data['providerFB'];
                    final provider =
                        providerFBData is List
                            ? providerFBData.join(', ')
                            : providerFBData?.toString() ?? '-';

                    final minQty = data['min_quantity']?.toString() ?? '-';

                    return DataRow(
                      onSelectChanged: (selected) {
                        if (selected == true) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => InventoryEditScreen(
                                    existingData: data,
                                    documentId: doc.id,
                                    categoryType: collectionName,
                                  ),
                            ),
                          );
                        }
                      },
                      cells: [
                        DataCell(
                          Text(
                            name,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        DataCell(
                          Center(
                            child: Text(
                              qty.toString(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 80,
                            child: Center(
                              child: Text(
                                size,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Center(
                            child: Text(
                              status,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        DataCell(
                          Center(
                            child: Text(
                              unitPrice,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        DataCell(
                          Center(
                            child: Text(
                              provider,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        DataCell(
                          Center(
                            child: Text(
                              minQty,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  } else {
                    final providerPrice =
                        data['provider_price'] != null
                            ? 'RM ${data['provider_price']}'
                            : '-';
                    final expDate =
                        data['exp_date'] is Timestamp
                            ? (data['exp_date'] as Timestamp)
                                .toDate()
                                .toString()
                                .split(' ')[0]
                            : '-';

                    return DataRow(
                      onSelectChanged: (selected) {
                        if (selected == true) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => InventoryEditScreen(
                                    existingData: data,
                                    documentId: doc.id,
                                    categoryType: collectionName,
                                  ),
                            ),
                          );
                        }
                      },
                      cells: [
                        DataCell(
                          Text(
                            name,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        DataCell(
                          Center(
                            child: Text(
                              qty.toString(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 80,
                            child: Center(
                              child: Text(
                                size,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Center(
                            child: Text(
                              status,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        DataCell(
                          Center(
                            child: Text(
                              unitPrice,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        DataCell(
                          Center(
                            child: Text(
                              providerPrice,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        DataCell(
                          Center(
                            child: Text(
                              expDate,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                }).toList(),
          ),
        );
      },
    );
  }
}

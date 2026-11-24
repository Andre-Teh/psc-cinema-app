import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderDataManagementPage extends StatelessWidget {
  const OrderDataManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          "Order Data",
          style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection("order_data")
                .snapshots(), // Use "order_data" here
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.yellow),
            );
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final docs = snapshot.data!.docs;
          double totalPrice = 0.0;

          // Calculate total price of all orders
          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            totalPrice += (data["finalPrice"] ?? 0.0);
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Display total price at the top
                Text(
                  "Total Price: \$${totalPrice.toStringAsFixed(2)}",
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 16),
                // Wrap the DataTable in a SingleChildScrollView to allow both horizontal and vertical scrolling
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical, // Enable vertical scrolling
                    child: SingleChildScrollView(
                      scrollDirection:
                          Axis.horizontal, // Enable horizontal scrolling
                      child: DataTable(
                        columnSpacing: 12,
                        columns: const [
                          DataColumn(
                            label: Text(
                              "Order ID",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              "Movie Title",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              "Cinema",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              "Showtime",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              "Seats",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              "Food Items",
                              style: TextStyle(color: Colors.white),
                            ),
                          ), // New column for Food Items
                          DataColumn(
                            label: Text(
                              "Final Price",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              "Status",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                        rows:
                            docs.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final docId = doc.id;
                              final seatList = (data['seats'] as List).join(
                                ", ",
                              ); // Combine all seat values
                              final foodItemsList = (data['foodItems'] as List)
                                  .map((item) {
                                    return "${item['title']} (x${item['quantity']}) - \$${item['total']}";
                                  })
                                  .join(", "); // Format foodItems as a string

                              return DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      data["orderID"] ?? "N/A",
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      data["movieTitle"] ?? "N/A",
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      data["cinema"] ?? "N/A",
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      data["showtime"] ?? "N/A",
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      seatList,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      foodItemsList,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ), // Display food items
                                  DataCell(
                                    Text(
                                      "\$${data["finalPrice"] ?? 0}",
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      data["status"] ?? "N/A",
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                                onSelectChanged: (_) {
                                  _showEditDialog(context, docId, data);
                                },
                              );
                            }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    String docId,
    Map<String, dynamic> data,
  ) {
    final orderIdController = TextEditingController(text: data["orderID"]);
    final movieTitleController = TextEditingController(
      text: data["movieTitle"],
    );
    final cinemaController = TextEditingController(text: data["cinema"]);
    final showtimeController = TextEditingController(text: data["showtime"]);
    final seatsController = TextEditingController(
      text: (data["seats"] as List).join(", "),
    );
    final finalPriceController = TextEditingController(
      text: data["finalPrice"].toString(),
    );
    final statusController = TextEditingController(text: data["status"]);

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text(
              "Edit Order Data",
              style: TextStyle(color: Colors.white),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField("Order ID", orderIdController),
                  _buildTextField("Movie Title", movieTitleController),
                  _buildTextField("Cinema", cinemaController),
                  _buildTextField("Showtime", showtimeController),
                  _buildTextField("Seats", seatsController),
                  _buildTextField(
                    "Final Price",
                    finalPriceController,
                    inputType: TextInputType.number,
                  ),
                  _buildTextField("Status", statusController),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow),
                onPressed: () {
                  FirebaseFirestore.instance
                      .collection("order_data")
                      .doc(docId)
                      .update({
                        "orderID": orderIdController.text.trim(),
                        "movieTitle": movieTitleController.text.trim(),
                        "cinema": cinemaController.text.trim(),
                        "showtime": showtimeController.text.trim(),
                        "seats":
                            seatsController.text
                                .split(", ")
                                .map((e) => e.trim())
                                .toList(),
                        "finalPrice":
                            double.tryParse(finalPriceController.text.trim()) ??
                            0,
                        "status": statusController.text.trim(),
                      });
                  Navigator.pop(context);
                },
                child: const Text(
                  "Save",
                  style: TextStyle(color: Colors.black),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                onPressed: () {
                  FirebaseFirestore.instance
                      .collection("order_data")
                      .doc(docId)
                      .delete();
                  Navigator.pop(context);
                },
                child: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType inputType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        keyboardType: inputType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white24),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.yellow),
          ),
        ),
      ),
    );
  }
}
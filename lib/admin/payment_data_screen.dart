import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentDataManagementPage extends StatelessWidget {
  const PaymentDataManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          "Payment Data",
          style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance.collection("Payment_Data").snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.yellow),
            );
          }

          final docs = snapshot.data!.docs;
          double totalPrice = 0.0;

          // Calculate total price
          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            totalPrice += (data["TotalPrice"] ?? 0.0);
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Display total price at the top
                Text(
                  "Total Price:\R\M ${totalPrice.toStringAsFixed(2)}",
                  style: const TextStyle(color: Colors.red, fontSize: 18),
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
                              "Payment ID",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              "Order ID",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              "Payment Method",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              "Bank Holder Name",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              "Card Holder",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              "Card Number",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              "Email",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              "Order Description",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              "Status",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              "Total Price",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                        rows:
                            docs.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final docId = doc.id;

                              return DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      data["PaymentID"] ?? "N/A",
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      data["OrderID"] ?? "N/A",
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      data["PaymentMethod"] ?? "N/A",
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      data["BankHolderName"] ?? "N/A",
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      data["Card_Holder"] ?? "N/A",
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      data["Card_Number"] ?? "N/A",
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      data["Email"] ?? "N/A",
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      data["OrderDescription"] ?? "N/A",
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      data["Status"] ?? "N/A",
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      "\R\M${data["TotalPrice"] ?? 0}",
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
    final paymentIdController = TextEditingController(text: data["PaymentID"]);
    final orderIdController = TextEditingController(text: data["OrderID"]);
    final paymentMethodController = TextEditingController(
      text: data["PaymentMethod"],
    );
    final bankHolderController = TextEditingController(
      text: data["BankHolderName"],
    );
    final cardHolderController = TextEditingController(
      text: data["Card_Holder"],
    );
    final cardNumberController = TextEditingController(
      text: data["Card_Number"],
    );
    final emailController = TextEditingController(text: data["Email"]);
    final orderDescController = TextEditingController(
      text: data["OrderDescription"],
    );
    final statusController = TextEditingController(text: data["Status"]);
    final totalPriceController = TextEditingController(
      text: data["TotalPrice"].toString(),
    );

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text(
              "Edit Payment Data",
              style: TextStyle(color: Colors.white),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField("Payment ID", paymentIdController),
                  _buildTextField("Order ID", orderIdController),
                  _buildTextField("Payment Method", paymentMethodController),
                  _buildTextField("Bank Holder Name", bankHolderController),
                  _buildTextField("Card Holder", cardHolderController),
                  _buildTextField("Card Number", cardNumberController),
                  _buildTextField("Email", emailController),
                  _buildTextField("Order Description", orderDescController),
                  _buildTextField("Status", statusController),
                  _buildTextField(
                    "Total Price",
                    totalPriceController,
                    inputType: TextInputType.number,
                  ),
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
                      .collection("Payment_Data")
                      .doc(docId)
                      .update({
                        "PaymentID": paymentIdController.text.trim(),
                        "OrderID": orderIdController.text.trim(),
                        "PaymentMethod": paymentMethodController.text.trim(),
                        "BankHolderName": bankHolderController.text.trim(),
                        "Card_Holder": cardHolderController.text.trim(),
                        "Card_Number": cardNumberController.text.trim(),
                        "Email": emailController.text.trim(),
                        "OrderDescription": orderDescController.text.trim(),
                        "Status": statusController.text.trim(),
                        "TotalPrice":
                            double.tryParse(totalPriceController.text.trim()) ??
                            0,
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
                      .collection("Payment_Data")
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
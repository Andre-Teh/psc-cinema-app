import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class TicketPerformanceScreen extends StatefulWidget {
  const TicketPerformanceScreen({super.key});

  @override
  State<TicketPerformanceScreen> createState() =>
      _TicketPerformanceScreenState();
}

class _TicketPerformanceScreenState extends State<TicketPerformanceScreen> {
  Map<String, int> ticketTypeCounts = {};
  bool isLoading = true;
  int totalTickets = 0;
  double totalAmount = 0.0;

  final Map<String, double> ticketPrices = {
    'SINGLE TICKET': 12.0,
    'CHILD': 8.0,
    'STUDENT': 10.0,
    'SENIOR': 6.0,
    'OKU': 5.0,
  };

  @override
  void initState() {
    super.initState();
    loadTicketTypeReport();
  }

  Future<void> loadTicketTypeReport() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('order_data')
            .where('status', isEqualTo: 'PAID')
            .get();

    final Map<String, int> counts = {};
    int total = 0;
    double amount = 0.0;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final List<dynamic>? foodItems = data['foodItems'];
      final List<dynamic>? discounts = data['enableDiscounts'];

      // 处理 enableDiscounts 里的票（如 STUDENT, SENIOR）
      if (discounts != null) {
        for (var item in discounts) {
          final type = (item['type'] ?? '').toString();
          final quantityRaw = item['quantity'] ?? 0;
          final quantity =
              quantityRaw is int ? quantityRaw : (quantityRaw as num).toInt();

          final upperType = type.toUpperCase();

          if (upperType.contains('CHILD') ||
              upperType.contains('STUDENT') ||
              upperType.contains('SENIOR') ||
              upperType.contains('OKU')) {
            counts[type] = (counts[type] ?? 0) + quantity;
            total += quantity;

            final matchedPrice =
                ticketPrices.entries
                    .firstWhere(
                      (e) => upperType.contains(e.key),
                      orElse: () => const MapEntry('UNKNOWN', 0.0),
                    )
                    .value;

            amount += matchedPrice * quantity;
          }
        }
      }

      if (foodItems != null) {
        for (var item in foodItems) {
          final title = (item['title'] ?? '').toString();
          final quantityRaw = item['quantity'] ?? 0;
          final quantity =
              quantityRaw is int ? quantityRaw : (quantityRaw as num).toInt();

          final upperTitle = title.toUpperCase();

          if (upperTitle.contains('CHILD') ||
              upperTitle.contains('STUDENT') ||
              upperTitle.contains('SENIOR') ||
              upperTitle.contains('OKU') ||
              upperTitle.contains('SINGLE TICKET')) {
            counts[title] = (counts[title] ?? 0) + quantity;
            total += quantity;

            final matchedPrice =
                ticketPrices.entries
                    .firstWhere(
                      (e) => upperTitle.contains(e.key),
                      orElse: () => const MapEntry('UNKNOWN', 0.0),
                    )
                    .value;

            amount += matchedPrice * quantity;
          }
        }
      }
    }

    setState(() {
      ticketTypeCounts = counts;
      totalTickets = total;
      totalAmount = amount;
      isLoading = false;
    });
  }

  Future<void> generatePdfReport() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build:
            (context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  "Ticket Type Report",
                  style: pw.TextStyle(fontSize: 24),
                ),
                pw.SizedBox(height: 12),
                pw.Text(
                  "Total Amount: RM ${totalAmount.toStringAsFixed(2)}",
                  style: pw.TextStyle(fontSize: 14),
                ),
                pw.Text(
                  "Total Tickets Sold: $totalTickets",
                  style: pw.TextStyle(fontSize: 14),
                ),
                pw.SizedBox(height: 16),
                pw.Table.fromTextArray(
                  headers: ['Type', 'Quantity', 'Amount (RM)'],
                  data:
                      ticketTypeCounts.entries.map((e) {
                        final matchedPrice =
                            ticketPrices.entries
                                .firstWhere(
                                  (p) => e.key.toUpperCase().contains(p.key),
                                  orElse: () => const MapEntry('UNKNOWN', 0.0),
                                )
                                .value;
                        final subtotal = matchedPrice * e.value;
                        return [
                          e.key,
                          e.value.toString(),
                          subtotal.toStringAsFixed(2),
                        ];
                      }).toList(),
                ),
              ],
            ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Ticket Type Report',
          style: TextStyle(color: Colors.white),
        ),
        leading: const BackButton(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
            onPressed: ticketTypeCounts.isNotEmpty ? generatePdfReport : null,
          ),
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Total Amount: RM ${totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.amber, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Total Tickets Sold: $totalTickets',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  ...ticketTypeCounts.entries.map((entry) {
                    final matchedPrice =
                        ticketPrices.entries
                            .firstWhere(
                              (e) => entry.key.toUpperCase().contains(e.key),
                              orElse: () => const MapEntry('UNKNOWN', 0.0),
                            )
                            .value;
                    final subtotal = matchedPrice * entry.value;

                    return Card(
                      color: Colors.grey[900],
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        title: Text(
                          entry.key,
                          style: const TextStyle(color: Colors.white),
                        ),
                        trailing: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${entry.value} tickets',
                              style: const TextStyle(color: Colors.amber),
                            ),
                            Text(
                              'RM ${subtotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
    );
  }
}

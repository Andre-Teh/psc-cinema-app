import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class FandBReportScreen extends StatefulWidget {
  const FandBReportScreen({super.key});

  @override
  State<FandBReportScreen> createState() => _FandBReportScreenState();
}

class _FandBReportScreenState extends State<FandBReportScreen> {
  List<Map<String, dynamic>> fbReport = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadFBReport();
  }

  Future<void> loadFBReport() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('order_data')
            .where('status', isEqualTo: 'PAID')
            .get();

    final Map<String, Map<String, dynamic>> foodSales = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final List<dynamic>? foodItems = data['foodItems'];

      if (foodItems != null) {
        for (var item in foodItems) {
          final title = (item['title'] ?? '').toString();
          final quantityRaw = item['quantity'] ?? 0;
          final priceRaw = item['price'] ?? 0;

          final quantity =
              quantityRaw is int ? quantityRaw : (quantityRaw as num).toInt();
          final price = priceRaw is num ? priceRaw.toDouble() : 0.0;

          if (title.toLowerCase().contains('ticket') ||
              title.toLowerCase().contains('child') ||
              title.toLowerCase().contains('student') ||
              title.toLowerCase().contains('senior'))
            continue;

          if (!foodSales.containsKey(title)) {
            foodSales[title] = {
              'title': title,
              'quantity': 0,
              'totalPrice': 0.0,
            };
          }

          foodSales[title]!['quantity'] += quantity;
          foodSales[title]!['totalPrice'] += quantity * price;
        }
      }
    }

    final sortedItems =
        foodSales.values.toList()
          ..sort((a, b) => b['quantity'].compareTo(a['quantity']));

    setState(() {
      fbReport = sortedItems;
      isLoading = false;
    });
  }

  Future<void> generatePdfReport() async {
    final pdf = pw.Document();

    final totalSold = fbReport.fold<int>(
      0,
      (sum, item) => sum + (item['quantity'] as int),
    );
    final totalRevenue = fbReport.fold<double>(
      0.0,
      (sum, item) => sum + (item['totalPrice'] as double),
    );

    pdf.addPage(
      pw.Page(
        pageTheme: pw.PageTheme(
          theme: pw.ThemeData.withFont(
            base: await PdfGoogleFonts.robotoRegular(),
            bold: await PdfGoogleFonts.robotoBold(),
          ),
        ),
        build:
            (pw.Context context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text("F&B Sales Report", style: pw.TextStyle(fontSize: 24)),
                pw.SizedBox(height: 8),
                pw.Text(
                  "Total Revenue: RM ${totalRevenue.toStringAsFixed(2)}",
                  style: pw.TextStyle(fontSize: 14),
                ),
                pw.Text(
                  "Total Quantity Sold: $totalSold",
                  style: pw.TextStyle(fontSize: 14),
                ),
                pw.SizedBox(height: 16),
                pw.Table.fromTextArray(
                  headers: ['Item', 'Quantity Sold', 'Total (RM)'],
                  data:
                      fbReport
                          .map(
                            (item) => [
                              item['title'],
                              item['quantity'].toString(),
                              item['totalPrice'].toStringAsFixed(2),
                            ],
                          )
                          .toList(),
                ),
              ],
            ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalSold = fbReport.fold<int>(
      0,
      (sum, item) => sum + (item['quantity'] as int),
    );
    final totalRevenue = fbReport.fold<double>(
      0.0,
      (sum, item) => sum + (item['totalPrice'] as double),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("F&B Report", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
            onPressed: fbReport.isNotEmpty ? generatePdfReport : null,
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Revenue: RM ${totalRevenue.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Total Quantity Sold: $totalSold',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: fbReport.length,
                      itemBuilder: (context, index) {
                        final item = fbReport[index];
                        return Card(
                          color: Colors.grey[900],
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ListTile(
                            title: Text(
                              item['title'],
                              style: const TextStyle(color: Colors.white),
                            ),
                            trailing: Text(
                              '${item['quantity']} sold (RM ${item['totalPrice'].toStringAsFixed(2)})',
                              style: const TextStyle(color: Colors.amber),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class MovieReportScreen extends StatefulWidget {
  const MovieReportScreen({super.key});

  @override
  State<MovieReportScreen> createState() => _MovieReportScreenState();
}

class _MovieReportScreenState extends State<MovieReportScreen> {
  List<Map<String, dynamic>> movieReport = [];
  bool isLoading = true;
  double totalRevenue = 0.0;

  @override
  void initState() {
    super.initState();
    loadMovieReport();
  }

  Future<void> loadMovieReport() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('order_data')
            .where('status', isEqualTo: 'PAID')
            .get();

    final reportMap = <String, Map<String, dynamic>>{};
    double sumRevenue = 0.0;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final title = data['movieTitle'] ?? 'Unknown';
      final seatCount = (data['seats'] as List?)?.length ?? 0;

      final rawTotal = data['finalPrice'] ?? data['total'] ?? 0.0;
      double amount = 0.0;
      if (rawTotal is int) {
        amount = rawTotal.toDouble();
      } else if (rawTotal is double) {
        amount = rawTotal;
      } else if (rawTotal is String) {
        amount = double.tryParse(rawTotal) ?? 0.0;
      }

      sumRevenue += amount;

      if (!reportMap.containsKey(title)) {
        reportMap[title] = {
          'movieTitle': title,
          'totalTickets': 0,
          'totalRevenue': 0.0,
        };
      }

      reportMap[title]!['totalTickets'] += seatCount;
      reportMap[title]!['totalRevenue'] += amount;
    }

    setState(() {
      movieReport = reportMap.values.toList();
      totalRevenue = sumRevenue;
      isLoading = false;
    });
  }

  Future<void> generatePdfReport() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Export PDF Report"),
            content: const Text(
              "Do you want to generate and download the movie report as a PDF?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text("Confirm"),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build:
            (pw.Context context) => pw.Padding(
              padding: const pw.EdgeInsets.all(24),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    "Movie Sales Report",
                    style: pw.TextStyle(fontSize: 24),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    "Total Revenue: RM ${totalRevenue.toStringAsFixed(2)}",
                    style: pw.TextStyle(fontSize: 14),
                  ),
                  pw.SizedBox(height: 16),
                  pw.Table.fromTextArray(
                    headers: ['Title', 'Tickets Sold', 'Revenue (RM)'],
                    data:
                        movieReport.map((movie) {
                          return [
                            movie['movieTitle'],
                            movie['totalTickets'].toString(),
                            movie['totalRevenue'].toStringAsFixed(2),
                          ];
                        }).toList(),
                  ),
                  pw.SizedBox(height: 24),
                  pw.Text(
                    "Generated on: ${DateTime.now().toLocal().toString().split('.')[0]}",
                    style: pw.TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Movie Report",
          style: TextStyle(color: Colors.white),
        ),
        leading: const BackButton(color: Colors.white),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
            onPressed: movieReport.isNotEmpty ? generatePdfReport : null,
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Total Revenue:",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        Text(
                          "RM ${totalRevenue.toStringAsFixed(2)}",
                          style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: movieReport.length,
                      itemBuilder: (context, index) {
                        final movie = movieReport[index];
                        return Card(
                          color: Colors.grey[900],
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ListTile(
                            title: Text(
                              movie['movieTitle'],
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              'Tickets: ${movie['totalTickets']} | Revenue: RM ${movie['totalRevenue'].toStringAsFixed(2)}',
                              style: const TextStyle(color: Colors.white70),
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

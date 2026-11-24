import 'package:flutter/material.dart';
import 'package:psc_cinema_app/manager/manger_dashboard.dart';
import 'DailyReportScreen.dart';
import 'MovieReportScreen.dart';
import 'FandBReportScreen.dart';
import 'ticketPerformanceScreen.dart';

class ReportSelectionScreen extends StatefulWidget {
  const ReportSelectionScreen({super.key});

  @override
  State<ReportSelectionScreen> createState() => _ReportSelectionScreenState();
}

class _ReportSelectionScreenState extends State<ReportSelectionScreen> {
  String? selectedTitle;
  String? hoveredTitle;

  final List<_ReportItem> reportItems = [
    _ReportItem(title: 'Daily Report', icon: Icons.calendar_today),
    _ReportItem(title: 'Movie Report', icon: Icons.movie),
    _ReportItem(title: 'F&B Report', icon: Icons.fastfood),
    _ReportItem(title: 'Ticket Types', icon: Icons.confirmation_num),
    _ReportItem(title: 'Customer', icon: Icons.people),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'REPORT CENTER',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const MangerDashboard()),
              (route) => false,
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children:
              reportItems.map((item) {
                final isSelected = item.title == selectedTitle;
                final isHovered = item.title == hoveredTitle;

                return MouseRegion(
                  onEnter: (_) {
                    setState(() {
                      hoveredTitle = item.title;
                    });
                  },
                  onExit: (_) {
                    setState(() {
                      hoveredTitle = null;
                    });
                  },
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedTitle = item.title;
                      });

                      switch (item.title) {
                        case 'Daily Report':
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const DailyReportScreen(),
                            ),
                          );
                          break;
                        case 'Movie Report':
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MovieReportScreen(),
                            ),
                          );
                          break;
                        case 'F&B Report':
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const FandBReportScreen(),
                            ),
                          );

                          break;
                        case 'Ticket Types':
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => const TicketPerformanceScreen(),
                            ),
                          );
                          break;
                        case 'Customer':
                          // TODO: Add navigation
                          break;
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.yellow : Colors.white10,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow:
                            (isSelected || isHovered)
                                ? [BoxShadow(color: Colors.yellow)]
                                : [],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(item.icon, color: Colors.white, size: 36),
                          const SizedBox(height: 10),
                          Text(
                            item.title.toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }
}

class _ReportItem {
  final String title;
  final IconData icon;

  const _ReportItem({required this.title, required this.icon});
}

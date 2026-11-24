import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';

class StaffDashboardPage extends StatelessWidget {
  final Map<String, double> dataMap = {"3": 12, "2": 7, "4": 1, "Break": 1};

  final List<Color> colorList = [
    Colors.black,
    Colors.grey[800]!,
    Colors.grey[400]!,
    Colors.grey[300]!,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 1,
        title: const Text(
          'Staff Management',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.yellow,
                side: const BorderSide(color: Colors.yellow),
              ),
              child: const Text("PDF", style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                _TabButton(title: "OVERALL", isActive: true),
                _TabButton(title: "ATTENDANCE", isActive: false),
                _TabButton(title: "SCHEDULE", isActive: false),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              "TODAY ATTENDANCE",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                decoration: TextDecoration.underline,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Present      12/20",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                        SizedBox(height: 6),
                        Text(
                          "Absent       8/20",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                        SizedBox(height: 6),
                        Text(
                          "Late            2/20",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 140,
                      height: 140,
                      child: CircularProgressIndicator(
                        value: 0.82,
                        strokeWidth: 12,
                        backgroundColor: Colors.grey[700],
                        color: Colors.yellow,
                      ),
                    ),
                    const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "82%",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          "Attendance",
                          style: TextStyle(fontSize: 14, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.yellow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                "VIEW ATTENDANCE",
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              "TODAY POSITION",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                decoration: TextDecoration.underline,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      dataMap: dataMap,
                      colorList: colorList,
                      chartRadius: 110,
                      chartType: ChartType.disc,
                      legendOptions: const LegendOptions(showLegends: false),
                      chartValuesOptions: const ChartValuesOptions(
                        showChartValues: false,
                      ),
                    ),
                    const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "3",
                          style: TextStyle(fontSize: 20, color: Colors.white),
                        ),
                        Text(
                          "2",
                          style: TextStyle(fontSize: 20, color: Colors.white),
                        ),
                        Text(
                          "4",
                          style: TextStyle(fontSize: 20, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Position        12/20",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      Text(
                        "Position        7/20",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      Text(
                        "Position        1/20",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      Text(
                        "Break            1/20",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              "Today Schedule Percentage : 100%",
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.yellow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                "VIEW SCHEDULE & POSITION",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String title;
  final bool isActive;

  const _TabButton({required this.title, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isActive ? Colors.black : Colors.transparent,
        border: Border.all(color: Colors.white),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        title,
        style: TextStyle(color: isActive ? Colors.white : Colors.white),
      ),
    );
  }
}

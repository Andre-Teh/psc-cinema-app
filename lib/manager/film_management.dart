import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'manger_dashboard.dart';
import 'filmList.dart';
import 'shcedule_view.dart';
import 'addfilm.dart';
import 'ticketPerformanceScreen.dart';
import 'filmOverallList.dart';

class FilmManagement extends StatefulWidget {
  const FilmManagement({super.key});

  @override
  State<FilmManagement> createState() => _FilmManagementState();
}

class _FilmManagementState extends State<FilmManagement> {
  int todayPerformance = 0;
  String hotFilmTitle = "Loading...";
  int hotFilmPercentage = 0;
  int completedToday = 0;
  int showingToday = 0;
  int preparingToday = 0;
  int totalToday = 0;

  @override
  void initState() {
    super.initState();
    loadTodayPerformance();
    loadHotFilm();
    loadTodayShowtimeStats();
  }

  Future<void> loadTodayPerformance() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final snapshot =
        await FirebaseFirestore.instance
            .collection('order_data')
            .where('status', isEqualTo: 'PAID')
            .get();

    int totalSeats = 0;
    for (var doc in snapshot.docs) {
      final timestamp = doc['createdAt'] as Timestamp?;
      final seatCount =
          (doc['seatCount'] is num) ? (doc['seatCount'] as num).toInt() : 0;
      if (timestamp != null) {
        final orderDate = DateFormat('yyyy-MM-dd').format(timestamp.toDate());
        if (orderDate == today) {
          totalSeats += seatCount;
        }
      }
    }

    setState(() {
      todayPerformance = totalSeats;
    });
  }

  Future<void> loadHotFilm() async {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final snapshot =
        await FirebaseFirestore.instance
            .collection('order_data')
            .where('status', isEqualTo: 'PAID')
            .get();

    Map<String, int> filmCount = {};
    for (var doc in snapshot.docs) {
      final timestamp = doc['createdAt'] as Timestamp?;
      final movie = doc['movieTitle'];
      final seats =
          (doc['seatCount'] is num) ? (doc['seatCount'] as num).toInt() : 0;

      if (timestamp != null && timestamp.toDate().isAfter(weekAgo)) {
        filmCount[movie] = (filmCount[movie] ?? 0) + seats;
      }
    }

    String topFilm = '';
    int topCount = 0;
    int totalCount = 0;
    filmCount.forEach((title, count) {
      totalCount += count;
      if (count > topCount) {
        topFilm = title;
        topCount = count;
      }
    });

    setState(() {
      hotFilmTitle = topFilm.isEmpty ? 'No Data' : topFilm;
      hotFilmPercentage =
          totalCount == 0 ? 0 : ((topCount / totalCount) * 100).round();
    });
  }

  Future<void> loadTodayShowtimeStats() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final snapshot = await FirebaseFirestore.instance.collection('films').get();
    final films = snapshot.docs.map((doc) => Film.fromDoc(doc)).toList();
    List<_ShowTimeEntry> entries = [];

    for (var film in films) {
      for (var show in film.showTimes) {
        if (show is Map<String, dynamic>) {
          final ts = show['datetime'] as Timestamp?;
          if (ts != null) {
            final date = ts.toDate();
            if (date.year == today.year &&
                date.month == today.month &&
                date.day == today.day) {
              entries.add(
                _ShowTimeEntry(
                  fid: film.fid,
                  title: film.filmsTitle,
                  datetime: date,
                  hall: show['hall'] ?? '',
                  durationMinutes: film.filmsDuration,
                ),
              );
            }
          }
        }
      }
    }

    int completed = 0, showing = 0, preparing = 0;
    for (var entry in entries) {
      final status = getShowTimeStatus(entry);
      if (status == ShowTimeStatus.completed) completed++;
      if (status == ShowTimeStatus.showing) showing++;
      if (status == ShowTimeStatus.preparing) preparing++;
    }

    setState(() {
      completedToday = completed;
      showingToday = showing;
      preparingToday = preparing;
      totalToday = entries.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          "Film Management",
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _TabButton(label: "OVERALL", onPressed: () {}),
              _TabButton(
                label: "View Schedule",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ScheduleScreen()),
                  );
                },
              ),
              _TabButton(
                label: "Add Film",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddFilmPage()),
                  );
                },
              ),
              _TabButton(
                label: "Edit Film",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MovieListScreen()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "HOT FILMS",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        hotFilmTitle,
                        style: const TextStyle(color: Colors.white),
                      ),
                      Text(
                        "$hotFilmPercentage% of week ticket",
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: Colors.white24,
                      child: Text(
                        "$todayPerformance",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Text(
                      "Today Film Performance",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              "Today Show",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _NumberStat(
                title: "Completed",
                value: "$completedToday / $totalToday",
              ),
              _NumberStat(title: "Showing", value: "$showingToday"),
              _NumberStat(title: "Preparing", value: "$preparingToday"),
            ],
          ),
          const SizedBox(height: 16),

          // ✅ VIEW LIST & VIEW SCHEDULE BUTTONS
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MovieScheduleScreen(),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white),
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text("VIEW LIST"),
                ),
                OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ScheduleScreen()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white),
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text("VIEW SCHEDULE"),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Center(
            child: Text(
              "Ticket Performance",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: const [
              _NumberStat(title: "Today", value: "20"),
              _NumberStat(title: "Week", value: "140"),
              _NumberStat(title: "Months", value: "560"),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TicketPerformanceScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white24),
              child: const Text(
                "VIEW TICKET PERFORMANCE",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 🔘 Reusable Button
class _TabButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const _TabButton({required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.white),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white)),
    );
  }
}

class _NumberStat extends StatelessWidget {
  final String title;
  final String value;

  const _NumberStat({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}

// 🔘 Film Model
class Film {
  final String fid;
  final String filmsTitle;
  final List<dynamic> showTimes;
  final String status;
  final String bannerUrl;
  final int filmsDuration;

  Film({
    required this.fid,
    required this.filmsTitle,
    required this.showTimes,
    required this.status,
    required this.bannerUrl,
    required this.filmsDuration,
  });

  factory Film.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Film(
      fid: data['fid'] ?? '',
      filmsTitle: data['films_title'] ?? '',
      showTimes: data['show_times'] ?? [],
      status: data['status'] ?? '',
      bannerUrl: data['banner_url'] ?? '',
      filmsDuration: data['films_duration'] ?? 90,
    );
  }
}

class _ShowTimeEntry {
  final String fid;
  final String title;
  final DateTime datetime;
  final String hall;
  final int durationMinutes;

  _ShowTimeEntry({
    required this.fid,
    required this.title,
    required this.datetime,
    required this.hall,
    required this.durationMinutes,
  });
}

enum ShowTimeStatus { completed, showing, preparing, comingSoon }

ShowTimeStatus getShowTimeStatus(_ShowTimeEntry entry) {
  final now = DateTime.now();
  final start = entry.datetime;
  final end = start.add(Duration(minutes: entry.durationMinutes));
  final diff = start.difference(now);

  if (now.isAfter(end)) return ShowTimeStatus.completed;
  if (now.isAfter(start) && now.isBefore(end)) return ShowTimeStatus.showing;
  if (diff.inMinutes <= 10 && !diff.isNegative) return ShowTimeStatus.preparing;
  return ShowTimeStatus.comingSoon;
}

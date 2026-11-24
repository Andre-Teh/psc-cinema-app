import 'package:flutter/material.dart';
import 'trailer_player.dart';
import 'seat_selection_screen.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '/src/loading.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MoviesDetailsScreen extends StatefulWidget {
  final String movieTitle;
  final String movieDescription;
  final String moviePosterUrl;
  final String movieBannerUrl;
  final String movieCategory;
  final String movieDuration;
  final String movieLanguage;
  final String moviePosterPath;
  final String movieBannerPath;
  final String fid;

  MoviesDetailsScreen({
    Key? key,
    required this.movieTitle,
    this.movieDescription = 'Default movie description',
    this.moviePosterUrl = '',
    required this.movieBannerUrl,
    required this.movieCategory,
    required this.movieDuration,
    required this.movieLanguage,
    required this.moviePosterPath,
    required this.movieBannerPath,
    required this.fid,
  }) : super(key: key);

  @override
  State<MoviesDetailsScreen> createState() => _MoviesDetailsScreenState();
}

class _MoviesDetailsScreenState extends State<MoviesDetailsScreen> {
  String selectedLocation = "KLANG VALLEY";
  String tempSelectedLocation = "KLANG VALLEY";
  bool rememberLocation = false;
  String? expandedCinema;
  List<DateInfo> weeklyDates = [];
  int selectedDateIndex = 0;

  final Map<String, Map<String, List<String>>> allShowtimes = {};

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    generateWeekDates();
    fetchUserAreaAndSetLocation();
    fetchShowtimesFromFirestore();
  }

  void generateWeekDates() {
    final now = DateTime.now();
    final todayWeekday = now.weekday;
    final monday = now.subtract(Duration(days: todayWeekday - 1));

    weeklyDates = List.generate(14, (index) {
      final date = monday.add(Duration(days: index));
      final weekday = DateFormat('E').format(date).toUpperCase(); // "MON"
      final day = date.day.toString().padLeft(2, '0');
      final month = _monthToUppercase(date.month);
      final label = "$weekday\n$day $month";
      final firestoreKey = "$day $month";
      return DateInfo(label: label, firestoreKey: firestoreKey);
    });

    selectedDateIndex = now.difference(monday).inDays;
    setState(() {
      _isLoading = false;
    });
  }

  void fetchUserAreaAndSetLocation() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final uid = user.uid;
    final doc =
        await FirebaseFirestore.instance.collection('Client').doc(uid).get();

    final data = doc.data();
    if (data != null && data.containsKey('district')) {
      final area = (data['district'] ?? 'KLANG VALLEY').toString();

      setState(() {
        selectedLocation = area.toUpperCase();
        tempSelectedLocation = area.toUpperCase();
      });
    }
  }

  void fetchShowtimesFromFirestore() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('films')
            .doc(widget.fid)
            .get();

    final data = doc.data();
    if (data == null || !data.containsKey('show_times')) return;

    final List<dynamic> showTimes = data['show_times'];
    final List<dynamic> packageList = data['package'] ?? ['UNKNOWN'];

    // Normalize package list
    final List<String> packages =
        packageList.whereType<String>().map((p) => p.toUpperCase()).toList();

    Map<String, Map<String, List<String>>> parsedShowtimes = {};

    for (final item in showTimes) {
      final timestamp = item['datetime'] as Timestamp?;
      if (timestamp == null) continue;

      final date = timestamp.toDate();
      final formattedDate = DateFormat('dd MMM').format(date).toUpperCase();
      final time = DateFormat.jm().format(date);

      for (final pkg in packages) {
        parsedShowtimes.putIfAbsent(formattedDate, () => {});
        parsedShowtimes[formattedDate]!.putIfAbsent(pkg, () => []);
        parsedShowtimes[formattedDate]![pkg]!.add(time);
      }
    }

    setState(() {
      allShowtimes.clear();
      allShowtimes.addAll(parsedShowtimes);
    });
  }

  String _monthToUppercase(int month) {
    const monthNames = [
      "JAN",
      "FEB",
      "MAR",
      "APR",
      "MAY",
      "JUN",
      "JUL",
      "AUG",
      "SEP",
      "OCT",
      "NOV",
      "DEC",
    ];
    return monthNames[month - 1];
  }

  final List<String> nearestCinemas = [
    '1 SHAMELIN',
    'CHERAS SENTRAL',
    'SURIA KLCC',
    'AMPANG POINT',
  ];

  final List<String> klangValleyCinemas = [
    '1 UTAMA',
    'AU2 SETIAWANGSA',
    'BUKIT RAJA',
    'BUKIT TINGGI',
    'CENTRAL I-CITY',
    'CHERAS SELATAN',
    'DPULZE CYBERJAYA',
    'STRAND KOTA DAMANSARA',
    'JAYA SEKSYEN 14',
    'KEPONG',
    'MINES',
    'RAWANG',
    'SETIAWALK PUCHONG',
    'SUNWAY PUTRA',
    'SUNWAY PYRAMID',
  ];

  final Set<String> favoriteCinemas = {};

  void _showLocationDialog() {
    tempSelectedLocation = selectedLocation; // Reset temp selection
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          "SET YOUR PREFERRED STATE/AREA",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Experience what's around you",
                    style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      children: [
                        for (String area in [
                          "All States/Areas",
                          "Klang Valley",
                          "Johor",
                          "Perak",
                          "Pulau Pinang",
                          "Sarawak",
                          "Negeri Sembilan",
                          "Terengganu",
                        ])
                          ListTile(
                            title: Text(
                              area,
                              style: const TextStyle(color: Colors.white),
                            ),
                            trailing:
                                tempSelectedLocation == area
                                    ? const Icon(Icons.check, color: Colors.red)
                                    : null,
                            onTap: () {
                              setModalState(() {
                                tempSelectedLocation = area;
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: rememberLocation,
                        onChanged: (value) {
                          setModalState(() {
                            rememberLocation = value ?? false;
                          });
                        },
                        checkColor: Colors.black,
                        activeColor: Colors.white,
                      ),
                      const Text(
                        "Remember my state/area",
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Color(0xFFF5A6A6),
                            Color.fromARGB(255, 200, 137, 137),
                          ],
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(5),
                          topRight: Radius.circular(18),
                          bottomRight: Radius.circular(5),
                          bottomLeft: Radius.circular(18),
                        ),
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            selectedLocation = tempSelectedLocation;
                          });
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(5),
                              topRight: Radius.circular(18),
                              bottomRight: Radius.circular(5),
                              bottomLeft: Radius.circular(18),
                            ),
                          ),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 13),
                          child: Text(
                            "CONFIRM",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showMoreInfoDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: EdgeInsets.all(20),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Blood Brothers: Bara Naga\n\n"
                    "An action-packed drama that explores themes of loyalty, betrayal, and family ties. "
                    "Set in the gritty underworld, it follows the journey of two estranged brothers "
                    "as they navigate crime and redemption.",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        "Close",
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showTrailerDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: EdgeInsets.zero,
          child: AspectRatio(aspectRatio: 16 / 9, child: TrailerPlayer()),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: PulsingLogo());
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar
            Container(
              height: 60, // ⬅️ Adjust this value to make the top bar taller
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Row(
                      children: [
                        Icon(Icons.arrow_back, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          "BACK",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _showLocationDialog,
                    child: Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          selectedLocation,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Movie Poster & Info
            Container(
              height: 160,
              width: double.infinity,
              child:
                  widget.movieBannerUrl.isNotEmpty
                      ? Image.network(
                        widget.movieBannerUrl,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) => const Center(
                              child: Icon(
                                Icons.broken_image,
                                color: Colors.white,
                              ),
                            ),
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        },
                      )
                      : Container(color: Colors.grey),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.movieTitle,
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${widget.movieCategory} | ${widget.movieDuration} | ${widget.movieLanguage}',
                    style: TextStyle(color: Colors.white70),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _showMoreInfoDialog,
                        icon: Icon(Icons.info_outline),
                        label: Text("More Info"),
                      ),
                      SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _showTrailerDialog,
                        icon: Icon(Icons.play_arrow),
                        label: Text("Watch Trailer"),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Date Selector
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  double itemWidth = (constraints.maxWidth - 84) / 7;

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: weeklyDates.length,
                    itemBuilder: (context, index) {
                      final isSelected = index == selectedDateIndex;
                      return Container(
                        width: itemWidth,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        child: GestureDetector(
                          onTap:
                              () => setState(() => selectedDateIndex = index),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                weeklyDates[index].label,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.visible,
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      isSelected ? Colors.red : Colors.white70,
                                  fontWeight:
                                      isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                ),
                              ),

                              if (isSelected)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  height: 2,
                                  width: 20,
                                  color: Colors.red,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Cinema List
            Expanded(
              child: ListView(
                children: [
                  if (favoriteCinemas.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                      child: Text(
                        "MY FAVOURITES",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    ...favoriteCinemas
                        .map(
                          (cinema) => _buildCinemaTile(
                            cinema,
                            showtimes:
                                allShowtimes[weeklyDates[selectedDateIndex]
                                    .firestoreKey] ??
                                {},
                            isFavorite: true,
                          ),
                        )
                        .toList(),
                  ],

                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: Text(
                      "NEAREST TO YOU",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  ...nearestCinemas
                      .map(
                        (cinema) => _buildCinemaTile(
                          cinema,
                          showtimes:
                              allShowtimes[weeklyDates[selectedDateIndex]
                                  .firestoreKey] ??
                              {},
                        ),
                      )
                      .toList(),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: Text(
                      "KLANG VALLEY",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  ...klangValleyCinemas
                      .map(
                        (cinema) => _buildCinemaTile(
                          cinema,
                          showtimes:
                              allShowtimes[weeklyDates[selectedDateIndex]
                                  .firestoreKey] ??
                              {},
                        ),
                      )
                      .toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCinemaTile(
    String name, {
    required Map<String, List<String>> showtimes,
    bool isFavorite = false,
  }) {
    final isFav = favoriteCinemas.contains(name);
    final isExpanded = expandedCinema == name;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        backgroundColor: Colors.black,
        collapsedBackgroundColor: Colors.black,
        iconColor: Colors.white,
        collapsedIconColor: Colors.white,
        onExpansionChanged: (expanded) {
          setState(() {
            expandedCinema = expanded ? name : null;
          });
        },
        title: Row(
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  if (isFav) {
                    favoriteCinemas.remove(name);
                  } else {
                    favoriteCinemas.add(name);
                  }
                });
              },
              child: Icon(
                isFav ? Icons.favorite : Icons.favorite_border,
                color: isFav ? Colors.red : Colors.white,
                size: 18,
              ),
            ),
            SizedBox(width: 8),
            Text(
              name,
              style: TextStyle(
                color: isExpanded ? Colors.white : Colors.white60,
                fontWeight: isExpanded ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
        children: [
          _buildLegend(),
          ...showtimes.entries.map((entry) {
            final packageName = entry.key;
            final times = entry.value;
            final colorMap = {
              "INDULGE": Colors.purple,
              "DELUXE": Colors.red,
              "IMAX": Colors.blue,
              "FAMILY": Colors.orange,
              "BEANIE": Colors.green,
            };

            final color = colorMap[packageName] ?? Colors.grey;

            return _buildShowtimesSection(packageName, color, times);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Row(
        children: [
          _legendImage('assets/images/seat_available.png', "Available"),
          const SizedBox(width: 10),
          _legendImage('assets/images/seat_sellingfast.png', "Selling fast"),
          const SizedBox(width: 10),
          _legendImage('assets/images/seat_sold.png', "Sold out"),
        ],
      ),
    );
  }

  Widget _legendImage(String assetPath, String label) {
    return Row(
      children: [
        Image.asset(assetPath, width: 20, height: 20),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(width: 10, height: 10, color: color),
        SizedBox(width: 4),
        Text(label, style: TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }

  Widget _buildShowtimesSection(
    String movies_package_name,
    Color color,
    List<String> times,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                movies_package_name,
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 6),
              Icon(Icons.info_outline, size: 16, color: Colors.white70),
            ],
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children:
                times.map((t) => _timeBox(t, movies_package_name)).toList(),
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _timeBox(String time, String movie_package_name) {
    return GestureDetector(
      onTap: () {
        final randomHallNumber = Random().nextInt(10) + 1;
        final movie_package_name = 'Cinema $randomHallNumber';

        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => SeatSelectionScreen(
                  movieTitle: widget.movieTitle,
                  showtime: time,
                  cinema: expandedCinema ?? 'Unknown Cinema',
                  date: weeklyDates[selectedDateIndex].label,
                  hall: movie_package_name,

                  movieCategory: widget.movieCategory,
                  movieDuration: widget.movieDuration,
                  movieLanguage: widget.movieLanguage,
                  moviePosterPath: widget.moviePosterPath,
                  movieBannerPath: widget.movieBannerPath,
                ),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(time, style: TextStyle(color: Colors.greenAccent)),
      ),
    );
  }
}

class DateInfo {
  final String label;
  final String firestoreKey;

  DateInfo({required this.label, required this.firestoreKey});
}

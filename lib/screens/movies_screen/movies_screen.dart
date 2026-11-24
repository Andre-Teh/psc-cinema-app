import 'package:flutter/material.dart';
import 'filter.dart';
import 'package:psc_cinema_app/screens/movies_screen/movies_details.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/src/loading.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MoviesScreen extends StatefulWidget {
  final VoidCallback onBack;
  final String initialCategory;

  const MoviesScreen({
    Key? key,
    required this.onBack,
    this.initialCategory = 'ALL',
  }) : super(key: key);

  @override
  State<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends State<MoviesScreen> {
  String selectedFilter = "ALL";
  String selectedLocation = "Klang Valley";
  String tempSelectedLocation = "Klang Valley";
  String userID = '';
  String area = '';
  bool rememberLocation = false;

  late String selectedCategory;

  List<Map<String, dynamic>> nowShowingMovies = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchNowShowingMovies();
    fetchUserLocation();
  }

  Future<void> fetchUserLocation() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final snapshot =
          await FirebaseFirestore.instance.collection('Client').doc(uid).get();
      if (snapshot.exists) {
        final data = snapshot.data();
        setState(() {
          userID = data?['uid'] ?? 'uid';
          area = (data?['district'] ?? 'KLANG VALLEY').toString();
        });
      }
    }
  }

  Future<void> fetchNowShowingMovies() async {
    final today = DateTime.now();

    final snapshot = await FirebaseFirestore.instance.collection('films').get();

    final movies =
        snapshot.docs
            .where((doc) {
              final data = doc.data();
              final release =
                  (data['films_release_date'] as Timestamp?)?.toDate();
              final end = (data['films_ended_date'] as Timestamp?)?.toDate();
              return release != null &&
                  end != null &&
                  today.isAfter(release) &&
                  today.isBefore(end);
            })
            .map((doc) {
              final data = doc.data();
              return {
                "fid": doc.id,
                "title": data["films_title"],
                "category": (data["filme_genre"] as List<dynamic>).join(", "),
                "duration": "${data["films_duration"] ?? 0} mins",
                "language": (data["films_language"] as List<dynamic>).join(
                  ", ",
                ),
                "poster": data["poster_url"],
                "banner": data["banner_url"],
                "package": List<String>.from(data["package"] ?? []),
              };
            })
            .toList();

    setState(() {
      nowShowingMovies = movies;
      _isLoading = false;
    });
  }

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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: PulsingLogo());
    }
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        title: const Text("MOVIES"),
        actions: [
          TextButton.icon(
            onPressed: _showLocationDialog,
            icon: const Icon(Icons.location_on, color: Colors.white, size: 18),
            label: Text(
              area.isNotEmpty ? area.toUpperCase() : "KLANG VALLEY",
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header container with slight grey background
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.fromARGB(255, 0, 0, 0),
                      Color.fromARGB(255, 41, 41, 41),
                    ],
                  ),
                ),
                child: SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    children:
                        ["ALL", "INDULGE", "IMAX", "FAMILY", "BEANIE"].map((
                          label,
                        ) {
                          final isSelected = selectedFilter == label;
                          final Map<String, Color> labelColors = {
                            "ALL": Color.fromARGB(255, 175, 50, 41),
                            "INDULGE": Color(0xFF9C27B0),
                            "IMAX": Color(0xFF2196F3),
                            "FAMILY": Color(0xFFFF9800),
                            "BEANIE": Color(0xFFF44336),
                          };
                          final labelColor = labelColors[label] ?? Colors.red;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedFilter = label;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 10),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isSelected
                                        ? Color(0xFF2C2C2C)
                                        : Colors.transparent,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(5),
                                  topRight: Radius.circular(18),
                                  bottomRight: Radius.circular(5),
                                  bottomLeft: Radius.circular(18),
                                ),
                                border:
                                    isSelected
                                        ? Border.all(
                                          color: labelColor,
                                          width: 2,
                                        )
                                        : null,
                              ),
                              child: Text(
                                label,
                                style: TextStyle(
                                  color: isSelected ? labelColor : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ),

              // Movie Cards
              Expanded(
                child: Builder(
                  builder: (context) {
                    List<Map<String, dynamic>> displayedMovies;

                    if (selectedFilter == "ALL") {
                      displayedMovies = nowShowingMovies;
                    } else {
                      displayedMovies =
                          nowShowingMovies
                              .where(
                                (movie) => (movie["package"] as List).contains(
                                  selectedFilter,
                                ),
                              )
                              .toList();
                    }

                    return displayedMovies.isNotEmpty
                        ? GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.6,
                              ),
                          itemCount: displayedMovies.length,
                          itemBuilder: (context, index) {
                            final movie = displayedMovies[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => MoviesDetailsScreen(
                                          fid: movie["fid"],
                                          movieTitle: movie["title"]!,
                                          moviePosterUrl: movie["poster"] ?? "",
                                          movieBannerUrl: movie["banner"]!,
                                          movieCategory: movie["category"]!,
                                          movieDuration: movie["duration"]!,
                                          movieLanguage: movie["language"]!,
                                          moviePosterPath:
                                              movie["poster"] ?? "",
                                          movieBannerPath:
                                              movie["banner"] ?? "",
                                        ),
                                  ),
                                );
                              },
                              child: _buildMovieCard(
                                title: movie["title"]!,
                                posterPath: movie["poster"]!,
                              ),
                            );
                          },
                        )
                        : const Center(
                          child: Text(
                            "No movies in this section.",
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                  },
                ),
              ),
            ],
          ),

          // Floating Filter Icon
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: const Color.fromARGB(154, 245, 166, 166),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MovieFilterScreen(),
                  ),
                );
              },
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(5),
                  topRight: Radius.circular(18),
                  bottomRight: Radius.circular(5),
                  bottomLeft: Radius.circular(18),
                ),
              ),
              child: const Icon(Icons.filter_alt, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // Reusable movie card with gradient outline border
  Widget _buildMovieCard({required String title, required String posterPath}) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFFF5A6A6), Color.fromARGB(255, 108, 74, 74)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(2),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            alignment: Alignment.bottomLeft,
            children: [
              Image.network(
                posterPath,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder:
                    (context, error, stackTrace) =>
                        Icon(Icons.broken_image, color: Colors.white),
              ),
              Container(
                width: double.infinity,
                color: Colors.black.withOpacity(0.6),
                padding: const EdgeInsets.all(8),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

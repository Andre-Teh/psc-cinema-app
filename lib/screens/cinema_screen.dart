import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CinemaScreen extends StatefulWidget {
  final VoidCallback onBack;

  const CinemaScreen({Key? key, required this.onBack}) : super(key: key);

  @override
  State<CinemaScreen> createState() => _CinemaScreenState();
}

final Set<String> favoriteCinemas = {};

class _CinemaScreenState extends State<CinemaScreen> {
  @override
  void initState() {
    super.initState();
    fetchUserLocation();
  }

  int selectedDateIndex = 0;
  String selectedFilter = "ALL";
  String? expandedCinema;
  String? area;
  String? userID;

  String selectedLocation = "Klang Valley";
  String tempSelectedLocation = "Klang Valley";
  bool rememberLocation = false;

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

  final Map<String, LatLng> cinemaCoordinates = {
    '1 SHAMELIN': LatLng(3.122240367839303, 101.73994067116442),
    'CHERAS SENTRAL': LatLng(3.078640310536297, 101.744941496656),
    'SURIA KLCC': LatLng(3.1577236603094088, 101.71222841199852),
    'AMPANG POINT': LatLng(3.1581259978550484, 101.7508349524782),
    '1 UTAMA': LatLng(3.148596400220356, 101.61714739665618),
    'AU2 SETIAWANGSA': LatLng(3.17737616836476, 101.75069766597154),
    'BUKIT RAJA': LatLng(3.060791572821446, 101.47238398131357),
    'BUKIT TINGGI': LatLng(2.994624595581669, 101.4447313966557),
    'CENTRAL I-CITY': LatLng(3.063365013003391, 101.482235896656),
    'CHERAS SELATAN': LatLng(3.0337617453527366, 101.76504169665579),
    'DPULZE CYBERJAYA': LatLng(2.922258379875725, 101.65093581014871),
    'STRAND KOTA DAMANSARA': LatLng(3.1558512481490903, 101.59291813898501),
    'JAYA SEKSYEN 14': LatLng(3.1093604055378448, 101.63723444083399),
    'KEPONG': LatLng(3.2133968002127973, 101.63907692549205),
    'MINES': LatLng(3.028396563188256, 101.71861509665582),
    'RAWANG': LatLng(3.3168787053261606, 101.53648450675905),
    'SETIAWALK PUCHONG': LatLng(3.029894418366616, 101.61597755432703),
    'SUNWAY PUTRA': LatLng(3.1666398459101943, 101.69249449850534),
    'SUNWAY PYRAMID': LatLng(3.0731378632149315, 101.60675853558925),
  };

  final Map<String, String> parkingZones = {
    '1 SHAMELIN': 'Level SB, Orange Zone',
    'CHERAS SENTRAL': 'Level 3, 3A & 5',
    'SURIA KLCC': 'Level P1, Green Zone',
    'AMPANG POINT': 'Level B',
    '1 UTAMA': 'Level L3, Old Wing Zone',
    'AU2 SETIAWANGSA': 'Level GROUND, Orange Zone',
    'BUKIT RAJA': 'Level L2, Blue & Red Zone',
    'BUKIT TINGGI':
        'Zone E Brown & Yellow Pillars; Number: B-E 24-27, B-D 17-23',
    'CENTRAL I-CITY': 'Level B1 & B2',
    'CHERAS SELATAN': 'Level L2, Red Zone',
    'DPULZE CYBERJAYA': 'Level P1, Orange Zone',
    'STRAND KOTA DAMANSARA': 'Level 3',
    'JAYA SEKSYEN 14': 'Level B1 & B2, Green & Blue Zone',
    'KEPONG': 'Level L2 & L3, Blue & Red Zone',
    'MINES': 'Level L2',
    'RAWANG': 'Level GROUND, B Zone',
    'SETIAWALK PUCHONG': 'Level B1, Blue Zone',
    'SUNWAY PUTRA': 'Level L6',
    'SUNWAY PYRAMID': 'Level CP2, CP3 & CP4, Orange Zone',

    // Add more for each cinema
  };

  void _showLocationDialog() {
    tempSelectedLocation = selectedLocation;
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
                    "Experience what’s around you",
                    style: TextStyle(color: Colors.white),
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
                            onTap:
                                () => setModalState(
                                  () => tempSelectedLocation = area,
                                ),
                          ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: rememberLocation,
                        onChanged:
                            (value) => setModalState(
                              () => rememberLocation = value ?? false,
                            ),
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
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        title: const Text("CINEMAS"),
        actions: [
          TextButton.icon(
            onPressed: _showLocationDialog,
            icon: const Icon(Icons.location_on, color: Colors.white, size: 18),
            label: Text(
              (area ?? "KLANG VALLEY").toUpperCase(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterTabs(),
          Expanded(
            child: ListView(
              children: [
                if (favoriteCinemas.isNotEmpty) ...[
                  _sectionHeader("MY FAVOURITES"),
                  ...favoriteCinemas.map(
                    (cinema) => _buildCinemaTile(cinema, isFavorite: true),
                  ),
                ],
                _sectionHeader("NEAREST TO YOU"),
                ...nearestCinemas.map((cinema) => _buildCinemaTile(cinema)),
                _sectionHeader("KLANG VALLEY"),
                ...klangValleyCinemas.map((cinema) => _buildCinemaTile(cinema)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF000000), Color(0xFF292929)],
        ),
      ),
      child: SizedBox(
        height: 40,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          children:
              ["ALL", "INDULGE", "IMAX", "FAMILY", "BEANIE"].map((label) {
                final isSelected = selectedFilter == label;
                final labelColor =
                    {
                      "ALL": const Color.fromARGB(255, 175, 50, 41),
                      "INDULGE": const Color(0xFF9C27B0),
                      "IMAX": const Color(0xFF2196F3),
                      "FAMILY": const Color(0xFFFF9800),
                      "BEANIE": const Color(0xFFF44336),
                    }[label]!;

                return GestureDetector(
                  onTap: () => setState(() => selectedFilter = label),
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? const Color(0xFF2C2C2C)
                              : Colors.transparent,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(5),
                        topRight: Radius.circular(18),
                        bottomRight: Radius.circular(5),
                        bottomLeft: Radius.circular(18),
                      ),
                      border:
                          isSelected
                              ? Border.all(color: labelColor, width: 2)
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
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(title, style: const TextStyle(color: Colors.white)),
    );
  }

  Widget _buildCinemaTile(String name, {bool isFavorite = false}) {
    final isExpanded = expandedCinema == name;
    final LatLng? position = cinemaCoordinates[name];

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
                  if (favoriteCinemas.contains(name)) {
                    favoriteCinemas.remove(name);
                  } else {
                    favoriteCinemas.add(name);
                  }
                });
              },
              child: Icon(
                favoriteCinemas.contains(name)
                    ? Icons.favorite
                    : Icons.favorite_border,
                color:
                    favoriteCinemas.contains(name) ? Colors.red : Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "AVAILABLE EXPERIENCES",
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child:
                      position == null
                          ? const SizedBox.shrink() // fallback if coords not found
                          : SizedBox(
                            height: 200,
                            child: GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: position,
                                zoom: 15,
                              ),
                              markers: {
                                Marker(
                                  markerId: MarkerId(name),
                                  position: position,
                                  infoWindow: InfoWindow(title: name),
                                ),
                              },
                              zoomControlsEnabled: false,
                              myLocationButtonEnabled: false,
                            ),
                          ),
                ),
                const SizedBox(height: 25),
                const Text(
                  "RECOMMENDED PARKING ZONE",
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  parkingZones[name] ?? 'Parking info not available',
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

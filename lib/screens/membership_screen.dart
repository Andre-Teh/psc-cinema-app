import 'package:flutter/material.dart';
import 'package:psc_cinema_app/screens/movies_screen/checkout_screen.dart';
import 'package:psc_cinema_app/screens/movies_screen/seat_selection_screen.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/src/loading.dart';

class MemberRewardsScreen extends StatefulWidget {
  final VoidCallback onBack;

  const MemberRewardsScreen({Key? key, required this.onBack}) : super(key: key);

  @override
  State<MemberRewardsScreen> createState() => MemberRewardsScreenState();
}

class SelectedRewardHolder {
  static Map<String, String>? reward;

  static void setReward(Map<String, String> selected) {
    reward = selected;
  }

  static Map<String, String>? getReward() {
    return reward;
  }

  static void clear() {
    reward = null;
  }
}

class MemberRewardsScreenState extends State<MemberRewardsScreen> {
  String selectedLocation = "Klang Valley";
  String tempSelectedLocation = "Klang Valley";
  String username = '';
  String userID = '';
  String area = '';
  bool rememberLocation = false;
  final int userMovieMoney = 400;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserRewards();
  }

  int userRewardPoints = 0;

  final List<Map<String, String>> rewards = [
    {
      'title': '"LILO & STITCH" TICKET FROM RM7\n',
      'image': 'assets/rewards/lilo&stitch.png',
    },
    {
      'title': '"MISSION: IMPOSSIBLE" TICKET FROM RM7\n',
      'image': 'assets/rewards/mission_impossible.png',
    },
    {
      'title': '"FINAL DESTINATION: BLOODLINES" TICKET FROM RM7',
      'image': 'assets/rewards/final_destination.png',
    },
    {
      'title': '"THUNDERBOLTS*" TICKET FROM RM7\n',
      'image': 'assets/rewards/thunderbolts.png',
    },
    {
      'title': '"GAYONG" TICKET FROM RM7\n',
      'image': 'assets/rewards/gayong.png',
    },
    {
      'title': '"A GILDED GAME 猎金游戏" TICKET FROM RM7\n',
      'image': 'assets/rewards/gilded_game.png',
    },
  ];

  Future<void> fetchUserRewards() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final snapshot =
          await FirebaseFirestore.instance.collection('Client').doc(uid).get();
      if (snapshot.exists) {
        final data = snapshot.data();
        setState(() {
          userID = data?['uid'] ?? 'uid';
          username = data?['UserName'] ?? 'UserName';
          area = (data?['district'] ?? 'KLANG VALLEY').toString();
          userRewardPoints = (data?['Rewards'] ?? 0).toInt();
        });
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

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
                    "Experience what's around you",
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

  void _showQrDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color.fromARGB(225, 0, 0, 0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                QrImageView(
                  data: '1234567890',
                  version: QrVersions.auto,
                  size: 250, // 🔥 Increased size
                  backgroundColor: Colors.white,
                ),
                const SizedBox(height: 24),
                const Text(
                  "PLATINUM",
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Card No.: ${userID.length >= 12 ? '${userID.substring(0, 4)} ${userID.substring(4, 8)} ${userID.substring(8, 12)}' : userID}",
                  style: const TextStyle(
                    color: Color.fromARGB(255, 255, 255, 255),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Present this code at the counter\nto collect and redeem more MovieMoney!",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            SelectedRewardHolder.clear();
            widget.onBack();
          },
        ),
        title: const Text("MEMBERSHIPS"),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Platinum Member Card
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFF5A6A6),
                    Color.fromARGB(255, 200, 137, 137),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(2),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "PLATINUM MEMBER",
                            style: TextStyle(
                              color: Color.fromARGB(255, 255, 255, 255),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            username.isNotEmpty ? username : 'USERNAME',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color.fromARGB(154, 255, 255, 255),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Card No.: ${userID.length >= 12 ? '${userID.substring(0, 4)} ${userID.substring(4, 8)} ${userID.substring(8, 12)}' : userID}",
                            style: const TextStyle(
                              color: Color.fromARGB(255, 255, 255, 255),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
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
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => _showQrDialog(context),
                      child: Column(
                        children: [
                          QrImageView(
                            data: '1234567890',
                            version: QrVersions.auto,
                            size: 80.0,
                            backgroundColor: Colors.white,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "MY QR",
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
            ),

            const SizedBox(height: 16),

            // Platinum Points
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFF5A6A6),
                    Color.fromARGB(255, 200, 137, 137),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(2),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      "PLATINUM POINTS",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "CHECK YOUR PLATINUM HERE",
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 12),
                    Container(
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
                        onPressed: () {},
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
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          child: Text(
                            "$userRewardPoints PLATINUM",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),
                    const Text(
                      "Expired before 27 May 2025",
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "REWARDS",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),

            GridView.builder(
              shrinkWrap: true, // ✅ let GridView expand inside scroll view
              physics:
                  NeverScrollableScrollPhysics(), // ✅ no internal scrolling
              padding: EdgeInsets.zero,
              itemCount: rewards.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.6, // 🔧 adjust to prevent tight layout
              ),
              itemBuilder: (_, index) {
                final reward = rewards[index];
                final bool canUseReward = userMovieMoney >= 300;

                return Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF0D1B2A),
                        Color.fromARGB(255, 200, 137, 137),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min, // ✅ prevent overflow
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                        child: Image.asset(
                          reward['image']!,
                          fit: BoxFit.cover,
                          height: 130,
                          width: double.infinity,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              reward['title']!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              '300 MovieMoney',
                              style: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Opacity(
                              opacity: canUseReward ? 1.0 : 0.5,
                              child: GestureDetector(
                                onTap:
                                    canUseReward
                                        ? () {
                                          SelectedRewardHolder.setReward(
                                            reward,
                                          );
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (_) => SeatSelectionScreen(
                                                    movieTitle: 'Movie 3',
                                                    cinema: '1 SHAMELIN',
                                                    date: '8 MAY',
                                                    showtime: '9:15 PM',
                                                    hall: 'H5',
                                                    movieCategory: 'Animation',
                                                    movieDuration:
                                                        '1 hr 48 mins',
                                                    movieLanguage: 'English',
                                                    moviePosterPath:
                                                        'assets/path_to_poster.jpg',
                                                    movieBannerPath:
                                                        'assets/path_to_banner.jpg',
                                                  ),
                                            ),
                                          ).then((result) {
                                            if (result != 'completed') {
                                              SelectedRewardHolder.clear();
                                            }
                                          });
                                        }
                                        : null,
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
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 18,
                                    ),
                                    child: Center(
                                      child: Text(
                                        'USE NOW',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:psc_cinema_app/src/auth_services.dart';
import 'film_management.dart';
import 'foodandbeveragesstore.dart';
import 'foodandbevup.dart';
import 'staff_dashboard.dart';
import 'reportdashboard.dart';
import '../src/EarnMoneychart.dart';

class MangerDashboard extends StatefulWidget {
  const MangerDashboard({super.key});

  @override
  State<MangerDashboard> createState() => _MangerDashboardState();
}

class _MangerDashboardState extends State<MangerDashboard> {
  int _selectedIndex = 2;
  String? _username;
  String? _email;
  ChartMode _selectedMode = ChartMode.weekly;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc =
          await FirebaseFirestore.instance
              .collection('Client')
              .doc(user.uid)
              .get();
      final data = doc.data();
      if (data != null) {
        setState(() {
          _username = data['UserName'] ?? 'User';
          _email = data['Email'] ?? 'email@example.com';
        });
      }
    }
  }

  Widget _getTabBody() {
    switch (_selectedIndex) {
      case 0:
        return const FilmManagement();
      case 1:
        return StaffDashboardPage();
      case 2:
        return _buildDashboard(); // 中间的是 DASHBOARD
      case 3:
        return const ReportSelectionScreen();
      case 4:
        return const FBManagementScreen();
      default:
        return const Center(
          child: Text("Unknown Page", style: TextStyle(color: Colors.white)),
        );
    }
  }

  Widget _buildDrawerItem(
    String title,
    IconData icon,
    int? tabIndex, {
    VoidCallback? onTapOverride,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap:
          onTapOverride ??
          () {
            Navigator.pop(context);
            if (tabIndex != null) {
              setState(() {
                _selectedIndex = tabIndex;
              });
            }
          },
    );
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton(
                onPressed:
                    () => setState(() => _selectedMode = ChartMode.weekly),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                ).copyWith(
                  foregroundColor: MaterialStateProperty.resolveWith<Color>((
                    states,
                  ) {
                    return states.contains(MaterialState.pressed)
                        ? Colors.black
                        : Colors.white;
                  }),
                  overlayColor: MaterialStateProperty.all(Colors.yellow),
                ),
                child: const Text("WEEKLY"),
              ),
              OutlinedButton(
                onPressed:
                    () => setState(() => _selectedMode = ChartMode.monthly),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                ).copyWith(
                  foregroundColor: MaterialStateProperty.resolveWith<Color>((
                    states,
                  ) {
                    return states.contains(MaterialState.pressed)
                        ? Colors.black
                        : Colors.white;
                  }),
                  overlayColor: MaterialStateProperty.all(
                    Colors.yellow.withOpacity(0.3),
                  ),
                ),
                child: const Text("MONTHLY"),
              ),
              OutlinedButton(
                onPressed:
                    () => setState(() => _selectedMode = ChartMode.yearly),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                ).copyWith(
                  foregroundColor: MaterialStateProperty.resolveWith<Color>((
                    states,
                  ) {
                    return states.contains(MaterialState.pressed)
                        ? Colors.black
                        : Colors.white;
                  }),
                  overlayColor: MaterialStateProperty.all(
                    Colors.yellow.withOpacity(0.3),
                  ),
                ),
                child: const Text("YEARLY"),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Text(
              "${_selectedMode.name.toUpperCase()} Earn",
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          EarnChart(key: ValueKey(_selectedMode), mode: _selectedMode),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const Text(
                  "Operation",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    buildButton("FILMS", Icons.movie, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FilmManagement(),
                        ),
                      );
                    }),
                    buildButton("STAFF", Icons.people, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StaffDashboardPage(),
                        ),
                      );
                    }),
                    buildButton("F&B", Icons.fastfood, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FBManagementScreen(),
                        ),
                      );
                    }),
                  ],
                ),
                Row(
                  children: [
                    buildButton("PROFILE", Icons.person_outline, () {}),
                    buildButton("REPORT", Icons.insert_chart, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ReportSelectionScreen(),
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildButton(String title, IconData icon, VoidCallback onTap) {
    return Expanded(child: HoverCard(title: title, icon: icon, onTap: onTap));
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Colors.white60,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer(); // ✅ Open the drawer
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _username ?? 'Loading...',
              style: const TextStyle(fontSize: 18, color: Colors.white),
            ),
            Text(
              "Hi, Platinum Manager ${_username ?? ''}",
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: const [
          Icon(Icons.notifications_none, color: Colors.white),
          SizedBox(width: 12),
          Icon(Icons.person_outline, color: Colors.white),
          SizedBox(width: 12),
        ],
      ),

      drawer: Drawer(
        backgroundColor: Colors.black,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // PROFILE SECTION
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Colors.black),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.grey,
                child: Text(
                  _username != null && _username!.isNotEmpty
                      ? _username![0].toUpperCase()
                      : 'U',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              accountName: Text(
                _username ?? "Loading...",
                style: const TextStyle(color: Colors.white),
              ),
              accountEmail: Text(
                _email ?? "Loading...",
                style: const TextStyle(color: Colors.white70),
              ),
            ),

            // MAIN MENU
            _buildSectionTitle("MAIN MENU"),
            _buildDrawerItem("Movies", Icons.local_movies_outlined, 0),
            _buildDrawerItem("Staff", Icons.groups_2_outlined, 1),
            _buildDrawerItem("Food & Beverages", Icons.fastfood_outlined, 4),
            _buildDrawerItem("Reports", Icons.insert_chart_outlined, 3),

            const Divider(color: Colors.white24),

            // SETTINGS
            _buildSectionTitle("SETTINGS"),
            _buildDrawerItem("Profile Information", Icons.person_outline, null),
            _buildDrawerItem(
              "Customer Services",
              Icons.support_agent_outlined,
              null,
            ),
            _buildDrawerItem(
              "Terms & Conditions",
              Icons.description_outlined,
              null,
            ),
            _buildDrawerItem(
              "Sign Out",
              Icons.logout,
              null,
              onTapOverride: () async {
                await AuthService().signout(
                  context: context,
                  localeNotifier: ValueNotifier(
                    const Locale('en'),
                  ), // Replace with actual if needed
                );
              },
            ),
          ],
        ),
      ),

      body: _getTabBody(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.pink,
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.movie), label: 'FILMS'), // 0
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'STAFF',
          ), // 1
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'DASHBOARD',
          ), // 2 ✅ 中间
          BottomNavigationBarItem(
            icon: Icon(Icons.insert_chart),
            label: 'REPORT',
          ), // 3
          BottomNavigationBarItem(
            icon: Icon(Icons.fastfood),
            label: 'F&B',
          ), // 4
        ],
      ),
    );
  }
}

class HoverCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const HoverCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final Color iconColor = _isHovered ? Colors.black : Colors.white;
    final Color textColor = _isHovered ? Colors.black : Colors.white;
    final Color bgColor = _isHovered ? Colors.yellow : Colors.grey[900]!;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(8),
          height: 100,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: _isHovered ? [BoxShadow(blurRadius: 12)] : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: iconColor, size: 32),
              const SizedBox(height: 8),
              Text(widget.title, style: TextStyle(color: textColor)),
            ],
          ),
        ),
      ),
    );
  }
}

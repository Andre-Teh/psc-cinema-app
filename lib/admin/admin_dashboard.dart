import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:psc_cinema_app/admin/order_data_screen.dart';
import 'package:psc_cinema_app/admin/payment_data_screen.dart';
import 'package:psc_cinema_app/manager/filmOverallList.dart';
import 'package:psc_cinema_app/manager/foodandbeveragesstore.dart';
import 'package:psc_cinema_app/manager/ticketPerformanceScreen.dart';
import 'package:psc_cinema_app/src/auth_services.dart';

import 'bank_type_screen.dart';
import 'beverage_screen.dart';
import 'client_data.dart';
import 'package:flutter/material.dart';
import 'e-wallettype.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final List<String> collections = [
    "Bank_Type",
    "FoodandBeverages",
    "Client",
    "Payment_Data",
    "booking_ticket",
    "e-wallet",
    "films",
    "order_data",
  ];

  int _selectedIndex = 0;
  String? _adminName;
  String? _adminEmail;
  bool _isLoading = true;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _loadAdminInfo() async {
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
          _adminName = data['UserName'] ?? 'Admin';
          _adminEmail = data['Email'] ?? 'admin@example.com';
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAdminInfo();
  }

  Drawer _buildAdminDrawer() {
    return Drawer(
      backgroundColor: Colors.black,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Move directly inside build so it reflects updated state
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Colors.black),
            accountName: Text(
              _adminName ?? "Loading...",
              style: const TextStyle(color: Colors.white),
            ),
            accountEmail: Text(
              _adminEmail ?? "Loading...",
              style: const TextStyle(color: Colors.white70),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                (_adminName != null && _adminName!.isNotEmpty)
                    ? _adminName![0].toUpperCase()
                    : 'A',
                style: const TextStyle(fontSize: 24, color: Colors.black),
              ),
            ),
            otherAccountsPictures: const [
              Icon(Icons.keyboard_arrow_down, color: Colors.white),
            ],
          ),
          _buildSectionTitle('MAIN MENU'),
          _buildDrawerItem(Icons.movie, 'Booking Ticket', () {}),
          _buildDrawerItem(Icons.event_seat, 'Seats Management', () {}),
          _buildDrawerItem(Icons.payment, 'Payments', () {}),
          _buildDrawerItem(Icons.fastfood, 'F&B Orders', () {}),
          _buildDrawerItem(Icons.local_offer, 'Packages & Promotions', () {}),
          _buildDrawerItem(Icons.comment, 'Comments & Reviews', () {}),
          const Divider(color: Colors.white24),
          _buildSectionTitle('SETTINGS'),
          _buildDrawerItem(Icons.person_outline, 'Profile Information', () {}),
          _buildDrawerItem(Icons.support_agent, 'Customer Services', () {}),
          _buildDrawerItem(
            Icons.description_outlined,
            'Terms & Conditions',
            () {},
          ),
          _buildDrawerItem(Icons.logout, 'Sign Out', () async {
            await AuthService().signout(
              context: context,
              localeNotifier: ValueNotifier(const Locale('en')),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white54,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }

  Widget buildButton(String title) {
    return Expanded(
      child: HoverCard(
        title: title,
        icon: Icons.folder,
        onTap: () {
          Widget page;
          switch (title) {
            case "Bank_Type":
              page = const BankTypeManagementPage();
              break;
            case "Beverages":
              page = const BeverageManagementPage();
              break;
            case "Client":
              page = ClientManagementScreen();
              break;
            case "e-wallet":
              page = const EWalletManagementPage();
              break;
            case "FoodandBeverages":
              page = const FBManagementScreen();
              break;
            case "films":
              page = const MovieListScreen();
              break;
            case "booking_ticket":
              page = const TicketPerformanceScreen();
              break;
            case "Payment_Data":
              page = const PaymentDataManagementPage();
              break;
            case "order_data":
              page = const OrderDataManagementPage();
              break;

            default:
              page = Scaffold(
                appBar: AppBar(title: Text(title)),
                body: Center(child: Text("Page for $title coming soon")),
              );
          }

          Navigator.push(context, MaterialPageRoute(builder: (_) => page));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      drawer: _buildAdminDrawer(),
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              "PSC Admin Panel",
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
            Text(
              "Welcome Admin",
              style: TextStyle(fontSize: 12, color: Colors.white70),
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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              "Manage Collections",
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
            const SizedBox(height: 8),
            ..._buildCollectionRows(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.pink,
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'DB'),
          BottomNavigationBarItem(icon: Icon(Icons.security), label: 'Access'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Config'),
          BottomNavigationBarItem(icon: Icon(Icons.backup), label: 'Backup'),
          BottomNavigationBarItem(icon: Icon(Icons.logout), label: 'Logout'),
        ],
      ),
    );
  }

  List<Widget> _buildCollectionRows() {
    List<Widget> rows = [];
    for (int i = 0; i < collections.length; i += 3) {
      rows.add(
        Row(
          children: [
            if (i < collections.length) buildButton(collections[i]),
            if (i + 1 < collections.length) buildButton(collections[i + 1]),
            if (i + 2 < collections.length) buildButton(collections[i + 2]),
          ],
        ),
      );
    }
    return rows;
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
    final Color bgColor =
        _isHovered
            ? const Color.fromARGB(255, 215, 186, 56)
            : Colors.grey[900]!;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(8),
          height: 100,
          transform:
              _isHovered
                  ? Matrix4.translationValues(0, -5, 0)
                  : Matrix4.identity(),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow:
                _isHovered
                    ? [
                      BoxShadow(
                        color: bgColor.withOpacity(0.5),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                    : [],
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

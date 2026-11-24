import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'login.dart';
import 'screens/home_screen.dart';
import 'screens/cinema_screen.dart';
import 'screens/membership_screen.dart';
import 'screens/movies_screen/movies_screen.dart';
import 'screens/promotions_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

final localeNotifier = ValueNotifier<Locale>(const Locale('en'));

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp(localeNotifier: localeNotifier));
}

class MyApp extends StatelessWidget {
  final ValueNotifier<Locale> localeNotifier;

  const MyApp({super.key, required this.localeNotifier});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: localeNotifier,
      builder: (context, locale, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: Colors.black,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: Colors.black,
              selectedItemColor: Colors.red,
              unselectedItemColor: Colors.grey,
            ),
            textTheme: ThemeData.dark().textTheme.apply(
              fontFamily: 'OpenSans',
              bodyColor: Colors.white,
              displayColor: Colors.white,
            ),
          ),
          home: AuthWrapper(localeNotifier: localeNotifier),
        );
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  final ValueNotifier<Locale> localeNotifier;

  const AuthWrapper({super.key, required this.localeNotifier});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      return MainPage(localeNotifier);
    } else {
      return Login(localeNotifier: localeNotifier);
    }
  }
}

class MainPage extends StatefulWidget {
  final ValueNotifier<Locale> localeNotifier;

  const MainPage(this.localeNotifier, {super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return HomeScreen(localeNotifier: widget.localeNotifier);
      case 1:
        return MoviesScreen(
          onBack: () {
            setState(() {
              _selectedIndex = 0;
            });
          },
        );
      case 2:
        return CinemaScreen(
          onBack: () {
            setState(() {
              _selectedIndex = 0;
            });
          },
        );
      case 3:
        return MemberRewardsScreen(
          onBack: () {
            setState(() {
              _selectedIndex = 0;
            });
          },
        );
      case 4:
        return PromotionsScreen(
          onBack: () {
            setState(() {
              _selectedIndex = 0;
            });
          },
        );
      default:
        return Center(child: Text("Page $index"));
    }
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;

    return Scaffold(
      body: _buildPage(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.movie), label: local.movies),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_city),
            label: local.cinemas,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.card_membership),
            label: local.memberships,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_offer),
            label: local.promotions,
          ),
        ],
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontSize: 10),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
      ),
    );
  }
}

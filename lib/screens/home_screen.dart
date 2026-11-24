import 'package:flutter/material.dart';
import 'package:psc_cinema_app/screens/about_us_screen.dart';
import 'package:psc_cinema_app/screens/membership_screen.dart';
import 'package:psc_cinema_app/screens/movies_screen/trailer_player.dart';
import 'package:psc_cinema_app/screens/my_booking_screen.dart';
import 'package:psc_cinema_app/screens/notifications_screen.dart';
import 'package:psc_cinema_app/screens/profile_screen.dart';
import 'package:psc_cinema_app/screens/movies_screen/movies_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:psc_cinema_app/screens/movies_screen/movies_details.dart';
import 'package:psc_cinema_app/screens/cinema_screen.dart';
import 'package:psc_cinema_app/screens/promotions_screen.dart';
import 'package:psc_cinema_app/screens/terms&conditions_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../src/auth_services.dart';
import '../src/loading.dart';

class HomeScreen extends StatefulWidget {
  final ValueNotifier<Locale> localeNotifier;

  const HomeScreen({super.key, required this.localeNotifier});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class Film {
  final String fid;
  final String title;
  final String posterUrl;
  final int duration;
  final List<String> genre;
  final List<String> language;
  final DateTime releaseDate;
  final DateTime endDate;

  Film({
    required this.title,
    required this.posterUrl,
    required this.duration,
    required this.genre,
    required this.language,
    required this.releaseDate,
    required this.endDate,
    required this.fid,
  });

  factory Film.fromFirestore(Map<String, dynamic> data, String fid) {
    return Film(
      fid: fid,
      title: data['films_title'] ?? 'Untitled',
      posterUrl: data['poster_url'] ?? '',
      duration: data['films_duration'] ?? 0,
      genre: List<String>.from(data['filme_genre'] ?? []),
      language: List<String>.from(data['films_language'] ?? []),
      releaseDate: (data['films_release_date'] as Timestamp).toDate(),
      endDate: (data['films_ended_date'] as Timestamp).toDate(),
    );
  }

  String get status {
    final now = DateTime.now();
    if (now.isBefore(releaseDate)) {
      return 'book_early';
    } else if (now.isAfter(endDate)) {
      return 'ended';
    } else {
      return 'now_showing';
    }
  }
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTabIndex = 0;
  int currentBannerIndex = 0;
  String? _username;
  String? _email;

  final PageController _bannerController = PageController();

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
  List<Film> _films = [];
  List<Film> _bookEarlyFilms = [];
  List<Film> _comingSoonFilms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadFilms();
  }

  Future<void> loadFilms() async {
    final films = await fetchFilms();
    setState(() {
      _films = films.where((f) => f.status == 'now_showing').toList();
      _bookEarlyFilms = films.where((f) => f.status == 'book_early').toList();
      _comingSoonFilms = films.where((f) => f.status == 'ended').toList();
      _isLoading = false;
    });
  }

  Future<List<Film>> fetchFilms() async {
    final snapshot = await FirebaseFirestore.instance.collection('films').get();
    return snapshot.docs
        .map((doc) => Film.fromFirestore(doc.data(), doc.id))
        .toList();
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

  // Top Banners (e.g., latest movie, hottest movie, merchandise)
  final List<Map<String, String>> topBanners = [
    {
      'title': 'FINAL DESTINATION: BLOODLINES',
      'poster': 'assets/movies/final_destination.webp',
      'banner': 'assets/movies/final_destination_banner.jpg',
    },
    {
      'title': 'THUNDERBOLTS*',
      'poster': 'assets/movies/new_avengers.webp',
      'banner': 'assets/movies/new_avengers_banner.jpg',
    },
    {
      'title': 'INDULGE coway',
      'banner': 'assets/promotions/indulge_banner.png',
    },
  ];

  // Movie Banners (Now Showing, Book Early, Coming Soon)
  final List<Map<String, String>> movieBanners = [
    {
      'title': 'BLOOD BROTHERS: BARA NAGA',
      'poster': 'assets/movies/blood_brothers.webp',
      'banner': 'assets/movies/blood_brothers_banner.jpg',
    },
    {
      'title': 'FINAL DESTINATION: BLOODLINES',
      'poster': 'assets/movies/final_destination.webp',
      'banner': 'assets/movies/final_destination_banner.jpg',
    },
    {
      'title': 'A GILDED GAME 猎金游戏',
      'poster': 'assets/movies/gilded_game.webp',
      'banner': 'assets/movies/gilded_game_banner.jpg',
    },
    {
      'title': 'HOLY NIGHT: DEMON HUNTERS',
      'poster': 'assets/movies/holy_night.webp',
      'banner': 'assets/movies/holy_night_banner.jpg',
    },
    {
      'title': 'LILO & STITCH',
      'poster': 'assets/movies/lilo&stitch.webp',
      'banner': 'assets/movies/lilo&stitch_banner.jpg',
    },
    {
      'title': 'LOVESICK 有病才會喜歡你',
      'poster': 'assets/movies/lovesick.webp',
      'banner': 'assets/movies/lovesick_banner.jpg',
    },
    {
      'title': 'A MINECRAFT MOVIE',
      'poster': 'assets/movies/minecraft.webp',
      'banner': 'assets/movies/minecraft_banner.png',
    },
    {
      'title': 'MISSION:\nIMPOSSIBLE - THE\nFINAL RECKONING',
      'poster': 'assets/movies/mission_impossible.webp',
      'banner': 'assets/movies/mission_impossible_banner.jpg',
    },
    {
      'title': 'THUNDERBOLTS*',
      'poster': 'assets/movies/new_avengers.webp',
      'banner': 'assets/movies/new_avengers_banner.jpg',
    },
    {
      'title': 'NE ZHA 2 哪吒之魔童闹海',
      'poster': 'assets/movies/nezha2.webp',
      'banner': 'assets/movies/nezha2_banner.jpg',
    },
  ];

  final Map<String, Map<String, String>> movieDetailsMap = {
    'BLOOD BROTHERS: BARA NAGA': {
      'category': 'Action, Drama',
      'duration': '2 hr 9 mins',
      'language': 'English',
    },
    'FINAL DESTINATION: BLOODLINES': {
      'category': 'Thriller, Horror',
      'duration': '1 hr 50 mins',
      'language': 'English',
    },
    'A GILDED GAME 猎金游戏': {
      'category': 'Crime, Drama',
      'duration': '2 hr 10 mins',
      'language': 'Mandarin',
    },
    'HOLY NIGHT: DEMON HUNTERS': {
      'category': 'Action, Fantasy, Horror',
      'duration': '1 hr 32 mins',
      'language': 'English',
    },
    'LILO & STITCH': {
      'category': 'Animation',
      'duration': '1 hr 48 mins',
      'language': 'English',
    },
    'LOVESICK 有病才會喜歡你': {
      'category': 'Drama, Comedy, Romance',
      'duration': '1 hr 51 mins',
      'language': 'Mandarin',
    },
    'A MINECRAFT MOVIE': {
      'category': 'Action, Adventure, Family',
      'duration': '1 hr 40 mins',
      'language': 'English',
    },
    'MISSION:\nIMPOSSIBLE - THE\nFINAL RECKONING': {
      'category': 'Action, Adventure',
      'duration': '2 hr 50 mins',
      'language': 'English',
    },
    'THUNDERBOLTS*': {
      'category': 'Action, Adventure',
      'duration': '2 hr 5 mins',
      'language': 'English',
    },
    'NE ZHA 2 哪吒之魔童闹海': {
      'category': 'Animation, Action, Drama',
      'duration': '2 hr 24 mins',
      'language': 'Mandarin',
    },
  };

  final List<Map<String, String>> bookEarlyBanners = [
    {
      'title': 'FINAL DESTINATION: BLOODLINES',
      'poster': 'assets/movies/final_destination.webp',
      'banner': 'assets/movies/final_destination_banner.jpg',
    },
    {
      'title': 'A GILDED GAME 猎金游戏',
      'poster': 'assets/movies/gilded_game.webp',
      'banner': 'assets/movies/gilded_game_banner.jpg',
    },
    {
      'title': 'LILO & STITCH',
      'poster': 'assets/movies/lilo&stitch.webp',
      'banner': 'assets/movies/lilo&stitch_banner.jpg',
    },
    {
      'title': 'LOVESICK 有病才會喜歡你',
      'poster': 'assets/movies/lovesick.webp',
      'banner': 'assets/movies/lovesick_banner.jpg',
    },
    {
      'title': 'A MINECRAFT MOVIE',
      'poster': 'assets/movies/minecraft.webp',
      'banner': 'assets/movies/minecraft_banner.png',
    },
    {
      'title': 'THUNDERBOLTS*',
      'poster': 'assets/movies/new_avengers.webp',
      'banner': 'assets/movies/new_avengers_banner.jpg',
    },
  ];

  final List<Map<String, String>> comingSoonBanners = [
    {
      'title': 'JOHN WICK PRESENTS: BALLERINA',
      'poster': 'assets/movies/john_wick.webp',
    },
    {'title': 'F1', 'poster': 'assets/movies/f1.webp'},
    {
      'title': 'HOW TO TRAIN\nYOUR DRAGON 2025\n(LIVE ACTION)',
      'poster': 'assets/movies/how_to_train_your_dragon.webp',
    },
    {'title': 'THE SMURFS MOVIE', 'poster': 'assets/movies/smurf.webp'},
    {'title': 'SUPERMAN', 'poster': 'assets/movies/superman.webp'},
    {'title': 'TOY STORY 5', 'poster': 'assets/movies/toy_story_5.webp'},
  ];

  final Map<String, Map<String, String>> comingSoonDetailsMap = {
    'JOHN WICK PRESENTS: BALLERINA': {
      'category': 'Action, Thriller',
      'duration': '0 hr 0 mins',
      'language': 'English',
    },
    'F1': {
      'category': 'Drama, Sports',
      'duration': '0 hr 0 mins',
      'language': 'English',
    },
    'HOW TO TRAIN\nYOUR DRAGON 2025\n(LIVE ACTION)': {
      'category': 'Action, Adventure, Fantasy',
      'duration': '0 hr 0 mins',
      'language': 'English',
    },
    'THE SMURFS MOVIE': {
      'category': 'Animation, Adventure, Comedy',
      'duration': '0 hr 0 mins',
      'language': 'English',
    },
    'SUPERMAN': {
      'category': 'Superhero',
      'duration': '0 hr 0 mins',
      'language': 'English',
    },
    'TOY STORY 5': {
      'category': 'Animation, Adventure, Comedy',
      'duration': '0 hr 0 mins',
      'language': 'English',
    },
  };

  final List<String> _tabTitles = ['NOW SHOWING', 'BOOK EARLY', 'COMING SOON'];

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildFilmCard(Film film) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.transparent,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.network(
              film.posterUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 180,
              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
            ),
          ),
          Container(
            width: double.infinity,
            height: 48,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF5A6A6), Color.fromARGB(255, 200, 137, 137)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: Center(
              child: Text(
                film.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: PulsingLogo());
    }

    final local = AppLocalizations.of(context)!;
    return Scaffold(
      drawer: Drawer(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black, Color(0xFF7A4F4F)],
              stops: [0.5, 0.8],
            ),
          ),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: ClipOval(
                        child: Image.asset(
                          'assets/psc logo.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      local.hiUser(_username ?? 'User'),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _email ?? 'email@example.com',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context); // Close drawer
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => ProfileScreen(
                                      localeNotifier: widget.localeNotifier,
                                    ),
                              ),
                            ).then((updated) {
                              if (updated == true) {
                                _loadUserInfo();
                              }
                            });
                          },
                          child: const Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  height: 1,
                  color: const Color.fromARGB(255, 21, 21, 21),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  local.mainMenu,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Icon(Icons.movie, color: Colors.white),
                title: Text(
                  local.movies,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context); // Close the drawer first
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => MoviesScreen(
                            onBack: () => Navigator.pop(context),
                          ),
                    ),
                  ).then((_) => _loadUserInfo());
                },
              ),
              ListTile(
                leading: Icon(Icons.location_city, color: Colors.white),
                title: Text(
                  local.cinemas,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context); // Close the drawer first
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => CinemaScreen(
                            onBack: () => Navigator.pop(context),
                          ),
                    ),
                  );
                },
              ),

              ListTile(
                leading: Icon(Icons.card_giftcard, color: Colors.white),
                title: Text(
                  local.myRewards,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => MemberRewardsScreen(
                            onBack: () => Navigator.pop(context),
                          ),
                    ),
                  );
                },
              ),

              ListTile(
                leading: Icon(Icons.local_offer, color: Colors.white),
                title: Text(
                  local.promotions,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => PromotionsScreen(
                            onBack: () => Navigator.pop(context),
                          ),
                    ),
                  );
                },
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: const Divider(
                  height: 32,
                  thickness: 1,
                  color: Color.fromARGB(255, 32, 32, 32),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  local.settings,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Icon(Icons.person_outline, color: Colors.white),
                title: Text(
                  local.profileInformation,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => ProfileScreen(
                            localeNotifier: ValueNotifier(const Locale('en')),
                          ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.info_outline, color: Colors.white),
                title: Text(
                  local.aboutUs,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AboutUsScreen()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.description_outlined, color: Colors.white),
                title: Text(
                  local.termsConditions,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TermsAndConditionsScreen(),
                    ),
                  );
                },
              ),
              _buildDrawerItem(Icons.logout, local.signOut, () async {
                await AuthService().signout(
                  context: context,
                  localeNotifier: widget.localeNotifier,
                );
              }),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  _loadUserInfo();
                  Scaffold.of(context).openDrawer();
                },
              ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MyBookingScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: const Text(
              'MY BOOKING',
              style: TextStyle(color: Colors.white),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          ProfileScreen(localeNotifier: widget.localeNotifier),
                ),
              ).then((updated) {
                if (updated == true) {
                  _loadUserInfo();
                }
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Top Banner Section (e.g., Latest Movie, Hottest Movie, etc.)
              SizedBox(
                height: 250,
                child: PageView.builder(
                  controller: _bannerController,
                  itemCount: topBanners.length,
                  onPageChanged: (index) {
                    setState(() {
                      currentBannerIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final banner = topBanners[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                      child: Column(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                banner['banner'] ?? 'assets/placeholder.jpg',
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                            ).copyWith(top: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (banner['title'] != 'INDULGE coway') ...[
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: _showTrailerDialog,
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(
                                          color: Colors.white,
                                          width: 2,
                                        ),
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
                                        padding: EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        child: Text(
                                          'WATCH TRAILER',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'OpenSans',
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                ],
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFF5A6A6),
                                          Color.fromARGB(255, 200, 137, 137),
                                        ],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                        stops: [0.55, 0.9],
                                      ),
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(5),
                                        topRight: Radius.circular(18),
                                        bottomRight: Radius.circular(5),
                                        bottomLeft: Radius.circular(18),
                                      ),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(5),
                                        topRight: Radius.circular(18),
                                        bottomRight: Radius.circular(5),
                                        bottomLeft: Radius.circular(18),
                                      ),
                                      child: InkWell(
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(5),
                                          topRight: Radius.circular(18),
                                          bottomRight: Radius.circular(5),
                                          bottomLeft: Radius.circular(18),
                                        ),
                                        onTap: () {
                                          final title = banner['title'] ?? '';
                                          if (title == 'INDULGE coway') {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (context) => MoviesScreen(
                                                      onBack:
                                                          () => Navigator.pop(
                                                            context,
                                                          ),
                                                      initialCategory:
                                                          'INDULGE',
                                                    ),
                                              ),
                                            );
                                          } else {
                                            final matchedBanner = movieBanners
                                                .firstWhere(
                                                  (movie) =>
                                                      movie['title'] == title,
                                                  orElse: () => {},
                                                );
                                            final details =
                                                movieDetailsMap[title] ?? {};

                                            if (matchedBanner.isNotEmpty &&
                                                details.isNotEmpty) {
                                              final matchedFilm = _films
                                                  .firstWhere(
                                                    (f) => f.title == title,
                                                    orElse:
                                                        () => Film(
                                                          fid: '',
                                                          title: '',
                                                          posterUrl: '',
                                                          duration: 0,
                                                          genre: [],
                                                          language: [],
                                                          releaseDate:
                                                              DateTime.now(),
                                                          endDate:
                                                              DateTime.now(),
                                                        ),
                                                  );
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (
                                                        _,
                                                      ) => MoviesDetailsScreen(
                                                        movieTitle: title,
                                                        moviePosterUrl:
                                                            matchedBanner['poster'] ??
                                                            '',
                                                        movieBannerUrl:
                                                            matchedBanner['banner'] ??
                                                            '',
                                                        movieCategory:
                                                            details['category'] ??
                                                            'Unknown',
                                                        movieDuration:
                                                            details['duration'] ??
                                                            'Unknown',
                                                        movieLanguage:
                                                            details['language'] ??
                                                            'Unknown',
                                                        moviePosterPath:
                                                            banner['poster'] ??
                                                            '',
                                                        movieBannerPath:
                                                            banner['banner'] ??
                                                            '',
                                                        fid: matchedFilm.fid,
                                                      ),
                                                ),
                                              );
                                            }
                                          }
                                        },
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          child: Center(
                                            child: Text(
                                              'BOOK NOW',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'OpenSans',
                                              ),
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
              ),

              // Movie Banners under "Now Showing", "Book Early", "Coming Soon".
              DefaultTabController(
                length: 3,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: TabBar(
                        indicatorColor: Color(0xFFF5A6A6),
                        labelStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        unselectedLabelColor: Colors.white,
                        tabs:
                            _tabTitles
                                .map((title) => Tab(text: title))
                                .toList(),
                      ),
                    ),
                    Container(
                      height: 470,
                      child: TabBarView(
                        physics: NeverScrollableScrollPhysics(),
                        children: [
                          // NOW SHOWING tab
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              height: 460,
                              child: GridView.builder(
                                shrinkWrap: true,
                                scrollDirection: Axis.horizontal,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 8,
                                      mainAxisSpacing: 8,
                                      childAspectRatio: 1.5,
                                    ),
                                itemCount: _films.length,
                                itemBuilder: (context, index) {
                                  final film = _films[index];

                                  return Padding(
                                    padding: EdgeInsets.only(
                                      left: index == 0 || index == 1 ? 16 : 3,
                                      right:
                                          index == _films.length - 2 ||
                                                  index == _films.length - 1
                                              ? 16
                                              : 0,
                                    ),
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) => MoviesDetailsScreen(
                                                  movieTitle: film.title,
                                                  moviePosterUrl:
                                                      film.posterUrl,
                                                  movieBannerUrl:
                                                      film.posterUrl,
                                                  movieCategory:
                                                      film.genre.isNotEmpty
                                                          ? film.genre.join(
                                                            ', ',
                                                          )
                                                          : 'Unknown',
                                                  movieDuration:
                                                      '${(film.duration / 60).floor()} hr ${film.duration % 60} mins',
                                                  movieLanguage:
                                                      film.language.isNotEmpty
                                                          ? film.language.join(
                                                            ', ',
                                                          )
                                                          : 'Unknown',
                                                  moviePosterPath:
                                                      film.posterUrl,
                                                  movieBannerPath:
                                                      film.posterUrl,
                                                  fid: film.fid,
                                                ),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          color: Colors.transparent,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  const BorderRadius.vertical(
                                                    top: Radius.circular(12),
                                                  ),
                                              child: Image.network(
                                                film.posterUrl,
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                                height: 180,
                                                errorBuilder:
                                                    (_, __, ___) => const Icon(
                                                      Icons.broken_image,
                                                    ),
                                              ),
                                            ),
                                            Container(
                                              width: double.infinity,
                                              height: 48,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 8,
                                                    horizontal: 6,
                                                  ),
                                              decoration: const BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Color(0xFFF5A6A6),
                                                    Color.fromARGB(
                                                      255,
                                                      200,
                                                      137,
                                                      137,
                                                    ),
                                                  ],
                                                  begin: Alignment.centerLeft,
                                                  end: Alignment.centerRight,
                                                ),
                                                borderRadius:
                                                    BorderRadius.vertical(
                                                      bottom: Radius.circular(
                                                        12,
                                                      ),
                                                    ),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  film.title,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),

                          // BOOK EARLY tab
                          SizedBox(
                            height: 450,
                            child: GridView.builder(
                              scrollDirection: Axis.horizontal,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                    childAspectRatio: 1.5,
                                  ),
                              itemCount: _bookEarlyFilms.length,
                              itemBuilder: (context, index) {
                                final film = _bookEarlyFilms[index];

                                return Padding(
                                  padding: EdgeInsets.only(
                                    left: index == 0 || index == 1 ? 16 : 3,
                                    right:
                                        index == _bookEarlyFilms.length - 2 ||
                                                index ==
                                                    _bookEarlyFilms.length - 1
                                            ? 16
                                            : 0,
                                  ),
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (_) => MoviesDetailsScreen(
                                                fid: film.fid,
                                                movieTitle: film.title,
                                                moviePosterUrl: film.posterUrl,
                                                movieBannerUrl: film.posterUrl,
                                                movieCategory: film.genre.join(
                                                  ', ',
                                                ),
                                                movieDuration:
                                                    '${(film.duration / 60).floor()} hr ${film.duration % 60} mins',
                                                movieLanguage: film.language
                                                    .join(', '),
                                                moviePosterPath: film.posterUrl,
                                                movieBannerPath: film.posterUrl,
                                              ),
                                        ),
                                      );
                                    },
                                    child: _buildFilmCard(film),
                                  ),
                                );
                              },
                            ),
                          ),

                          // COMING SOON tab
                          SizedBox(
                            height: 450,
                            child: GridView.builder(
                              scrollDirection: Axis.horizontal,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                    childAspectRatio: 1.5,
                                  ),
                              itemCount: _comingSoonFilms.length,
                              itemBuilder: (context, index) {
                                final film = _comingSoonFilms[index];

                                return Padding(
                                  padding: EdgeInsets.only(
                                    left: index == 0 || index == 1 ? 16 : 3,
                                    right:
                                        index == _comingSoonFilms.length - 2 ||
                                                index ==
                                                    _comingSoonFilms.length - 1
                                            ? 16
                                            : 0,
                                  ),
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (_) => MoviesDetailsScreen(
                                                fid: film.fid,
                                                movieTitle: film.title,
                                                moviePosterUrl: film.posterUrl,
                                                movieBannerUrl: film.posterUrl,
                                                movieCategory: film.genre.join(
                                                  ', ',
                                                ),
                                                movieDuration:
                                                    '${(film.duration / 60).floor()} hr ${film.duration % 60} mins',
                                                movieLanguage: film.language
                                                    .join(', '),
                                                moviePosterPath: film.posterUrl,
                                                movieBannerPath: film.posterUrl,
                                              ),
                                        ),
                                      );
                                    },
                                    child: _buildFilmCard(film),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:psc_cinema_app/screens/promotion_details_screen.dart';

class PromotionsScreen extends StatefulWidget {
  final VoidCallback onBack;

  const PromotionsScreen({Key? key, required this.onBack}) : super(key: key);

  @override
  State<PromotionsScreen> createState() => _PromotionsScreenState();
}

class PromotionSection {
  final String title;
  final String content;

  PromotionSection({required this.title, required this.content});
}

class _PromotionsScreenState extends State<PromotionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, String>> popularPromotions = [
    {
      "image": "assets/promotions/aloha_party.jpg",
      "title": "Come join our Aloha Party!",
      "subtitle": "A Tropical Getaway for The Girls",
    },
    {
      "image": "assets/promotions/free_movie_ticket.webp",
      "title": "Win Free Movie Tickets",
      "subtitle": "1 May 2025, onwards (every weekend)",
    },
    {
      "image": "assets/promotions/free_drinks.png",
      "title": "Throw Like A Hero & Get Free Drink",
      "subtitle": "1 May 2025, onwards (Weekends ONLY)",
    },
    {
      "image": "assets/promotions/hero_perks.webp",
      "title": "Unlock Your Hero Perks",
      "subtitle": "1 May 2025 onwards",
    },
    {
      "image": "assets/promotions/lilo&stitch.jpg",
      "title": "Lilo & Stitch Activity Booklet",
      "subtitle": "In cinemas 22 May 2025",
    },
    {
      "image": "assets/promotions/stitch_cup.jpg",
      "title": "Limited Edition Stitch Cup",
      "subtitle": "TGV Exclusive",
    },
  ];

  final List<Map<String, String>> homeofheroesPromotions = [
    {
      "image": "assets/promotions/free_movie_ticket.webp",
      "title": "Win Free Movie Tickets",
      "subtitle": "1 May 2025, onwards (every weekend)",
    },
    {
      "image": "assets/promotions/hero_perks.webp",
      "title": "Unlock Your Hero Perks",
      "subtitle": "1 May 2025 onwards",
    },
    {
      "image": "assets/promotions/free_drinks.png",
      "title": "Throw Like A Hero & Get Free Drink",
      "subtitle": "1 May 2025, onwards (Weekends ONLY)",
    },
  ];

  final List<Map<String, String>> partnerOffersPromotions = [
    {
      "image": "assets/promotions/10off.png",
      "title": "RM10 Off IMAX Movie Ticket",
      "subtitle": "From 3 March 2025, while stocks last",
    },
    {
      "image": "assets/promotions/18off.jpg",
      "title": "RM18 Ticket With TNG eWallet",
      "subtitle": "While stocks last",
    },
    {
      "image": "assets/promotions/20off.png",
      "title": "RM20 Off Indulge Ticket",
      "subtitle": "From 5 May until 29 June 2025, while stocks last",
    },
  ];

  List<PromotionSection> _getPromotionSections(String title) {
    switch (title) {
      case "Come join our Aloha Party!":
        return [
          PromotionSection(
            title: "Event Date",
            content: "24th May 2025 (Saturday)",
          ),
          PromotionSection(
            title: "Tickets on Sale Date",
            content: "9th May 2025 (Friday)",
          ),
          PromotionSection(
            title: "Participating Locations",
            content: '''
• TGV Suria KLCC
• TGV 1 Utama
• TGV Pavilion Bukit Jalil
• TGV Tebrau City
• TGV Gurney Paragon''',
          ),
          PromotionSection(title: "Theme", content: "Hawaiian tropical theme"),
          PromotionSection(
            title: "Dress Code",
            content: "Tropical / Lilo & Stitch",
          ),
          PromotionSection(
            title: "How To Get The Party Entry",
            content: '''
Step 1: Select session and number of tickets
Step 2: Choose “Ladies Party” Ticket (RM40/RM95)
Step 3: Make payment
Step 4: Join & collect mystery gifts!''',
          ),
          PromotionSection(
            title: "What You Can Get",
            content: '''
• 1x movie ticket
• Event & activity access
• Mystery gifts''',
          ),
          PromotionSection(
            title: "Event Agenda",
            content: '''
3:00PM – Registration
4:00PM – Games
4:30PM – Best Dress Award
5:00PM – Movie begins''',
          ),
          PromotionSection(
            title: "Terms & Conditions",
            content: '''
• Gifts redeemable only on event day
• One gift per ticket after activity completion
• Not valid with other promotions
• Terms subject to change by TGV''',
          ),
        ];

      case "Win Free Movie Tickets":
        return [
          PromotionSection(
            title: "Contest Period",
            content: "1 May 2025, onwards (every weekend)",
          ),
          PromotionSection(
            title: "Participating Location",
            content: "All TGV locations",
          ),
          PromotionSection(
            title: "How To Participate",
            content: '''
• Share on social media with #TGVHomeOfHeroes and #TGVMovieClub
• Get 100 MovieMoney from the counter
• BONUS: Win free tickets and exclusive prizes''',
          ),
          PromotionSection(
            title: "Terms & Conditions",
            content: '''
• Available every weekend from 1 May 2025
• While stocks last
• Must post on social media with hashtags
• Not valid with other promos
• Terms may change without notice''',
          ),
        ];

      case "Throw Like A Hero & Get Free Drink":
        return [
          PromotionSection(
            title: "Promotion Period",
            content: "1 May 2025 onwards (Weekends ONLY)",
          ),
          PromotionSection(
            title: "Participating Location",
            content: "All TGV locations",
          ),
          PromotionSection(
            title: "Activities",
            content: "Sticky Bomb challenge",
          ),
          PromotionSection(
            title: "How To Win",
            content: '''
• Complete the challenge
• First 100 daily win FREE hot chocolate*
*Mineral water if no hot drink machine''',
          ),
          PromotionSection(
            title: "Terms & Conditions",
            content: '''
• While stocks last
• First 100 participants daily
• Substitutes apply based on location
• Not valid with other promotions''',
          ),
        ];

      case "Unlock Your Hero Perks":
        return [
          PromotionSection(
            title: "Promotion Period",
            content: "1 May – 1 June 2025 (Sat & Sun only)",
          ),
          PromotionSection(
            title: "Participating Location",
            content: "All TGV locations",
          ),
          PromotionSection(
            title: "Weekly Events",
            content: '''
1. Cosplay: 30 Apr – 4 May
2. Martial Arts: 9–11 May
3. Dress Like Tom Cruise: 16–18 May
4. Ejens Unite: 23–31 May''',
          ),
          PromotionSection(
            title: "How To Join",
            content: '''
• Dress up & follow the weekly theme
• Be among the first 100 to get free hot chocolate/mineral water
• Snap photo, post with #TGVHomeOfHeroes & #TGVMovieClub
• Get 100 MovieMoney instantly''',
          ),
          PromotionSection(
            title: "Terms & Conditions",
            content: '''
• Free drinks for first 100 only
• Must follow dress code & theme
• Not combinable with other promos''',
          ),
        ];

      case "Lilo & Stitch Activity Booklet":
        return [
          PromotionSection(
            title: "Promotion Period",
            content: "From 29 May 2025, while stocks last",
          ),
          PromotionSection(
            title: "Participating Locations",
            content: '''
• TGV Ampang Point
• TGV Tasek Central
• TGV 1 Utama
• TGV Central i-City
• TGV Pavilion Bukit Jalil
• TGV Bukit Indah
• TGV Toppen
• TGV Tebrau City''',
          ),
          PromotionSection(
            title: "How To Get It",
            content: '''
• Buy TWO "Lilo & Stitch" Junior tickets
• Show MovieClub login
• Collect at tearing point (1 hour before show)
• 1 booklet per 2 tickets''',
          ),
          PromotionSection(
            title: "Terms & Conditions",
            content: '''
• Valid at Junior halls only
• While stocks last
• One redemption per transaction
• Must be MovieClub member''',
          ),
        ];

      case "Limited Edition Stitch Cup":
        return [
          PromotionSection(
            title: "Promotion Period",
            content: "From 15 May 2025, while stocks last",
          ),
          PromotionSection(
            title: "Participating Location",
            content: "All TGV locations",
          ),
          PromotionSection(
            title: "Promo A – RM65",
            content: "1x Stitch Cup + any 1 Food Combo",
          ),
          PromotionSection(
            title: "Promo B – RM60",
            content: "1x Stitch Cup only",
          ),
          PromotionSection(
            title: "Promo C – RM50",
            content: "1x Stitch Cup (pay with 500 MovieMoney)",
          ),
          PromotionSection(
            title: "Terms & Conditions",
            content: '''
• While stocks last
• Only available at counters
• Not valid with other promos
• Images are for illustration only
''',
          ),
        ];

      default:
        return [
          PromotionSection(title: "Info", content: "More details coming soon!"),
        ];
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            widget.onBack();
          },
        ),
        title: const Text(
          "PROMOTIONS",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Container(
            alignment: Alignment.centerLeft,
            width: double.infinity,
            color: Colors.black,
            padding: EdgeInsets.zero,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.red,
              isScrollable: false,
              labelPadding: EdgeInsets.symmetric(horizontal: 0),
              tabs: const [
                Tab(
                  child: Text(
                    "POPULAR",
                    style: TextStyle(fontSize: 14), // smaller font
                  ),
                ),
                Tab(
                  child: Text(
                    "HOME OF HEROES",
                    style: TextStyle(fontSize: 14), // smaller font
                  ),
                ),
                Tab(
                  child: Text(
                    "PARTNER OFFERS",
                    style: TextStyle(fontSize: 14), // smaller font
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: NeverScrollableScrollPhysics(),
              children: [
                _buildPopularPromotionsGrid(),
                _buildHomeOfHerosPromotionsGrid(),
                _buildPartnerOfferPromotionsGrid(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularPromotionsGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: popularPromotions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.75,
      ),
      itemBuilder: (context, index) {
        final promo = popularPromotions[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => PromotionDetailScreen(
                      title: promo["title"]!,
                      subtitle: promo["subtitle"]!,
                      image: promo["image"]!,
                      sections: _getPromotionSections(promo["title"]!),
                    ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF5A6A6), Color.fromARGB(255, 200, 137, 137)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: Image.asset(
                    promo["image"]!,
                    width: double.infinity,
                    height: 160,
                    fit: BoxFit.cover,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          promo["title"]!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          promo["subtitle"]!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHomeOfHerosPromotionsGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: homeofheroesPromotions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.75,
      ),
      itemBuilder: (context, index) {
        final promo = homeofheroesPromotions[index];
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF5A6A6), Color.fromARGB(255, 200, 137, 137)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Image.asset(
                  promo["image"]!,
                  width: double.infinity,
                  height: 160,
                  fit: BoxFit.cover,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        promo["title"]!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        promo["subtitle"]!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPartnerOfferPromotionsGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: partnerOffersPromotions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.75,
      ),
      itemBuilder: (context, index) {
        final promo = partnerOffersPromotions[index];
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF5A6A6), Color.fromARGB(255, 200, 137, 137)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Image.asset(
                  promo["image"]!,
                  width: double.infinity,
                  height: 160,
                  fit: BoxFit.cover,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        promo["title"]!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        promo["subtitle"]!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

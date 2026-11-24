import 'package:flutter/material.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "ABOUT US",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title above the image
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            
            ),

            // Centered logo
            Center(
              child: Image.asset(
                'assets/psc logo.png',
                width: 180,
                height: 100,
                fit: BoxFit.contain,
              ),
            ),

            const SizedBox(height: 5),

            // Description text
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                '''At PSC Cinemas, it is not just about movies but a total entertainment experience! Since 1995, we have welcomed millions of guests through our doors, offering the widest range of cinematic experiences in Malaysia.

Innovation is at the core of what we do. We are proud to lead Malaysia with the first-in-market, IMAX with Laser Systems and 12-Channel Sound Technology, delivering the world’s most captivating moviegoing experience! Our INDULGE halls, now featuring the revolutionary bed cinema with Coway Berex smart mattresses, redefine premium moviegoing and bring luxury to a new level of comfort. Relaxation finds a home in our Beanie halls, providing cozy beanbag pods, and our Junior halls invite kids to play, laugh, and learn in an engaging edutainment setting. At PSC, endless possibilities await – innovation never stops here!

PSC Cinemas operates 328 screens in 40 locations throughout Malaysia. PSC Cinemas can be found in major shopping centers across Kuala Lumpur, Selangor, Negeri Sembilan, Perak, Penang, Johor, Terengganu, and Sarawak.

As a subsidiary of the Usaha Tegas Group, we are part of a global and local presence with diversified investments in telecommunications, satellite operations, media & broadcasting, oil & gas, and real estate assets.''',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Movie Filter',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
          bodyLarge: TextStyle(color: Colors.white),
          bodySmall: TextStyle(color: Colors.white),
          titleLarge: TextStyle(color: Colors.white),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
      ),
      home: const MovieFilterScreen(),
    );
  }
}

class MovieFilterScreen extends StatefulWidget {
  const MovieFilterScreen({super.key});

  @override
  State<MovieFilterScreen> createState() => _MovieFilterScreenState();
}

class _MovieFilterScreenState extends State<MovieFilterScreen> {
  final List<String> roles = [
    "ACTION",
    "DRAMA",
    "THRILLER",
    "CRIME",
    "FANTASY",
    "HORROR",
    "ANIMATION",
    "COMEDY",
    "ROMANCE",
    "FAMILY",
    "ADVENTURE",
  ];
  final List<String> languages = ["English", "Mandarin"];
  final List<String> experiences = ["INDULGE", "IMAX", "FAMILY", "BEANIE"];
  final List<String> ratings = ["1", "2-3", "4-5"];

  final Set<String> selectedRoles = {};
  final Set<String> selectedExperiences = {};
  String? selectedLanguage;
  String? selectedRating;

  bool get canApply =>
      selectedRoles.isNotEmpty &&
      selectedLanguage != null &&
      selectedExperiences.isNotEmpty;

  Widget buildSingleSelectRating(List<String> items) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          items.map((item) {
            return SelectableChip(
              label: item,
              isSelected: selectedRating == item,
              onTap: () {
                setState(() {
                  selectedRating = item;
                });
              },
            );
          }).toList(),
    );
  }

  Widget buildMultiSelectChips(List<String> items, Set<String> selectedSet) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          items.map((item) {
            return SizedBox(
              child: SelectableChip(
                label: item,
                isSelected: selectedSet.contains(item),
                onTap: () {
                  setState(() {
                    if (selectedSet.contains(item)) {
                      selectedSet.remove(item);
                    } else {
                      selectedSet.add(item);
                    }
                  });
                },
              ),
            );
          }).toList(),
    );
  }

  Widget buildSingleSelectLanguage(List<String> items) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          items.map((item) {
            return SizedBox(
              child: SelectableChip(
                label: item,
                isSelected: selectedLanguage == item,
                onTap: () {
                  setState(() {
                    if (selectedLanguage == item) {
                      selectedLanguage = null;
                    } else {
                      selectedLanguage = item;
                    }
                  });
                },
              ),
            );
          }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('MOVIES FILTER'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 80,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Category",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      buildMultiSelectChips(roles, selectedRoles),

                      const SizedBox(height: 20),
                      const Text(
                        "Language",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      buildSingleSelectLanguage(languages),

                      const SizedBox(height: 20),
                      const Text(
                        "Experience",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      buildMultiSelectChips(experiences, selectedExperiences),

                      const SizedBox(height: 20),
                      const Text(
                        "Rating",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      buildSingleSelectRating(ratings),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),

      bottomNavigationBar: SizedBox(
        height: 80,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 26),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      selectedRoles.clear();
                      selectedLanguage = null;
                      selectedExperiences.clear();
                      selectedRating = null;
                    });
                  },
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(5),
                    topRight: Radius.circular(18),
                    bottomRight: Radius.circular(5),
                    bottomLeft: Radius.circular(18),
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFFF5A6A6),
                          Color.fromARGB(255, 200, 137, 137),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        stops: [0.55, 1.0],
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(5),
                        topRight: Radius.circular(18),
                        bottomRight: Radius.circular(5),
                        bottomLeft: Radius.circular(18),
                      ),
                    ),
                    child: const Text(
                      "RESET",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap:
                      canApply
                          ? () {
                            print(
                              "APPLY -> Roles: $selectedRoles, Language: $selectedLanguage, Experiences: $selectedExperiences, Rating: $selectedRating",
                            );
                          }
                          : null,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(5),
                    topRight: Radius.circular(18),
                    bottomRight: Radius.circular(5),
                    bottomLeft: Radius.circular(18),
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient:
                          canApply
                              ? const LinearGradient(
                                colors: [
                                  Color(0xFFF5A6A6),
                                  Color.fromARGB(255, 200, 137, 137),
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                stops: [0.55, 1.0],
                              )
                              : null,
                      color: canApply ? null : Colors.grey.shade800,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(5),
                        topRight: Radius.circular(18),
                        bottomRight: Radius.circular(5),
                        bottomLeft: Radius.circular(18),
                      ),
                    ),
                    child: Text(
                      "APPLY",
                      style: TextStyle(
                        color: canApply ? Colors.white : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SelectableChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const SelectableChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient:
              isSelected
                  ? const LinearGradient(
                    colors: [
                      Color(0xFFF5A6A6),
                      Color.fromARGB(255, 200, 137, 137),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    stops: [0.55, 1.0],
                  )
                  : null,
          color: isSelected ? null : Colors.transparent,
          border: Border.all(color: Colors.white),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.pentagon_outlined,
              size: 16,
              color: isSelected ? Colors.white : Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

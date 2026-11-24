import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class EditFilmPage extends StatefulWidget {
  final String fid; // Use fid instead of document ID

  const EditFilmPage({super.key, required this.fid});

  @override
  State<EditFilmPage> createState() => _EditFilmPageState();
}

class _EditFilmPageState extends State<EditFilmPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _directorController = TextEditingController();
  final _durationController = TextEditingController();
  List<String> _selectedGenres = [];
  List<String> _selectedLanguages = [];
  final _basePriceController = TextEditingController();
  final _studentDiscountController = TextEditingController();
  DateTime? _releaseDate;
  DateTime? _endedDate;
  String? posterUrl;
  String? bannerUrl;
  String? trailerUrl;
  List<Map<String, dynamic>> _showTimes = [];
  Set<String> _selectedPackages = {};

  File? _posterFile;
  File? _bannerFile;
  File? _trailerFile;
  bool _uploading = false;
  bool _studentPrice = false;
  bool _seniorDiscount = false;
  bool _childDiscount = false;
  bool _okuDiscount = false;

  final picker = ImagePicker();

  Uint8List? _posterBytes;
  Uint8List? _bannerBytes;

  String? documentId; // save actual document ID for update

  @override
  void initState() {
    super.initState();
    loadFilmData();
  }

  Future<void> loadFilmData() async {
    final query =
        await FirebaseFirestore.instance
            .collection('films')
            .where('fid', isEqualTo: widget.fid)
            .limit(1)
            .get();

    if (query.docs.isEmpty) {
      print("No film found with fid ${widget.fid}");
      return;
    }

    final doc = query.docs.first;
    documentId = doc.id;
    final data = doc.data();

    setState(() {
      _titleController.text = data['films_title'] ?? '';
      _descController.text = data['films_description'] ?? '';
      _directorController.text = data['films_director'] ?? '';
      _durationController.text = (data['films_duration'] ?? '').toString();
      _basePriceController.text = (data['price_range'] ?? '').toString();
      _studentDiscountController.text =
          (data['student_discount'] ?? '').toString();
      _selectedGenres = List<String>.from(data['filme_genre'] ?? []);
      _selectedLanguages = List<String>.from(data['films_language'] ?? []);
      _selectedPackages = Set<String>.from(data['package'] ?? []);
      _showTimes = List<Map<String, dynamic>>.from(data['show_times'] ?? []);
      _releaseDate = (data['films_release_date'] as Timestamp?)?.toDate();
      _endedDate = (data['films_ended_date'] as Timestamp?)?.toDate();
      posterUrl = data['poster_url'];
      bannerUrl = data['banner_url'];
      trailerUrl = data['trailer_url'];

      List enabled = data['enabled_discounts'] ?? [];
      _studentPrice = enabled.contains("Student");
      _seniorDiscount = enabled.contains("Senior");
      _childDiscount = enabled.contains("Child");
      _okuDiscount = enabled.contains("OKU");

      _loadImageFromUrl(data['poster_url'], isPoster: true);
      _loadImageFromUrl(data['banner_url'], isPoster: false);
    });
  }

  Future<void> _loadImageFromUrl(String? url, {required bool isPoster}) async {
    if (url == null || url.isEmpty) return;
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        setState(() {
          if (isPoster) {
            _posterBytes = bytes;
          } else {
            _bannerBytes = bytes;
          }
        });
      } else {
        print('Image fetch failed with status ${response.statusCode}');
      }
    } catch (e) {
      print('Image load error: $e');
    }
  }

  Future<void> _pickFile(String type) async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        if (type == 'poster') {
          _posterFile = File(picked.path);
          _posterBytes = bytes;
        }
        if (type == 'banner') {
          _bannerFile = File(picked.path);
          _bannerBytes = bytes;
        }
      });
    }
  }

  Future<void> _pickTrailer() async {
    final picked = await picker.pickVideo(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _trailerFile = File(picked.path));
    }
  }

  Future<void> _deleteFilm() async {
    if (documentId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.black,
            title: const Text(
              "Confirm Delete",
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              "Are you sure you want to delete this film?",
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      setState(() => _uploading = true);

      // Delete associated storage files if available
      Future<void> deleteFromStorage(String? url) async {
        if (url != null && url.isNotEmpty) {
          try {
            final ref = FirebaseStorage.instance.refFromURL(url);
            await ref.delete();
          } catch (e) {
            print("Failed to delete $url: $e");
          }
        }
      }

      await deleteFromStorage(posterUrl);
      await deleteFromStorage(bannerUrl);
      await deleteFromStorage(trailerUrl);

      // Delete Firestore document
      await FirebaseFirestore.instance
          .collection('films')
          .doc(documentId!)
          .delete();

      setState(() => _uploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Film deleted successfully")),
      );
      Navigator.pop(context);
    }
  }

  Future<String?> uploadImageToFirebase({
    required Uint8List data,
    required String folder,
  }) async {
    try {
      final fileName = '$folder/${DateTime.now().millisecondsSinceEpoch}.png';
      final ref = FirebaseStorage.instance.ref().child(fileName);
      final uploadTask = ref.putData(
        data,
        SettableMetadata(contentType: 'image/png'),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Firebase upload error: $e');
      return null;
    }
  }

  String _getStatusFromDates(DateTime release, DateTime end) {
    final now = DateTime.now();
    if (now.isBefore(release)) return "Coming Soon";
    if (now.isAfter(end)) return "Ended";
    return "Showing Now";
  }

  Future<void> _updateFilm() async {
    if (documentId == null) return; // ensure we have a valid doc

    final enabledDiscounts = <String>[];
    if (_studentPrice) enabledDiscounts.add("Student");
    if (_seniorDiscount) enabledDiscounts.add("Senior");
    if (_childDiscount) enabledDiscounts.add("Child");
    if (_okuDiscount) enabledDiscounts.add("OKU");

    setState(() => _uploading = true);

    String? posterUrl;
    if (_posterBytes != null && _posterFile != null) {
      posterUrl = await uploadImageToFirebase(
        data: kIsWeb ? _posterBytes! : await _posterFile!.readAsBytes(),
        folder: 'Poster',
      );
    }

    String? bannerUrl;
    if (_bannerBytes != null && _bannerFile != null) {
      bannerUrl = await uploadImageToFirebase(
        data: kIsWeb ? _bannerBytes! : await _bannerFile!.readAsBytes(),
        folder: 'Banner',
      );
    }

    String? trailerUrl;
    if (_trailerFile != null && !kIsWeb) {
      final ref = FirebaseStorage.instance.ref().child(
        'Trailer/${DateTime.now().millisecondsSinceEpoch}.mp4',
      );
      await ref.putFile(_trailerFile!);
      trailerUrl = await ref.getDownloadURL();
    }

    final status = _getStatusFromDates(_releaseDate!, _endedDate!);
    int basePrice = int.tryParse(_basePriceController.text) ?? 0;

    await FirebaseFirestore.instance
        .collection('films')
        .doc(documentId!)
        .update({
          'films_title': _titleController.text,
          'films_description': _descController.text,
          'films_director': _directorController.text,
          'films_duration': int.tryParse(_durationController.text) ?? 0,
          'filme_genre': _selectedGenres,
          'films_language': _selectedLanguages,
          'films_release_date': Timestamp.fromDate(_releaseDate!),
          'films_ended_date': Timestamp.fromDate(_endedDate!),
          'status': status,
          'package': _selectedPackages.toList(),
          'price_range': basePrice,
          'student_discount':
              _studentPrice
                  ? int.tryParse(_studentDiscountController.text) ?? 0
                  : 0,
          if (posterUrl != null) 'poster_url': posterUrl,
          if (bannerUrl != null) 'banner_url': bannerUrl,
          if (trailerUrl != null) 'trailer_url': trailerUrl,
          'show_times': _showTimes,
          'enabled_discounts': enabledDiscounts,
          'updated_at': Timestamp.now(),
        });

    setState(() => _uploading = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Film updated successfully")));
    Navigator.pop(context);
  }

  Future<String?> _selectHall(String currentHall) async {
    String? selectedHall = currentHall;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            "Select Hall",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          content: DropdownButtonFormField<String>(
            value: currentHall,
            items:
                ["Main Hall", "Hall A", "Hall B", "Hall C"]
                    .map(
                      (hall) =>
                          DropdownMenuItem(value: hall, child: Text(hall)),
                    )
                    .toList(),
            onChanged: (value) => selectedHall = value,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                "OK",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
    return selectedHall;
  }

  void _addShowTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null) {
        final hall = await _selectHall("Main Hall");
        final dateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
        setState(() {
          _showTimes.add({
            'datetime': Timestamp.fromDate(dateTime),
            'hall': hall ?? 'Main Hall',
          });
        });
      }
    }
  }

  void _editShowTime(int index) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null) {
        final hall = await _selectHall(_showTimes[index]['hall']);
        final dateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
        setState(() {
          _showTimes[index] = {
            'datetime': Timestamp.fromDate(dateTime),
            'hall': hall ?? 'Main Hall',
          };
        });
      }
    }
  }

  Widget _buildPackageCard(String label) {
    final selected = _selectedPackages.contains(label);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (selected) {
            _selectedPackages.remove(label);
          } else {
            _selectedPackages.add(label);
          }
        });
      },
      child: Card(
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Colors.white),
          borderRadius: BorderRadius.circular(8),
        ),
        color: selected ? Colors.yellow : Colors.black,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final genres = ["Action", "Comedy", "Drama", "Sci-Fi", "Horror"];
    final languages = [
      "English",
      "Chinese",
      "Malay",
      "Tamil",
      "Hindi",
      "Japanese",
      "Korean",
      "Spanish",
      "French",
      "German",
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Add Film', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Title',
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.yellow),
                  ),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _descController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.yellow),
                  ),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                style: const TextStyle(color: Colors.white),
                controller: _directorController,
                decoration: const InputDecoration(
                  labelText: 'Director',
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.yellow),
                  ),
                ),
              ),
              TextFormField(
                style: const TextStyle(color: Colors.white),
                controller: _durationController,
                decoration: const InputDecoration(
                  labelText: 'Duration (min)',
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.yellow),
                  ),
                ),
              ),
              MultiSelectDialogField(
                items: genres.map((g) => MultiSelectItem(g, g)).toList(),
                title: const Text(
                  "Genres",
                  style: TextStyle(color: Colors.white),
                ),
                buttonText: const Text(
                  "Select Genres",
                  style: TextStyle(color: Colors.white),
                ),
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border.all(color: Colors.white),
                  borderRadius: BorderRadius.circular(4),
                ),
                selectedColor: Colors.yellow,
                selectedItemsTextStyle: const TextStyle(color: Colors.white),
                itemsTextStyle: const TextStyle(color: Colors.white),
                backgroundColor: Colors.black,
                searchable: false,
                initialValue: _selectedGenres,
                onConfirm: (values) {
                  setState(() {
                    _selectedGenres = List<String>.from(values);
                  });
                },
                chipDisplay: MultiSelectChipDisplay(
                  textStyle: const TextStyle(color: Colors.black),
                  chipColor: Colors.yellow.shade100,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 10),
              MultiSelectDialogField(
                items: languages.map((g) => MultiSelectItem(g, g)).toList(),
                title: const Text(
                  "Languages",
                  style: TextStyle(color: Colors.white),
                ),
                buttonText: const Text(
                  "Select Languages",
                  style: TextStyle(color: Colors.white),
                ),
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border.all(color: Colors.white),
                  borderRadius: BorderRadius.circular(4),
                ),
                selectedColor: Colors.yellow,
                selectedItemsTextStyle: const TextStyle(color: Colors.white),
                itemsTextStyle: const TextStyle(color: Colors.white),
                backgroundColor: Colors.black,
                searchable: false,
                initialValue: _selectedLanguages,
                onConfirm: (values) {
                  setState(() {
                    _selectedLanguages = List<String>.from(values);
                  });
                },
                chipDisplay: MultiSelectChipDisplay(
                  textStyle: const TextStyle(color: Colors.black),
                  chipColor: Colors.yellow.shade100,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              ListTile(
                title: Text(
                  _releaseDate == null
                      ? 'Select Release Date'
                      : 'Release Date: ${_releaseDate!.toLocal().toString().split(' ')[0]}',
                  style: TextStyle(color: Colors.white),
                ),
                trailing: const Icon(Icons.calendar_today, color: Colors.white),
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    setState(() => _releaseDate = pickedDate);
                  }
                },
              ),

              ListTile(
                title: Text(
                  _endedDate == null
                      ? 'Select Ended Date'
                      : 'Ended Date: ${_endedDate!.toLocal().toString().split(' ')[0]}',
                  style: const TextStyle(color: Colors.white),
                ),
                trailing: const Icon(Icons.calendar_today, color: Colors.white),
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    setState(() => _endedDate = pickedDate);
                  }
                },
              ),

              const SizedBox(height: 12),
              const Text(
                'Select Formats:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Wrap(
                spacing: 8,
                children: [
                  _buildPackageCard("INDULGE"),
                  _buildPackageCard("IMAX"),
                  _buildPackageCard("FAMILY"),
                  _buildPackageCard("BEANIE"),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _basePriceController,
                decoration: const InputDecoration(labelText: 'Base Price'),
              ),
              SwitchListTile(
                title: const Text(
                  'Enable Student Discount',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                value: _studentPrice,
                onChanged: (v) => setState(() => _studentPrice = v),
              ),
              SwitchListTile(
                title: const Text(
                  'Enable Senior Citizen Discount',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                value: _seniorDiscount,
                onChanged: (v) => setState(() => _seniorDiscount = v),
              ),
              SwitchListTile(
                title: const Text(
                  'Enable Child Ticket Discount',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                value: _childDiscount,
                onChanged: (v) => setState(() => _childDiscount = v),
              ),
              SwitchListTile(
                title: const Text(
                  'Enable OKU (Disabled) Discount',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                value: _okuDiscount,
                onChanged: (v) => setState(() => _okuDiscount = v),
              ),

              const SizedBox(height: 12),
              const Text(
                'Show Times:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Table(
                border: TableBorder.all(),
                columnWidths: const {
                  0: FlexColumnWidth(),
                  1: FlexColumnWidth(),
                  2: FixedColumnWidth(50),
                  3: FixedColumnWidth(50),
                },
                children: [
                  const TableRow(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Text("DateTime"),
                      ),
                      Padding(padding: EdgeInsets.all(8), child: Text("Hall")),
                      Padding(padding: EdgeInsets.all(8), child: Text("✏️")),
                      Padding(padding: EdgeInsets.all(8), child: Text("❌")),
                    ],
                  ),
                  ..._showTimes.asMap().entries.map(
                    (entry) => TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            entry.value['datetime'].toDate().toString(),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(entry.value['hall']),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editShowTime(entry.key),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed:
                              () => setState(
                                () => _showTimes.removeAt(entry.key),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: _addShowTime,
                child: const Text(
                  'Add Show Time',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Poster
              // Poster
              GestureDetector(
                onTap: () => _pickFile('poster'),
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    border: Border.all(color: Colors.yellow, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child:
                        _posterBytes == null
                            ? const Text(
                              'Tap to upload poster',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            )
                            : kIsWeb
                            ? Image.memory(_posterBytes!, fit: BoxFit.cover)
                            : Image.file(_posterFile!, fit: BoxFit.cover),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Banner
              GestureDetector(
                onTap: () => _pickFile('banner'),
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    border: Border.all(color: Colors.yellow, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child:
                        _bannerBytes == null
                            ? const Text(
                              'Tap to upload banner',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            )
                            : kIsWeb
                            ? Image.memory(_bannerBytes!, fit: BoxFit.cover)
                            : Image.file(_bannerFile!, fit: BoxFit.cover),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              GestureDetector(
                onTap: _pickTrailer,
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    border: Border.all(color: Colors.yellow, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child:
                        _trailerFile == null
                            ? const Text(
                              'Tap to upload trailer',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color.fromRGBO(255, 255, 255, 1),
                              ),
                            )
                            : Text(
                              'Trailer: ${_trailerFile!.path.split('/').last}',
                              style: const TextStyle(color: Colors.white),
                            ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceEvenly, // 或 center/start
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _uploading ? null : _updateFilm,
                      icon:
                          _uploading
                              ? const SizedBox(
                                width: 10,
                                height: 10,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Icon(Icons.upload),
                      label: Text(_uploading ? 'Uploading...' : 'Update'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _uploading ? null : _deleteFilm,
                      icon:
                          _uploading
                              ? const SizedBox(
                                width: 10,
                                height: 10,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Icon(Icons.upload),
                      label: Text(_uploading ? 'Delete...' : 'Delete'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

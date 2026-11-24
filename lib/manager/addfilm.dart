import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

class AddFilmPage extends StatefulWidget {
  const AddFilmPage({super.key});

  @override
  State<AddFilmPage> createState() => _AddFilmPageState();
}

class _AddFilmPageState extends State<AddFilmPage> {
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

  Future<void> _submitFilm() async {
    final enabledDiscounts = <String>[];
    if (_studentPrice) enabledDiscounts.add("Student");
    if (_seniorDiscount) enabledDiscounts.add("Senior");
    if (_childDiscount) enabledDiscounts.add("Child");
    if (_okuDiscount) enabledDiscounts.add("OKU");

    if (!_formKey.currentState!.validate() ||
        _posterFile == null ||
        _releaseDate == null ||
        _endedDate == null ||
        _selectedGenres.isEmpty ||
        _selectedLanguages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please complete all fields and upload the image"),
        ),
      );
      return;
    }

    setState(() => _uploading = true);
    // 上传 Poster
    final posterUrl = await uploadImageToFirebase(
      data: kIsWeb ? _posterBytes! : await _posterFile!.readAsBytes(),
      folder: 'Poster',
    );

    // 上传 Banner
    final bannerUrl =
        _bannerBytes != null
            ? await uploadImageToFirebase(data: _bannerBytes!, folder: 'Banner')
            : null;

    String? trailerUrl;
    if (_trailerFile != null && !kIsWeb) {
      final ref = FirebaseStorage.instance.ref().child(
        'Trailer/${DateTime.now().millisecondsSinceEpoch}.mp4',
      );
      await ref.putFile(_trailerFile!);
      trailerUrl = await ref.getDownloadURL();
    }

    if (posterUrl == null || bannerUrl == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Image upload failed")));
      setState(() => _uploading = false);
      return;
    }

    int basePrice = int.tryParse(_basePriceController.text) ?? 0;
    if (_selectedPackages.contains("2D")) {
      basePrice = (basePrice * 1.1).round();
    }

    final status = _getStatusFromDates(_releaseDate!, _endedDate!);

    await FirebaseFirestore.instance.collection('films').add({
      'fid': 'F${DateTime.now().millisecondsSinceEpoch}',
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
      'poster_url': posterUrl,
      'banner_url': bannerUrl,
      'trailer_url': trailerUrl,
      'created_at': Timestamp.now(),
      'show_times': _showTimes,
      'enabled_discounts': enabledDiscounts,
    });

    setState(() => _uploading = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Film uploaded successfully")));
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
                selectedItemsTextStyle: const TextStyle(color: Colors.black),
                itemsTextStyle: const TextStyle(color: Colors.white),
                backgroundColor: Colors.black,
                searchable: false,
                initialValue: _selectedGenres,
                onConfirm: (values) {
                  setState(() {
                    _selectedGenres = List<String>.from(values);
                  });
                },
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
              ElevatedButton.icon(
                onPressed: _uploading ? null : _submitFilm,
                icon:
                    _uploading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.upload),
                label: Text(_uploading ? 'Uploading...' : 'Submit'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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

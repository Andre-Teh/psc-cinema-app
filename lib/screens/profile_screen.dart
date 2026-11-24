import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../src/auth_services.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatefulWidget {
  final ValueNotifier<Locale> localeNotifier;

  const ProfileScreen({super.key, required this.localeNotifier});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  String? _username = null;
  String? _birthDate = null; // Not set
  String? _district = null; // Not set
  String? _gender = null; // Not set
  String? _language = null; // Default language
  String? _email = null;
  String? _contact = null;
  int _rewards = 0;

  String? _originalUsername;
  String? _originalBirthDate;
  String? _originalDistrict;
  String? _originalGender;
  String? _originalLanguage;

  final _districts = [
    'Batu Caves',
    'Bandar Tun Razak',
    'Bukit Jalil',
    'Cheras',
    'Sungai Besi',
    'Kepong',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
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
          _username = data['UserName'] ?? 'Unknown';
          _birthDate = data['birthday'];
          _district = data['district'];
          _gender = data['gender'];
          _language = data['language'] ?? 'English';
          _email = data['Email'] ?? '';
          _contact = data['Contact_Number'] ?? '';
          _rewards = data['Rewards'] ?? 0;
        });
        widget.localeNotifier.value =
            (_language == 'Chinese') ? const Locale('zh') : const Locale('en');
      }
    }
  }

  final _languages = ['English', 'Chinese'];

  bool _hasChanges = false;

  void _startEditing() {
    // Save original values before starting edit
    _originalUsername = _username;
    _originalBirthDate = _birthDate;
    _originalDistrict = _district;
    _originalGender = _gender;
    _originalLanguage = _language;

    setState(() {
      _isEditing = true;
      _hasChanges = false;
    });
  }

  void _cancelEditing() {
    setState(() {
      // Restore original values
      _username = _originalUsername;
      _birthDate = _originalBirthDate;
      _district = _originalDistrict;
      _gender = _originalGender;
      _language = _originalLanguage;

      _isEditing = false;
      _hasChanges = false;
    });
  }

  void _showUnsavedChangesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 8),
              Text('Unsaved Changes?'),
            ],
          ),
          content: Text(
            'Continue without saving? Any changes made will be lost.',
            style: TextStyle(fontSize: 14),
          ),
          actionsPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Just close the dialog
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                _cancelEditing(); // Now cancel editing properly
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text('Continue'),
            ),
          ],
        );
      },
    );
  }

  void _showUpdateDialog(String type) {
    final TextEditingController phoneController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.grey[850],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.mark_email_read_rounded,
                  size: 60,
                  color: Colors.red,
                ),
                const SizedBox(height: 20),
                Text(
                  'UPDATE YOUR ${type.toUpperCase()}?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'All future sign-ins and notifications will be sent to your new ${type.toLowerCase()}.',
                  style: TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Enter new phone number',
                    hintStyle: const TextStyle(color: Colors.white54),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context); // Cancel
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'CANCEL',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context); // close dialog
                          final auth = AuthService();
                          final error = await auth.updatePhoneNumber(
                            context: context,
                            phoneNumber: phoneController.text,
                            onSuccess: () async {
                              // update Firestore phone number
                              final user = FirebaseAuth.instance.currentUser;
                              if (user != null) {
                                await FirebaseFirestore.instance
                                    .collection('Client')
                                    .doc(user.uid)
                                    .update({
                                      'Contact_Number': phoneController.text,
                                    });
                              }
                              _loadUserProfile(); // refresh
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Phone number updated!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                          );
                          if (error != null) {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text(error)));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('CONFIRM'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _saveChanges() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('Client').doc(user.uid).update({
      'UserName': _username,
      'birthday': _birthDate,
      'district': _district,
      'gender': _gender,
      'language': _language,
    });

    widget.localeNotifier.value =
        (_language == 'Chinese') ? const Locale('zh') : const Locale('en');

    setState(() {
      _isEditing = false;
      _hasChanges = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile updated successfully.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(_birthDate ?? '1990-01-01'),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _birthDate = picked.toString().split(' ')[0];
        _hasChanges = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;
    const palePink = Color(0xFFF5A6A6);
    const borderPink = Color(0xFFF48FB1);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.keyboard_arrow_left, // Replace with your desired icon
            color: Colors.white, // Customize color if needed
          ),
          iconSize: 30.0,
          onPressed: () {
            Navigator.of(context).pop(true); // Your custom back functionality
          },
        ),
        title: Text(local.myProfile),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // PROFILE INFO Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                    _isEditing
                        ? Color.fromARGB(31, 135, 135, 135)
                        : const Color.fromARGB(31, 135, 135, 135),
                borderRadius: BorderRadius.circular(10),
                border:
                    _isEditing ? Border.all(color: palePink, width: 2) : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        local.profileInfo,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 19,
                        ),
                      ),
                      if (!_isEditing)
                        TextButton(
                          onPressed: _startEditing,
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 10,
                            ),
                          ),
                          child: Text(
                            local.edit,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // NAME
                  Padding(
                    padding:
                        _isEditing
                            ? const EdgeInsets.only(top: 10.0)
                            : EdgeInsets.zero,
                    child: Text(
                      local.name.toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  _isEditing
                      ? TextFormField(
                        initialValue: _username,
                        onChanged: (val) {
                          setState(() {
                            _username = val;
                            _hasChanges = true;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Enter your name',
                          isDense: true,
                          contentPadding: EdgeInsets.only(
                            left: 0,
                            right: 0,
                            bottom: 8,
                            top: 8,
                          ),
                          border: UnderlineInputBorder(),
                        ),
                      )
                      : Text(
                        _username ?? local.notSet,
                        style: TextStyle(
                          fontWeight: FontWeight.normal,
                          color: _username == null ? Colors.grey : Colors.white,
                          fontSize: _birthDate == null ? 14 : 16,
                        ),
                      ),

                  const SizedBox(height: 20),

                  // DATE OF BIRTH
                  Padding(
                    padding:
                        _isEditing
                            ? const EdgeInsets.only(top: 20.0)
                            : EdgeInsets.zero,
                    child: Text(
                      local.dateOfBirth.toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  _isEditing
                      ? InkWell(
                        onTap: _selectDate,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _birthDate ?? local.selectDateOfBirth,
                                    style: TextStyle(
                                      color:
                                          _birthDate == null
                                              ? Colors.grey
                                              : Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.calendar_today,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Divider(
                              color: Colors.grey,
                              height: 1,
                              thickness: 1,
                            ),
                          ],
                        ),
                      )
                      : Text(
                        _birthDate ?? local.notSet,
                        style: TextStyle(
                          fontWeight: FontWeight.normal,
                          color:
                              _birthDate == null ? Colors.grey : Colors.white,
                          fontSize: 16,
                        ),
                      ),

                  const SizedBox(height: 20),

                  // DISTRICT
                  Padding(
                    padding:
                        _isEditing
                            ? const EdgeInsets.only(top: 20.0)
                            : EdgeInsets.zero,
                    child: Text(
                      local.district.toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  _isEditing
                      ? DropdownButtonFormField(
                        value: _district,
                        items:
                            _districts
                                .map(
                                  (d) => DropdownMenuItem(
                                    value: d,
                                    child: Text(d),
                                  ),
                                )
                                .toList(),
                        onChanged: (val) {
                          setState(() {
                            _district = val.toString();
                            _hasChanges = true;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: local.selectDistrict,
                          isDense: true,
                          contentPadding: EdgeInsets.only(
                            left: 0,
                            right: 0,
                            bottom: 8,
                            top: 8,
                          ),
                          border: UnderlineInputBorder(),
                        ),
                      )
                      : Text(
                        _district ?? local.notSet,
                        style: TextStyle(
                          fontWeight: FontWeight.normal,
                          color: _district == null ? Colors.grey : Colors.white,
                          fontSize: _district == null ? 14 : 16,
                        ),
                      ),

                  const SizedBox(height: 20),

                  // GENDER
                  Padding(
                    padding:
                        _isEditing
                            ? const EdgeInsets.only(top: 20.0)
                            : EdgeInsets.zero,
                    child: Text(
                      local.gender.toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (_isEditing)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children:
                            [local.male, local.female].map((g) {
                              final selected =
                                  (_gender == 'Male' && g == local.male) ||
                                  (_gender == 'Female' && g == local.female);
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _gender =
                                          g == local.male ? "Male" : "Female";
                                      _hasChanges = true;
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: Duration(milliseconds: 300),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          selected
                                              ? palePink
                                              : Colors.transparent,
                                      border: Border.all(color: palePink),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow:
                                          selected
                                              ? [
                                                BoxShadow(
                                                  color: Colors.pinkAccent
                                                      .withOpacity(0.3),
                                                  blurRadius: 6,
                                                ),
                                              ]
                                              : [],
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      g,
                                      style: TextStyle(
                                        fontWeight:
                                            selected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                        color:
                                            selected
                                                ? Colors.white
                                                : Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    )
                  else
                    Text(
                      _gender == 'Male'
                          ? local.male
                          : _gender == 'Female'
                          ? local.female
                          : local.notSet,
                      style: TextStyle(
                        fontWeight: FontWeight.normal,
                        color: _gender == null ? Colors.grey : Colors.white,
                        fontSize: _gender == null ? 14 : 16,
                      ),
                    ),
                  const SizedBox(height: 24),

                  // LANGUAGE
                  Padding(
                    padding:
                        _isEditing
                            ? const EdgeInsets.only(top: 20.0)
                            : EdgeInsets.zero,
                    child: Text(
                      local.language.toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  _isEditing
                      ? DropdownButtonFormField<String>(
                        value: _language,
                        items:
                            _languages.map((lang) {
                              return DropdownMenuItem<String>(
                                value: lang,
                                child: Text(
                                  lang == 'English'
                                      ? local.english
                                      : local.chinese,
                                ),
                              );
                            }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _language = val!;
                            _hasChanges = true;
                          });
                        },
                        decoration: const InputDecoration(
                          hintText: 'Select language',
                          isDense: true,
                          contentPadding: EdgeInsets.only(
                            left: 0,
                            right: 0,
                            bottom: 8,
                            top: 8,
                          ),
                          border: UnderlineInputBorder(),
                        ),
                      )
                      : Text(
                        _language == 'English'
                            ? local.english
                            : _language == 'Chinese'
                            ? local.chinese
                            : local.notSet,
                        style: TextStyle(
                          fontWeight: FontWeight.normal,
                          color: _language == null ? Colors.grey : Colors.white,
                          fontSize: _language == null ? 14 : 16,
                        ),
                      ),
                  const SizedBox(height: 24),

                  if (_isEditing)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // Cancel Button
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(5),
                              topRight: Radius.circular(18),
                              bottomRight: Radius.circular(5),
                              bottomLeft: Radius.circular(18),
                            ),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: TextButton(
                            onPressed: () => _showUnsavedChangesDialog(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 50,
                                vertical: 10,
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const Spacer(), // Spacer between buttons
                        // Save Button
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(5),
                              topRight: Radius.circular(18),
                              bottomRight: Radius.circular(5),
                              bottomLeft: Radius.circular(18),
                            ),
                            color: _hasChanges ? palePink : Colors.grey[300],
                          ),
                          child: TextButton(
                            onPressed: _hasChanges ? _saveChanges : null,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 50,
                                vertical: 10,
                              ),
                            ),
                            child: const Text(
                              'Save',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // CONTACT INFO (view only)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color.fromARGB(31, 135, 135, 135),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    local.contactInfo,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
                  ),
                  const SizedBox(height: 15),
                  _buildInfoRowWithButton(
                    local,
                    local.mobileNo,
                    _contact ?? local.notSet,
                  ),
                  _buildInfoRowWithButton(
                    local,
                    local.emailAddress,
                    _email ?? local.notSet,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRowWithButton(
    AppLocalizations local,
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Color.fromARGB(255, 255, 255, 255),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () => _showUpdateDialog(title.toLowerCase()),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white, width: 2),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(5),
                  topRight: Radius.circular(18),
                  bottomRight: Radius.circular(5),
                  bottomLeft: Radius.circular(18),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: Text(
              local.update, // dynamic localized value
              style: const TextStyle(
                // style CAN stay const
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

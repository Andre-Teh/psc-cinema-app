import 'dart:io' as io;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class BankTypeManagementPage extends StatefulWidget {
  const BankTypeManagementPage({super.key});

  @override
  State<BankTypeManagementPage> createState() => _BankTypeManagementPageState();
}

class _BankTypeManagementPageState extends State<BankTypeManagementPage> {
  final CollectionReference bankCollection = FirebaseFirestore.instance
      .collection('Bank_Type');
  final TextEditingController _addController = TextEditingController();
  final TextEditingController _editController = TextEditingController();

  Uint8List? _selectedImageBytes;
  io.File? _selectedImageFile;
  Uint8List? _editImageBytes;
  io.File? _editImageFile;
  List<Map<String, dynamic>> bankList = [];
  bool isLoading = true;
  bool isDialogLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBankTypes();
  }

  Future<void> _loadBankTypes() async {
    setState(() => isLoading = true);
    try {
      final snapshot = await bankCollection.get();
      final banks =
          snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              'id': doc.id,
              'bank_name': data['bank_name'] ?? '',
              'bank_image': data['bank_image'] ?? '',
            };
          }).toList();

      setState(() {
        bankList = banks;
        isLoading = false;
        errorMessage = null;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => isLoading = true);
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _selectedImageFile = null;
        });
      } else {
        setState(() {
          _selectedImageFile = io.File(picked.path);
          _selectedImageBytes = null;
        });
      }
      setState(() => isLoading = false);
    }
  }

  Future<void> _pickEditImage(StateSetter setDialogState) async {
    setDialogState(() => isDialogLoading = true);
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setDialogState(() {
          _editImageBytes = bytes;
          _editImageFile = null;
        });
      } else {
        setDialogState(() {
          _editImageFile = io.File(picked.path);
          _editImageBytes = null;
        });
      }
    }
    setDialogState(() => isDialogLoading = false);
  }

  Future<void> _addBankType() async {
    final newType = _addController.text.trim();
    if (newType.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter bank name')));
      return;
    }
    if (_selectedImageBytes == null && _selectedImageFile == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select an image')));
      return;
    }

    setState(() => isLoading = true);
    try {
      String imageUrl = '';
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = FirebaseStorage.instance.ref().child('Bank/$fileName.jpg');

      if (kIsWeb && _selectedImageBytes != null) {
        await ref.putData(_selectedImageBytes!);
        imageUrl = await ref.getDownloadURL();
      } else if (_selectedImageFile != null) {
        await ref.putFile(_selectedImageFile!);
        imageUrl = await ref.getDownloadURL();
      }

      final newDoc = bankCollection.doc();
      await newDoc.set({
        'bank_id': newDoc.id,
        'bank_name': newType,
        'bank_image': imageUrl,
      });

      _addController.clear();
      setState(() {
        _selectedImageBytes = null;
        _selectedImageFile = null;
      });
      await _loadBankTypes();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Bank added successfully')));
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _editBankType(String docId, String currentName) {
    _editController.text = currentName;
    _editImageBytes = null;
    _editImageFile = null;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: const Text('Edit Bank Name'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(controller: _editController),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed:
                            isDialogLoading
                                ? null
                                : () => _pickEditImage(setDialogState),
                        icon: const Icon(Icons.image),
                        label: const Text('Change Image'),
                      ),
                      if (isDialogLoading)
                        const Padding(
                          padding: EdgeInsets.only(top: 10),
                          child: CircularProgressIndicator(),
                        ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed:
                          isDialogLoading
                              ? null
                              : () async {
                                setDialogState(() => isDialogLoading = true);
                                final newName = _editController.text.trim();
                                if (newName.isEmpty) return;
                                final updateData = {'bank_name': newName};

                                if (_editImageBytes != null ||
                                    _editImageFile != null) {
                                  final fileName =
                                      DateTime.now().millisecondsSinceEpoch
                                          .toString();
                                  final ref = FirebaseStorage.instance
                                      .ref()
                                      .child('Bank/$fileName.jpg');

                                  if (kIsWeb && _editImageBytes != null) {
                                    await ref.putData(_editImageBytes!);
                                    updateData['bank_image'] =
                                        await ref.getDownloadURL();
                                  } else if (_editImageFile != null) {
                                    await ref.putFile(_editImageFile!);
                                    updateData['bank_image'] =
                                        await ref.getDownloadURL();
                                  }
                                }

                                await bankCollection
                                    .doc(docId)
                                    .update(updateData);
                                Navigator.pop(context);
                                setDialogState(() => isDialogLoading = false);
                                await _loadBankTypes();
                              },
                      child: const Text('Save'),
                    ),
                  ],
                ),
          ),
    );
  }

  Future<void> _deleteBankType(String docId) async {
    final docSnapshot = await bankCollection.doc(docId).get();
    final data = docSnapshot.data() as Map<String, dynamic>?;
    final imageUrl = data?['bank_image'] ?? '';

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Delete Bank'),
            content: const Text('Are you sure you want to delete this bank?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      setState(() => isLoading = true);
      try {
        if (imageUrl.isNotEmpty) {
          final ref = FirebaseStorage.instance.refFromURL(imageUrl);
          await ref.delete();
        }
        await bankCollection.doc(docId).delete();
        await _loadBankTypes();
      } catch (e) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Bank Type'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _addController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Enter new bank type',
                          hintStyle: TextStyle(color: Colors.white54),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white54),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: isLoading ? null : _addBankType,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                      ),
                      child: const Text('Add'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: isLoading ? null : _pickImage,
                      icon: const Icon(Icons.image),
                      label: const Text("Choose Image"),
                    ),
                    const SizedBox(width: 10),
                    if (_selectedImageBytes != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.memory(
                          _selectedImageBytes!,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        ),
                      )
                    else if (_selectedImageFile != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.file(
                          _selectedImageFile!,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (errorMessage != null)
              Text(
                'Error: \$errorMessage',
                style: const TextStyle(color: Colors.red),
              )
            else if (bankList.isEmpty)
              const Text(
                'No bank types found',
                style: TextStyle(color: Colors.white),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: bankList.length,
                  itemBuilder: (context, index) {
                    final bank = bankList[index];
                    final bankId = bank['id'];
                    final bankName = bank['bank_name'];
                    final bankImage = bank['bank_image'];

                    return Card(
                      color: Colors.grey[900],
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child:
                              bankImage.isNotEmpty
                                  ? Image.network(
                                    bankImage,
                                    width: 30,
                                    height: 30,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(
                                              Icons.broken_image,
                                              color: Colors.red,
                                            ),
                                  )
                                  : const Icon(
                                    Icons.account_balance,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                        ),
                        title: Text(
                          bankName,
                          style: const TextStyle(color: Colors.white),
                        ),
                        trailing: Wrap(
                          spacing: 12,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.amber),
                              onPressed: () => _editBankType(bankId, bankName),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteBankType(bankId),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

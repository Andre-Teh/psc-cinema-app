import 'dart:io' as io;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class EWalletManagementPage extends StatefulWidget {
  const EWalletManagementPage({super.key});

  @override
  State<EWalletManagementPage> createState() => _EWalletManagementPageState();
}

class _EWalletManagementPageState extends State<EWalletManagementPage> {
  final CollectionReference eWalletCollection = FirebaseFirestore.instance
      .collection('e-wallet');
  final TextEditingController _addController = TextEditingController();
  final TextEditingController _editController = TextEditingController();

  Uint8List? _selectedImageBytes;
  io.File? _selectedImageFile;
  Uint8List? _editImageBytes;
  io.File? _editImageFile;
  List<Map<String, dynamic>> eWalletList = [];
  bool isLoading = true;
  bool isDialogLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadEWallets();
  }

  Future<void> _loadEWallets() async {
    setState(() => isLoading = true);
    try {
      final snapshot = await eWalletCollection.get();
      final wallets =
          snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              'id': doc.id,
              'e-wallet_name': data['e-wallet_name'] ?? '',
              'e-wallet_image': data['e-wallet_image'] ?? '',
            };
          }).toList();

      setState(() {
        eWalletList = wallets;
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

  Future<void> _addEWallet() async {
    final newType = _addController.text.trim();
    if (newType.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter e-wallet name')),
      );
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
      final ref = FirebaseStorage.instance.ref().child(
        'E-Wallet/$fileName.jpg',
      );

      if (kIsWeb && _selectedImageBytes != null) {
        await ref.putData(_selectedImageBytes!);
        imageUrl = await ref.getDownloadURL();
      } else if (_selectedImageFile != null) {
        await ref.putFile(_selectedImageFile!);
        imageUrl = await ref.getDownloadURL();
      }

      final newDoc = eWalletCollection.doc();
      await newDoc.set({
        'e-wallet_id': newDoc.id,
        'e-wallet_name': newType,
        'e-wallet_image': imageUrl,
      });

      _addController.clear();
      setState(() {
        _selectedImageBytes = null;
        _selectedImageFile = null;
      });
      await _loadEWallets();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('E-Wallet added successfully')),
      );
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _editEWallet(String docId, String currentName) async {
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
                  title: const Text('Edit E-Wallet Name'),
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
                                final updateData = {'e-wallet_name': newName};

                                if (_editImageBytes != null ||
                                    _editImageFile != null) {
                                  final fileName =
                                      DateTime.now().millisecondsSinceEpoch
                                          .toString();
                                  final ref = FirebaseStorage.instance
                                      .ref()
                                      .child('E-Wallet/$fileName.jpg');

                                  if (kIsWeb && _editImageBytes != null) {
                                    await ref.putData(_editImageBytes!);
                                    updateData['e-wallet_image'] =
                                        await ref.getDownloadURL();
                                  } else if (_editImageFile != null) {
                                    await ref.putFile(_editImageFile!);
                                    updateData['e-wallet_image'] =
                                        await ref.getDownloadURL();
                                  }
                                }

                                await eWalletCollection
                                    .doc(docId)
                                    .update(updateData);
                                Navigator.pop(context);
                                setDialogState(() => isDialogLoading = false);
                                await _loadEWallets();
                              },
                      child: const Text('Save'),
                    ),
                  ],
                ),
          ),
    );
  }

  Future<void> _deleteEWallet(String docId) async {
    final docSnapshot = await eWalletCollection.doc(docId).get();
    final data = docSnapshot.data() as Map<String, dynamic>?;
    final imageUrl = data?['e-wallet_image'] ?? '';

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Delete E-Wallet'),
            content: const Text(
              'Are you sure you want to delete this e-wallet?',
            ),
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
        await eWalletCollection.doc(docId).delete();
        await _loadEWallets();
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
        title: const Text('Manage E-Wallet Types'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _addController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Enter new e-wallet type',
                      hintStyle: TextStyle(color: Colors.white54),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white54),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: isLoading ? null : _addEWallet,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
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
            const SizedBox(height: 24),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (errorMessage != null)
              Text(
                'Error: \$errorMessage',
                style: const TextStyle(color: Colors.red),
              )
            else if (eWalletList.isEmpty)
              const Text(
                'No e-wallet types found',
                style: TextStyle(color: Colors.white),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: eWalletList.length,
                  itemBuilder: (context, index) {
                    final wallet = eWalletList[index];
                    final walletId = wallet['id'];
                    final walletName = wallet['e-wallet_name'];
                    final walletImage = wallet['e-wallet_image'];

                    return Card(
                      color: Colors.grey[900],
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child:
                              walletImage.isNotEmpty
                                  ? Image.network(
                                    walletImage,
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
                                    Icons.account_balance_wallet,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                        ),
                        title: Text(
                          walletName,
                          style: const TextStyle(color: Colors.white),
                        ),
                        trailing: Wrap(
                          spacing: 12,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.amber),
                              onPressed:
                                  () => _editEWallet(walletId, walletName),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteEWallet(walletId),
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

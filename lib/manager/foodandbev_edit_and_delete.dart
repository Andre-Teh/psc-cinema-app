import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class InventoryEditScreen extends StatefulWidget {
  final ScrollController? scrollController;
  final Map<String, dynamic> existingData;
  final String documentId;
  final String categoryType;

  const InventoryEditScreen({
    Key? key,
    this.scrollController,
    required this.existingData,
    required this.documentId,
    required this.categoryType,
  }) : super(key: key);

  @override
  State<InventoryEditScreen> createState() => _InventoryEditScreenState();
}

class _InventoryEditScreenState extends State<InventoryEditScreen> {
  bool isBeverages = false;
  bool isFoodPackage = false;
  bool isPackageFB = false;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController providerPriceController = TextEditingController();
  final TextEditingController unitPriceController = TextEditingController();
  final TextEditingController minquantityController = TextEditingController();

  DateTime? selectedDate;

  final List<String> allSizes = ['Large', 'Regular', 'Small', 'None'];
  final List<String> packagelSizes = ['Closed', 'Open'];
  final List<String> needFBSizes = ['Provide', 'Non-Provide'];

  String? selectedSize;
  String? packagestatus;
  String? needSizes;

  File? selectedImageFile;
  String? uploadedImageUrl;

  final ImagePicker picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    loadExistingData();
  }

  void loadExistingData() {
    final data = widget.existingData;
    final type = widget.categoryType;

    if (type == 'Beverages') {
      isBeverages = true;
      nameController.text = data['bevname'] ?? '';
      quantityController.text = data['bevquantity']?.toString() ?? '';
      providerPriceController.text = data['provider_price'] ?? '';
    } else if (type == 'Food') {
      isFoodPackage = true;
      nameController.text = data['foodname'] ?? '';
      quantityController.text = data['foodquantity']?.toString() ?? '';
      providerPriceController.text = data['providr_price'] ?? '';
    } else {
      isPackageFB = true;
      nameController.text = data['package_name'] ?? '';
      quantityController.text = data['package_quantity']?.toString() ?? '';
    }

    if (data['fbstatus'] is String) {
      packagestatus = data['fbstatus'];
    }

    if (data['providerFB'] is String) {
      needSizes = data['providerFB'];
    } else if (data['providerFB'] is List &&
        (data['providerFB'] as List).isNotEmpty) {
      needSizes = (data['providerFB'] as List).first.toString();
    }

    unitPriceController.text = data['unit_price']?.toString() ?? '';
    minquantityController.text = data['min_quantity']?.toString() ?? '';
    selectedSize = data['size'];
    uploadedImageUrl = data['img_url'] ?? data['image_url'];

    if (data['exp_date'] is Timestamp) {
      selectedDate = (data['exp_date'] as Timestamp).toDate();
    } else {
      selectedDate = DateTime.now();
    }
  }

  void setDefaultDate() {
    final now = DateTime.now();
    if (isBeverages) {
      selectedDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    } else {
      selectedDate = DateTime(now.year, now.month, now.day, 0, 0, 0);
    }
  }

  Future<void> pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() {
        if (isBeverages) {
          selectedDate = DateTime(date.year, date.month, date.day, 23, 59, 59);
        } else {
          selectedDate = DateTime(date.year, date.month, date.day, 0, 0, 0);
        }
      });
    }
  }

  Future<void> pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        if (kIsWeb) {
          selectedImageFile = null;
          uploadedImageUrl = null;
        } else {
          selectedImageFile = File(picked.path);
          uploadedImageUrl = null;
        }
      });
    }
  }

  Future<String?> uploadImage() async {
    try {
      String categoryPath =
          isBeverages
              ? 'Beverages'
              : isFoodPackage
              ? 'Food'
              : 'FandBPackage';

      final timestamp = DateTime.now().millisecondsSinceEpoch;

      if (kIsWeb) {
        final pickedFile = await picker.pickImage(source: ImageSource.gallery);
        if (pickedFile == null) return null;

        final bytes = await pickedFile.readAsBytes();
        final fileName = '${timestamp}_${pickedFile.name}';

        final ref = FirebaseStorage.instance
            .ref()
            .child(categoryPath)
            .child(fileName);

        final metadata = SettableMetadata(contentType: 'image/jpeg');

        await ref.putData(bytes, metadata);
        return await ref.getDownloadURL();
      } else {
        if (selectedImageFile == null) return null;

        final fileName =
            '${timestamp}_${selectedImageFile!.path.split('/').last}';

        final ref = FirebaseStorage.instance
            .ref()
            .child(categoryPath)
            .child(fileName);

        await ref.putFile(selectedImageFile!);
        return await ref.getDownloadURL();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Image upload failed: $e')));
      return null;
    }
  }

  Future<void> submitData() async {
    if (!_formKey.currentState!.validate() ||
        selectedDate == null ||
        selectedSize == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all fields and select size'),
        ),
      );
      return;
    }

    String? imageUrl = uploadedImageUrl;
    if (imageUrl == null) {
      imageUrl = await uploadImage();
      if (imageUrl == null) return;
      setState(() {
        uploadedImageUrl = imageUrl;
      });
    }

    final data =
        isBeverages
            ? {
              'bevname': nameController.text.trim(),
              'bevquantity': int.parse(quantityController.text.trim()),
              'exp_date': Timestamp.fromDate(selectedDate!),
              'img_url': imageUrl,
              'provider_price': providerPriceController.text.trim(),
              'size': selectedSize,
              'unit_price': int.parse(unitPriceController.text.trim()),
              'min_quantity': int.parse(minquantityController.text.trim()),
              'fbstatus': packagestatus,
              'providerFB': needSizes,
            }
            : isFoodPackage
            ? {
              'foodname': nameController.text.trim(),
              'foodquantity': int.parse(quantityController.text.trim()),
              'exp_date': Timestamp.fromDate(selectedDate!),
              'image_url': imageUrl,
              'providr_price': providerPriceController.text.trim(),
              'size': selectedSize,
              'unit_price': int.parse(unitPriceController.text.trim()),
              'min_quantity': int.parse(minquantityController.text.trim()),
              'fbstatus': packagestatus,
              'providerFB': needSizes,
            }
            : {
              'package_name': nameController.text.trim(),
              'package_quantity': int.parse(quantityController.text.trim()),
              'image_url': imageUrl,
              'size': selectedSize,
              'unit_price': int.parse(unitPriceController.text.trim()),
              'min_quantity': int.parse(minquantityController.text.trim()),
              'fbstatus': packagestatus,
              'providerFB': needSizes,
            };

    final collectionName =
        isBeverages
            ? 'Beverages'
            : isFoodPackage
            ? 'Food'
            : 'FandBPackage';

    try {
      await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(widget.documentId)
          .update(data);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Updated successfully!')));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
    }
  }

  Widget buildSizeSelector() {
    return Wrap(
      spacing: 12,
      children:
          allSizes.map((size) {
            final selected = selectedSize == size;
            return ChoiceChip(
              label: Text(
                size,
                style: TextStyle(color: selected ? Colors.black : Colors.white),
              ),
              selected: selected,
              selectedColor: Colors.yellow,
              backgroundColor: Colors.grey[800],
              onSelected: (bool selectedNow) {
                setState(() {
                  if (selectedNow) {
                    selectedSize = size;
                  } else {
                    if (selectedSize == size) selectedSize = null;
                  }
                });
              },
            );
          }).toList(),
    );
  }

  Widget buildFoodSizeSelector() {
    return Wrap(
      spacing: 12,
      children:
          packagelSizes.map((size) {
            final selected = packagestatus == size;
            return ChoiceChip(
              label: Text(
                size,
                style: TextStyle(color: selected ? Colors.black : Colors.white),
              ),
              selected: selected,
              selectedColor: Colors.yellow,
              backgroundColor: Colors.grey[800],
              onSelected: (bool selectedNow) {
                setState(() {
                  if (selectedNow) {
                    packagestatus = size;
                  } else {
                    if (packagestatus == size) packagestatus = null;
                  }
                });
              },
            );
          }).toList(),
    );
  }

  Widget buildFBProviderSelector() {
    return Wrap(
      spacing: 12,
      children:
          needFBSizes.map((size) {
            final selected = needSizes == size;
            return ChoiceChip(
              label: Text(
                size,
                style: TextStyle(color: selected ? Colors.black : Colors.white),
              ),
              selected: selected,
              selectedColor: Colors.yellow,
              backgroundColor: Colors.grey[800],
              onSelected: (bool selectedNow) {
                setState(() {
                  if (selectedNow) {
                    needSizes = size;
                  } else {
                    if (needSizes == size) needSizes = null;
                  }
                });
              },
            );
          }).toList(),
    );
  }

  Widget buildImagePreview() {
    final imageUrl = uploadedImageUrl;

    if (imageUrl != null && imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        width: 150,
        height: 150,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 150,
            height: 150,
            color: Colors.red[900],
            alignment: Alignment.center,
            child: const Text(
              'Failed to load',
              style: TextStyle(color: Colors.white),
            ),
          );
        },
      );
    } else if (selectedImageFile != null && !kIsWeb) {
      return Image.file(
        selectedImageFile!,
        width: 150,
        height: 150,
        fit: BoxFit.cover,
      );
    } else {
      return Container(
        width: 150,
        height: 150,
        color: Colors.grey[700],
        child: const Icon(Icons.image, color: Colors.white70, size: 80),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr =
        selectedDate != null
            ? '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}'
            : 'Select Date';

    return Scaffold(
      appBar: AppBar(
        title: const Text('F&B Input', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ToggleButtons(
              isSelected: [
                isBeverages,
                isFoodPackage,
                isPackageFB,
              ], // Adjusted for 3 categories
              onPressed: (index) {
                setState(() {
                  isBeverages = index == 0;
                  isFoodPackage = index == 1;
                  isPackageFB = index == 2;
                });
              },
              color: Colors.white70,
              selectedColor: Colors.black,
              fillColor: Colors.yellow,
              borderRadius: BorderRadius.circular(8),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Beverages',
                    style: TextStyle(
                      color: isBeverages ? Colors.black : Colors.white70,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Food',
                    style: TextStyle(
                      color: isFoodPackage ? Colors.black : Colors.white70,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Package',
                    style: TextStyle(
                      color: isPackageFB ? Colors.black : Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                controller: widget.scrollController,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Fields common to all categories (Beverages, Food, and Package)
                      TextFormField(
                        controller: nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText:
                              isBeverages
                                  ? 'Beverage Name'
                                  : isFoodPackage
                                  ? 'Food Name'
                                  : 'Package Name',
                          labelStyle: const TextStyle(color: Colors.white70),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white54),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.yellow),
                          ),
                        ),
                        validator:
                            (v) =>
                                v == null || v.trim().isEmpty
                                    ? 'Required'
                                    : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: quantityController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText:
                              isBeverages
                                  ? 'Beverage Quantity'
                                  : isFoodPackage
                                  ? 'Food Quantity'
                                  : 'Package Quantity',
                          labelStyle: const TextStyle(color: Colors.white70),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white54),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.yellow),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          if (int.tryParse(v.trim()) == null)
                            return 'Enter valid number';
                          return null;
                        },
                      ),

                      const SizedBox(height: 12),
                      TextFormField(
                        controller: minquantityController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText:
                              isBeverages
                                  ? 'Min Beverages Quantity'
                                  : isFoodPackage
                                  ? 'Min Food Quantity'
                                  : 'Min Package Quantity',
                          labelStyle: const TextStyle(color: Colors.white70),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white54),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.yellow),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          if (int.tryParse(v.trim()) == null)
                            return 'Enter valid number';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: pickDate,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Expiration Date',
                            labelStyle: const TextStyle(color: Colors.white70),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white54),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.yellow),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                dateStr,
                                style: const TextStyle(color: Colors.white),
                              ),
                              const Icon(
                                Icons.calendar_today,
                                color: Colors.white70,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Select Size:',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      buildSizeSelector(),
                      const SizedBox(height: 12),
                      Text(
                        'Select Status:',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      buildFoodSizeSelector(),
                      const SizedBox(height: 12),
                      Text(
                        'Select Provided:',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      buildFBProviderSelector(),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: providerPriceController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText:
                              'Provider Price (Package does not allow input)',
                          labelStyle: const TextStyle(color: Colors.white70),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white54),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.yellow),
                          ),
                        ),
                        validator:
                            (v) =>
                                v == null || v.trim().isEmpty
                                    ? 'Required'
                                    : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: unitPriceController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Unit Price',
                          labelStyle: const TextStyle(color: Colors.white70),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white54),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.yellow),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          if (int.tryParse(v.trim()) == null)
                            return 'Enter valid number';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'Image:',
                              style: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                buildImagePreview(),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  onPressed: pickImage,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.yellow,
                                  ),
                                  child: const Text('Select Image'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: () async {
                              if (!_formKey.currentState!.validate() ||
                                  selectedDate == null ||
                                  selectedSize == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please complete all fields'),
                                  ),
                                );
                                return;
                              }

                              String? imageUrl = uploadedImageUrl;
                              if (imageUrl == null) {
                                imageUrl = await uploadImage();
                                if (imageUrl == null) return;
                              }

                              final updatedData = {
                                // 根据你已有的 `submitData()` 逻辑填充对应字段
                                'size': selectedSize,
                                'unit_price': int.parse(
                                  unitPriceController.text.trim(),
                                ),
                                'min_quantity': int.parse(
                                  minquantityController.text.trim(),
                                ),
                                'fbstatus': packagestatus,
                                'providerFB': needSizes,
                                'exp_date': Timestamp.fromDate(selectedDate!),
                                'img_url': imageUrl,
                              };

                              if (isBeverages) {
                                updatedData['bevname'] =
                                    nameController.text.trim();
                                updatedData['bevquantity'] = int.parse(
                                  quantityController.text.trim(),
                                );
                                updatedData['provider_price'] =
                                    providerPriceController.text.trim();
                              } else if (isFoodPackage) {
                                updatedData['foodname'] =
                                    nameController.text.trim();
                                updatedData['foodquantity'] = int.parse(
                                  quantityController.text.trim(),
                                );
                                updatedData['providr_price'] =
                                    providerPriceController.text.trim();
                              } else if (isPackageFB) {
                                updatedData['package_name'] =
                                    nameController.text.trim();
                                updatedData['package_quantity'] = int.parse(
                                  quantityController.text.trim(),
                                );
                              }

                              final collectionName =
                                  isBeverages
                                      ? 'Beverages'
                                      : isFoodPackage
                                      ? 'Food'
                                      : 'FandBPackage';

                              try {
                                await FirebaseFirestore.instance
                                    .collection(collectionName)
                                    .doc(widget.documentId!)
                                    .update(updatedData);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Updated successfully'),
                                  ),
                                );
                                Navigator.pop(context);
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Update failed: $e')),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 14,
                              ),
                            ),
                            child: const Text('Edit'),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              final collectionName =
                                  isBeverages
                                      ? 'Beverages'
                                      : isFoodPackage
                                      ? 'Food'
                                      : 'FandBPackage';

                              try {
                                await FirebaseFirestore.instance
                                    .collection(collectionName)
                                    .doc(widget.documentId!)
                                    .delete();

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Deleted successfully'),
                                  ),
                                );
                                Navigator.pop(context);
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Delete failed: $e')),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 14,
                              ),
                            ),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

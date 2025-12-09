import 'dart:typed_data';
import 'package:fasalmitra/services/listing_service.dart';
import 'package:fasalmitra/services/alert_service.dart';
import 'package:flutter/material.dart';
import 'package:fasalmitra/services/language_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fasalmitra/services/certificate_service.dart';

class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key});

  static const String routeName = '/create-listing';

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _dateController = TextEditingController();

  String? _selectedCategory;
  DateTime? _selectedDate;

  Uint8List? _certificateBytes;
  String? _certificateName;

  Uint8List? _imageBytes;
  String? _imageName;

  String? _selectedLocation;
  bool _isLoading = false;

  final List<String> _categories = ['Seeds', 'Byproduct'];

  final List<String> _states = [
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
    'Andaman and Nicobar Islands',
    'Chandigarh',
    'Dadra and Nagar Haveli and Daman and Diu',
    'Delhi',
    'Jammu and Kashmir',
    'Ladakh',
    'Lakshadweep',
    'Puducherry',
  ];

  final List<String> _seedNames = [
    'Groundnut',
    'Mustard',
    'Rapeseed',
    'Soybean',
    'Sunflower',
    'Sesame',
    'Safflower',
    'Niger Seed',
    'Castor Seed',
    'Linseed (Flaxseed)',
    'Cottonseed',
    'Coconut (Copra)',
    'Oil Palm',
    'Mahua Seed',
    'Sal Seed',
    'Neem Seed',
    'Karanj (Pongamia) Seed',
    'Jatropha Seed',
    'Rice Bran',
    'Corn Germ',
  ];

  final List<String> _byproductNames = [
    'Groundnut Cake',
    'Mustard Cake',
    'Rapeseed Meal',
    'Soybean Meal (Soya Meal)',
    'Sunflower Meal',
    'Sesame Cake',
    'Safflower Cake',
    'Niger Cake',
    'Castor Cake (De-oiled Cake)',
    'Linseed Cake',
    'Cottonseed Cake (Cottonseed Meal)',
    'Coconut Cake (Copra Cake)',
    'Palm Kernel Cake (PKC)',
    'Mahua Cake',
    'Sal Cake',
    'Neem Cake',
    'Karanj Cake',
    'Jatropha Cake',
    'De-oiled Rice Bran (DORB)',
    'Corn Germ Meal',
  ];

  List<String> get _currentProductNames =>
      _selectedCategory == 'Byproduct' ? _byproductNames : _seedNames;

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = "${picked.month}/${picked.day}/${picked.year}";
      });
    }
  }

  Future<void> _pickFile(bool isCertificate) async {
    try {
      FilePickerResult? result;
      if (isCertificate) {
        // Pick PDF or Images for certificate
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
          withData: true, // Important for Web
        );
      } else {
        // Pick Images only for product image
        result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          withData: true, // Important for Web
        );
      }

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() {
          if (isCertificate) {
            _certificateBytes = file.bytes;
            _certificateName = file.name;
          } else {
            _imageBytes = file.bytes;
            _imageName = file.name;
          }
        });
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
      if (mounted) {
        AlertService.instance.show(
          context,
          'Failed to pick file: $e',
          AlertType.error,
        );
      }
    }
  }

  Future<void> _generateCertificate() async {
    if (_nameController.text.isEmpty || _selectedDate == null) {
      AlertService.instance.show(
        context,
        'Please select Product Name and Date first',
        AlertType.warning,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final filename = await CertificateService.instance.generateCertificate(
        commodity: _nameController.text,
        date: _selectedDate!.toIso8601String().split('T')[0],
      );

      final bytes = await CertificateService.instance
          .downloadCertificateAsBytes(filename);

      if (mounted) {
        setState(() {
          _certificateName = filename;
          _certificateBytes = Uint8List.fromList(bytes);
        });
        AlertService.instance.show(
          context,
          LanguageService.instance.t('certGenerated'),
          AlertType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        AlertService.instance.show(
          context,
          'Certificate Generation Failed: $e',
          AlertType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _viewCertificate() async {
    if (_certificateBytes == null || _certificateName == null) return;

    // Determine if it is an image
    bool isImage =
        _certificateName!.toLowerCase().endsWith('.jpg') ||
        _certificateName!.toLowerCase().endsWith('.jpeg') ||
        _certificateName!.toLowerCase().endsWith('.png');

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with title and close button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      LanguageService.instance.t('certificate'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Content
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
                maxWidth: MediaQuery.of(context).size.width * 0.9,
              ),
              child: isImage
                  ? InteractiveViewer(
                      child: Image.memory(
                        _certificateBytes!,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  size: 48,
                                  color: Colors.red,
                                ),
                                const SizedBox(height: 16),
                                Text('Failed to load image: $error'),
                              ],
                            ),
                          );
                        },
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.description,
                            size: 64,
                            color: Colors.blue,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _certificateName!,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Preview not available for this file type.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _submitListing() async {
    if (_formKey.currentState!.validate()) {
      if (_certificateBytes == null) {
        AlertService.instance.show(
          context,
          'Please upload a certificate',
          AlertType.warning,
        );
        return;
      }
      if (_imageBytes == null) {
        AlertService.instance.show(
          context,
          'Please upload a product image',
          AlertType.warning,
        );
        return;
      }
      // Ensure dropdowns are selected
      if (_selectedLocation == null) {
        AlertService.instance.show(
          context,
          'Please select a location',
          AlertType.warning,
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        await ListingService.instance.createListing(
          title: _nameController.text,
          category: _selectedCategory!,
          quantity: double.parse(_quantityController.text),
          price: double.parse(_priceController.text),
          processingDate: _selectedDate!,
          certificateBytes: _certificateBytes!,
          certificateName: _certificateName!,
          imageBytes: _imageBytes!,
          imageName: _imageName!,
          location: _selectedLocation!,
        );

        if (!mounted) return;
        AlertService.instance.show(
          context,
          'Listing created successfully!',
          AlertType.success,
        );
        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;
        AlertService.instance.show(context, 'Error: $e', AlertType.error);
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: LanguageService.instance,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(LanguageService.instance.t('listProduct')),
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Category Dropdown
                            DropdownButtonFormField<String>(
                              value: _selectedCategory,
                              decoration: InputDecoration(
                                labelText: LanguageService.instance.t(
                                  'categoryLabel',
                                ),
                                border: const OutlineInputBorder(),
                              ),
                              items: ['Seeds', 'Byproduct'].map((category) {
                                return DropdownMenuItem(
                                  value: category,
                                  child: Text(
                                    LanguageService.instance.t(
                                      category.toLowerCase(),
                                    ),
                                  ), // 'seeds', 'byproduct' keys
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedCategory = value;
                                    // Clear the product name when category changes
                                    _nameController.clear();
                                  });
                                }
                              },
                              validator: (value) => value == null
                                  ? LanguageService.instance.t('categoryLabel')
                                  : null,
                            ),
                            const SizedBox(height: 16),

                            // Product Name (Autocomplete)
                            LayoutBuilder(
                              builder: (context, constraints) {
                                return Autocomplete<String>(
                                  optionsBuilder:
                                      (TextEditingValue textEditingValue) {
                                        if (textEditingValue.text.isEmpty) {
                                          return const Iterable<String>.empty();
                                        }
                                        return _currentProductNames.where((
                                          String option,
                                        ) {
                                          return option.toLowerCase().contains(
                                            textEditingValue.text.toLowerCase(),
                                          );
                                        });
                                      },
                                  onSelected: (String selection) {
                                    _nameController.text = selection;
                                  },
                                  fieldViewBuilder:
                                      (
                                        context,
                                        textEditingController,
                                        focusNode,
                                        onFieldSubmitted,
                                      ) {
                                        // Sync: if external populated (e.g. selection), sync internal
                                        if (_nameController.text.isNotEmpty &&
                                            textEditingController
                                                .text
                                                .isEmpty) {
                                          textEditingController.text =
                                              _nameController.text;
                                        }

                                        return TextFormField(
                                          controller: textEditingController,
                                          focusNode: focusNode,
                                          decoration: InputDecoration(
                                            labelText: LanguageService.instance
                                                .t('productNameLabel'),
                                            hintText: LanguageService.instance
                                                .t('productNameHint'),
                                            border: const OutlineInputBorder(),
                                            suffixIcon: const Icon(
                                              Icons.arrow_drop_down,
                                            ),
                                          ),
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return LanguageService.instance.t(
                                                'productNameLabel',
                                              );
                                            }
                                            if (!_currentProductNames.contains(
                                              value,
                                            )) {
                                              return 'Please select a valid product';
                                            }
                                            return null;
                                          },
                                          onChanged: (value) {
                                            _nameController.text = value;
                                          },
                                        );
                                      },
                                  optionsViewBuilder:
                                      (context, onSelected, options) {
                                        return Align(
                                          alignment: Alignment.topLeft,
                                          child: Material(
                                            elevation: 4.0,
                                            child: SizedBox(
                                              width: constraints.maxWidth,
                                              child: ListView.builder(
                                                padding: EdgeInsets.zero,
                                                shrinkWrap: true,
                                                itemCount: options.length,
                                                itemBuilder:
                                                    (
                                                      BuildContext context,
                                                      int index,
                                                    ) {
                                                      final String option =
                                                          options.elementAt(
                                                            index,
                                                          );
                                                      return InkWell(
                                                        onTap: () {
                                                          onSelected(option);
                                                        },
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets.all(
                                                                16.0,
                                                              ),
                                                          child: Text(option),
                                                        ),
                                                      );
                                                    },
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                );
                              },
                            ),
                            const SizedBox(height: 16),

                            // Processing Date
                            TextFormField(
                              controller: _dateController,
                              decoration: InputDecoration(
                                labelText: LanguageService.instance.t(
                                  'dateLabel',
                                ),
                                border: const OutlineInputBorder(),
                                suffixIcon: const Icon(Icons.calendar_today),
                              ),
                              readOnly: true,
                              onTap: () => _selectDate(context),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return LanguageService.instance.t(
                                    'dateLabel',
                                  );
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Quantity
                            TextFormField(
                              controller: _quantityController,
                              decoration: InputDecoration(
                                labelText: LanguageService.instance.t(
                                  'qtyLabel',
                                ),
                                border: const OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return LanguageService.instance.t('qtyLabel');
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Invalid number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Price
                            TextFormField(
                              controller: _priceController,
                              decoration: InputDecoration(
                                labelText: LanguageService.instance.t(
                                  'priceLabel',
                                ),
                                border: const OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return LanguageService.instance.t(
                                    'priceLabel',
                                  );
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Invalid number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Certificate Picker
                            Text(
                              LanguageService.instance.t('certLabel'),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                if (_certificateBytes == null)
                                  ElevatedButton.icon(
                                    onPressed: _isLoading
                                        ? null
                                        : _generateCertificate,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange.shade600,
                                      foregroundColor: Colors.white,
                                    ),
                                    icon: const Icon(
                                      Icons.verified_user,
                                      size: 18,
                                    ),
                                    label: Text(
                                      LanguageService.instance.t(
                                        'generateCertificate',
                                      ),
                                    ),
                                  )
                                else
                                  Expanded(
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _certificateName!,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.visibility),
                                          tooltip: 'View Certificate',
                                          onPressed: _viewCertificate,
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.close,
                                            color: Colors.red,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _certificateBytes = null;
                                              _certificateName = null;
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Image Picker
                            Text(
                              LanguageService.instance.t('imageLabel'),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                OutlinedButton(
                                  onPressed: () => _pickFile(false),
                                  child: Text(
                                    LanguageService.instance.t('chooseFile'),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    _imageName ??
                                        LanguageService.instance.t('noFile'),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Location Dropdown
                            DropdownButtonFormField<String>(
                              value: _selectedLocation,
                              decoration: InputDecoration(
                                labelText: LanguageService.instance.t(
                                  'locationLabel',
                                ),
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.location_on),
                              ),
                              items: _states.map((location) {
                                return DropdownMenuItem(
                                  value: location,
                                  child: Text(location),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedLocation = value;
                                });
                              },
                              validator: (value) => value == null
                                  ? LanguageService.instance.t('locationLabel')
                                  : null,
                            ),
                            const SizedBox(height: 24),

                            // Submit Button
                            SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _submitListing,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF386641),
                                  foregroundColor: Colors.white,
                                ),
                                child: _isLoading
                                    ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                    : Text(
                                        LanguageService.instance.t(
                                          'submitListing',
                                        ),
                                        style: const TextStyle(fontSize: 16),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}

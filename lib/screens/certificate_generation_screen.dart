import 'package:flutter/material.dart';
import 'package:fasalmitra/services/language_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fasalmitra/services/certificate_service.dart';
import 'package:fasalmitra/services/alert_service.dart';

class CertificateGenerationScreen extends StatefulWidget {
  const CertificateGenerationScreen({super.key});

  static const String routeName = '/certificate-generation';

  @override
  State<CertificateGenerationScreen> createState() =>
      _CertificateGenerationScreenState();
}

class _CertificateGenerationScreenState
    extends State<CertificateGenerationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commodityController = TextEditingController();
  final _dateController = TextEditingController();
  DateTime? _selectedDate;
  bool _isLoading = false;
  String? _generatedCertificateUrl;

  @override
  void dispose() {
    _commodityController.dispose();
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
        // Format as YYYY-MM-DD for API
        _dateController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _handleGenerate() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      AlertService.instance.show(
        context,
        LanguageService.instance.t('selectDate'),
        AlertType.warning,
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _generatedCertificateUrl = null;
    });

    try {
      final filename = await CertificateService.instance.generateCertificate(
        commodity: _commodityController.text.trim(),
        date: _dateController.text,
      );

      if (!mounted) return;

      AlertService.instance.show(
        context,
        LanguageService.instance.t('certGenerated'),
        AlertType.success,
      );

      setState(() {
        // Construct full URL assuming media path pattern.
        // This might need adjustment based on backend config,
        // usually it's passed back full or we assume /media/
        // Using service helper
        _generatedCertificateUrl = CertificateService.instance
            .getCertificateUrl(filename);
      });
    } catch (e) {
      if (!mounted) return;
      debugPrint('Certificate Generation Error: $e');
      AlertService.instance.show(
        context,
        LanguageService.instance.t('somethingWrong'),
        AlertType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _downloadCertificate() async {
    if (_generatedCertificateUrl == null) return;

    final urlString = _generatedCertificateUrl!;
    final uri = Uri.parse(urlString);

    try {
      // Try launching directly. canLaunchUrl can be flaky on some platforms/configs
      // and we want to catch the specific error if it fails.
      // LaunchMode.externalApplication is often better for downloads/new tabs.
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $urlString');
      }
    } catch (e) {
      if (mounted) {
        AlertService.instance.show(
          context,
          'Failed to open: $urlString\nError: $e',
          AlertType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(LanguageService.instance.t('genCertTitle'))),
      body: AnimatedBuilder(
        animation: LanguageService.instance,
        builder: (context, child) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        LanguageService.instance.t('genCertTitle'),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Commodity Input
                      TextFormField(
                        controller: _commodityController,
                        decoration: InputDecoration(
                          labelText: LanguageService.instance.t(
                            'commodityLabel',
                          ),
                          hintText: LanguageService.instance.t('commodityHint'),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return LanguageService.instance.t('enterCommodity');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Date Input
                      TextFormField(
                        controller: _dateController,
                        decoration: InputDecoration(
                          labelText: LanguageService.instance.t(
                            'processingDate',
                          ),
                          hintText: 'YYYY-MM-DD',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          suffixIcon: const Icon(Icons.calendar_today),
                        ),
                        readOnly: true,
                        onTap: () => _selectDate(context),
                      ),
                      const SizedBox(height: 32),

                      // Generate Button
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleGenerate,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                              0xFF1B5E20,
                            ), // Dark Green like screenshot
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : Text(
                                  LanguageService.instance.t('generateCertBtn'),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),

                      // Download Section
                      if (_generatedCertificateUrl != null) ...[
                        const SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            border: Border.all(color: Colors.green),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 48,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                LanguageService.instance.t('certReady'),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                onPressed: _downloadCertificate,
                                icon: const Icon(Icons.download),
                                label: Text(
                                  LanguageService.instance.t('downloadCert'),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.green.shade800,
                                  side: BorderSide(
                                    color: Colors.green.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

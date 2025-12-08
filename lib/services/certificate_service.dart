import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fasalmitra/services/auth_service.dart';

class CertificateService {
  CertificateService._();
  static final CertificateService instance = CertificateService._();

  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  Future<String> generateCertificate({
    required String commodity,
    required String date,
  }) async {
    final token = await AuthService.instance.getToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final url = Uri.parse('$_baseUrl/generate-certificate/');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'commodity': commodity, 'date': date}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['filename'];
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to generate certificate');
    }
  }

  String getCertificateUrl(String filename) {
    // Schema: GET /download-certificate/<filename>/
    // Using simple concatenation to match how generate-certificate works.
    // Assuming _baseUrl does not end with / as per usage in generateCertificate.
    return '$_baseUrl/download-certificate/$filename/';
  }

  Future<List<int>> downloadCertificateAsBytes(String filename) async {
    final token = await AuthService.instance.getToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final url = Uri.parse(getCertificateUrl(filename));
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Failed to download certificate: ${response.statusCode}');
    }
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;

class PredictionService {
  PredictionService._();

  static final PredictionService instance = PredictionService._();

  static const String _baseUrl =
      'https://oilseed-price-api-1.onrender.com/api/dashboard';

  Future<Map<String, dynamic>> fetchDashboardData(
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
          'Failed to load predictions: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching predictions: $e');
    }
  }
}

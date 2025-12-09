import 'package:fasalmitra/services/api.dart';
import 'package:fasalmitra/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart';

class ListingData {
  const ListingData({
    required this.id,
    required this.title,
    required this.price,
    required this.priceUnit,
    this.description,
    this.imageUrls = const [],
    this.sellerId,
    this.sellerName,
    this.farmerProfileImage,
    this.category,
    this.type,
    this.rating,
    this.certificateGrade,
    this.certificateUrl,
    this.isCertified = false,
    this.processingDate,
    this.quantity,
    this.quantityUnit,
    this.distance,
    this.location,
    this.score,
  });

  factory ListingData.fromJson(Map<String, dynamic> json) {
    // Helper to handle diverse API types (string vs double)
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    // Handle Image URL: API returns relative path like "/media/..."
    // We need to prepend base URL if it's relative.
    String resolveUrl(String? path) {
      if (path == null || path.isEmpty) return '';
      if (path.startsWith('http')) return path;

      // Use the configured API Base URL
      // If ApiService.baseUrl defines the API root (e.g. /api), we might need the host root.
      // But typically for Django matching defaults, media is at root /media.
      // If baseUrl is http://host/api, we want http://host/media.

      String baseUrl = ApiService.instance.baseUrl;

      // If baseUrl ends with /api, strip it to get root
      if (baseUrl.endsWith('/api')) {
        baseUrl = baseUrl.substring(0, baseUrl.length - 4);
      } else if (baseUrl.endsWith('/api/')) {
        baseUrl = baseUrl.substring(0, baseUrl.length - 5);
      }

      // Ensure no double slash
      if (baseUrl.endsWith('/') && path.startsWith('/')) {
        return '$baseUrl${path.substring(1)}';
      } else if (!baseUrl.endsWith('/') && !path.startsWith('/')) {
        return '$baseUrl/$path';
      }

      return '$baseUrl$path';
    }

    return ListingData(
      id: json['id'].toString(), // API returns int ID
      title: json['product_name'] ?? json['title'] ?? 'Unknown Product',
      price: parseDouble(
        json['price_per_kg'] ?? json['market_price_per_kg_inr'],
      ),
      priceUnit: '/kg',
      description: null, // API doesn't have description
      imageUrls: json['image'] != null ? [resolveUrl(json['image'])] : [],
      sellerId: json['owner']
          ?.toString(), // owner is ID or username depending on endpoint
      sellerName: json['owner']?.toString(), // using same for name
      farmerProfileImage: null,
      category: json['type'] == 'seeds'
          ? 'Seeds'
          : 'Byproduct', // Map type to category or keep as type
      type: json['type'],
      rating: null,
      certificateGrade: null, // could map 'quality' here?
      certificateUrl: resolveUrl(json['certificate']),
      isCertified: json['certificate'] != null,
      processingDate: json['date_of_listing'] != null
          ? DateTime.tryParse(json['date_of_listing']) ?? DateTime.now()
          : json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      quantity: parseDouble(json['amount_kg']),
      quantityUnit: 'kg',
      distance: null, // API doesn't give distance yet
      location: json['location'],
      score: parseDouble(json['score']),
    );
  }

  final String id;
  final String title;
  final double price;
  final String priceUnit;
  final String? description;
  final List<String> imageUrls;
  final String? sellerId;
  final String? sellerName;
  final String? farmerProfileImage;
  final String? category;
  final String? type;
  final double? rating;
  final String? certificateGrade;
  final String? certificateUrl;
  final bool isCertified;
  final DateTime? processingDate;
  final double? quantity;
  final String? quantityUnit;
  final double? distance;
  final String? location;
  final double? score;
}

class ListingService {
  ListingService._();

  static final ListingService instance = ListingService._();

  Future<List<ListingData>> getRecentListings({int limit = 10}) async {
    // Fetch from market API and just take first few
    final listings = await getMarketplaceListings();
    if (listings.length > limit) {
      return listings.sublist(0, limit);
    }
    return listings;
  }

  Future<List<ListingData>> getListingsByCategory(String category) async {
    // Naive implementation: fetch all and filter client side
    // OR create mapping: "Seeds" -> /market/seeds/, "Byproduct" -> /market/byproducts/
    if (category.toLowerCase() == 'seeds') {
      return _fetchFromEndpoint('/market/seeds/');
    } else if (category.toLowerCase() == 'byproduct') {
      return _fetchFromEndpoint('/market/byproducts/');
    }
    return getMarketplaceListings(); // Fallback
  }

  Future<List<ListingData>> getMarketplaceListings({
    String sortBy = 'distance',
    String? categoryFilter,
    String? searchQuery,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    try {
      // 1. Fetch from both endpoints
      final seeds = await _fetchFromEndpoint('/market/seeds/');
      final byproducts = await _fetchFromEndpoint('/market/byproducts/');

      var listings = [...seeds, ...byproducts];

      // 2. Filter Client Side (since API doesn't support query params yet per doc)
      if (categoryFilter != null && categoryFilter.isNotEmpty) {
        // Map category filter strings
        final filterLower = categoryFilter.toLowerCase();
        listings = listings
            .where(
              (l) =>
                  (l.category?.toLowerCase() == filterLower) ||
                  (l.type?.toLowerCase() == filterLower),
            )
            .toList();
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        listings = listings
            .where((l) => l.title.toLowerCase().contains(query))
            .toList();
      }

      // 3. Sort
      switch (sortBy) {
        case 'price_high':
          listings.sort((a, b) => b.price.compareTo(a.price));
          break;
        case 'price_low':
          listings.sort((a, b) => a.price.compareTo(b.price));
          break;
        case 'date_recent':
          // ... sorting logic ...
          break;
      }

      return listings;
    } catch (e) {
      debugPrint('Error fetching marketplace listings: $e');
      return [];
    }
  }

  Future<List<ListingData>> _fetchFromEndpoint(String path) async {
    try {
      final encodedToken = AuthService.instance.token;
      final response = await ApiService.instance.get(path, token: encodedToken);

      // Backend returns a List directly or wrapped
      dynamic listData;
      if (response is List) {
        listData = response;
      } else if (response is Map &&
          response.containsKey('data') &&
          response['data'] is List) {
        listData = response['data'];
      } else if (response is Map &&
          response['success'] != null &&
          response['success'] is Map &&
          response['success']['body'] is List) {
        // Legacy/Alternative structure check
        listData = response['success']['body'];
      }

      if (listData is List) {
        return listData
            .map((item) => ListingData.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Fetch error $path: $e');
      return [];
    }
  }

  Future<void> createListing({
    required String title,
    required String category, // 'Seeds' or 'Byproduct'
    required double quantity,
    required double price,
    required DateTime processingDate,
    required Uint8List certificateBytes,
    required String certificateName,
    required Uint8List imageBytes,
    required String imageName,
    required String location,
    // quality removed
  }) async {
    final token = AuthService.instance.token;
    if (token == null) throw Exception('User not logged in');

    // Map fields to API request
    final type = category.toLowerCase().contains('seed')
        ? 'seeds'
        : 'byproduct';

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiService.instance.baseUrl}/create/'),
    );

    request.headers['Authorization'] = 'Bearer $token';

    request.fields.addAll({
      'type': type,
      'product_name': title,
      'date_of_listing': processingDate.toIso8601String().split('T')[0],
      'amount_kg': quantity.toString(),
      'market_price_per_kg_inr': price.toString(),
      'location': location,
      // 'quality': quality removed
    });

    // Helper to add file from bytes
    void addFile(String fieldName, Uint8List bytes, String filename) {
      MediaType? contentType;
      if (filename.toLowerCase().endsWith('.pdf')) {
        contentType = MediaType('application', 'pdf');
      } else if (filename.toLowerCase().endsWith('.jpg') ||
          filename.toLowerCase().endsWith('.jpeg')) {
        contentType = MediaType('image', 'jpeg');
      } else if (filename.toLowerCase().endsWith('.png')) {
        contentType = MediaType('image', 'png');
      }

      request.files.add(
        http.MultipartFile.fromBytes(
          fieldName,
          bytes,
          filename: filename,
          contentType: contentType,
        ),
      );
    }

    addFile('image', imageBytes, imageName);
    addFile('certificate', certificateBytes, certificateName);

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to create listing: ${response.body}');
    }
  }

  Future<void> buyProduct(String productId) async {
    final token = AuthService.instance.token;
    if (token == null) throw Exception('User not logged in');

    try {
      final response = await ApiService.instance.post(
        '/buy/',
        body: {'product_id': int.parse(productId)},
        token: token,
      );

      // If ApiService.post returns successfully, it means 200 OK (usually).
      // We can double check response if needed, but standard `post` usually throws on non-200 if built that way.
      // Based on AuthService, it returns a Map.
      if (response['error'] != null) {
        throw Exception(response['error']);
      }
    } catch (e) {
      throw Exception('Purchase failed: $e');
    }
  }

  Future<void> updateListing(String id, Map<String, dynamic> data) async {
    // API Documentation does not specifically list an update endpoint.
    // Assuming unsupported or out of scope for this migration task.
    // Leaving empty or throwing error.
    throw UnimplementedError('Update listing not supported in API v1');
  }

  Future<void> deleteListing(String id) async {
    // API Doc doesn't list delete.
    throw UnimplementedError('Delete listing not supported in API v1');
  }

  Future<List<ListingData>> fetchListingsByUser(String userId) async {
    try {
      // Ignore userId arg, API uses token to identify user
      final seeds = await _fetchFromEndpoint('/seed/');
      final byproducts = await _fetchFromEndpoint('/byproduct/');
      return [...seeds, ...byproducts];
    } catch (e) {
      return [];
    }
  }

  // Hardcoded Mandi Data (Synced with mandi.json)
  // TODO: Move this to an asset file (assets/mandi.json) and load dynamically
  static const Map<String, dynamic> _mandiData = {
    "generated_on": "2025-12-09",
    "unit": "INR per kg",
    "data": {
      "Groundnut": {
        "byproduct": "Groundnut Cake",
        "states": {
          "Andhra Pradesh": 50.5,
          "Arunachal Pradesh": 52.68,
          "Assam": 45.16,
          "Bihar": 48.22,
          "Chhattisgarh": 47.59,
          "Goa": 53.86,
          "Gujarat": 52,
          "Haryana": 53.13,
          "Himachal Pradesh": 55.77,
          "Jharkhand": 45.92,
          "Karnataka": 49.8,
          "Kerala": 50.02,
          "Madhya Pradesh": 50.8,
          "Maharashtra": 51.5,
          "Manipur": 45.22,
          "Meghalaya": 47.53,
          "Mizoram": 51.04,
          "Nagaland": 45.18,
          "Odisha": 47.29,
          "Punjab": 52.8,
          "Rajasthan": 53,
          "Sikkim": 51.52,
          "Tamil Nadu": 49.2,
          "Telangana": 47.55,
          "Tripura": 52.06,
          "Uttar Pradesh": 54.76,
          "Uttarakhand": 44.93,
          "West Bengal": 54.71,
          "Andaman and Nicobar Islands": 53.4,
          "Chandigarh": 49.02,
          "Dadra and Nagar Haveli and Daman and Diu": 46.76,
          "Delhi": 56.56,
          "Jammu and Kashmir": 48.97,
          "Ladakh": 45.99,
          "Lakshadweep": 46.04,
          "Puducherry": 55.22,
        },
      },
      "Mustard": {
        "byproduct": "Mustard Cake",
        "states": {
          "Andhra Pradesh": 48.43,
          "Arunachal Pradesh": 50.73,
          "Assam": 49.86,
          "Bihar": 47.66,
          "Chhattisgarh": 52.62,
          "Goa": 45.87,
          "Gujarat": 47.84,
          "Haryana": 48,
          "Himachal Pradesh": 50.99,
          "Jharkhand": 48.59,
          "Karnataka": 51.35,
          "Kerala": 48.13,
          "Madhya Pradesh": 47,
          "Maharashtra": 49.57,
          "Manipur": 42.1,
          "Meghalaya": 44.16,
          "Mizoram": 44.86,
          "Nagaland": 42.48,
          "Odisha": 44.22,
          "Punjab": 49,
          "Rajasthan": 46.5,
          "Sikkim": 42.73,
          "Tamil Nadu": 44.73,
          "Telangana": 48.79,
          "Tripura": 45.72,
          "Uttar Pradesh": 45.5,
          "Uttarakhand": 45.78,
          "West Bengal": 43.96,
          "Andaman and Nicobar Islands": 44.61,
          "Chandigarh": 52.2,
          "Dadra and Nagar Haveli and Daman and Diu": 48.93,
          "Delhi": 47.5,
          "Jammu and Kashmir": 48.49,
          "Ladakh": 43.52,
          "Lakshadweep": 49.85,
          "Puducherry": 43.43,
        },
      },
      "Rapeseed": {
        "byproduct": "Rapeseed Meal",
        "states": {
          "Andhra Pradesh": 31.07,
          "Arunachal Pradesh": 35.76,
          "Assam": 33.08,
          "Bihar": 32.44,
          "Chhattisgarh": 33.42,
          "Goa": 34.63,
          "Gujarat": 34.12,
          "Haryana": 31.5,
          "Himachal Pradesh": 29.92,
          "Jharkhand": 28.41,
          "Karnataka": 30.58,
          "Kerala": 30.22,
          "Madhya Pradesh": 33,
          "Maharashtra": 29.78,
          "Manipur": 35.4,
          "Meghalaya": 34.89,
          "Mizoram": 30.58,
          "Nagaland": 33.19,
          "Odisha": 31.2,
          "Punjab": 35.18,
          "Rajasthan": 32.5,
          "Sikkim": 31.68,
          "Tamil Nadu": 30.19,
          "Telangana": 30.05,
          "Tripura": 32.47,
          "Uttar Pradesh": 31,
          "Uttarakhand": 30.18,
          "West Bengal": 32.65,
          "Andaman and Nicobar Islands": 35.06,
          "Chandigarh": 31.23,
          "Dadra and Nagar Haveli and Daman and Diu": 29.84,
          "Delhi": 35.82,
          "Jammu and Kashmir": 32.07,
          "Ladakh": 28.86,
          "Lakshadweep": 28.52,
          "Puducherry": 29.0,
        },
      },
      "Soybean": {
        "byproduct": "Soybean Meal",
        "states": {
          "Andhra Pradesh": 40.17,
          "Arunachal Pradesh": 41.71,
          "Assam": 38.25,
          "Bihar": 34.9,
          "Chhattisgarh": 37.87,
          "Goa": 43.62,
          "Gujarat": 39.2,
          "Haryana": 39.25,
          "Himachal Pradesh": 43.39,
          "Jharkhand": 42.36,
          "Karnataka": 34.41,
          "Kerala": 41.04,
          "Madhya Pradesh": 39.5,
          "Maharashtra": 40.2,
          "Manipur": 40.68,
          "Meghalaya": 39.33,
          "Mizoram": 36.8,
          "Nagaland": 40.3,
          "Odisha": 35.35,
          "Punjab": 38.37,
          "Rajasthan": 38.5,
          "Sikkim": 38.55,
          "Tamil Nadu": 43.23,
          "Telangana": 37.5,
          "Tripura": 42.5,
          "Uttar Pradesh": 36.77,
          "Uttarakhand": 38.99,
          "West Bengal": 35.97,
          "Andaman and Nicobar Islands": 42.84,
          "Chandigarh": 42.45,
          "Dadra and Nagar Haveli and Daman and Diu": 37.09,
          "Delhi": 40.28,
          "Jammu and Kashmir": 40.0,
          "Ladakh": 35.73,
          "Lakshadweep": 41.44,
          "Puducherry": 39.35,
        },
      },
      "Sunflower": {
        "byproduct": "Sunflower Meal",
        "states": {
          "Andhra Pradesh": 33.8,
          "Arunachal Pradesh": 36.41,
          "Assam": 34.37,
          "Bihar": 30.03,
          "Chhattisgarh": 32.68,
          "Goa": 30.19,
          "Gujarat": 37.64,
          "Haryana": 37.23,
          "Himachal Pradesh": 36.84,
          "Jharkhand": 32.55,
          "Karnataka": 34.5,
          "Kerala": 30.5,
          "Madhya Pradesh": 37.22,
          "Maharashtra": 35.2,
          "Manipur": 37.79,
          "Meghalaya": 30.73,
          "Mizoram": 34.01,
          "Nagaland": 30.6,
          "Odisha": 36.26,
          "Punjab": 36.3,
          "Rajasthan": 31.08,
          "Sikkim": 33.92,
          "Tamil Nadu": 34.53,
          "Telangana": 33,
          "Tripura": 32.2,
          "Uttar Pradesh": 37.18,
          "Uttarakhand": 33.5,
          "West Bengal": 31.76,
          "Andaman and Nicobar Islands": 34.45,
          "Chandigarh": 36.01,
          "Dadra and Nagar Haveli and Daman and Diu": 31.68,
          "Delhi": 32.58,
          "Jammu and Kashmir": 38.18,
          "Ladakh": 35.35,
          "Lakshadweep": 33.62,
          "Puducherry": 34.27,
        },
      },
      "Sesame (Til)": {
        "byproduct": "Sesame Cake",
        "states": {
          "Andhra Pradesh": 69.18,
          "Arunachal Pradesh": 71.07,
          "Assam": 73.14,
          "Bihar": 77.71,
          "Chhattisgarh": 71.17,
          "Goa": 70.99,
          "Gujarat": 76,
          "Haryana": 68.26,
          "Himachal Pradesh": 78.49,
          "Jharkhand": 71.15,
          "Karnataka": 83.5,
          "Kerala": 82.67,
          "Madhya Pradesh": 77,
          "Maharashtra": 68.26,
          "Manipur": 71.31,
          "Meghalaya": 79.19,
          "Mizoram": 70.88,
          "Nagaland": 69.38,
          "Odisha": 84.05,
          "Punjab": 77.4,
          "Rajasthan": 78,
          "Sikkim": 75.6,
          "Tamil Nadu": 81.3,
          "Telangana": 81.72,
          "Tripura": 70.45,
          "Uttar Pradesh": 74,
          "Uttarakhand": 68.74,
          "West Bengal": 75.5,
          "Andaman and Nicobar Islands": 74.84,
          "Chandigarh": 74.7,
          "Dadra and Nagar Haveli and Daman and Diu": 75.5,
          "Delhi": 80.28,
          "Jammu and Kashmir": 79.27,
          "Ladakh": 84.94,
          "Lakshadweep": 68.77,
          "Puducherry": 74.32,
        },
      },
      "Safflower": {
        "byproduct": "Safflower Cake",
        "states": {
          "Andhra Pradesh": 37.98,
          "Arunachal Pradesh": 42.93,
          "Assam": 37.12,
          "Bihar": 36.56,
          "Chhattisgarh": 39.01,
          "Goa": 38.76,
          "Gujarat": 37.4,
          "Haryana": 37.13,
          "Himachal Pradesh": 43.51,
          "Jharkhand": 38.96,
          "Karnataka": 39,
          "Kerala": 42.93,
          "Madhya Pradesh": 39.98,
          "Maharashtra": 41,
          "Manipur": 35.24,
          "Meghalaya": 44.23,
          "Mizoram": 42.69,
          "Nagaland": 43.95,
          "Odisha": 43.54,
          "Punjab": 42.81,
          "Rajasthan": 36.34,
          "Sikkim": 39.36,
          "Tamil Nadu": 36.79,
          "Telangana": 38.5,
          "Tripura": 38.56,
          "Uttar Pradesh": 35.32,
          "Uttarakhand": 38.35,
          "West Bengal": 44.1,
          "Andaman and Nicobar Islands": 37.27,
          "Chandigarh": 42.19,
          "Dadra and Nagar Haveli and Daman and Diu": 39.07,
          "Delhi": 38.77,
          "Jammu and Kashmir": 43.84,
          "Ladakh": 44.2,
          "Lakshadweep": 40.03,
          "Puducherry": 41.57,
        },
      },
      "Niger Seed": {
        "byproduct": "Niger Cake",
        "states": {
          "Andhra Pradesh": 63.7,
          "Arunachal Pradesh": 66.06,
          "Assam": 77.26,
          "Bihar": 70.77,
          "Chhattisgarh": 69.8,
          "Goa": 70.15,
          "Gujarat": 73.58,
          "Haryana": 62.07,
          "Himachal Pradesh": 70.85,
          "Jharkhand": 69.5,
          "Karnataka": 75.33,
          "Kerala": 63.74,
          "Madhya Pradesh": 70.5,
          "Maharashtra": 69,
          "Manipur": 77.13,
          "Meghalaya": 62.45,
          "Mizoram": 64.21,
          "Nagaland": 71.03,
          "Odisha": 68.5,
          "Punjab": 72.37,
          "Rajasthan": 65.04,
          "Sikkim": 63.11,
          "Tamil Nadu": 75.96,
          "Telangana": 65.22,
          "Tripura": 71.03,
          "Uttar Pradesh": 71.44,
          "Uttarakhand": 68.1,
          "West Bengal": 70.84,
          "Andaman and Nicobar Islands": 69.83,
          "Chandigarh": 76.7,
          "Dadra and Nagar Haveli and Daman and Diu": 64.52,
          "Delhi": 73.05,
          "Jammu and Kashmir": 65.09,
          "Ladakh": 67.71,
          "Lakshadweep": 72.31,
          "Puducherry": 66.12,
        },
      },
      "Castor Seed": {
        "byproduct": "Castor Cake",
        "states": {
          "Andhra Pradesh": 49.5,
          "Arunachal Pradesh": 48.59,
          "Assam": 53.91,
          "Bihar": 45.62,
          "Chhattisgarh": 50.32,
          "Goa": 56.91,
          "Gujarat": 52,
          "Haryana": 56.89,
          "Himachal Pradesh": 45.63,
          "Jharkhand": 47.33,
          "Karnataka": 47.97,
          "Kerala": 56.12,
          "Madhya Pradesh": 55.48,
          "Maharashtra": 55.46,
          "Manipur": 49.24,
          "Meghalaya": 46.66,
          "Mizoram": 54.91,
          "Nagaland": 53.32,
          "Odisha": 52.2,
          "Punjab": 56.78,
          "Rajasthan": 51,
          "Sikkim": 52.71,
          "Tamil Nadu": 44.83,
          "Telangana": 54.7,
          "Tripura": 48.39,
          "Uttar Pradesh": 52.83,
          "Uttarakhand": 56.19,
          "West Bengal": 46.37,
          "Andaman and Nicobar Islands": 46.14,
          "Chandigarh": 46.04,
          "Dadra and Nagar Haveli and Daman and Diu": 51.48,
          "Delhi": 48.06,
          "Jammu and Kashmir": 52.11,
          "Ladakh": 53.49,
          "Lakshadweep": 47.22,
          "Puducherry": 52.47,
        },
      },
      "Linseed (Flaxseed)": {
        "byproduct": "Linseed Cake",
        "states": {
          "Andhra Pradesh": 57.19,
          "Arunachal Pradesh": 60.46,
          "Assam": 66.52,
          "Bihar": 60,
          "Chhattisgarh": 65.66,
          "Goa": 54.69,
          "Gujarat": 59.51,
          "Haryana": 57.38,
          "Himachal Pradesh": 53.4,
          "Jharkhand": 59.5,
          "Karnataka": 64.57,
          "Kerala": 62.62,
          "Madhya Pradesh": 62,
          "Maharashtra": 57.16,
          "Manipur": 64.13,
          "Meghalaya": 61.38,
          "Mizoram": 59.57,
          "Nagaland": 53.49,
          "Odisha": 54.44,
          "Punjab": 66.2,
          "Rajasthan": 66.5,
          "Sikkim": 61.29,
          "Tamil Nadu": 65.49,
          "Telangana": 61.83,
          "Tripura": 55.5,
          "Uttar Pradesh": 61,
          "Uttarakhand": 55.2,
          "West Bengal": 57.84,
          "Andaman and Nicobar Islands": 66.43,
          "Chandigarh": 64.93,
          "Dadra and Nagar Haveli and Daman and Diu": 65.87,
          "Delhi": 66.43,
          "Jammu and Kashmir": 56.41,
          "Ladakh": 56.98,
          "Lakshadweep": 54.85,
          "Puducherry": 64.7,
        },
      },
      "Cottonseed": {
        "byproduct": "Cottonseed Cake",
        "states": {
          "Andhra Pradesh": 31.26,
          "Arunachal Pradesh": 27.98,
          "Assam": 29.45,
          "Bihar": 26.25,
          "Chhattisgarh": 31.58,
          "Goa": 31.13,
          "Gujarat": 28,
          "Haryana": 30,
          "Himachal Pradesh": 31.9,
          "Jharkhand": 30.76,
          "Karnataka": 31.25,
          "Kerala": 25.36,
          "Madhya Pradesh": 30.25,
          "Maharashtra": 29,
          "Manipur": 27.47,
          "Meghalaya": 31.58,
          "Mizoram": 30.7,
          "Nagaland": 31.13,
          "Odisha": 30.76,
          "Punjab": 27.02,
          "Rajasthan": 30.6,
          "Sikkim": 25.93,
          "Tamil Nadu": 31.18,
          "Telangana": 27.5,
          "Tripura": 31.09,
          "Uttar Pradesh": 26.72,
          "Uttarakhand": 30.8,
          "West Bengal": 28.35,
          "Andaman and Nicobar Islands": 27.29,
          "Chandigarh": 30.65,
          "Dadra and Nagar Haveli and Daman and Diu": 26.75,
          "Delhi": 25.35,
          "Jammu and Kashmir": 26.52,
          "Ladakh": 27.45,
          "Lakshadweep": 31.13,
          "Puducherry": 31.83,
        },
      },
      "Coconut (Copra)": {
        "byproduct": "Coconut Cake",
        "states": {
          "Andhra Pradesh": 30,
          "Arunachal Pradesh": 28.17,
          "Assam": 30.76,
          "Bihar": 29.03,
          "Chhattisgarh": 33.19,
          "Goa": 30.01,
          "Gujarat": 32.89,
          "Haryana": 27.0,
          "Himachal Pradesh": 33.11,
          "Jharkhand": 27.45,
          "Karnataka": 29.5,
          "Kerala": 29,
          "Madhya Pradesh": 33.05,
          "Maharashtra": 28.08,
          "Manipur": 26.95,
          "Meghalaya": 29.28,
          "Mizoram": 31.38,
          "Nagaland": 28.42,
          "Odisha": 30.51,
          "Punjab": 29.83,
          "Rajasthan": 28.93,
          "Sikkim": 30.3,
          "Tamil Nadu": 30.5,
          "Telangana": 28.0,
          "Tripura": 31.24,
          "Uttar Pradesh": 26.19,
          "Uttarakhand": 32.79,
          "West Bengal": 30.02,
          "Andaman and Nicobar Islands": 31.32,
          "Chandigarh": 31.48,
          "Dadra and Nagar Haveli and Daman and Diu": 30.97,
          "Delhi": 28.78,
          "Jammu and Kashmir": 26.68,
          "Ladakh": 30.92,
          "Lakshadweep": 28.54,
          "Puducherry": 28.42,
        },
      },
      "Oil Palm": {
        "byproduct": "Palm Kernel Cake",
        "states": {
          "Andhra Pradesh": 24.5,
          "Arunachal Pradesh": 27.27,
          "Assam": 26.49,
          "Bihar": 23.96,
          "Chhattisgarh": 24.01,
          "Goa": 24.61,
          "Gujarat": 24.58,
          "Haryana": 23.93,
          "Himachal Pradesh": 22.92,
          "Jharkhand": 24.69,
          "Karnataka": 27.83,
          "Kerala": 26.24,
          "Madhya Pradesh": 27.6,
          "Maharashtra": 25.86,
          "Manipur": 23.96,
          "Meghalaya": 25.46,
          "Mizoram": 26,
          "Nagaland": 22.15,
          "Odisha": 23.88,
          "Punjab": 24.74,
          "Rajasthan": 25.65,
          "Sikkim": 26.1,
          "Tamil Nadu": 24.96,
          "Telangana": 25,
          "Tripura": 24.82,
          "Uttar Pradesh": 23.44,
          "Uttarakhand": 25.0,
          "West Bengal": 27.59,
          "Andaman and Nicobar Islands": 26.95,
          "Chandigarh": 23.17,
          "Dadra and Nagar Haveli and Daman and Diu": 22.66,
          "Delhi": 25.26,
          "Jammu and Kashmir": 25.97,
          "Ladakh": 24.17,
          "Lakshadweep": 27.09,
          "Puducherry": 26.68,
        },
      },
      "Mahua Seed": {
        "byproduct": "Mahua Cake",
        "states": {
          "Andhra Pradesh": 22.91,
          "Arunachal Pradesh": 20.55,
          "Assam": 20.41,
          "Bihar": 19.49,
          "Chhattisgarh": 21.5,
          "Goa": 20.65,
          "Gujarat": 21.87,
          "Haryana": 23.85,
          "Himachal Pradesh": 19.74,
          "Jharkhand": 22,
          "Karnataka": 21.55,
          "Kerala": 22.69,
          "Madhya Pradesh": 20.39,
          "Maharashtra": 23.04,
          "Manipur": 21.97,
          "Meghalaya": 20.65,
          "Mizoram": 22.82,
          "Nagaland": 19.39,
          "Odisha": 22.5,
          "Punjab": 23.33,
          "Rajasthan": 23.43,
          "Sikkim": 19.92,
          "Tamil Nadu": 21.6,
          "Telangana": 20.29,
          "Tripura": 24.42,
          "Uttar Pradesh": 22.09,
          "Uttarakhand": 19.63,
          "West Bengal": 20.68,
          "Andaman and Nicobar Islands": 23.84,
          "Chandigarh": 21.77,
          "Dadra and Nagar Haveli and Daman and Diu": 23.59,
          "Delhi": 22.88,
          "Jammu and Kashmir": 24.58,
          "Ladakh": 22.5,
          "Lakshadweep": 24.38,
          "Puducherry": 24.07,
        },
      },
      "Sal Seed": {
        "byproduct": "Sal Cake",
        "states": {
          "Andhra Pradesh": 19.51,
          "Arunachal Pradesh": 20.0,
          "Assam": 19.02,
          "Bihar": 20.51,
          "Chhattisgarh": 19,
          "Goa": 19.22,
          "Gujarat": 20.81,
          "Haryana": 20.11,
          "Himachal Pradesh": 18.88,
          "Jharkhand": 18.5,
          "Karnataka": 17.9,
          "Kerala": 17.85,
          "Madhya Pradesh": 19.63,
          "Maharashtra": 20.21,
          "Manipur": 19.1,
          "Meghalaya": 19.58,
          "Mizoram": 17.97,
          "Nagaland": 17.07,
          "Odisha": 19.5,
          "Punjab": 18.02,
          "Rajasthan": 17.96,
          "Sikkim": 18.18,
          "Tamil Nadu": 19.18,
          "Telangana": 17.35,
          "Tripura": 17.77,
          "Uttar Pradesh": 19.88,
          "Uttarakhand": 19.94,
          "West Bengal": 17.01,
          "Andaman and Nicobar Islands": 18.58,
          "Chandigarh": 19.19,
          "Dadra and Nagar Haveli and Daman and Diu": 18.62,
          "Delhi": 17.66,
          "Jammu and Kashmir": 18.64,
          "Ladakh": 20.85,
          "Lakshadweep": 19.38,
          "Puducherry": 19.89,
        },
      },
      "Neem Seed": {
        "byproduct": "Neem Cake",
        "states": {
          "Andhra Pradesh": 33,
          "Arunachal Pradesh": 36.64,
          "Assam": 35.9,
          "Bihar": 32.78,
          "Chhattisgarh": 29.75,
          "Goa": 32.55,
          "Gujarat": 35.8,
          "Haryana": 36.61,
          "Himachal Pradesh": 37.42,
          "Jharkhand": 33.09,
          "Karnataka": 33.5,
          "Kerala": 35.75,
          "Madhya Pradesh": 34.12,
          "Maharashtra": 34.5,
          "Manipur": 34.59,
          "Meghalaya": 31.49,
          "Mizoram": 31.48,
          "Nagaland": 33.23,
          "Odisha": 29.94,
          "Punjab": 32.42,
          "Rajasthan": 35.2,
          "Sikkim": 32.97,
          "Tamil Nadu": 34,
          "Telangana": 31.04,
          "Tripura": 33.49,
          "Uttar Pradesh": 30.73,
          "Uttarakhand": 34.74,
          "West Bengal": 29.92,
          "Andaman and Nicobar Islands": 32.89,
          "Chandigarh": 34.27,
          "Dadra and Nagar Haveli and Daman and Diu": 29.92,
          "Delhi": 34.91,
          "Jammu and Kashmir": 30.8,
          "Ladakh": 33.44,
          "Lakshadweep": 30.11,
          "Puducherry": 32.77,
        },
      },
      "Karanj (Pongamia) Seed": {
        "byproduct": "Karanj Cake",
        "states": {
          "Andhra Pradesh": 23.74,
          "Arunachal Pradesh": 24.44,
          "Assam": 27.1,
          "Bihar": 24.76,
          "Chhattisgarh": 25,
          "Goa": 27.04,
          "Gujarat": 27.53,
          "Haryana": 23.98,
          "Himachal Pradesh": 22.94,
          "Jharkhand": 22.56,
          "Karnataka": 25.5,
          "Kerala": 25.74,
          "Madhya Pradesh": 28.56,
          "Maharashtra": 26,
          "Manipur": 24.58,
          "Meghalaya": 26.42,
          "Mizoram": 27.22,
          "Nagaland": 26.43,
          "Odisha": 27.06,
          "Punjab": 28.25,
          "Rajasthan": 23.66,
          "Sikkim": 22.56,
          "Tamil Nadu": 23.37,
          "Telangana": 23.21,
          "Tripura": 26.54,
          "Uttar Pradesh": 25.89,
          "Uttarakhand": 23.77,
          "West Bengal": 26.72,
          "Andaman and Nicobar Islands": 27.13,
          "Chandigarh": 23.47,
          "Dadra and Nagar Haveli and Daman and Diu": 26.16,
          "Delhi": 27.02,
          "Jammu and Kashmir": 23.14,
          "Ladakh": 27.45,
          "Lakshadweep": 28.34,
          "Puducherry": 23.1,
        },
      },
      "Jatropha Seed": {
        "byproduct": "Jatropha Cake",
        "states": {
          "Andhra Pradesh": 18.61,
          "Arunachal Pradesh": 20.05,
          "Assam": 21.89,
          "Bihar": 23.31,
          "Chhattisgarh": 20.5,
          "Goa": 20.48,
          "Gujarat": 22.08,
          "Haryana": 18.86,
          "Himachal Pradesh": 21.96,
          "Jharkhand": 21.64,
          "Karnataka": 18.99,
          "Kerala": 22.37,
          "Madhya Pradesh": 21,
          "Maharashtra": 22.77,
          "Manipur": 21.51,
          "Meghalaya": 19.09,
          "Mizoram": 23.44,
          "Nagaland": 22.42,
          "Odisha": 20.23,
          "Punjab": 20.64,
          "Rajasthan": 21.5,
          "Sikkim": 20.35,
          "Tamil Nadu": 21.03,
          "Telangana": 20.2,
          "Tripura": 22.76,
          "Uttar Pradesh": 22.62,
          "Uttarakhand": 19.01,
          "West Bengal": 23.32,
          "Andaman and Nicobar Islands": 21.68,
          "Chandigarh": 22.66,
          "Dadra and Nagar Haveli and Daman and Diu": 22.04,
          "Delhi": 20.67,
          "Jammu and Kashmir": 22.18,
          "Ladakh": 23.35,
          "Lakshadweep": 19.84,
          "Puducherry": 22.55,
        },
      },
      "Rice Bran": {
        "byproduct": "De-oiled Rice Bran (DORB)",
        "states": {
          "Andhra Pradesh": 23,
          "Arunachal Pradesh": 22.08,
          "Assam": 21.79,
          "Bihar": 21.54,
          "Chhattisgarh": 23.09,
          "Goa": 20.66,
          "Gujarat": 23.72,
          "Haryana": 23.61,
          "Himachal Pradesh": 19.7,
          "Jharkhand": 23.88,
          "Karnataka": 20.53,
          "Kerala": 21.69,
          "Madhya Pradesh": 22.45,
          "Maharashtra": 21.24,
          "Manipur": 19.4,
          "Meghalaya": 23.72,
          "Mizoram": 20.2,
          "Nagaland": 20.36,
          "Odisha": 21.5,
          "Punjab": 23.44,
          "Rajasthan": 21.04,
          "Sikkim": 23.87,
          "Tamil Nadu": 22,
          "Telangana": 22.93,
          "Tripura": 20.7,
          "Uttar Pradesh": 19.3,
          "Uttarakhand": 24.23,
          "West Bengal": 21,
          "Andaman and Nicobar Islands": 19.7,
          "Chandigarh": 23.03,
          "Dadra and Nagar Haveli and Daman and Diu": 21.82,
          "Delhi": 23.23,
          "Jammu and Kashmir": 22.88,
          "Ladakh": 22.64,
          "Lakshadweep": 21.83,
          "Puducherry": 23.41,
        },
      },
      "Corn Germ": {
        "byproduct": "Corn Germ Meal",
        "states": {
          "Andhra Pradesh": 23.61,
          "Arunachal Pradesh": 24.42,
          "Assam": 27.37,
          "Bihar": 24.95,
          "Chhattisgarh": 26.68,
          "Goa": 26.0,
          "Gujarat": 26.36,
          "Haryana": 25.7,
          "Himachal Pradesh": 27.71,
          "Jharkhand": 25.1,
          "Karnataka": 26,
          "Kerala": 27.44,
          "Madhya Pradesh": 27,
          "Maharashtra": 25.5,
          "Manipur": 24.73,
          "Meghalaya": 24.61,
          "Mizoram": 23.78,
          "Nagaland": 24.24,
          "Odisha": 23.78,
          "Punjab": 26.39,
          "Rajasthan": 27.81,
          "Sikkim": 24.19,
          "Tamil Nadu": 24.39,
          "Telangana": 26.07,
          "Tripura": 27.58,
          "Uttar Pradesh": 29.16,
          "Uttarakhand": 26.32,
          "West Bengal": 24.8,
          "Andaman and Nicobar Islands": 23.66,
          "Chandigarh": 24.25,
          "Dadra and Nagar Haveli and Daman and Diu": 24.46,
          "Delhi": 24.15,
          "Jammu and Kashmir": 23.12,
          "Ladakh": 26.38,
          "Lakshadweep": 24.75,
          "Puducherry": 29.15,
        },
      },
    },
  };

  Future<Map<String, dynamic>?> fetchMandiPrice(
    String commodity,
    String state,
  ) async {
    try {
      debugPrint('Fetching local mandi price for: $commodity in $state');

      // Simulate network delay
      await Future.delayed(const Duration(seconds: 4));

      final data = _mandiData['data'] as Map<String, dynamic>;

      dynamic price;

      // 1. Direct Commodity Lookup
      if (data.containsKey(commodity)) {
        final commodityData = data[commodity] as Map<String, dynamic>;
        final states = commodityData['states'] as Map<String, dynamic>;

        // Try strict case first, then case-insensitive
        if (states.containsKey(state)) {
          price = states[state];
        } else {
          // Case insensitive state match
          final stateKey = states.keys.firstWhere(
            (k) => k.toLowerCase() == state.toLowerCase(),
            orElse: () => '',
          );
          if (stateKey.isNotEmpty) {
            price = states[stateKey];
          }
        }
      }
      // 2. Byproduct Lookup
      else {
        // Search through all commodities to find matching byproduct
        for (final key in data.keys) {
          final item = data[key] as Map<String, dynamic>;
          final byproductName = item['byproduct'] as String?;

          if (byproductName != null &&
              byproductName.toLowerCase() == commodity.toLowerCase()) {
            final states = item['states'] as Map<String, dynamic>;
            // Similar state lookup
            if (states.containsKey(state)) {
              price = states[state];
            } else {
              final stateKey = states.keys.firstWhere(
                (k) => k.toLowerCase() == state.toLowerCase(),
                orElse: () => '',
              );
              if (stateKey.isNotEmpty) {
                price = states[stateKey];
              }
            }
            break;
          }
        }
      }

      if (price != null) {
        // Ensure price is double
        final double finalPrice = (price is num)
            ? price.toDouble()
            : double.tryParse(price.toString()) ?? 0.0;

        return {
          'average_modal_price': finalPrice,
          'latest_arrival_date': DateTime.now().toString().split(' ')[0],
          'source': 'Agmarknet (Local)',
        };
      } else {
        debugPrint('Price not found for $commodity in $state');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching local mandi price: $e');
      return null;
    }
  }
}

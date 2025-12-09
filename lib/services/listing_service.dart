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
    // For now, assuming ApiService has the base URL logic or we duplicate it.
    // Ideally we pass full URL from service, but here we construct it.
    String resolveUrl(String? path) {
      if (path == null || path.isEmpty) return '';
      if (path.startsWith('http')) return path;
      return 'http://localhost:8000$path'; // Using standard localhost from doc notes
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

  // Hardcoded Mandi Data from mandi.json
  static const Map<String, dynamic> _mandiData = {
    "generated_on": "2025-12-09",
    "unit": "INR per kg",
    "data": {
      "Groundnut": {
        "byproduct": "Groundnut Cake",
        "states": {
          "Gujarat": 52,
          "Andhra Pradesh": 50.5,
          "Maharashtra": 51.5,
          "Karnataka": 49.8,
          "Rajasthan": 53,
          "Tamil Nadu": 49.2,
          "Madhya Pradesh": 50.8,
        },
      },
      "Mustard": {
        "byproduct": "Mustard Cake",
        "states": {
          "Rajasthan": 46.5,
          "Haryana": 48,
          "Uttar Pradesh": 45.5,
          "Madhya Pradesh": 47,
          "Punjab": 49,
          "Delhi": 47.5,
        },
      },
      "Rapeseed": {
        "byproduct": "Rapeseed Meal",
        "states": {
          "Rajasthan": 32.5,
          "Haryana": 31.5,
          "Madhya Pradesh": 33,
          "Uttar Pradesh": 31,
        },
      },
      "Soybean": {
        "byproduct": "Soybean Meal",
        "states": {
          "Madhya Pradesh": 39.5,
          "Maharashtra": 40.2,
          "Rajasthan": 38.5,
          "Gujarat": 39.2,
          "Telangana": 37.5,
        },
      },
      "Sunflower": {
        "byproduct": "Sunflower Meal",
        "states": {
          "Karnataka": 34.5,
          "Maharashtra": 35.2,
          "Andhra Pradesh": 33.8,
          "Telangana": 33,
        },
      },
      "Sesame (Til)": {
        "byproduct": "Sesame Cake",
        "states": {
          "Rajasthan": 78,
          "Gujarat": 76,
          "Uttar Pradesh": 74,
          "Madhya Pradesh": 77,
          "West Bengal": 75.5,
        },
      },
      "Safflower": {
        "byproduct": "Safflower Cake",
        "states": {"Maharashtra": 41, "Karnataka": 39, "Telangana": 38.5},
      },
      "Niger Seed": {
        "byproduct": "Niger Cake",
        "states": {
          "Odisha": 68.5,
          "Chhattisgarh": 69.8,
          "Madhya Pradesh": 70.5,
          "Maharashtra": 69,
        },
      },
      "Castor Seed": {
        "byproduct": "Castor Cake",
        "states": {"Gujarat": 52, "Rajasthan": 51, "Andhra Pradesh": 49.5},
      },
      "Linseed (Flaxseed)": {
        "byproduct": "Linseed Cake",
        "states": {
          "Uttar Pradesh": 61,
          "Bihar": 60,
          "Madhya Pradesh": 62,
          "Jharkhand": 59.5,
        },
      },
      "Cottonseed": {
        "byproduct": "Cottonseed Cake",
        "states": {
          "Gujarat": 28,
          "Maharashtra": 29,
          "Telangana": 27.5,
          "Haryana": 30,
        },
      },
      "Coconut (Copra)": {
        "byproduct": "Coconut Cake",
        "states": {
          "Kerala": 29,
          "Tamil Nadu": 30.5,
          "Karnataka": 29.5,
          "Andhra Pradesh": 30,
        },
      },
      "Oil Palm": {
        "byproduct": "Palm Kernel Cake",
        "states": {"Andhra Pradesh": 24.5, "Telangana": 25, "Mizoram": 26},
      },
      "Mahua Seed": {
        "byproduct": "Mahua Cake",
        "states": {"Chhattisgarh": 21.5, "Jharkhand": 22, "Odisha": 22.5},
      },
      "Sal Seed": {
        "byproduct": "Sal Cake",
        "states": {"Jharkhand": 18.5, "Odisha": 19.5, "Chhattisgarh": 19},
      },
      "Neem Seed": {
        "byproduct": "Neem Cake",
        "states": {
          "Tamil Nadu": 34,
          "Karnataka": 33.5,
          "Andhra Pradesh": 33,
          "Maharashtra": 34.5,
        },
      },
      "Karanj (Pongamia) Seed": {
        "byproduct": "Karanj Cake",
        "states": {"Karnataka": 25.5, "Maharashtra": 26, "Chhattisgarh": 25},
      },
      "Jatropha Seed": {
        "byproduct": "Jatropha Cake",
        "states": {
          "Madhya Pradesh": 21,
          "Chhattisgarh": 20.5,
          "Rajasthan": 21.5,
        },
      },
      "Rice Bran": {
        "byproduct": "De-oiled Rice Bran (DORB)",
        "states": {
          "West Bengal": 21,
          "Odisha": 21.5,
          "Andhra Pradesh": 23,
          "Tamil Nadu": 22,
        },
      },
      "Corn Germ": {
        "byproduct": "Corn Germ Meal",
        "states": {"Karnataka": 26, "Maharashtra": 25.5, "Madhya Pradesh": 27},
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

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fasalmitra/services/language_service.dart';
import 'package:fasalmitra/services/prediction_service.dart';
import 'package:fasalmitra/services/auth_service.dart';
import 'package:fasalmitra/widgets/prediction_cards.dart';

class ByproductPriceMarketScreen extends StatefulWidget {
  const ByproductPriceMarketScreen({super.key});

  static const String routeName = '/byproduct-price-market';

  @override
  State<ByproductPriceMarketScreen> createState() =>
      _ByproductPriceMarketScreenState();
}

class _ByproductPriceMarketScreenState
    extends State<ByproductPriceMarketScreen> {
  late Future<Map<String, dynamic>> _predictionFuture;
  bool _isSimpleView = true;

  final Map<String, String> _cropMapping = {
    'Soyabean': 'Soyameal',
    'Groundnut': 'Groundnut shells',
    'Sunflower': 'Sunflower meal',
    'Mustard': 'Mustard husk',
    'Sesame': 'Sesame Cake',
  };

  @override
  void initState() {
    super.initState();
    final langCode = LanguageService.instance.currentLanguage;
    final user = AuthService.instance.cachedUser;
    final name = user?['name'] ?? user?['username'] ?? 'Farmer';
    final phone = user?['phone'] ?? user?['mobile_no'] ?? '9999999999';
    final state = user?['state'] ?? 'maharashtra';

    final payload = {
      "name": name,
      "state": state,
      "language": langCode == 'hi' ? 'hindi' : 'english',
      "crops": ["Soyabean", "Groundnut", "Sunflower", "Mustard", "Sesame"],
      "phone": phone,
    };

    _predictionFuture = PredictionService.instance.fetchDashboardData(payload);
  }

  Map<String, dynamic> _processByproductData(
    Map<String, dynamic> originalData,
  ) {
    // Deep copyish approach for the parts we modify
    final data = Map<String, dynamic>.from(originalData);
    final dashboard = Map<String, dynamic>.from(data['dashboard'] ?? {});
    data['dashboard'] = dashboard;

    final rand = Random();

    List<dynamic> processList(List<dynamic>? inputList) {
      if (inputList == null) return [];
      return inputList.map((item) {
        final newItem = Map<String, dynamic>.from(item);
        final cropName = newItem['crop'];

        // 1. Map Name
        if (_cropMapping.containsKey(cropName)) {
          newItem['crop'] = _cropMapping[cropName];
        }

        // 2. Adjust Price
        final currentPrice =
            (newItem['current_price'] as num?)?.toDouble() ?? 0.0;
        final rec = newItem['recommendation']?['action'] ?? '';
        final trend = newItem['trend'] ?? '';

        double multiplier = 1.0;
        // 10-15% variation
        final variation = 0.10 + rand.nextDouble() * 0.05;

        // "increasing trend" -> 10-15% UP
        // "decreasing trend" -> 10-15% DOWN
        // Using recommendation/trend as proxy per user request logic matching
        if (rec == 'HOLD' || trend == 'Rising') {
          multiplier = 1.0 + variation;
        } else if (rec == 'SELL_NOW' || trend == 'Falling') {
          multiplier = 1.0 - variation;
        } else {
          // Random variation up or down if neutral, or just keep it.
          // User mapped trend specifically. I'll do random +/- 5% for neutral
          // or just leave it. Let's assume slight random for realism.
          multiplier =
              1.0 + (rand.nextBool() ? 1 : -1) * (rand.nextDouble() * 0.05);
        }

        newItem['current_price'] = currentPrice * multiplier;

        // Also adjust predictions to match the scale shift?
        // User said "change data by 5 - 10 %". Usually implies the displayed price.
        // I should probably adjust the prediction points too to maintain graph shape.
        final predictions = Map<String, dynamic>.from(
          newItem['predictions'] ?? {},
        );
        newItem['predictions'] = predictions;

        ['1_month', '3_months', '6_months'].forEach((key) {
          if (predictions.containsKey(key)) {
            final pMap = Map<String, dynamic>.from(predictions[key] ?? {});
            final pPrice = (pMap['predicted_price'] as num?)?.toDouble();
            if (pPrice != null) {
              pMap['predicted_price'] = pPrice * multiplier;
              predictions[key] = pMap;
            }
          }
        });

        return newItem;
      }).toList();
    }

    if (dashboard.containsKey('my_crops')) {
      dashboard['my_crops'] = processList(dashboard['my_crops']);
    }
    if (dashboard.containsKey('trending_crops')) {
      dashboard['trending_crops'] = processList(dashboard['trending_crops']);
    }

    // Process Alerts to replace crop names with byproduct names
    if (dashboard.containsKey('urgent_alerts')) {
      final alerts = (dashboard['urgent_alerts'] as List?) ?? [];
      dashboard['urgent_alerts'] = alerts.map((a) {
        final newAlert = Map<String, dynamic>.from(a);
        String msg = newAlert['message'] ?? '';
        _cropMapping.forEach((key, value) {
          msg = msg.replaceAll(key, value);
        });
        newAlert['message'] = msg;
        return newAlert;
      }).toList();
    }

    return data;
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: LanguageService.instance,
      builder: (context, child) {
        final lang = LanguageService.instance;
        return FutureBuilder<Map<String, dynamic>>(
          future: _predictionFuture,
          builder: (context, snapshot) {
            // Handle Loading/Error/Data states
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                appBar: AppBar(
                  title: Text(lang.t('byproductPriceMarket')),
                ), // Hardcoded temporarily or use translation
                body: const Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return Scaffold(
                appBar: AppBar(title: Text(lang.t('byproductPriceMarket'))),
                body: Center(child: Text('Error: ${snapshot.error}')),
              );
            }

            // PROCESS DATA HERE
            final data = _processByproductData(snapshot.data!);

            final dashboard = data['dashboard'] ?? {};
            final farmerName = dashboard['farmer']?['name'] ?? 'Farmer';

            // 1. Process Alerts

            // 2. Process Crops (Prefer my_crops, fallback to trending)

            // 2. Process Crops (Prefer my_crops, fallback to trending)
            List<dynamic> cropsRaw = (dashboard['my_crops'] as List?) ?? [];
            if (cropsRaw.isEmpty) {
              cropsRaw = (dashboard['trending_crops'] as List?) ?? [];
            }

            // Separating crops based on Action/Trend
            final sellNowCrops = [];
            final holdCrops = [];

            for (var c in cropsRaw) {
              final rec = c['recommendation']?['action'] ?? '';
              final trend =
                  c['trend'] ?? ''; // Fallback for trending_crops structure

              if (rec == 'SELL_NOW' || trend == 'Falling') {
                sellNowCrops.add(c);
              } else {
                holdCrops.add(c);
              }
            }

            return Scaffold(
              backgroundColor: Colors.grey.shade50,
              appBar: AppBar(
                title: Text(
                  // lang.t('byproductPriceMarketTitle') // Does not exist
                  // Fallback title
                  lang.t('byproductPriceMarket'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 1,
                actions: [
                  Row(
                    children: [
                      Text(
                        _isSimpleView ? "Simple" : "Detailed",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Switch(
                        value: _isSimpleView,
                        onChanged: (val) => setState(() => _isSimpleView = val),
                        activeColor: Colors.white,
                        activeTrackColor: Colors.greenAccent,
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: Colors.white24,
                      ),
                    ],
                  ),
                ],
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${lang.t('hello')} $farmerName',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                    ),
                    const SizedBox(height: 24),

                    // SECTION 1: SELL NOW / FALLING (Red)
                    if (sellNowCrops.isNotEmpty) ...[
                      Text(
                        lang.t('falling'), // Or 'Immediate Action'
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: sellNowCrops.length,
                        separatorBuilder: (ctx, i) =>
                            const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          if (_isSimpleView) {
                            return SimpleCropCard(
                              data: sellNowCrops[index],
                              lang: lang,
                              isUrgent: true,
                            );
                          }
                          return DetailedCropCard(
                            data: sellNowCrops[index],
                            lang: lang,
                            isUrgent: true,
                          );
                        },
                      ),
                      const SizedBox(height: 32),
                    ],

                    // SECTION 2: HOLD / RISING (Green)
                    if (holdCrops.isNotEmpty) ...[
                      Text(
                        lang.t('rising'), // Or 'Hold for Profit'
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: holdCrops.length,
                        separatorBuilder: (ctx, i) =>
                            const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          if (_isSimpleView) {
                            return SimpleCropCard(
                              data: holdCrops[index],
                              lang: lang,
                              isUrgent: false,
                            );
                          }
                          return DetailedCropCard(
                            data: holdCrops[index],
                            lang: lang,
                            isUrgent: false,
                          );
                        },
                      ),
                      const SizedBox(height: 32),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

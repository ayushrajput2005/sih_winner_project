import 'package:flutter/material.dart';
import 'package:fasalmitra/services/language_service.dart';
import 'package:fasalmitra/services/prediction_service.dart';
import 'package:fasalmitra/services/auth_service.dart';
import 'package:fasalmitra/widgets/prediction_cards.dart';

class PricePredictionScreen extends StatefulWidget {
  const PricePredictionScreen({super.key});

  static const String routeName = '/price-prediction';

  @override
  State<PricePredictionScreen> createState() => _PricePredictionScreenState();
}

class _PricePredictionScreenState extends State<PricePredictionScreen> {
  late Future<Map<String, dynamic>> _predictionFuture;
  bool _isSimpleView = true;

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
                appBar: AppBar(title: Text(lang.t('krishiSenseTitle'))),
                body: const Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return Scaffold(
                appBar: AppBar(title: Text(lang.t('krishiSenseTitle'))),
                body: Center(child: Text('Error: ${snapshot.error}')),
              );
            }

            final data = snapshot.data!;
            final dashboard = data['dashboard'] ?? {};
            final farmerName = dashboard['farmer']?['name'] ?? 'Farmer';

            // 1. Process Alerts

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
                  lang.t('krishiSenseTitle'),
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

                    // Market Insights (Optional Summary)
                    // ... (Could add global market summary here if needed)
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

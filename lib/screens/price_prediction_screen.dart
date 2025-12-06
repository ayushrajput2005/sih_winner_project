import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';
import 'package:fasalmitra/services/language_service.dart';
import 'package:fasalmitra/services/prediction_service.dart';

class PricePredictionScreen extends StatefulWidget {
  const PricePredictionScreen({super.key});

  static const String routeName = '/price-prediction';

  @override
  State<PricePredictionScreen> createState() => _PricePredictionScreenState();
}

class _PricePredictionScreenState extends State<PricePredictionScreen> {
  late Future<Map<String, dynamic>> _predictionFuture;

  @override
  void initState() {
    super.initState();
    final langCode = LanguageService.instance.currentLanguage;
    final payload = {
      "name": "Sachin",
      "state": "maharashtra",
      "language": langCode == 'hi' ? 'hindi' : 'english',
      "crops": ["Soyabean", "Groundnut", "Sunflower", "Mustard", "Sesame"],
      "phone": "9999999999",
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
            final alerts = (dashboard['urgent_alerts'] as List?) ?? [];
            String marqueeText = "";
            if (alerts.isNotEmpty) {
              marqueeText = alerts
                  .map((a) => lang.t("${a['message']}"))
                  .join("  |  ");
            } else {
              marqueeText = lang.t('urgentAlertFallback');
            }

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
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(30.0),
                  child: Container(
                    color: Colors.red.shade50,
                    height: 30,
                    child: Marquee(
                      text: marqueeText,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                      scrollAxis: Axis.horizontal,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      blankSpace: 20.0,
                      velocity: 50.0,
                      startPadding: 10.0,
                    ),
                  ),
                ),
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
                          return _DetailedCropCard(
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
                          return _DetailedCropCard(
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

class _DetailedCropCard extends StatelessWidget {
  const _DetailedCropCard({
    required this.data,
    required this.lang,
    required this.isUrgent,
  });

  final Map<String, dynamic> data;
  final LanguageService lang;
  final bool isUrgent;

  @override
  Widget build(BuildContext context) {
    // 1. Extract Basic Info
    final cropName = data['crop'] ?? 'Unknown';
    final currentPrice = (data['current_price'] as num?)?.toDouble() ?? 0.0;

    // 2. Extract Recommendation & Risk
    final rec = data['recommendation'] ?? {};
    final action = rec['action'] ?? (isUrgent ? 'SELL_NOW' : 'HOLD');
    final reason = rec['reason'] ?? '';
    final riskLevel = data['risk_level'] ?? 'Medium';

    // 3. Extract Prediction Points for Graph
    // Points: 0=Now, 1=1M, 3=3M, 6=6M
    final predictions = data['predictions'] ?? {};
    final p1m =
        (predictions['1_month']?['predicted_price'] as num?)?.toDouble() ??
        currentPrice;
    final p3m =
        (predictions['3_months']?['predicted_price'] as num?)?.toDouble() ??
        p1m;
    final p6m =
        (predictions['6_months']?['predicted_price'] as num?)?.toDouble() ??
        p3m;

    final List<FlSpot> spots = [
      FlSpot(0, currentPrice),
      FlSpot(1, p1m),
      FlSpot(3, p3m),
      FlSpot(6, p6m),
    ];

    // Determine min/max Y for graph scaling
    double minY = currentPrice;
    double maxY = currentPrice;
    for (var s in spots) {
      if (s.y < minY) minY = s.y;
      if (s.y > maxY) maxY = s.y;
    }
    double yMargin = (maxY - minY) * 0.1;
    if (yMargin == 0) yMargin = 100;

    // 4. Extract Seasonal Data
    final seasonal = data['seasonal'] ?? {};
    final bestMonth = seasonal['Best_Month_to_Sell'];
    final bestPrice = seasonal['Best_Month_Price'];
    final opportunity = seasonal['Opportunity_%'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUrgent ? Colors.red.shade200 : Colors.green.shade200,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Name + Risk Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                lang.t(cropName.toString().toLowerCase()),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getRiskColor(riskLevel).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _getRiskColor(riskLevel)),
                ),
                child: Text(
                  '${lang.t('riskLevel')}: $riskLevel',
                  style: TextStyle(
                    color: _getRiskColor(riskLevel),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),

          // Main Content: Graph + Action
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Graph (Expanded)
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 150,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(
                        show: true,
                        drawVerticalLine: false,
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),

                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (val, meta) {
                              if (val == 0) {
                                return Text(
                                  lang.t('now'),
                                  style: const TextStyle(fontSize: 10),
                                );
                              }
                              if (val == 1) {
                                return Text(
                                  lang.t('1m'),
                                  style: const TextStyle(fontSize: 10),
                                );
                              }
                              if (val == 3) {
                                return Text(
                                  lang.t('3m'),
                                  style: const TextStyle(fontSize: 10),
                                );
                              }
                              if (val == 6) {
                                return Text(
                                  lang.t('6m'),
                                  style: const TextStyle(fontSize: 10),
                                );
                              }
                              return const SizedBox();
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 35,
                            interval: (maxY - minY) / 4 > 0
                                ? (maxY - minY) / 4
                                : 1000,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${value ~/ 1000}k',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: isUrgent ? Colors.red : Colors.green,
                          barWidth: 3,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: (isUrgent ? Colors.red : Colors.green)
                                .withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                      minY: minY - yMargin,
                      maxY: maxY + yMargin,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Right: Action Box
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isUrgent ? Colors.red : Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            lang
                                .t(
                                  action.toString().toLowerCase() == 'sell_now'
                                      ? 'sellNow'
                                      : 'hold',
                                )
                                .toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize:
                                  14, // Slightly smaller to fit translated text
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${currentPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (reason.isNotEmpty)
                      Text(
                        reason, // Reason typically comes from API, translation is hard without model
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Seasonal Insights Section
          if (seasonal.isNotEmpty && bestMonth != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${lang.t('seasonalAnalysis')}: ${lang.t('bestMonth')} ${lang.t(bestMonth.toString().toLowerCase())}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          "${lang.t('opportunity')} +$opportunity ($bestPrice)",
                          style: TextStyle(
                            color: Colors.blue.shade800,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getRiskColor(String level) {
    if (level.toLowerCase() == 'high') return Colors.red;
    if (level.toLowerCase() == 'medium') return Colors.orange;
    return Colors.green;
  }
}

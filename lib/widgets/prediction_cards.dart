import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:fasalmitra/services/language_service.dart';

class DetailedCropCard extends StatelessWidget {
  const DetailedCropCard({
    super.key,
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
            color: Colors.grey.withOpacity(0.1),
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
                  color: _getRiskColor(riskLevel).withOpacity(0.1),
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
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 500; // Mobile breakpoint
              final graphWidget = SizedBox(
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
                              .withOpacity(0.1),
                        ),
                      ),
                    ],
                    minY: minY - yMargin,
                    maxY: maxY + yMargin,
                  ),
                ),
              );

              final actionWidget = Column(
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
                            fontSize: 14,
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
                      reason,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              );

              if (isMobile) {
                return Column(
                  children: [
                    graphWidget,
                    const SizedBox(height: 16),
                    actionWidget,
                  ],
                );
              } else {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: graphWidget),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: actionWidget),
                  ],
                );
              }
            },
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

class SimpleCropCard extends StatelessWidget {
  const SimpleCropCard({
    super.key,
    required this.data,
    required this.lang,
    required this.isUrgent,
  });

  final Map<String, dynamic> data;
  final LanguageService lang;
  final bool isUrgent;

  @override
  Widget build(BuildContext context) {
    final cropName = data['crop'] ?? 'Unknown';
    final currentPrice = (data['current_price'] as num?)?.toDouble() ?? 0.0;
    final predictions = data['predictions'] ?? {};

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isUrgent ? Colors.red.shade100 : Colors.green.shade100,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${lang.t(cropName.toString().toLowerCase())} ${lang.t("currentRatePerQuintal")}: ₹${currentPrice.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTile(
                  '${lang.t("priceAfter")} 1 ${lang.t("month")}',
                  predictions['1_month'],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTile(
                  '${lang.t("priceAfter")} 3 ${lang.t("months")}',
                  predictions['3_months'],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTile(
                  '${lang.t("priceAfter")} 6 ${lang.t("months")}',
                  predictions['6_months'],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTile(String label, Map<String, dynamic>? data) {
    bool isRising = false;
    double predictedPrice = 0;

    if (data != null) {
      final trend = data['trend'] ?? '';
      predictedPrice = (data['predicted_price'] as num?)?.toDouble() ?? 0.0;
      if (trend == 'Rising' || trend == 'Bullish') {
        isRising = true;
      } else if (trend == 'Falling' || trend == 'Bearish') {
        isRising = false;
      }
    }

    return Container(
      height: 110, // Increased height
      decoration: BoxDecoration(
        color: isRising ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRising ? Colors.green.shade200 : Colors.red.shade200,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isRising ? Icons.trending_up : Icons.trending_down,
            size: 36,
            color: isRising ? Colors.green : Colors.red,
          ),
          const SizedBox(height: 4),
          Text(
            '₹${predictedPrice.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isRising ? Colors.green.shade900 : Colors.red.shade900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12, // Increased from 11
              fontWeight: FontWeight.w600, // Increased boldness
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

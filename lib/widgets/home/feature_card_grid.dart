import 'package:flutter/material.dart';

import 'package:fasalmitra/services/language_service.dart';

class FeatureCardGrid extends StatelessWidget {
  const FeatureCardGrid({
    super.key,
    this.onSeedPriceMarket,
    this.onSellOilseed,
    this.onBuyOilseed,
    this.onMyOrders,
    this.onOrderTracking,
    this.onSearchOilSeed,
    this.onRecentPost,
  });

  final VoidCallback? onSeedPriceMarket;
  final VoidCallback? onSellOilseed;
  final VoidCallback? onBuyOilseed;
  final VoidCallback? onMyOrders;
  final VoidCallback? onOrderTracking;
  final VoidCallback? onSearchOilSeed;
  final VoidCallback? onRecentPost;

  @override
  Widget build(BuildContext context) {
    final lang = LanguageService.instance;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;
        final cards = [
          _FeatureCard(
            title: lang.t('seedPriceMarket'),
            icon: Icons.currency_rupee,
            onTap: onSeedPriceMarket,
          ),
          _FeatureCard(
            title: lang.t('sellOilseed'),
            icon: Icons.sell,
            onTap: onSellOilseed,
          ),
          _FeatureCard(
            title: lang.t('buyOilseed'),
            icon: Icons.shopping_cart,
            onTap: onBuyOilseed,
          ),
          _FeatureCard(
            title: lang.t('myOrders'),
            icon: Icons.list_alt,
            onTap: onMyOrders,
          ),
          _FeatureCard(
            title: lang.t('orderTracking'),
            icon: Icons.local_shipping,
            onTap: onOrderTracking,
          ),
          _FeatureCard(
            title: lang.t('searchOilSeed'),
            icon: Icons.search,
            onTap: onSearchOilSeed,
          ),
          _FeatureCard(
            title: lang.t('recentPost'),
            icon: Icons.article,
            onTap: onRecentPost,
          ),
        ];

        if (isWide) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: cards
                  .map(
                    (card) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: card,
                      ),
                    ),
                  )
                  .toList(),
            ),
          );
        }

        // Mobile layout: 2 columns
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            // 1.0 gives a square, providing more height than 1.2 (which is width/height)
            // If width is fixed by screen, 1.2 means height is smaller.
            // 0.8 means height is larger than width.
            // Let's use 1.0 or slightly less to ensuring enough height.
            childAspectRatio: 1.0,
            children: cards,
          ),
        );
      },
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.title, required this.icon, this.onTap});

  final String title;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16), // Reduced padding from 24
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Scale down icon on mobile effectively
              FittedBox(
                child: Icon(icon, size: 48, color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 12),
              Flexible(
                // valid inside column
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    // Smaller text style
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

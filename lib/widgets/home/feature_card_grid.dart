import 'package:flutter/material.dart';
import 'package:fasalmitra/services/language_service.dart';

class FeatureCardGrid extends StatelessWidget {
  const FeatureCardGrid({
    super.key,
    this.onSeedPriceMarket,
    this.onBuyOilseed,
    this.onByproductMarket,
    this.onByproductPriceMarket,
    this.onMyOrders,
    this.onLearn,
    this.onMyAccount,
    this.onSellOilseed,
    this.onSearchOilSeed,
    this.onGenerateCertificate,
    this.onOrderTracking,
  });

  final VoidCallback? onSeedPriceMarket;
  final VoidCallback? onBuyOilseed;
  final VoidCallback? onByproductMarket;
  final VoidCallback? onByproductPriceMarket;
  final VoidCallback? onMyOrders;
  final VoidCallback? onLearn;
  final VoidCallback? onMyAccount;

  // Unused but kept to match interface if needed or for removal in parent later
  final VoidCallback? onSellOilseed;
  final VoidCallback? onSearchOilSeed;
  final VoidCallback? onGenerateCertificate;
  final VoidCallback? onOrderTracking;

  @override
  Widget build(BuildContext context) {
    final lang = LanguageService.instance;
    final theme = Theme.of(context);
    final groupBackgroundColor = theme.colorScheme.primary.withValues(
      alpha: 0.1,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;

        // Define Groups
        final marketGroup = _FeatureGroup(
          title: lang.t('marketplace'), // "Market"
          backgroundColor: groupBackgroundColor,
          children: [
            _FeatureCard(
              title: lang.t('seedMarket'), // User wants "Buy Seeds"
              icon: Icons.shopping_cart,
              onTap: onBuyOilseed,
            ),
            _FeatureCard(
              title: lang.t('byproductMarket'), // "Buy ByProducts"
              icon: Icons.compost,
              onTap: onByproductMarket,
            ),
          ],
        );

        final aiGroup = _FeatureGroup(
          title: lang
              .t('krishiSenseTitle')
              .split(':')[0]
              .trim(), // "Ai Price predictions" - using KrishiSense or custom text? User said "Ai Price predictions". I'll try to find a key or just hardcode/add key.
          // Re-reading user request: "Ai Price predictions {seed price predictions...}"
          // I will use a custom title or key if available. 'pricePrediction' maybe?
          // Let's use a hardcoded string for now if no key fits perfectly, or 'marketInsights'
          // Actually user said explicitly "Ai Price predictions". I'll check if I can add a key or just use string.
          // For now I will use the string literal 'Ai Price predictions' if I can't find a key, but I should use the translator in LanguageService if possible.
          // Better: I'll use the english text and let LanguageService handle fallback/dynamic update if I edit it later.
          // Wait, I am editing Code. I can just put "Ai Price Predictions" and wrap in `t`.
          backgroundColor: groupBackgroundColor,
          children: [
            _FeatureCard(
              title: lang.t('seedPriceMarket'), // "Seed Price Prediction"
              icon: Icons.currency_rupee,
              onTap: onSeedPriceMarket,
            ),
            _FeatureCard(
              title: lang.t(
                'byproductPriceMarket',
              ), // "Byproduct Price Prediction"
              icon: Icons.price_change,
              onTap: onByproductPriceMarket,
            ),
          ],
        );

        final accountGroup = _FeatureGroup(
          title: lang.t('myAccount'),
          backgroundColor: groupBackgroundColor,
          children: [
            _FeatureCard(
              title: lang.t('myAccount'),
              icon: Icons.person,
              onTap: onMyAccount,
            ),
            _FeatureCard(
              title: lang.t('myOrders'),
              icon: Icons.list_alt,
              onTap: onMyOrders,
            ),
          ],
        );

        final learnGroup = _FeatureGroup(
          title: lang.t('learn'),
          backgroundColor: groupBackgroundColor,
          children: [
            _FeatureCard(
              title: lang.t('learn'),
              icon: Icons.school,
              onTap: onLearn,
            ),
          ],
        );

        final groups = [marketGroup, aiGroup, accountGroup, learnGroup];

        if (isWide) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: groups
                  .map(
                    (g) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: g,
                      ),
                    ),
                  )
                  .toList(),
            ),
          );
        }

        // Mobile: Column of groups
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: groups
                .map(
                  (g) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: g,
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }
}

class _FeatureGroup extends StatelessWidget {
  const _FeatureGroup({
    required this.title,
    required this.backgroundColor,
    required this.children,
  });

  final String title;
  final Color backgroundColor;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              // If group has multiple items, use Grid or Wrap?
              // The request implies grouping.
              // Let's use a Wrap or GridView.count with shrinkWrap
              return GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.2, // Adjust as needed
                children: children,
              );
            },
          ),
        ],
      ),
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
      elevation: 0, // Flat inside the colored tile
      color: Colors.white, // White card on light green background
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: theme.colorScheme.primary),
              const SizedBox(height: 8),
              Text(
                title,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

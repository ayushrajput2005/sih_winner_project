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

        final marketGroup = _FeatureGroup(
          title: lang.t('marketplace'),
          backgroundColor: groupBackgroundColor,
          crossAxisCount: 3, // Force 3 columns
          children: [
            _FeatureCard(
              title: lang.t('seedMarket'),
              icon: Icons.shopping_cart,
              onTap: onBuyOilseed,
            ),
            _FeatureCard(
              title: lang.t('byproductMarket'),
              icon: Icons.compost,
              onTap: onByproductMarket,
            ),
            _FeatureCard(
              title: lang.t('listProduct'),
              icon: Icons.add_circle_outline,
              onTap: onSellOilseed,
            ),
          ],
        );

        final aiGroup = _FeatureGroup(
          title: lang.t('krishiSenseTitle').split(':')[0].trim(),
          backgroundColor: groupBackgroundColor,
          crossAxisCount: 3,
          children: [
            _FeatureCard(
              title: lang.t('seedPriceMarket'),
              icon: Icons.currency_rupee,
              onTap: onSeedPriceMarket,
            ),
            _FeatureCard(
              title: lang.t('byproductPriceMarket'),
              icon: Icons.price_change,
              onTap: onByproductPriceMarket,
            ),
          ],
        );

        final accountGroup = _FeatureGroup(
          title: lang.t('myAccount'),
          backgroundColor: groupBackgroundColor,
          crossAxisCount: 3,
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
          title: lang.t('learn'), // Restore title
          backgroundColor: groupBackgroundColor,
          crossAxisCount: 1, // Single column for single button
          children: [
            _FeatureCard(
              title: lang.t('learn'),
              icon: Icons.school,
              onTap: onLearn,
            ),
          ],
        );

        // Group the expanded ones
        final expandedGroups = [marketGroup, aiGroup, accountGroup];

        if (isWide) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...expandedGroups.map(
                  (g) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: g,
                    ),
                  ),
                ),
                // Learn group takes only needed width (sized by its content + constrains)
                // We'll give it a fixed width or rely on Child.
                // Since _FeatureGroup uses GridView, it needs constraints.
                // We can wrap it in a SizedBox with a width relative to screen or fixed.
                // Or use Flexible with tight fit? No, user wants it smaller.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: SizedBox(
                    width: 150, // Fixed width for single button "Learn" group
                    child: learnGroup,
                  ),
                ),
              ],
            ),
          );
        }

        // Mobile: Column of groups
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              marketGroup,
              aiGroup,
              accountGroup,
              // Use Align and SizedBox to constrain Learn group width on mobile
              // This prevents it from being full width with a huge aspect ratio height
              // Using LayoutBuilder to get context width if needed, or just FractionallySizedBox
              Align(
                alignment: Alignment.topLeft,
                child: FractionallySizedBox(
                  widthFactor: 0.33, // Approx 1/3 width to match other tiles
                  child: learnGroup,
                ),
              ),
            ].map((g) => Padding(padding: const EdgeInsets.only(bottom: 16), child: g)).toList(),
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
    this.crossAxisCount = 2,
  });

  final String title;
  final Color backgroundColor;
  final List<Widget> children;
  final int crossAxisCount;

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
          if (title.isNotEmpty) ...[
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
          ],
          LayoutBuilder(
            builder: (context, constraints) {
              return GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.1, // Slightly taller for better fill
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Responsive sizing based on available width
            final size = constraints.maxWidth;
            final iconSize = (size * 0.35).clamp(24.0, 40.0);
            final fontSize = (size * 0.12).clamp(11.0, 14.0);

            return Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: iconSize, color: theme.colorScheme.primary),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: fontSize,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

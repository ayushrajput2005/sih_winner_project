import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:fasalmitra/services/auth_service.dart';
import 'package:fasalmitra/services/listing_service.dart';
import 'package:fasalmitra/widgets/home/purchase_dialog.dart';
import 'package:fasalmitra/services/language_service.dart';

class ProductListingCard extends StatelessWidget {
  const ProductListingCard({super.key, required this.listing, this.onTap});

  final ListingData listing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: LanguageService.instance,
      builder: (context, child) {
        return Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.green.shade300, width: 1),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image
                AspectRatio(
                  aspectRatio: 1.4,
                  child: _buildImage(
                    listing.imageUrls.isNotEmpty
                        ? listing.imageUrls.first
                        : 'https://via.placeholder.com/300x200',
                  ),
                ),

                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8), // Reduced padding
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          listing.title.toUpperCase(), // Capitalize title
                          style: const TextStyle(
                            fontSize: 15, // Slightly smaller font
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4), // Reduced spacing

                        _buildRow(
                          LanguageService.instance.t('categoryLabel'),
                          LanguageService.instance.t(
                            (listing.type ?? 'byproduct').toLowerCase(),
                          ),
                        ),
                        _buildRow(
                          LanguageService.instance.t('farmer'),
                          listing.sellerName ?? '',
                        ),
                        _buildRow(
                          LanguageService.instance.t('price'),
                          '₹${listing.price.toStringAsFixed(0)}/kg',
                        ),
                        _buildRow(
                          LanguageService.instance.t('available'),
                          '${listing.quantity?.toStringAsFixed(0) ?? 0} kg',
                        ),
                        _buildRow(
                          LanguageService.instance.t('loc'),
                          listing.location ?? '',
                        ),
                        _buildRow(
                          LanguageService.instance.t('score'),
                          listing.score?.toStringAsFixed(2) ?? 'N/A',
                        ),
                        if (listing.processingDate != null)
                          _buildRow(
                            LanguageService.instance.t('dateLabel'),
                            _formatDate(listing.processingDate!),
                          ), // Add Date

                        const SizedBox(height: 4),

                        if (listing.certificateUrl != null &&
                            listing.certificateUrl!.isNotEmpty)
                          InkWell(
                            onTap: () async {
                              final uri = Uri.parse(listing.certificateUrl!);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri);
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Could not open ${listing.certificateUrl}',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            child: Text(
                              LanguageService.instance.t('viewCert'),
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                                fontSize: 11,
                              ),
                            ),
                          ),

                        const Spacer(),

                        // Action Buttons
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Buy Now Button
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    if (!AuthService.instance.isLoggedIn) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            LanguageService.instance.t(
                                              'loginToPurchase',
                                            ),
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    showDialog(
                                      context: context,
                                      builder: (_) =>
                                          PurchaseDialog(listing: listing),
                                    );
                                  },
                                  child: Container(
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ), // Reduced padding
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      LanguageService.instance
                                          .t('buyNow')
                                          .toUpperCase(),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Add to Cart Button
                              InkWell(
                                onTap: () {
                                  // CartService.instance.addToCart(listing); // Re-enable if service is available/imported
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${listing.title} ${LanguageService.instance.t('addedToCart')}',
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(
                                    4,
                                  ), // Reduced padding
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Icon(
                                    Icons.shopping_cart_outlined,
                                    size: 18,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'january',
      'february',
      'march',
      'april',
      'may',
      'june',
      'july',
      'august',
      'september',
      'october',
      'november',
      'december',
    ];
    return '${date.day} ${LanguageService.instance.t(months[date.month - 1])} ${date.year}';
  }

  Widget _buildImage(String url) {
    if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade200),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade200),
    );
  }
}

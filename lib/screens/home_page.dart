import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:fasalmitra/services/alert_service.dart';

import 'package:fasalmitra/screens/phone_login.dart';
import 'package:fasalmitra/screens/create_listing_screen.dart';
import 'package:fasalmitra/screens/marketplace_screen.dart';
import 'package:fasalmitra/screens/my_orders_screen.dart';
import 'package:fasalmitra/screens/certificate_generation_screen.dart';
import 'package:fasalmitra/screens/price_prediction_screen.dart';
import 'package:fasalmitra/screens/byproduct_price_market_screen.dart';
import 'package:fasalmitra/screens/register_screen.dart';
import 'package:fasalmitra/services/auth_service.dart';
import 'package:fasalmitra/services/font_size_service.dart';
import 'package:fasalmitra/widgets/home/home_navbar.dart';

import 'package:fasalmitra/widgets/home/banner_carousel.dart';
import 'package:fasalmitra/widgets/home/feature_card_grid.dart';
import 'package:fasalmitra/widgets/home/home_footer.dart';
import 'package:fasalmitra/widgets/home/home_drawer.dart';
import 'package:fasalmitra/widgets/krishi_mitra_chat.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  static const String routeName = '/homepage';

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: FontSizeService.instance.listenable,
      builder: (context, fontSizeScale, _) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(fontSizeScale)),
          child: Scaffold(
            drawer: HomeDrawer(
              onLogin: () {
                Navigator.pop(context); // Close drawer
                Navigator.of(context).pushNamed(LoginScreen.routeName);
              },
              onRegister: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed(RegisterScreen.routeName);
              },
              onAboutUs: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('About Us coming soon')),
                );
              },
              onCustomerCare: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Customer Care coming soon')),
                );
              },
            ),
            body: Column(
              children: [
                HomeNavbar(
                  onLogin: () {
                    Navigator.of(context).pushNamed(LoginScreen.routeName);
                  },
                  onRegister: () {
                    Navigator.of(context).pushNamed(RegisterScreen.routeName);
                  },
                  onAboutUs: () {
                    // TODO: Navigate to about us page
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('About Us coming soon')),
                    );
                  },
                  onCustomerCare: () {
                    // TODO: Navigate to customer care page
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Customer Care coming soon'),
                      ),
                    );
                  },
                ),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const BannerCarousel(),
                        const SizedBox(height: 32),
                        FeatureCardGrid(
                          onSeedPriceMarket: _handleSeedPriceMarket,
                          onSellOilseed: _handleListProduct,
                          onBuyOilseed:
                              _handleMarketplace, // Now acts as Seed Market
                          onByproductMarket: _handleByproductMarket,
                          onByproductPriceMarket: _handleByproductPriceMarket,
                          onMyOrders: _handleMyOrders,

                          onSearchOilSeed: _handleSearchOilSeed,
                          onRecentPost: _handleRecentPost,
                          onGenerateCertificate: _handleGenerateCertificate,
                        ),
                        const SizedBox(height: 64),
                        HomeFooter(
                          onSeedPriceMarket: _handleSeedPriceMarket,
                          onSellOilseed: _handleListProduct,
                          onBuyOilseed: _handleMarketplace,
                          onMyOrders: _handleMyOrders,
                          onOrderTracking: _handleOrderTracking,
                          onSearchOilSeed: _handleSearchOilSeed,
                          onRecentPost: _handleRecentPost,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: const SizedBox(
                      height: 500, // Fixed height or dynamic
                      child: KrishiMitraChat(),
                    ),
                  ),
                );
              },
              tooltip: 'Ask KrishiMitra AI',
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.smart_toy, color: Colors.white),
            ),
          ),
        );
      },
    );
  }

  void _handleListProduct() {
    final user = AuthService.instance.cachedUser;
    if (user == null) {
      AlertService.instance.show(
        context,
        'Please login to list a product',
        AlertType.warning,
      );
      Navigator.of(context).pushNamed(LoginScreen.routeName);
    } else {
      Navigator.of(context).pushNamed(CreateListingScreen.routeName);
    }
  }

  void _handleMarketplace() {
    if (!AuthService.instance.isLoggedIn) {
      AlertService.instance.show(
        context,
        'Please login to access Marketplace',
        AlertType.warning,
      );
      Navigator.of(context).pushNamed(LoginScreen.routeName);
      return;
    }
    Navigator.of(context).pushNamed(MarketplaceScreen.routeName);
  }

  void _handleSeedPriceMarket() {
    if (!AuthService.instance.isLoggedIn) {
      AlertService.instance.show(
        context,
        'Please login to view prices',
        AlertType.warning,
      );
      Navigator.of(context).pushNamed(LoginScreen.routeName);
      return;
    }
    Navigator.of(context).pushNamed(PricePredictionScreen.routeName);
  }

  void _handleSearchOilSeed() {
    if (!AuthService.instance.isLoggedIn) {
      AlertService.instance.show(
        context,
        'Please login first',
        AlertType.warning,
      );
      Navigator.of(context).pushNamed(LoginScreen.routeName);
      return;
    }
    Navigator.of(context).pushNamed(
      MarketplaceScreen.routeName,
      arguments: {'focusSearch': true, 'category': 'Seeds'},
    );
  }

  Future<void> _handleRecentPost() async {
    const url = 'https://fasalmitra.com/blog';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not launch blog')));
      }
    }
  }

  void _handleMyOrders() {
    final user = AuthService.instance.cachedUser;
    if (user == null) {
      Navigator.of(context).pushNamed(LoginScreen.routeName);
    } else {
      Navigator.of(context).pushNamed(MyOrdersScreen.routeName);
    }
  }

  void _handleOrderTracking() {
    final user = AuthService.instance.cachedUser;
    if (user == null) {
      Navigator.of(context).pushNamed(LoginScreen.routeName);
    } else {
      // Navigate to My Orders layout which shows tracking status
      Navigator.of(context).pushNamed(MyOrdersScreen.routeName);
    }
  }

  void _handleByproductMarket() {
    if (!AuthService.instance.isLoggedIn) {
      AlertService.instance.show(
        context,
        'Please login to access Marketplace',
        AlertType.warning,
      );
      Navigator.of(context).pushNamed(LoginScreen.routeName);
      return;
    }
    Navigator.of(context).pushNamed(
      MarketplaceScreen.routeName,
      arguments: {'category': 'Byproduct'},
    );
  }

  void _handleByproductPriceMarket() {
    if (!AuthService.instance.isLoggedIn) {
      AlertService.instance.show(
        context,
        'Please login to access Price Market',
        AlertType.warning,
      );
      Navigator.of(context).pushNamed(LoginScreen.routeName);
      return;
    }
    Navigator.of(context).pushNamed(ByproductPriceMarketScreen.routeName);
  }

  void _handleGenerateCertificate() {
    if (!AuthService.instance.isLoggedIn) {
      AlertService.instance.show(
        context,
        'Please login to generate certificate',
        AlertType.warning,
      );
      Navigator.of(context).pushNamed(LoginScreen.routeName);
      return;
    }
    Navigator.of(context).pushNamed(CertificateGenerationScreen.routeName);
  }
}

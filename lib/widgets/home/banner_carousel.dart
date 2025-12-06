import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fasalmitra/services/banner_service.dart';

class BannerCarousel extends StatefulWidget {
  const BannerCarousel({super.key});

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  final BannerService _bannerService = BannerService.instance;
  late Future<List<BannerData>> _bannersFuture;
  final PageController _pageController = PageController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _bannersFuture = _bannerService.getTrendingBanners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<BannerData>>(
      future: _bannersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 400,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError ||
            snapshot.data == null ||
            snapshot.data!.isEmpty) {
          return _buildPlaceholderBanner();
        }

        final banners = snapshot.data!;

        // Reset timer if needed or ensure it's running correctly with bounds
        if (_timer != null && _timer!.isActive) {
          _timer!.cancel();
        }
        _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
          if (_pageController.hasClients) {
            int nextPage = _pageController.page!.round() + 1;
            if (nextPage >= banners.length) {
              nextPage = 0;
            }
            _pageController.animateToPage(
              nextPage,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          }
        });

        return SizedBox(
          height: 400,
          child: PageView.builder(
            controller: _pageController,
            itemCount: banners.length,
            itemBuilder: (context, index) {
              return _BannerCard(banner: banners[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildPlaceholderBanner() {
    return Container(
      height: 400,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Icon(Icons.image, size: 50, color: Colors.grey),
      ),
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({required this.banner});

  final BannerData banner;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            if (banner.linkUrl != null) {
              final uri = Uri.parse(banner.linkUrl!);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              } else {
                debugPrint('Could not launch ${banner.linkUrl}');
              }
            }
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Image
              if (banner.imageUrl != null)
                banner.imageUrl!.startsWith('http')
                    ? Image.network(
                        banner.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(Icons.broken_image, size: 50),
                          );
                        },
                      )
                    : Image.asset(
                        banner.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(Icons.broken_image, size: 50),
                          );
                        },
                      ),

              // No Text Overlay as requested
            ],
          ),
        ),
      ),
    );
  }
}

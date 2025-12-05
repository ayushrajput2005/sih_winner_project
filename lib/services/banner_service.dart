class BannerData {
  const BannerData({
    required this.id,
    required this.title,
    this.imageUrl,
    this.description,
    this.linkUrl,
  });

  final String id;
  final String title;
  final String? imageUrl;
  final String? description;
  final String? linkUrl;
}

class BannerService {
  BannerService._();

  static final BannerService instance = BannerService._();

  Future<List<BannerData>> getTrendingBanners() async {
    // Simulate network delay
    await Future<void>.delayed(const Duration(milliseconds: 500));

    // Mock data - replace with real API call later
    return [
      const BannerData(
        id: '1',
        title: 'Trending OilSeeds',
        description: 'Discover the latest trends in oilseeds',
        imageUrl: 'assets/images/banners/banner1.jpg',
        linkUrl: 'https://example.com/banner1', // Placeholder link
      ),
      const BannerData(
        id: '2',
        title: 'PMFBY',
        description: 'PMFBY Yojna',
        imageUrl: 'assets/images/banners/banner2.jpg',
        linkUrl: 'https://pmfby.gov.in/', // Placeholder link
      ),
      const BannerData(
        id: '3',
        title: 'New Arrivals',
        description: 'Check out new products',
        imageUrl: 'assets/images/banners/banner3.jpg',
        linkUrl: 'https://example.com/banner3',
      ),
      const BannerData(
        id: '4',
        title: 'Special Offer',
        description: 'Limited time offers',
        imageUrl: 'assets/images/banners/banner4.png',
        linkUrl: 'https://example.com/banner4',
      ),
    ];
  }

  Future<BannerData?> getBannerById(String id) async {
    final banners = await getTrendingBanners();
    try {
      return banners.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }
}

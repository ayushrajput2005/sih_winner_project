class BlogPost {
  final String title;
  final String description;
  final String url;
  final String date;

  const BlogPost({
    required this.title,
    required this.description,
    required this.url,
    required this.date,
  });
}

class TutorialVideo {
  final String title;
  final String videoId;
  final String description;

  const TutorialVideo({
    required this.title,
    required this.videoId,
    required this.description,
  });

  String get thumbnailUrl => 'https://img.youtube.com/vi/$videoId/0.jpg';
  String get videoUrl => 'https://www.youtube.com/watch?v=$videoId';
}

class LearnData {
  static const List<BlogPost> blogPosts = [
    BlogPost(
      title: 'Modern Farming Techniques',
      description: 'Learn about the latest technologies in agriculture.',
      url: 'https://fasalmitra.com/blog/modern-farming',
      date: '2025-12-01',
    ),
    BlogPost(
      title: 'Soil Health Management',
      description: 'Tips to maintain and improve soil fertility.',
      url: 'https://fasalmitra.com/blog/soil-health',
      date: '2025-11-25',
    ),
    BlogPost(
      title: 'Guide to Organic Farming',
      description: 'Step-by-step guide to starting organic farming.',
      url: 'https://fasalmitra.com/blog/organic-farming',
      date: '2025-11-15',
    ),
  ];

  static const List<TutorialVideo> tutorialVideos = [
    TutorialVideo(
      title: 'Cotton Seed Cake & Oil Manufacturing Business',
      videoId: 'EbAH4yRj43M', // Placeholder
      description: 'Cotton Seed Cake & Oil Manufacturing Business.',
    ),
    TutorialVideo(
      title: 'How To Start Soybean Oil Processing Business ',
      videoId: 'ON1kTYxyU84', // Placeholder
      description: 'How To Start Soybean Oil Processing Business .',
    ),
  ];
}

abstract class ApiInterface {
  static const String baseUrl = 'https://fourhoi.com/';

  Future<Map<String, dynamic>> homeFeed(int? page) async {
    throw UnimplementedError('getHomeFeed() has not been implemented.');
  }

  Future<Map<String, dynamic>> videoDetail(String videoId) async {
    throw UnimplementedError('videoDetail() has not been implemented.');
  }

  Future<Map<String, dynamic>> videoPlayUrl(String videoId) async {
    throw UnimplementedError('getVideoPlayUrl() has not been implemented.');
  }

  Future<Map<String, dynamic>> search(
    String keyword,
    int page,
    int size,
    String? indexId,
  ) async {
    throw UnimplementedError('search() has not been implemented.');
  }

  Future<Map<String, dynamic>> relatedVideos(String videoId) async {
    throw UnimplementedError('relatedVideos() has not been implemented.');
  }
}

class SearchResult {
  final bool hasMore;
  final String? indexId;
  final List<Map<String, dynamic>> videos;

  SearchResult({
    required this.hasMore,
    required this.indexId,
    required this.videos,
  });
}

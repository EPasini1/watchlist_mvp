import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/movie.dart';

class OmdbApiService {
  static const String _apiKey = 'e9f9fbfc';
  static const String _baseUrl = 'https://www.omdbapi.com/';

  Future<List<Movie>> searchTitles(String query) async {
    final q = Uri.encodeComponent(query.trim());
    if (q.isEmpty) return [];

    final url = Uri.parse('$_baseUrl?s=$q&apikey=$_apiKey');
    final res = await http.get(url);
    if (res.statusCode != 200) return [];

    final data = jsonDecode(res.body);
    if (data['Response'] != 'True' || data['Search'] == null) return [];

    // Mapeia -> Movie e remove DUPLICADOS preservando a ordem (por imdbID)
    final raw = (data['Search'] as List)
        .map((e) => Movie.fromJson(e as Map<String, dynamic>))
        .toList();

    final seen = <String>{};
    final deduped = <Movie>[];
    for (final m in raw) {
      final id = (m.imdbID).toLowerCase();
      if (seen.add(id)) deduped.add(m);
    }

    return deduped;
  }

  Future<Map<String, dynamic>?> fetchDetails(String imdbID) async {
    final url = Uri.parse('$_baseUrl?i=$imdbID&plot=short&apikey=$_apiKey');
    final res = await http.get(url);
    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body);
    if (data['Response'] != 'True') return null;
    return data as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> fetchSeasonEpisodes(String imdbID, int season) async {
    final url = Uri.parse('$_baseUrl?i=$imdbID&Season=$season&apikey=$_apiKey');
    final res = await http.get(url);
    if (res.statusCode != 200) return [];
    final data = jsonDecode(res.body);
    final eps = data['Episodes'] as List<dynamic>?;
    if (eps == null) return [];
    return eps.map((e) => e as Map<String, dynamic>).toList();
  }

  Future<int> fetchTotalEpisodes(String imdbID) async {
    final details = await fetchDetails(imdbID);
    if (details == null) return 0;

    final totalSeasons = int.tryParse('${details['totalSeasons']}') ?? 0;
    if (totalSeasons == 0) return 0;

    var sum = 0;
    for (var s = 1; s <= totalSeasons; s++) {
      final eps = await fetchSeasonEpisodes(imdbID, s);
      sum += eps.length;
    }
    return sum;
  }
}

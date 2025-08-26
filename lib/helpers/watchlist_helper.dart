import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/movie.dart';
import '../services/omdb_api_service.dart';

class WatchlistHelper {
  static const String _watchlistKey = 'watchlist';
  static String _watchedKey(String imdbID) => 'watched_$imdbID';

  // 🔹 NOVO: chave para "filme assistido"
  static String _movieWatchedKey(String imdbID) => 'movie_watched_$imdbID';

  // ---------- Watchlist ----------
  static Future<void> saveToWatchlist(Movie movie) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_watchlistKey) ?? [];
    list.removeWhere((e) => Movie.fromJson(jsonDecode(e)).imdbID == movie.imdbID);
    list.add(jsonEncode(movie.toJson()));
    await prefs.setStringList(_watchlistKey, list);
  }

  static Future<void> removeFromWatchlist(String imdbID) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_watchlistKey) ?? [];
    list.removeWhere((e) => Movie.fromJson(jsonDecode(e)).imdbID == imdbID);
    await prefs.setStringList(_watchlistKey, list);
    await prefs.remove(_watchedKey(imdbID));
    await prefs.remove(_movieWatchedKey(imdbID)); // 🔹 limpa flag do filme
  }

  static Future<List<Movie>> getWatchlist() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_watchlistKey) ?? [];
    return list.map((e) => Movie.fromJson(jsonDecode(e))).toList();
  }

  static Future<Set<String>> getSavedImdbIds() async {
    final items = await getWatchlist();
    return items.map((m) => m.imdbID).toSet();
  }

  // ---------- Série: episódios assistidos ----------
  static Future<List<String>> getWatchedEpisodes(String imdbID) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_watchedKey(imdbID)) ?? [];
  }

  static Future<void> saveWatchedEpisodes(String imdbID, List<String> episodes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_watchedKey(imdbID), episodes);
  }

  static Future<void> toggleEpisode(String imdbID, String episodeKey) async {
    final list = await getWatchedEpisodes(imdbID);
    if (list.contains(episodeKey)) {
      list.remove(episodeKey);
    } else {
      list.add(episodeKey);
    }
    await saveWatchedEpisodes(imdbID, list);
  }

  static String lastWatchedLabel(List<String> watched) {
    if (watched.isEmpty) return 'Nenhum episódio assistido';
    final sorted = watched.toList()..sort();
    final last = sorted.last;
    final reg = RegExp(r'S(\d+)E(\d+)', caseSensitive: false);
    final m = reg.firstMatch(last);
    if (m == null) return last;
    return 'T${m.group(1)} | E${m.group(2)}';
  }

  static Future<String> computeStatus(String imdbID) async {
    final watched = await getWatchedEpisodes(imdbID);
    if (watched.isEmpty) return '🆕 Novo';
    final total = await OmdbApiService().fetchTotalEpisodes(imdbID);
    if (total == 0) return '🟢 Em andamento';
    if (watched.length >= total) return '✅ Finalizado';
    return '🟢 Em andamento';
  }

  // ---------- Filme: flag "assistido" ----------
  static Future<bool> isMovieWatched(String imdbID) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_movieWatchedKey(imdbID)) ?? false;
  }

  static Future<void> setMovieWatched(String imdbID, bool watched) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_movieWatchedKey(imdbID), watched);
  }

  static Future<void> toggleMovieWatched(String imdbID) async {
    final current = await isMovieWatched(imdbID);
    await setMovieWatched(imdbID, !current);
  }
}

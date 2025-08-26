import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../helpers/watchlist_helper.dart';
import '../models/movie.dart';
import '../services/omdb_api_service.dart';
import '../theme_controller.dart';
import 'series_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final OmdbApiService _api = OmdbApiService();

  List<Movie> _results = [];
  Set<String> _savedIds = {};

  @override
  void initState() {
    super.initState();
    _loadSavedIds();
  }

  Future<void> _loadSavedIds() async {
    final ids = await WatchlistHelper.getSavedImdbIds();
    setState(() => _savedIds = ids);
  }

  Future<void> _search() async {
    final q = _controller.text.trim();
    if (q.isEmpty) return;

    final res = await _api.searchTitles(q);

    // Segurança extra: dedupe também aqui (caso futuro)
    final seen = <String>{};
    final deduped = <Movie>[];
    for (final m in res) {
      final id = m.imdbID.toLowerCase();
      if (seen.add(id)) deduped.add(m);
    }

    setState(() => _results = deduped);
  }

  Future<void> _toggleSave(Movie m) async {
    if (_savedIds.contains(m.imdbID)) {
      await WatchlistHelper.removeFromWatchlist(m.imdbID);
    } else {
      await WatchlistHelper.saveToWatchlist(m);
    }
    await _loadSavedIds();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeController>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explorar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: () => theme.toggleTheme(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Digite um título',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _search,
                ),
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _search(),
            ),
          ),
          Expanded(
            child: _results.isEmpty
                ? const Center(child: Text('Nenhum resultado'))
                : ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (_, i) {
                      final m = _results[i];
                      final saved = _savedIds.contains(m.imdbID);

                      Widget leading;
                      if (m.poster != 'N/A' && m.poster.trim().isNotEmpty) {
                        leading = Image.network(
                          m.poster,
                          width: 50,
                          fit: BoxFit.cover,
                          // Evita “HTTP request failed: statusCode 0” (CORS no Web)
                          errorBuilder: (ctx, err, st) => const Icon(Icons.image_not_supported),
                        );
                      } else {
                        leading = const Icon(Icons.movie);
                      }

                      return ListTile(
                        leading: leading,
                        title: Text(m.title),
                        subtitle: Text('${m.year}  •  ${m.type}'),
                        trailing: IconButton(
                          icon: Icon(saved ? Icons.check_box : Icons.add_box_outlined),
                          color: saved ? Colors.green : null,
                          onPressed: () => _toggleSave(m),
                        ),
                        onTap: () {
                          if (m.type.toLowerCase() == 'series') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SeriesDetailScreen(
                                  imdbID: m.imdbID,
                                  title: m.title,
                                ),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

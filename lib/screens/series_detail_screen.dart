import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../helpers/watchlist_helper.dart';
import '../services/omdb_api_service.dart';
import '../theme_controller.dart';

class SeriesDetailScreen extends StatefulWidget {
  final String imdbID;
  final String title;

  const SeriesDetailScreen({
    super.key,
    required this.imdbID,
    required this.title,
  });

  @override
  State<SeriesDetailScreen> createState() => _SeriesDetailScreenState();
}

class _SeriesDetailScreenState extends State<SeriesDetailScreen> {
  final OmdbApiService _api = OmdbApiService();

  int _currentSeason = 1;
  List<Map<String, dynamic>> _episodes = [];
  Set<String> _watched = {};

  @override
  void initState() {
    super.initState();
    _loadWatched();
    _fetchEpisodes();
  }

  Future<void> _loadWatched() async {
    final list = await WatchlistHelper.getWatchedEpisodes(widget.imdbID);
    setState(() => _watched = list.toSet());
  }

  Future<void> _fetchEpisodes() async {
    final eps = await _api.fetchSeasonEpisodes(widget.imdbID, _currentSeason);
    setState(() => _episodes = eps);
  }

  Future<void> _toggle(String epKey) async {
    await WatchlistHelper.toggleEpisode(widget.imdbID, epKey);
    await _loadWatched();
  }

  void _nextSeason() {
    setState(() => _currentSeason += 1);
    _fetchEpisodes();
  }

  void _prevSeason() {
    if (_currentSeason == 1) return;
    setState(() => _currentSeason -= 1);
    _fetchEpisodes();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeController>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.title} - Temporada $_currentSeason'),
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: () => theme.toggleTheme(),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton(onPressed: _prevSeason, child: const Text('← Temporada')),
              ElevatedButton(onPressed: _nextSeason, child: const Text('Temporada →')),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: _episodes.isEmpty
                ? const Center(child: Text('Sem episódios encontrados.'))
                : ListView.builder(
                    itemCount: _episodes.length,
                    itemBuilder: (_, i) {
                      final ep = _episodes[i];
                      final epNum = ep['Episode'];
                      final epTitle = ep['Title'] ?? 'Sem título';
                      final epReleased = ep['Released'] ?? '';
                      final epKey = 'S${_currentSeason}E$epNum';

                      return CheckboxListTile(
                        value: _watched.contains(epKey),
                        onChanged: (_) => _toggle(epKey),
                        title: Text('$epNum. $epTitle'),
                        subtitle: Text('Exibido em: $epReleased'),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

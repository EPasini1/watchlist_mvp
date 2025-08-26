import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../helpers/watchlist_helper.dart';
import '../models/movie.dart';
import '../theme_controller.dart';
import 'search_screen.dart';
import 'series_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Movie> _watchlist = [];
  int _currentIndex = 0; // 0 Séries, 1 Filmes

  @override
  void initState() {
    super.initState();
    _loadWatchlist();
  }

  Future<void> _loadWatchlist() async {
    final list = await WatchlistHelper.getWatchlist();
    setState(() => _watchlist = list);
  }

  List<Movie> get _series =>
      _watchlist.where((m) => m.type.toLowerCase() == 'series').toList();

  List<Movie> get _movies =>
      _watchlist.where((m) => m.type.toLowerCase() == 'movie').toList();

  Widget _buildCard(Movie m) {
    return FutureBuilder(
      future: Future.wait([
        WatchlistHelper.getWatchedEpisodes(m.imdbID),
        WatchlistHelper.computeStatus(m.imdbID),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(child: ListTile(title: Text('Carregando...')));
        }
        final watched = snapshot.data![0] as List<String>;
        final status = snapshot.data![1] as String;
        final last = WatchlistHelper.lastWatchedLabel(watched);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: InkWell(
            onTap: () async {
              if (m.type.toLowerCase() == 'series') {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SeriesDetailScreen(
                      imdbID: m.imdbID,
                      title: m.title,
                    ),
                  ),
                );
                _loadWatchlist(); // refresh ao voltar
              }
            },
            child: Row(
              children: [
                (m.poster != 'N/A')
                    ? Image.network(m.poster, width: 80, height: 100, fit: BoxFit.cover)
                    : Container(width: 80, height: 100, color: Colors.grey),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(last),
                        const SizedBox(height: 4),
                        Text(
                          status,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: status.startsWith('✅')
                                ? Colors.green
                                : (status.startsWith('🆕')
                                    ? Colors.blueGrey
                                    : Colors.orange),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    status.startsWith('✅')
                        ? Icons.check_circle
                        : status.startsWith('🆕')
                            ? Icons.fiber_new
                            : Icons.timelapse,
                    color: status.startsWith('✅')
                        ? Colors.green
                        : (status.startsWith('🆕') ? Colors.blueGrey : Colors.orange),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildList(List<Movie> data) {
    if (data.isEmpty) {
      return const Center(child: Text('Nada por aqui ainda.'));
    }
    return RefreshIndicator(
      onRefresh: _loadWatchlist,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: data.length,
        itemBuilder: (_, i) => _buildCard(data[i]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeController>(context, listen: false);

    final titles = ['Séries', 'Filmes'];
    final body = _currentIndex == 0 ? _buildList(_series) : _buildList(_movies);

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_currentIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: () => theme.toggleTheme(),
          ),
        ],
      ),
      body: body,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) async {
          if (i == 2) {
            // Explorar abre a tela de busca
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            );
            _loadWatchlist(); // recarrega ao voltar
          } else {
            setState(() => _currentIndex = i);
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.tv),
            label: 'Séries',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.movie_creation_outlined),
            label: 'Filmes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Explorar',
          ),
        ],
      ),
    );
  }
}

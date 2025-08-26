class Movie {
  final String title;
  final String year;
  final String poster;
  final String imdbID;
  final String type; // "movie" ou "series"
  final String? plot;

  Movie({
    required this.title,
    required this.year,
    required this.poster,
    required this.imdbID,
    required this.type,
    this.plot,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      title: json['Title'] ?? 'Sem título',
      year: json['Year'] ?? '',
      poster: json['Poster'] ?? 'N/A',
      imdbID: json['imdbID'] ?? '',
      type: json['Type'] ?? '',
      plot: json['Plot'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Title': title,
      'Year': year,
      'Poster': poster,
      'imdbID': imdbID,
      'Type': type,
      if (plot != null) 'Plot': plot,
    };
  }
}

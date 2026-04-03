class Track {
  final int id;
  final DateTime datetime;
  final String commentaire;

  const Track({
    required this.id,
    required this.datetime,
    required this.commentaire,
  });

  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      id: json['id'] as int,
      datetime: DateTime.parse(json['datetime'] as String).toLocal(),
      commentaire: json['commentaire'] as String? ?? '',
    );
  }
}

class Track {
  final int id;
  final DateTime datetime;
  final String commentaire;
  final double? valeur;
  final String? localId; // non-null = en attente de sync

  bool get isPending => localId != null;

  const Track({
    required this.id,
    required this.datetime,
    required this.commentaire,
    this.valeur,
    this.localId,
  });

  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      id: json['id'] as int,
      datetime: DateTime.parse(json['datetime'] as String).toLocal(),
      commentaire: json['commentaire'] as String? ?? '',
      valeur: (json['valeur'] as num?)?.toDouble(),
    );
  }
}

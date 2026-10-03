class City {
  const City({required this.name, required this.lat, required this.lng});

  /// Builds a city from one object of assets/data/romanian_cities.json.
  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      name: json['name'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
    );
  }

  final String name;
  final double lat;
  final double lng;
}
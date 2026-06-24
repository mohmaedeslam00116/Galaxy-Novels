import 'catalog_data.dart';

class RankingsData {
  const RankingsData({required this.period, required this.items});

  factory RankingsData.fromJson(Map<String, dynamic> json) {
    return RankingsData(
      period: _asString(json['period']),
      items: _asList(json['items'])
          .map((item) => CatalogNovel.fromJson(_asMap(item)))
          .where((item) => item.title.isNotEmpty)
          .toList(growable: false),
    );
  }

  final String period;
  final List<CatalogNovel> items;
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return const {};
}

List<Object?> _asList(Object? value) {
  if (value is List) {
    return value.cast<Object?>();
  }
  return const [];
}

String _asString(Object? value) => value?.toString() ?? '';

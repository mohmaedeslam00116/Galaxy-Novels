import 'catalog_data.dart';

class RankingsData {
  const RankingsData({required this.period, required this.items});

  factory RankingsData.fromJson(Map<String, dynamic> json) {
    final data = _asMap(json['data']);
    final source = data.isNotEmpty ? data : json;
    final items = _asList(source['items']);
    final fallbackItems = items.isEmpty ? _asList(source['novels']) : items;

    return RankingsData(
      period: _asString(source['period']),
      items: fallbackItems
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

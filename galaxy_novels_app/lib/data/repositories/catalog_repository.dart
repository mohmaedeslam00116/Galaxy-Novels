import '../models/catalog_data.dart';

abstract class CatalogRepository {
  Stream<CatalogLoadState> watchCatalog();
}

class CatalogLoadState {
  const CatalogLoadState({
    required this.items,
    required this.loadedParts,
    required this.totalParts,
    required this.isLoadingMore,
    this.backgroundError,
  });

  final List<CatalogNovel> items;
  final int loadedParts;
  final int totalParts;
  final bool isLoadingMore;
  final String? backgroundError;

  CatalogLoadState copyWith({
    List<CatalogNovel>? items,
    int? loadedParts,
    int? totalParts,
    bool? isLoadingMore,
    String? backgroundError,
  }) {
    return CatalogLoadState(
      items: items ?? this.items,
      loadedParts: loadedParts ?? this.loadedParts,
      totalParts: totalParts ?? this.totalParts,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      backgroundError: backgroundError ?? this.backgroundError,
    );
  }
}

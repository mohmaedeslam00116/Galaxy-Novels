import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/app_dependencies.dart';
import '../../../app/app_theme.dart';
import '../../../data/models/catalog_data.dart';
import '../../../data/models/search_index_data.dart';
import '../../../data/repositories/catalog_repository.dart';
import '../../../data/repositories/search_repository.dart';
import '../../../design_system/components/galaxy_command_bar.dart';
import '../../../design_system/foundation/galaxy_adaptive.dart';
import '../../ads/application/inline_native_ad_repository.dart';
import '../../ads/presentation/inline_native_ad_slot.dart';
import '../../novel_details/presentation/novel_details_navigation.dart';
import '../application/library_customization_repository.dart';
import '../domain/catalog_query.dart';
import '../domain/library_customization.dart';
import 'library_customization_metrics.dart';
import 'widgets/catalog_novel_tile.dart';

const double _catalogMaximumContentWidth = 900;

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({this.initialQuery, super.key});

  final CatalogQuery? initialQuery;

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final _searchController = TextEditingController();

  CatalogRepository? _repository;
  SearchRepository? _searchRepository;
  Stream<CatalogLoadState>? _catalogStream;
  Future<SearchIndex>? _searchIndexFuture;
  late CatalogQuery _query = widget.initialQuery ?? const CatalogQuery();
  LibraryCustomizationRepository? _customizationRepository;
  LibraryCustomization _customization = LibraryCustomization.defaults;
  LibraryLayout? _sessionLayout;
  bool _resolvedInitialCustomization = false;
  Timer? _searchDebounce;

  LibraryCustomization get _effectiveCustomization =>
      _customization.copyWith(layout: _sessionLayout ?? _customization.layout);

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialQuery?.searchText ?? '';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repository = AppDependencies.of(context).catalogRepository;
    final searchRepository = AppDependencies.of(context).searchRepository;
    if (_repository != repository) {
      _repository = repository;
      _catalogStream = repository.watchCatalog();
    }
    if (_searchRepository != searchRepository) {
      _searchRepository = searchRepository;
      _searchIndexFuture = null;
    }
    final customizationRepository = LibraryCustomizationRepositoryScope.maybeOf(
      context,
    );
    final nextCustomization =
        customizationRepository?.value ?? LibraryCustomization.defaults;
    _customizationRepository = customizationRepository;
    if (nextCustomization != _customization || !_resolvedInitialCustomization) {
      if (nextCustomization.layout != _customization.layout) {
        _sessionLayout = null;
      }
      _customization = nextCustomization;
      if (widget.initialQuery == null) {
        _query = _query.copyWith(sort: nextCustomization.defaultSort);
      }
      _resolvedInitialCustomization = true;
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CatalogLoadState>(
      stream: _catalogStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return _buildCatalogContent(
            state: null,
            items: const [],
            initialStateSliver: _CatalogSkeleton(
              customization: _effectiveCustomization,
            ),
          );
        }

        if (snapshot.hasError && !snapshot.hasData) {
          return _buildCatalogContent(
            state: null,
            items: const [],
            initialStateSliver: SliverFillRemaining(
              hasScrollBody: false,
              child: _CatalogMessage(
                title: 'تعذر تحميل المكتبة الآن',
                actionLabel: 'إعادة المحاولة',
                onAction: _retryCatalog,
              ),
            ),
          );
        }

        final state = snapshot.data;
        final items = state?.items ?? const [];
        if (items.isEmpty) {
          return _buildCatalogContent(
            state: state,
            items: items,
            initialStateSliver: const SliverFillRemaining(
              hasScrollBody: false,
              child: _CatalogMessage(title: 'لا توجد روايات في المكتبة الآن'),
            ),
          );
        }

        final searchFuture = _query.searchText.trim().isEmpty
            ? null
            : _searchIndexFuture;
        if (searchFuture == null) {
          return _buildCatalogContent(state: state, items: items);
        }

        return FutureBuilder<SearchIndex>(
          future: searchFuture,
          builder: (context, searchSnapshot) {
            return _buildCatalogContent(
              state: state,
              items: items,
              searchIndex: searchSnapshot.data,
            );
          },
        );
      },
    );
  }

  Widget _buildCatalogContent({
    required CatalogLoadState? state,
    required List<CatalogNovel> items,
    SearchIndex? searchIndex,
    Widget? initialStateSliver,
  }) {
    final searchItems = searchIndex == null || _query.searchText.trim().isEmpty
        ? null
        : searchIndex
              .search(_query.searchText)
              .map((item) {
                return item.toCatalogNovel();
              })
              .toList(growable: false);
    final source = searchItems ?? items;
    final effectiveQuery = searchItems == null
        ? _query
        : _query.copyWith(searchText: '');
    final result = applyCatalogQuery(source, effectiveQuery);

    final customization = _effectiveCustomization;
    return CustomScrollView(
      key: const ValueKey('catalog-scroll-view'),
      slivers: [
        if (customization.pinCompactSearch)
          SliverPersistentHeader(
            pinned: true,
            delegate: _CatalogSearchHeaderDelegate(
              controller: _searchController,
              query: _query,
              onChanged: _onSearchChanged,
              onClear: _clearSearchText,
            ),
          ),
        SliverToBoxAdapter(
          child: _CatalogControls(
            includeSearch: !customization.pinCompactSearch,
            searchController: _searchController,
            viewState: (
              query: _query,
              layout: customization.layout,
              defaultSort: customization.defaultSort,
              resultCount: state == null ? null : result.items.length,
              availableStatuses: result.availableStatuses,
              availableGenres: result.availableGenres,
            ),
            actions: (
              searchChanged: _onSearchChanged,
              searchCleared: _clearSearchText,
              sortChanged: (sort) {
                setState(() => _query = _query.copyWith(sort: sort));
                _persistRuntimeSort(sort);
              },
              layoutChanged: _setLayout,
              filtersChanged: (status, genre) {
                setState(() {
                  _query = _query.copyWith(
                    statusLabel: status,
                    genreName: genre,
                    clearStatus: status == null,
                    clearGenre: genre == null,
                  );
                });
              },
              clearAll: _clearQuery,
            ),
          ),
        ),
        if (initialStateSliver != null)
          initialStateSliver
        else if (state?.backgroundError != null)
          SliverToBoxAdapter(
            child: _CatalogLoadStatus(state: state, onRetry: _retryCatalog),
          ),
        if (initialStateSliver == null && result.items.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _CatalogMessage(
              title: 'لا توجد نتائج مطابقة',
              actionLabel: 'مسح البحث والفلاتر',
              onAction: _clearQuery,
            ),
          )
        else if (initialStateSliver == null)
          _CatalogNovelResults(
            items: result.items,
            customization: customization,
            onOpen: _openNovelDetails,
          ),
        if (initialStateSliver == null && state?.backgroundError == null)
          SliverToBoxAdapter(
            child: _CatalogLoadStatus(state: state, onRetry: _retryCatalog),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) {
        return;
      }
      setState(() => _query = _query.copyWith(searchText: value));
      if (value.trim().isNotEmpty && _searchIndexFuture == null) {
        _searchIndexFuture = _searchRepository?.loadSearchIndex();
      }
    });
  }

  void _clearQuery() {
    _searchDebounce?.cancel();
    _searchController.clear();
    setState(() => _query = CatalogQuery(sort: _customization.defaultSort));
  }

  void _clearSearchText() {
    _searchDebounce?.cancel();
    _searchController.clear();
    setState(() => _query = _query.copyWith(searchText: ''));
  }

  void _retryCatalog() {
    final repository = _repository;
    if (repository == null) {
      return;
    }
    setState(() {
      _catalogStream = repository.watchCatalog();
    });
  }

  void _openNovelDetails(String manifestPath) {
    unawaited(NovelDetailsNavigation.open(context, manifestPath: manifestPath));
  }

  void _setLayout(LibraryLayout layout) {
    if (_effectiveCustomization.layout == layout) return;
    setState(() => _sessionLayout = layout);
    final repository = _customizationRepository;
    if (_customization.rememberViewAndSort && repository != null) {
      unawaited(repository.update(repository.value.copyWith(layout: layout)));
    }
  }

  void _persistRuntimeSort(CatalogSort sort) {
    final repository = _customizationRepository;
    if (!_customization.rememberViewAndSort || repository == null) return;
    unawaited(repository.update(repository.value.copyWith(defaultSort: sort)));
  }
}

typedef _CatalogFiltersChanged =
    void Function(String? statusLabel, String? genreName);

typedef _CatalogControlsViewState = ({
  List<String> availableGenres,
  List<String> availableStatuses,
  CatalogSort defaultSort,
  LibraryLayout layout,
  CatalogQuery query,
  int? resultCount,
});

typedef _CatalogControlsActions = ({
  VoidCallback clearAll,
  _CatalogFiltersChanged filtersChanged,
  ValueChanged<LibraryLayout> layoutChanged,
  ValueChanged<String> searchChanged,
  VoidCallback searchCleared,
  ValueChanged<CatalogSort> sortChanged,
});

class _CatalogControls extends StatelessWidget {
  const _CatalogControls({
    required this.includeSearch,
    required this.searchController,
    required this.viewState,
    required this.actions,
  });

  final bool includeSearch;
  final TextEditingController searchController;
  final _CatalogControlsViewState viewState;
  final _CatalogControlsActions actions;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = GalaxyAdaptiveMetrics.forWidth(
      MediaQuery.sizeOf(context).width,
    ).horizontalPadding;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        12,
        horizontalPadding,
        10,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (includeSearch) ...[
            _CatalogSearchField(
              controller: searchController,
              query: viewState.query,
              onChanged: actions.searchChanged,
              onClear: actions.searchCleared,
            ),
            const SizedBox(height: 10),
          ],
          _CatalogTools(
            filterButton: _CatalogToolButton(
              key: const ValueKey('catalog-filter-button'),
              icon: Icons.category_outlined,
              label: viewState.query.genreName ?? 'كل التصنيفات',
              onTap: () => _showFilters(context),
            ),
            sortButton: _CatalogSortButton(
              selectedSort: viewState.query.sort,
              onSelected: actions.sortChanged,
            ),
            layout: viewState.layout,
            onLayoutChanged: actions.layoutChanged,
          ),
          _ActiveCatalogFilters(
            query: viewState.query,
            defaultSort: viewState.defaultSort,
            onSearchCleared: actions.searchCleared,
            onSortReset: () => actions.sortChanged(viewState.defaultSort),
            onFiltersChanged: actions.filtersChanged,
            onClear: actions.clearAll,
          ),
          if (viewState.resultCount case final count?) ...[
            const SizedBox(height: 10),
            Text(
              '$count رواية',
              key: const ValueKey('catalog-results-summary'),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showFilters(BuildContext context) async {
    final result = await showModalBottomSheet<_FilterSelection>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Semantics(
          label: 'فلاتر المكتبة',
          scopesRoute: true,
          namesRoute: true,
          explicitChildNodes: true,
          child: FractionallySizedBox(
            heightFactor: 0.78,
            child: _CatalogFiltersSheet(
              selectedStatus: viewState.query.statusLabel,
              selectedGenre: viewState.query.genreName,
              availableStatuses: viewState.availableStatuses,
              availableGenres: viewState.availableGenres,
            ),
          ),
        );
      },
    );

    if (result != null) {
      actions.filtersChanged(result.status, result.genre);
    }
  }
}

class _CatalogNovelResults extends StatelessWidget {
  const _CatalogNovelResults({
    required this.items,
    required this.customization,
    required this.onOpen,
  });

  final List<CatalogNovel> items;
  final LibraryCustomization customization;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final outerPadding = libraryOuterPadding(customization.density);
        final adaptivePadding = GalaxyAdaptiveMetrics.forWidth(
          constraints.crossAxisExtent,
        ).horizontalPadding;
        final horizontalPadding = _catalogHorizontalPadding(
          constraints.crossAxisExtent,
          minimum: math.max(outerPadding, adaptivePadding),
        );
        final spacing = libraryCardSpacing(customization.density);
        final chunks = _catalogResultChunks(items.length);

        if (customization.layout == LibraryLayout.list) {
          return SliverMainAxisGroup(
            slivers: [
              for (
                var chunkIndex = 0;
                chunkIndex < chunks.length;
                chunkIndex++
              ) ...[
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  sliver: SliverList.separated(
                    key: ValueKey(
                      chunkIndex == 0
                          ? 'catalog-sliver-list'
                          : 'catalog-sliver-list-$chunkIndex',
                    ),
                    itemCount:
                        chunks[chunkIndex].end - chunks[chunkIndex].start,
                    separatorBuilder: (_, _) => SizedBox(height: spacing),
                    itemBuilder: (context, index) {
                      final novel = items[chunks[chunkIndex].start + index];
                      return CatalogNovelTile(
                        novel: novel,
                        customization: customization,
                        onTap: novel.manifest.isEmpty
                            ? null
                            : () => onOpen(novel.manifest),
                      );
                    },
                  ),
                ),
                if (chunks[chunkIndex].adAfter)
                  const SliverToBoxAdapter(
                    child: InlineNativeAdSlot(
                      placement: InlineNativeAdPlacement.library,
                    ),
                  ),
              ],
            ],
          );
        }

        final gridWidth = constraints.crossAxisExtent - horizontalPadding * 2;
        final columns = _catalogColumnCount(
          gridWidth,
          customization.cardSize,
          spacing,
        );
        final tileWidth = (gridWidth - (columns - 1) * spacing) / columns;
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final tileExtent = libraryGridTileExtent(
          tileWidth,
          customization,
          textScale,
        );
        return SliverMainAxisGroup(
          slivers: [
            for (
              var chunkIndex = 0;
              chunkIndex < chunks.length;
              chunkIndex++
            ) ...[
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                sliver: SliverGrid(
                  key: ValueKey(
                    chunkIndex == 0
                        ? 'catalog-sliver-grid'
                        : 'catalog-sliver-grid-$chunkIndex',
                  ),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: spacing,
                    mainAxisSpacing: librarySectionSpacing(
                      customization.density,
                    ),
                    mainAxisExtent: tileExtent,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final novel = items[chunks[chunkIndex].start + index];
                      return CatalogNovelTile(
                        novel: novel,
                        customization: customization,
                        onTap: novel.manifest.isEmpty
                            ? null
                            : () => onOpen(novel.manifest),
                      );
                    },
                    childCount:
                        chunks[chunkIndex].end - chunks[chunkIndex].start,
                  ),
                ),
              ),
              if (chunks[chunkIndex].adAfter)
                const SliverToBoxAdapter(
                  child: InlineNativeAdSlot(
                    placement: InlineNativeAdPlacement.library,
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}

List<({int start, int end, bool adAfter})> _catalogResultChunks(int count) {
  if (count <= 0) return const [];
  if (count < 8) return [(start: 0, end: count, adAfter: false)];

  final chunks = <({int start, int end, bool adAfter})>[];
  var start = 0;
  var end = math.min(8, count);
  while (start < count) {
    chunks.add((
      start: start,
      end: end,
      adAfter: end == 8 || end - start == 12,
    ));
    start = end;
    end = math.min(start + 12, count);
  }
  return chunks;
}

class _CatalogSearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  _CatalogSearchHeaderDelegate({
    required this.controller,
    required this.query,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final CatalogQuery query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  double get minExtent => 60;

  @override
  double get maxExtent => 76;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final theme = Theme.of(context);
    final progress = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final horizontalPadding = GalaxyAdaptiveMetrics.forWidth(
      MediaQuery.sizeOf(context).width,
    ).horizontalPadding;
    return SizedBox.expand(
      child: Material(
        color: theme.scaffoldBackgroundColor,
        elevation: overlapsContent ? 2 : 0,
        surfaceTintColor: Colors.transparent,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            12 - progress * 6,
            horizontalPadding,
            8 - progress * 2,
          ),
          child: _CatalogSearchField(
            controller: controller,
            query: query,
            onChanged: onChanged,
            onClear: onClear,
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _CatalogSearchHeaderDelegate oldDelegate) {
    return oldDelegate.query != query || oldDelegate.controller != controller;
  }
}

class _CatalogTools extends StatelessWidget {
  const _CatalogTools({
    required this.filterButton,
    required this.sortButton,
    required this.layout,
    required this.onLayoutChanged,
  });

  final Widget filterButton;
  final Widget sortButton;
  final LibraryLayout layout;
  final ValueChanged<LibraryLayout> onLayoutChanged;

  @override
  Widget build(BuildContext context) {
    final next = layout == LibraryLayout.grid
        ? LibraryLayout.list
        : LibraryLayout.grid;
    return KeyedSubtree(
      key: const ValueKey('catalog-tools-row'),
      child: GalaxyCommandBar(
        label: 'أدوات المكتبة',
        leading: Row(
          children: [
            Expanded(child: filterButton),
            const SizedBox(width: 8),
            Expanded(child: sortButton),
          ],
        ),
        actions: [
          GalaxyCommand(
            key: const ValueKey('catalog-layout-toggle'),
            icon: layout == LibraryLayout.grid
                ? Icons.view_list_rounded
                : Icons.grid_view_rounded,
            label: next == LibraryLayout.grid ? 'شبكة' : 'قائمة',
            onPressed: () => onLayoutChanged(next),
            selected: true,
          ),
        ],
      ),
    );
  }
}

class _CatalogSearchField extends StatelessWidget {
  const _CatalogSearchField({
    required this.controller,
    required this.query,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final CatalogQuery query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;
    final hasSearch = query.searchText.trim().isNotEmpty;

    return TextField(
      key: const ValueKey('catalog-search-field'),
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        isDense: true,
        constraints: const BoxConstraints(minHeight: 48),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: hasSearch
            ? IconButton(
                tooltip: 'مسح البحث',
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded),
              )
            : null,
        hintText: 'ابحث عن رواية...',
        fillColor: tokens.surfaceRaised,
      ),
    );
  }
}

class _CatalogSortButton extends StatelessWidget {
  const _CatalogSortButton({
    required this.selectedSort,
    required this.onSelected,
  });

  final CatalogSort selectedSort;
  final ValueChanged<CatalogSort> onSelected;

  @override
  Widget build(BuildContext context) {
    final tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return PopupMenuButton<CatalogSort>(
      key: const ValueKey('catalog-sort-menu'),
      initialValue: selectedSort,
      position: PopupMenuPosition.under,
      tooltip: 'ترتيب الروايات',
      color: tokens.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: tokens.border),
      ),
      onSelected: onSelected,
      itemBuilder: (context) {
        return [
          for (final sort in CatalogSort.values)
            PopupMenuItem(
              value: sort,
              child: Row(
                children: [
                  Icon(
                    selectedSort == sort
                        ? Icons.check_rounded
                        : Icons.sort_rounded,
                    color: selectedSort == sort
                        ? tokens.primary
                        : tokens.textSecondary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(sort.label, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
        ];
      },
      child: _CatalogToolSurface(
        icon: Icons.sort_rounded,
        label: selectedSort.label,
        trailingIcon: Icons.keyboard_arrow_down_rounded,
      ),
    );
  }
}

class _CatalogToolButton extends StatelessWidget {
  const _CatalogToolButton({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Semantics(
        label: label,
        button: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: _CatalogToolSurface(
            icon: icon,
            label: label,
            trailingIcon: Icons.keyboard_arrow_down_rounded,
          ),
        ),
      ),
    );
  }
}

class _CatalogToolSurface extends StatelessWidget {
  const _CatalogToolSurface({
    required this.icon,
    required this.label,
    required this.trailingIcon,
  });

  final IconData icon;
  final String label;
  final IconData trailingIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;
    final compact = GalaxyAdaptive.of(context) == GalaxyLayoutTier.compact;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Ink(
        color: Colors.transparent,
        child: compact
            ? Center(child: Icon(icon, color: tokens.accent, size: 20))
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Icon(icon, color: tokens.accent, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Icon(trailingIcon, color: tokens.textSecondary, size: 20),
                  ],
                ),
              ),
      ),
    );
  }
}

class _ActiveCatalogFilters extends StatelessWidget {
  const _ActiveCatalogFilters({
    required this.query,
    required this.defaultSort,
    required this.onSearchCleared,
    required this.onSortReset,
    required this.onFiltersChanged,
    required this.onClear,
  });

  final CatalogQuery query;
  final CatalogSort defaultSort;
  final VoidCallback onSearchCleared;
  final VoidCallback onSortReset;
  final void Function(String? status, String? genre) onFiltersChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final activeWidgets = <Widget>[
      if (query.searchText.trim().isNotEmpty)
        _ActiveFilterPill(
          key: const ValueKey('catalog-active-filter-search'),
          label: 'بحث: ${query.searchText.trim()}',
          onClear: onSearchCleared,
        ),
      if (query.statusLabel case final status?)
        _ActiveFilterPill(
          key: const ValueKey('catalog-active-filter-status'),
          label: 'الحالة: $status',
          onClear: () => onFiltersChanged(null, query.genreName),
        ),
      if (query.genreName case final genre?)
        _ActiveFilterPill(
          key: const ValueKey('catalog-active-filter-genre'),
          label: 'تصنيف: $genre',
          onClear: () => onFiltersChanged(query.statusLabel, null),
        ),
      if (query.sort != defaultSort)
        _ActiveFilterPill(
          key: const ValueKey('catalog-active-sort'),
          label: 'ترتيب: ${query.sort.label}',
          onClear: onSortReset,
        ),
    ];

    if (activeWidgets.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ...activeWidgets,
          TextButton.icon(
            key: const ValueKey('catalog-clear-query'),
            onPressed: onClear,
            icon: const Icon(Icons.close_rounded, size: 18),
            label: const Text('مسح'),
          ),
        ],
      ),
    );
  }
}

class _ActiveFilterPill extends StatelessWidget {
  const _ActiveFilterPill({
    required this.label,
    required this.onClear,
    super.key,
  });

  final String label;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return Material(
      color: tokens.surfaceSoft,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onClear,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.close_rounded, color: tokens.textSecondary, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _CatalogFiltersSheet extends StatefulWidget {
  const _CatalogFiltersSheet({
    required this.selectedStatus,
    required this.selectedGenre,
    required this.availableStatuses,
    required this.availableGenres,
  });

  final String? selectedStatus;
  final String? selectedGenre;
  final List<String> availableStatuses;
  final List<String> availableGenres;

  @override
  State<_CatalogFiltersSheet> createState() => _CatalogFiltersSheetState();
}

class _CatalogFiltersSheetState extends State<_CatalogFiltersSheet> {
  String? _status;
  String? _genre;

  @override
  void initState() {
    super.initState();
    _status = widget.selectedStatus;
    _genre = widget.selectedGenre;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.availableStatuses.length > 1) ...[
                      Text(
                        'الحالة',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final status in widget.availableStatuses)
                            FilterChip(
                              label: Text(status),
                              selected: _status == status,
                              onSelected: (selected) {
                                setState(
                                  () => _status = selected ? status : null,
                                );
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (widget.availableGenres.isNotEmpty) ...[
                      Text(
                        'التصنيفات',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final genre in widget.availableGenres)
                            FilterChip(
                              label: Text(genre),
                              selected: _genre == genre,
                              onSelected: (selected) {
                                setState(
                                  () => _genre = selected ? genre : null,
                                );
                              },
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(
                        context,
                      ).pop(_FilterSelection(status: _status, genre: _genre));
                    },
                    child: const Text('تطبيق'),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(const _FilterSelection());
                  },
                  child: const Text('مسح'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterSelection {
  const _FilterSelection({this.status, this.genre});

  final String? status;
  final String? genre;
}

class _CatalogLoadStatus extends StatelessWidget {
  const _CatalogLoadStatus({required this.state, required this.onRetry});

  final CatalogLoadState? state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final currentState = state;
    if (currentState == null) {
      return const SizedBox.shrink();
    }

    if (currentState.backgroundError != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            const Expanded(child: Text('تعذر تحميل بقية المكتبة')),
            TextButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
          ],
        ),
      );
    }

    if (!currentState.isLoadingMore) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Text(
        'جار تحديث المكتبة...',
        style: Theme.of(context).textTheme.labelMedium,
      ),
    );
  }
}

class _CatalogSkeleton extends StatelessWidget {
  const _CatalogSkeleton({required this.customization});

  final LibraryCustomization customization;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final adaptivePadding = GalaxyAdaptiveMetrics.forWidth(
          constraints.crossAxisExtent,
        ).horizontalPadding;
        final horizontalPadding = _catalogHorizontalPadding(
          constraints.crossAxisExtent,
          minimum: math.max(
            libraryOuterPadding(customization.density),
            adaptivePadding,
          ),
        );
        final spacing = libraryCardSpacing(customization.density);
        if (customization.layout == LibraryLayout.list) {
          return SliverPadding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              8,
              horizontalPadding,
              24,
            ),
            sliver: SliverList.separated(
              key: const ValueKey('catalog-list-skeleton'),
              itemCount: 5,
              separatorBuilder: (_, _) => SizedBox(height: spacing),
              itemBuilder: (context, index) => _CatalogListSkeletonCard(
                key: ValueKey('catalog-list-skeleton-card-$index'),
                customization: customization,
              ),
            ),
          );
        }
        final gridWidth = constraints.crossAxisExtent - horizontalPadding * 2;
        final columns = _catalogColumnCount(
          gridWidth,
          customization.cardSize,
          spacing,
        );
        final tileWidth = (gridWidth - (columns - 1) * spacing) / columns;
        final tileExtent = libraryGridTileExtent(
          tileWidth,
          customization,
          MediaQuery.textScalerOf(context).scale(1),
        );
        return SliverPadding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            8,
            horizontalPadding,
            24,
          ),
          sliver: SliverGrid.builder(
            key: const ValueKey('catalog-grid-skeleton'),
            itemCount: 6,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: spacing,
              mainAxisSpacing: librarySectionSpacing(customization.density),
              mainAxisExtent: tileExtent,
            ),
            itemBuilder: (context, index) => _CatalogSkeletonCard(
              key: ValueKey('catalog-skeleton-card-$index'),
            ),
          ),
        );
      },
    );
  }
}

class _CatalogSkeletonCard extends StatelessWidget {
  const _CatalogSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary.withValues(alpha: 0.10);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(height: 14, color: color),
        const SizedBox(height: 6),
        FractionallySizedBox(
          widthFactor: 0.62,
          alignment: AlignmentDirectional.centerStart,
          child: Container(height: 12, color: color),
        ),
      ],
    );
  }
}

class _CatalogListSkeletonCard extends StatelessWidget {
  const _CatalogListSkeletonCard({required this.customization, super.key});

  final LibraryCustomization customization;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary.withValues(alpha: 0.10);
    final coverWidth = libraryListCoverWidth(customization.cardSize);
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: libraryListMinimumHeight(customization.cardSize),
      ),
      child: Row(
        children: [
          Container(width: coverWidth, height: coverWidth / 0.70, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(height: 16, color: color),
                const SizedBox(height: 10),
                FractionallySizedBox(
                  widthFactor: 0.64,
                  alignment: AlignmentDirectional.centerStart,
                  child: Container(height: 12, color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

double _catalogHorizontalPadding(double width, {double minimum = 16}) {
  return math.max(minimum, (width - _catalogMaximumContentWidth) / 2);
}

int _catalogColumnCount(double width, LibraryCardSize size, double spacing) {
  final availableWidth = width.isFinite && width > 0 ? width : 360.0;
  final fittedColumns =
      ((availableWidth + spacing) / (libraryMinimumCardWidth(size) + spacing))
          .floor();
  return fittedColumns.clamp(2, libraryMaximumColumns(size)).toInt();
}

class _CatalogMessage extends StatelessWidget {
  const _CatalogMessage({required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, textAlign: TextAlign.center),
            if (actionLabel != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

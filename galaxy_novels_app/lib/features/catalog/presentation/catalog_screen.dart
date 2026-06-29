import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_dependencies.dart';
import '../../../app/app_theme.dart';
import '../../../data/models/catalog_data.dart';
import '../../../data/models/search_index_data.dart';
import '../../../data/repositories/catalog_repository.dart';
import '../../../data/repositories/search_repository.dart';
import '../../novel_details/presentation/novel_details_screen.dart';
import '../domain/catalog_query.dart';
import 'widgets/catalog_novel_tile.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final _searchController = TextEditingController();

  CatalogRepository? _repository;
  SearchRepository? _searchRepository;
  Stream<CatalogLoadState>? _catalogStream;
  Future<SearchIndex>? _searchIndexFuture;
  CatalogQuery _query = const CatalogQuery();
  Timer? _searchDebounce;

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
          return const _CatalogSkeleton();
        }

        if (snapshot.hasError && !snapshot.hasData) {
          return _CatalogMessage(
            title: 'تعذر تحميل المكتبة الآن',
            actionLabel: 'إعادة المحاولة',
            onAction: _retryCatalog,
          );
        }

        final state = snapshot.data;
        final items = state?.items ?? const [];
        if (items.isEmpty) {
          return const _CatalogMessage(title: 'لا توجد روايات في المكتبة الآن');
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

    return CustomScrollView(
      key: const ValueKey('catalog-scroll-view'),
      slivers: [
        SliverToBoxAdapter(
          child: _CatalogControls(
            searchController: _searchController,
            query: _query,
            resultCount: result.items.length,
            availableStatuses: result.availableStatuses,
            availableGenres: result.availableGenres,
            onSearchChanged: _onSearchChanged,
            onSearchCleared: _clearSearchText,
            onSortChanged: (sort) {
              setState(() => _query = _query.copyWith(sort: sort));
            },
            onFiltersChanged: (status, genre) {
              setState(() {
                _query = _query.copyWith(
                  statusLabel: status,
                  genreName: genre,
                  clearStatus: status == null,
                  clearGenre: genre == null,
                );
              });
            },
            onClear: _clearQuery,
          ),
        ),
        if (state?.backgroundError != null)
          SliverToBoxAdapter(
            child: _CatalogLoadStatus(state: state, onRetry: _retryCatalog),
          ),
        if (result.items.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _CatalogMessage(
              title: 'لا توجد نتائج مطابقة',
              actionLabel: 'مسح البحث والفلاتر',
              onAction: _clearQuery,
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverLayoutBuilder(
              builder: (context, constraints) {
                final columns = _catalogColumnCount(
                  constraints.crossAxisExtent,
                );
                final spacing = columns > 3 ? 14.0 : 12.0;
                final tileExtent = _catalogTileExtent(
                  constraints.crossAxisExtent,
                  columns,
                  spacing,
                );

                return SliverGrid(
                  key: const ValueKey('catalog-sliver-grid'),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: spacing,
                    mainAxisSpacing: 16,
                    mainAxisExtent: tileExtent,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final novel = result.items[index];
                    return CatalogNovelTile(
                      novel: novel,
                      onTap: novel.manifest.isEmpty
                          ? null
                          : () => _openNovelDetails(novel.manifest),
                    );
                  }, childCount: result.items.length),
                );
              },
            ),
          ),
        if (state?.backgroundError == null)
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
    setState(() => _query = const CatalogQuery());
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
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => NovelDetailsScreen(manifestPath: manifestPath),
      ),
    );
  }
}

class _CatalogControls extends StatelessWidget {
  const _CatalogControls({
    required this.searchController,
    required this.query,
    required this.resultCount,
    required this.availableStatuses,
    required this.availableGenres,
    required this.onSearchChanged,
    required this.onSearchCleared,
    required this.onSortChanged,
    required this.onFiltersChanged,
    required this.onClear,
  });

  final TextEditingController searchController;
  final CatalogQuery query;
  final int resultCount;
  final List<String> availableStatuses;
  final List<String> availableGenres;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchCleared;
  final ValueChanged<CatalogSort> onSortChanged;
  final void Function(String? status, String? genre) onFiltersChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: tokens.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: tokens.accent.withValues(alpha: 0.22),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Icon(
                    Icons.local_library_outlined,
                    color: tokens.accent,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'مكتبة الروايات',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
              ),
              _ResultCountPill(count: resultCount),
            ],
          ),
          const SizedBox(height: 14),
          _CatalogSearchField(
            controller: searchController,
            query: query,
            onChanged: onSearchChanged,
            onClear: onSearchCleared,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _CatalogToolButton(
                  key: const ValueKey('catalog-filter-button'),
                  icon: Icons.category_outlined,
                  label: query.genreName ?? 'كل التصنيفات',
                  onTap: () => _showFilters(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CatalogSortButton(
                  selectedSort: query.sort,
                  onSelected: onSortChanged,
                ),
              ),
            ],
          ),
          _ActiveCatalogFilters(
            query: query,
            onSearchCleared: onSearchCleared,
            onSortReset: () => onSortChanged(CatalogSort.latest),
            onFiltersChanged: onFiltersChanged,
            onClear: onClear,
          ),
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
        return FractionallySizedBox(
          heightFactor: 0.78,
          child: _CatalogFiltersSheet(
            selectedStatus: query.statusLabel,
            selectedGenre: query.genreName,
            availableStatuses: availableStatuses,
            availableGenres: availableGenres,
          ),
        );
      },
    );

    if (result != null) {
      onFiltersChanged(result.status, result.genre);
    }
  }
}

class _ResultCountPill extends StatelessWidget {
  const _ResultCountPill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return DecoratedBox(
      key: const ValueKey('catalog-results-count'),
      decoration: BoxDecoration(
        color: tokens.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.primary.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Text(
          '$count رواية',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelMedium?.copyWith(
            color: tokens.primary,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
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
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: _CatalogToolSurface(
        icon: icon,
        label: label,
        trailingIcon: Icons.keyboard_arrow_down_rounded,
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

    return Ink(
      height: 54,
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.border),
      ),
      child: Padding(
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
    );
  }
}

class _ActiveCatalogFilters extends StatelessWidget {
  const _ActiveCatalogFilters({
    required this.query,
    required this.onSearchCleared,
    required this.onSortReset,
    required this.onFiltersChanged,
    required this.onClear,
  });

  final CatalogQuery query;
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
      if (query.sort != CatalogSort.latest)
        _ActiveFilterPill(
          key: const ValueKey('catalog-active-sort'),
          label: 'ترتيب: ${query.sort.label}',
          onClear: onSortReset,
        ),
    ];

    if (activeWidgets.isEmpty) {
      return const SizedBox(height: 10);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Wrap(spacing: 8, runSpacing: 8, children: activeWidgets),
          ),
          const SizedBox(width: 8),
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
  const _CatalogSkeleton();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary.withValues(alpha: 0.10);
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(width: 54, height: 76, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 14, width: 160, color: color),
                    const SizedBox(height: 8),
                    Container(height: 12, width: 120, color: color),
                    const SizedBox(height: 8),
                    Container(height: 12, width: 90, color: color),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
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

int _catalogColumnCount(double width) {
  if (width >= 720) {
    return 5;
  }
  if (width >= 520) {
    return 4;
  }
  return 3;
}

double _catalogTileExtent(double width, int columns, double spacing) {
  final safeWidth = width.isFinite && width > 0 ? width : 360.0;
  final tileWidth = (safeWidth - (columns - 1) * spacing) / columns;
  final coverHeight = tileWidth / 0.70;
  return (coverHeight + 78).clamp(226.0, 292.0).toDouble();
}

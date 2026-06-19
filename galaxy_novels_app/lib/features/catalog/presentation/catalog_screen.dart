import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_dependencies.dart';
import '../../../data/repositories/catalog_repository.dart';
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
  Stream<CatalogLoadState>? _catalogStream;
  CatalogQuery _query = const CatalogQuery();
  Timer? _searchDebounce;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repository = AppDependencies.of(context).catalogRepository;
    if (_repository != repository) {
      _repository = repository;
      _catalogStream = repository.watchCatalog();
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

        final result = applyCatalogQuery(items, _query);

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: result.items.length + 2,
          itemBuilder: (context, index) {
            if (index == 0) {
              return _CatalogControls(
                searchController: _searchController,
                query: _query,
                resultCount: result.items.length,
                availableStatuses: result.availableStatuses,
                availableGenres: result.availableGenres,
                onSearchChanged: _onSearchChanged,
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
              );
            }

            if (result.items.isEmpty && index == 1) {
              return _CatalogMessage(
                title: 'لا توجد نتائج مطابقة',
                actionLabel: 'مسح البحث والفلاتر',
                onAction: _clearQuery,
              );
            }

            final itemIndex = index - 1;
            if (itemIndex < result.items.length) {
              return CatalogNovelTile(novel: result.items[itemIndex]);
            }

            return _CatalogLoadStatus(state: state, onRetry: _retryCatalog);
          },
        );
      },
    );
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) {
        return;
      }
      setState(() => _query = _query.copyWith(searchText: value));
    });
  }

  void _clearQuery() {
    _searchDebounce?.cancel();
    _searchController.clear();
    setState(() => _query = const CatalogQuery());
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
}

class _CatalogControls extends StatelessWidget {
  const _CatalogControls({
    required this.searchController,
    required this.query,
    required this.resultCount,
    required this.availableStatuses,
    required this.availableGenres,
    required this.onSearchChanged,
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
  final ValueChanged<CatalogSort> onSortChanged;
  final void Function(String? status, String? genre) onFiltersChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'ابحث في المكتبة',
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              DropdownButton<CatalogSort>(
                value: query.sort,
                items: [
                  for (final sort in CatalogSort.values)
                    DropdownMenuItem(value: sort, child: Text(sort.label)),
                ],
                onChanged: (sort) {
                  if (sort != null) {
                    onSortChanged(sort);
                  }
                },
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _showFilters(context),
                icon: const Icon(Icons.tune),
                label: const Text('فلاتر'),
              ),
              const Spacer(),
              if (query.hasActiveFilters)
                TextButton(onPressed: onClear, child: const Text('مسح')),
            ],
          ),
          if (query.hasActiveFilters)
            Text(
              '$resultCount نتيجة',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
              ),
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

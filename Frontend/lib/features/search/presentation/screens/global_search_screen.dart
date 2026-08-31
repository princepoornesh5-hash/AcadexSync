import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/utils/navigation_extensions.dart';
import '../../domain/models/search_models.dart';
import '../providers/search_providers.dart';
import '../widgets/search_result_card.dart';
import '../../../../core/presentation/widgets/acadex_feedback.dart';
import '../../../../core/presentation/widgets/acadex_chip.dart';

class GlobalSearchScreen extends ConsumerStatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  ConsumerState<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      ref.read(searchQueryProvider.notifier).state = _searchController.text;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onResultTapped(SearchResult result) {
    ref.read(recentSearchesProvider.notifier).addSearch(result.title);
    if (result.destinationRoute.isNotEmpty) {
      context.push(result.destinationRoute);
    }
  }

  Widget _buildFilterChips(bool isDark) {
    final currentFilter = ref.watch(searchFilterProvider);
    
    final filters = [
      null,
      SearchResultType.student,
      SearchResultType.faculty,
      SearchResultType.department,
      SearchResultType.subject,
    ];

    String getFilterName(SearchResultType? type) {
      if (type == null) return "All";
      final text = type.toString().split('.').last;
      return text[0].toUpperCase() + text.substring(1);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: filters.map((filter) {
          final isSelected = currentFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AcadexChip(
              label: getFilterName(filter),
              isSelected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  ref.read(searchFilterProvider.notifier).state = filter;
                } else if (filter != null) {
                  ref.read(searchFilterProvider.notifier).state = null;
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecentSearches(bool isDark) {
    final recentSearches = ref.watch(recentSearchesProvider);
    
    if (recentSearches.isEmpty) {
      return const Center(
        child: AcadexEmptyState(
          icon: LucideIcons.search,
          title: "Search Acadex",
          subtitle: "Quickly find students, faculty, departments, subjects, and notes across campus.",
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Recent Searches",
              style: AcadexTypography.eyebrow(
                color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
              ),
            ),
            TextButton(
              onPressed: () {
                ref.read(recentSearchesProvider.notifier).clearSearches();
              },
              child: Text(
                "Clear",
                style: AcadexTypography.caption(color: AcadexColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...recentSearches.map((query) => ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          leading: Icon(
            LucideIcons.history,
            size: 18,
            color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
          ),
          title: Text(
            query,
            style: AcadexTypography.body(
              color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
            ),
          ),
          trailing: IconButton(
            icon: Icon(
              LucideIcons.x,
              size: 16,
              color: isDark ? AcadexColors.darkInkFaint : AcadexColors.inkFaint,
            ),
            onPressed: () {
              ref.read(recentSearchesProvider.notifier).removeSearch(query);
            },
          ),
          onTap: () {
            _searchController.text = query;
            _searchController.selection = TextSelection.fromPosition(
              TextPosition(offset: _searchController.text.length),
            );
          },
        )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final resultsAsync = ref.watch(searchResultsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AcadexColors.darkCanvas : AcadexColors.canvas,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Header
            Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 20, 12),
              decoration: BoxDecoration(
                color: isDark ? AcadexColors.darkSurface : AcadexColors.surface,
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? AcadexColors.darkHairline : AcadexColors.hairline,
                  ),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      LucideIcons.arrowLeft,
                      color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                    ),
                    onPressed: () => context.safePop(fallbackRoute: '/dashboard'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      style: AcadexTypography.body(
                        color: isDark ? AcadexColors.darkInk : AcadexColors.ink,
                      ),
                      decoration: InputDecoration(
                        hintText: "Search students, faculty, departments...",
                        prefixIcon: Icon(
                          LucideIcons.search,
                          size: 18,
                          color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                        ),
                        suffixIcon: query.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  LucideIcons.x,
                                  size: 16,
                                  color: isDark ? AcadexColors.darkInkMuted : AcadexColors.inkMuted,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                },
                              )
                            : null,
                      ),
                      onSubmitted: (value) {
                        if (value.trim().isNotEmpty) {
                          ref.read(recentSearchesProvider.notifier).addSearch(value);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Filters
            _buildFilterChips(isDark),

            // Content Area
            Expanded(
              child: query.trim().isEmpty
                  ? _buildRecentSearches(isDark)
                  : resultsAsync.when(
                      data: (results) {
                        if (results.isEmpty) {
                          return Center(
                            child: AcadexEmptyState(
                              icon: LucideIcons.searchX,
                              title: "No results found for \"$query\"",
                              subtitle: "Try checking your spelling or selecting a different filter type.",
                            ),
                          );
                        }
                        
                        return ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: results.length,
                          itemBuilder: (context, index) {
                            final result = results[index];
                            return SearchResultCard(
                              result: result,
                              onTap: () => _onResultTapped(result),
                            );
                          },
                        );
                      },
                      loading: () => const AcadexLoadingState(message: "Searching campus records..."),
                      error: (err, stack) => Center(
                        child: AcadexErrorState(
                          message: 'Error executing search: $err',
                          onRetry: () => ref.refresh(searchResultsProvider),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

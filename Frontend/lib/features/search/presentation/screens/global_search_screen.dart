import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_theme.dart';
import '../../domain/models/search_models.dart';
import '../providers/search_providers.dart';
import '../widgets/search_result_card.dart';
import '../widgets/search_empty_state.dart';

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
    // Add to recent searches
    ref.read(recentSearchesProvider.notifier).addSearch(result.title);
    
    // In a real application, you would navigate to the destination route here
    // For mock, just go back or navigate to a placeholder if route is set up
    // context.push(result.destinationRoute);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Navigating to ${result.destinationRoute}')),
    );
  }

  Widget _buildFilterChips() {
    final currentFilter = ref.watch(searchFilterProvider);
    
    // Provide a list of available filters
    final filters = [
      null, // All
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: filters.map((filter) {
          final isSelected = currentFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(getFilterName(filter)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  ref.read(searchFilterProvider.notifier).state = filter;
                } else if (filter != null) {
                  ref.read(searchFilterProvider.notifier).state = null; // Default back to All
                }
              },
              backgroundColor: AppColors.surfaceDarkElevated,
              selectedColor: AppColors.primary.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.onDark,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.hairlineDark,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecentSearches() {
    final recentSearches = ref.watch(recentSearchesProvider);
    
    if (recentSearches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.search, size: 48, color: AppColors.textMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              "Search Acadex",
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.onDark),
            ),
            const SizedBox(height: 8),
            Text(
              "Find students, faculty, departments and more.",
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Recent Searches",
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
            TextButton(
              onPressed: () {
                ref.read(recentSearchesProvider.notifier).clearSearches();
              },
              child: const Text("Clear"),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...recentSearches.map((query) => ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(LucideIcons.history, color: AppColors.textMuted),
          title: Text(query, style: const TextStyle(color: AppColors.onDark)),
          trailing: IconButton(
            icon: const Icon(LucideIcons.x, color: AppColors.textMuted, size: 18),
            onPressed: () {
              ref.read(recentSearchesProvider.notifier).removeSearch(query);
            },
          ),
          onTap: () {
            _searchController.text = query;
            // Place cursor at end
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

    return Scaffold(
      backgroundColor: AppColors.canvasDark,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Header
            Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 24, 12),
              decoration: const BoxDecoration(
                color: AppColors.surfaceDarkElevated,
                border: Border(bottom: BorderSide(color: AppColors.hairlineDark)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.arrowLeft, color: AppColors.onDark),
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDarkElevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.hairlineDark),
                      ),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        style: const TextStyle(color: AppColors.onDark),
                        decoration: InputDecoration(
                          hintText: "Search students, faculty...",
                          hintStyle: const TextStyle(color: AppColors.textMuted),
                          prefixIcon: const Icon(LucideIcons.search, color: AppColors.textMuted),
                          suffixIcon: query.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(LucideIcons.xCircle, color: AppColors.textMuted),
                                  onPressed: () {
                                    _searchController.clear();
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        onSubmitted: (value) {
                          if (value.trim().isNotEmpty) {
                            ref.read(recentSearchesProvider.notifier).addSearch(value);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Filters
            _buildFilterChips(),

            // Content Area
            Expanded(
              child: query.trim().isEmpty
                  ? _buildRecentSearches()
                  : resultsAsync.when(
                      data: (results) {
                        if (results.isEmpty) {
                          return SearchEmptyState(query: query);
                        }
                        
                        return ListView.builder(
                          padding: const EdgeInsets.all(24),
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
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => Center(
                        child: Text('Error: $err', style: const TextStyle(color: AppColors.error)),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

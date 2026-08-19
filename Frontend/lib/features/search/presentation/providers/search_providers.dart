import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/search_models.dart';
import '../../data/repositories/mock_search_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../domain/repositories/search_repository.dart';
import '../../data/repositories/firebase_search_repository.dart';
import '../../../../core/firebase/firebase_services.dart';
import '../../../../core/firebase/firebase_initializer.dart';

// --- Repositories ---

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  if (FirebaseInitializer.shouldUseMock) {
    return MockSearchRepository();
  }
  final firestoreService = ref.watch(firestoreServiceProvider);
  return FirebaseSearchRepository(firestoreService);
});

// --- State Providers ---

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchFilterProvider = StateProvider<SearchResultType?>((ref) => null);

// --- Recent Searches Provider ---

class RecentSearchesNotifier extends Notifier<List<String>> {
  @override
  List<String> build() {
    return []; // In a real app, this would load from SharedPreferences/Hive
  }

  void addSearch(String query) {
    if (query.trim().isEmpty) return;
    final currentState = state;
    // Remove if already exists to move it to the top
    final filtered = currentState.where((q) => q.toLowerCase() != query.toLowerCase()).toList();
    filtered.insert(0, query.trim());
    
    // Keep only top 10
    if (filtered.length > 10) {
      filtered.removeLast();
    }
    state = filtered;
  }

  void removeSearch(String query) {
    state = state.where((q) => q != query).toList();
  }

  void clearSearches() {
    state = [];
  }
}

final recentSearchesProvider = NotifierProvider<RecentSearchesNotifier, List<String>>(() {
  return RecentSearchesNotifier();
});

// --- Search Results Provider ---

final searchResultsProvider = FutureProvider.autoDispose<List<SearchResult>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  final filter = ref.watch(searchFilterProvider);
  final authState = ref.watch(authProvider);

  if (query.trim().isEmpty) {
    return [];
  }

  if (authState is! AuthAuthenticated) {
    return [];
  }

  // Debouncing logic: Wait 300ms before triggering the search
  await Future.delayed(const Duration(milliseconds: 300));
  
  // If the provider was disposed during the delay (e.g. user typed a new character),
  // this execution will be cancelled. We can check if it's still alive, but FutureProvider handles basic cancellation.
  
  final searchRepo = ref.read(searchRepositoryProvider);
  return searchRepo.search(query, authState.user, filterType: filter);
});

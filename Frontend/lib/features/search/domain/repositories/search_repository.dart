import '../../../auth/domain/models/user_model.dart';
import '../models/search_models.dart';

abstract class SearchRepository {
  /// Executes a search query for the given [currentUser], returning matching entities
  /// scoped securely by their role and tenant context.
  /// 
  /// Optionally filters by [filterType] (e.g. only return Students).
  /// [limit] defines the maximum number of results to fetch per category.
  Future<List<SearchResult>> search(
    String query,
    UserModel currentUser, {
    SearchResultType? filterType,
    int limit = 10,
  });
}

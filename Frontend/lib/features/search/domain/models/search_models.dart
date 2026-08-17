enum SearchResultType {
  student,
  faculty,
  hod,
  collegeAdmin,
  college,
  department,
  course,
  academicYear,
  semester,
  section,
  subject,
  attendance,
}

class SearchResult {
  final String id;
  final String title;
  final String subtitle;
  final SearchResultType type;
  final String destinationRoute;
  final int relevanceScore;
  final Map<String, dynamic>? metadata;

  const SearchResult({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.destinationRoute,
    this.relevanceScore = 0,
    this.metadata,
  });

  SearchResult copyWith({
    String? id,
    String? title,
    String? subtitle,
    SearchResultType? type,
    String? destinationRoute,
    int? relevanceScore,
    Map<String, dynamic>? metadata,
  }) {
    return SearchResult(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      type: type ?? this.type,
      destinationRoute: destinationRoute ?? this.destinationRoute,
      relevanceScore: relevanceScore ?? this.relevanceScore,
      metadata: metadata ?? this.metadata,
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../firebase/firebase_services.dart';

class PaginatedState<T> {
  final List<T> items;
  final bool isLoading;
  final bool isFetchingMore;
  final bool hasReachedMax;
  final Object? error;
  final DocumentSnapshot? lastDocument;

  const PaginatedState({
    this.items = const [],
    this.isLoading = true,
    this.isFetchingMore = false,
    this.hasReachedMax = false,
    this.error,
    this.lastDocument,
  });

  PaginatedState<T> copyWith({
    List<T>? items,
    bool? isLoading,
    bool? isFetchingMore,
    bool? hasReachedMax,
    Object? error,
    DocumentSnapshot? lastDocument,
  }) {
    return PaginatedState<T>(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      error: error ?? this.error,
      lastDocument: lastDocument ?? this.lastDocument,
    );
  }
}

abstract class PaginationNotifier<T> extends StateNotifier<PaginatedState<T>> {
  PaginationNotifier() : super(PaginatedState<T>());

  int get limit => 20;

  Future<PaginatedResponse<T>> fetchPage({DocumentSnapshot? startAfter});

  Future<void> loadInitial() async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await fetchPage();
      if (mounted) {
        state = state.copyWith(
          items: response.data,
          lastDocument: response.lastDocument,
          hasReachedMax: !response.hasMore,
          isLoading: false,
        );
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(error: e, isLoading: false);
      }
    }
  }

  Future<void> loadMore() async {
    if (!mounted || state.isFetchingMore || state.hasReachedMax || state.isLoading) return;

    state = state.copyWith(isFetchingMore: true, error: null);
    try {
      final response = await fetchPage(startAfter: state.lastDocument);
      if (mounted) {
        state = state.copyWith(
          items: [...state.items, ...response.data],
          lastDocument: response.lastDocument,
          hasReachedMax: !response.hasMore,
          isFetchingMore: false,
        );
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(error: e, isFetchingMore: false);
      }
    }
  }

  Future<void> refresh() async {
    await loadInitial();
  }
}

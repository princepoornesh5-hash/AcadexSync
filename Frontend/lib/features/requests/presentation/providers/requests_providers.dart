import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/requests_repository.dart';
import '../../data/repositories/api_requests_repository.dart';
import '../../domain/models/request_model.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';

final requestsRepositoryProvider = Provider<RequestsRepository>((ref) {
  return ApiRequestsRepository();
});

class RequestsFilterState {
  final RequestStatus? status;
  final String? requestType;
  final String searchQuery;

  const RequestsFilterState({
    this.status,
    this.requestType,
    this.searchQuery = '',
  });

  RequestsFilterState copyWith({
    RequestStatus? status,
    String? requestType,
    String? searchQuery,
    bool clearStatus = false,
    bool clearRequestType = false,
  }) {
    return RequestsFilterState(
      status: clearStatus ? null : (status ?? this.status),
      requestType: clearRequestType ? null : (requestType ?? this.requestType),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

final requestsFilterProvider = StateProvider<RequestsFilterState>((ref) {
  return const RequestsFilterState();
});

final myRequestsProvider = FutureProvider.autoDispose<List<RequestModel>>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState is! AuthAuthenticated) return [];

  final repo = ref.watch(requestsRepositoryProvider);
  final filter = ref.watch(requestsFilterProvider);

  final requests = await repo.getMyRequests(
    status: filter.status,
    requestType: filter.requestType,
  );

  if (filter.searchQuery.isNotEmpty) {
    final q = filter.searchQuery.toLowerCase();
    return requests.where((r) {
      return r.title.toLowerCase().contains(q) ||
          r.description.toLowerCase().contains(q) ||
          r.requestId.toLowerCase().contains(q) ||
          (r.targetName?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  return requests;
});

final incomingRequestsProvider = FutureProvider.autoDispose<List<RequestModel>>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState is! AuthAuthenticated) return [];

  final repo = ref.watch(requestsRepositoryProvider);
  final filter = ref.watch(requestsFilterProvider);

  final requests = await repo.getIncomingRequests(
    status: filter.status,
    requestType: filter.requestType,
  );

  if (filter.searchQuery.isNotEmpty) {
    final q = filter.searchQuery.toLowerCase();
    return requests.where((r) {
      return r.title.toLowerCase().contains(q) ||
          r.description.toLowerCase().contains(q) ||
          r.requestId.toLowerCase().contains(q) ||
          r.requesterName.toLowerCase().contains(q);
    }).toList();
  }

  return requests;
});

final requestSummaryCountsProvider = FutureProvider.autoDispose<RequestSummaryCounts>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState is! AuthAuthenticated) return const RequestSummaryCounts();

  final repo = ref.watch(requestsRepositoryProvider);
  return await repo.getSummaryCounts();
});

final requestDetailProvider = FutureProvider.family.autoDispose<RequestModel?, String>((ref, id) async {
  final repo = ref.watch(requestsRepositoryProvider);
  return await repo.getRequestById(id);
});

class RequestActionNotifier extends AsyncNotifier<void> {
  bool _isSubmitting = false;

  bool get isSubmitting => _isSubmitting;

  @override
  Future<void> build() async {}

  Future<RequestModel?> createRequest({
    required RequestType requestType,
    String? title,
    required String description,
    AcademicContextModel? academicContext,
    RequestDetailsModel? details,
  }) async {
    // Re-entrancy guard against double taps
    if (_isSubmitting) return null;
    _isSubmitting = true;
    state = const AsyncLoading();

    RequestModel? created;
    state = await AsyncValue.guard(() async {
      try {
        final repo = ref.read(requestsRepositoryProvider);
        created = await repo.createRequest(
          requestType: requestType,
          title: title,
          description: description,
          academicContext: academicContext,
          details: details,
        );
        ref.invalidate(myRequestsProvider);
        ref.invalidate(requestSummaryCountsProvider);
        ref.invalidate(unreadNotificationCountProvider);
        ref.invalidate(notificationsProvider);
      } finally {
        _isSubmitting = false;
      }
    });

    return created;
  }

  Future<RequestModel?> respondToRequest({
    required String id,
    required String action,
    String? message,
  }) async {
    if (_isSubmitting) return null;
    _isSubmitting = true;
    state = const AsyncLoading();

    RequestModel? result;
    state = await AsyncValue.guard(() async {
      try {
        final repo = ref.read(requestsRepositoryProvider);
        result = await repo.respondToRequest(
          id: id,
          action: action,
          message: message,
        );
        ref.invalidate(incomingRequestsProvider);
        ref.invalidate(myRequestsProvider);
        ref.invalidate(requestDetailProvider(id));
        ref.invalidate(requestSummaryCountsProvider);
        ref.invalidate(unreadNotificationCountProvider);
        ref.invalidate(notificationsProvider);
      } finally {
        _isSubmitting = false;
      }
    });

    return result;
  }

  Future<RequestModel?> updateStatus({
    required String id,
    required RequestStatus status,
    String? note,
  }) async {
    if (_isSubmitting) return null;
    _isSubmitting = true;
    state = const AsyncLoading();

    RequestModel? result;
    state = await AsyncValue.guard(() async {
      try {
        final repo = ref.read(requestsRepositoryProvider);
        result = await repo.updateStatus(
          id: id,
          status: status,
          note: note,
        );
        ref.invalidate(incomingRequestsProvider);
        ref.invalidate(myRequestsProvider);
        ref.invalidate(requestDetailProvider(id));
        ref.invalidate(requestSummaryCountsProvider);
        ref.invalidate(unreadNotificationCountProvider);
        ref.invalidate(notificationsProvider);
      } finally {
        _isSubmitting = false;
      }
    });

    return result;
  }
}

final requestActionProvider = AsyncNotifierProvider<RequestActionNotifier, void>(() {
  return RequestActionNotifier();
});

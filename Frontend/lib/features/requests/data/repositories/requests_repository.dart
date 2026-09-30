import '../../domain/models/request_model.dart';

abstract class RequestsRepository {
  Future<List<RequestModel>> getMyRequests({
    RequestStatus? status,
    String? requestType,
    int page = 1,
    int limit = 50,
  });

  Future<List<RequestModel>> getIncomingRequests({
    RequestStatus? status,
    String? requestType,
    int page = 1,
    int limit = 50,
  });

  Future<RequestSummaryCounts> getSummaryCounts();

  Future<RequestModel?> getRequestById(String id);

  Future<RequestModel> createRequest({
    required RequestType requestType,
    String? title,
    required String description,
    AcademicContextModel? academicContext,
    RequestDetailsModel? details,
    String? status,
    String? relatedEntityType,
    String? relatedEntityId,
  });

  Future<RequestModel> submitRequest(String id);

  Future<RequestModel> cancelRequest(String id, {String? reason});

  Future<RequestModel> startReview(String id);

  Future<RequestModel> respondToRequest({
    required String id,
    required String action, // APPROVED, REJECTED, RESOLVED
    String? message,
  });

  Future<RequestModel> updateStatus({
    required String id,
    required RequestStatus status,
    String? note,
  });
}

class SuperAdminSystemHealth {
  final String serverStatus;
  final String syncStatus;
  final String apiLatency;
  final int activeUsers;

  SuperAdminSystemHealth({
    required this.serverStatus,
    required this.syncStatus,
    required this.apiLatency,
    required this.activeUsers,
  });
}

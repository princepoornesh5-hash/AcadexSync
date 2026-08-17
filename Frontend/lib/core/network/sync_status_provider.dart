import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SyncStatus { online, offline, syncing, failed }

class SyncStatusNotifier extends StateNotifier<SyncStatus> {
  SyncStatusNotifier() : super(SyncStatus.online);

  void setOnline() => state = SyncStatus.online;
  void setOffline() => state = SyncStatus.offline;
  void setSyncing() => state = SyncStatus.syncing;
  void setFailed() => state = SyncStatus.failed;
}

final syncStatusProvider = StateNotifierProvider<SyncStatusNotifier, SyncStatus>((ref) {
  return SyncStatusNotifier();
});

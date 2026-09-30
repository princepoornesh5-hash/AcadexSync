import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../network/api_client.dart';
import '../models/realtime_event.dart';

class RealtimeService {
  static const String _envWsUrl = String.fromEnvironment('REALTIME_WS_URL');

  final FlutterSecureStorage _storage;
  final String? _customWsUrl;

  WebSocketChannel? _channel;
  StreamSubscription? _channelSubscription;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;

  int _reconnectAttempts = 0;
  bool _isExplicitlyDisconnected = false;
  bool _isDisposed = false;

  RealtimeConnectionStatus _status = RealtimeConnectionStatus.disconnected;
  final _statusController = StreamController<RealtimeConnectionStatus>.broadcast();
  final _eventController = StreamController<RealtimeEvent>.broadcast();

  // Deduplication cache: bounded set of processed eventIds
  final List<String> _processedEventIdList = [];
  final Set<String> _processedEventIdSet = {};
  static const int _maxDeduplicationHistory = 500;

  RealtimeService({
    FlutterSecureStorage? storage,
    String? wsUrl,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _customWsUrl = wsUrl;

  RealtimeConnectionStatus get status => _status;
  Stream<RealtimeConnectionStatus> get statusStream => _statusController.stream;
  Stream<RealtimeEvent> get eventStream => _eventController.stream;

  /// Resolves WebSocket URL from ApiClient base URL or environment override.
  String get activeWsUrl {
    final customUrl = _customWsUrl;
    if (customUrl != null && customUrl.isNotEmpty) {
      return customUrl;
    }
    if (_envWsUrl.isNotEmpty) {
      return _envWsUrl;
    }

    final httpBase = ApiClient.defaultBaseUrl;
    String wsBase = httpBase;
    if (wsBase.startsWith('https://')) {
      wsBase = 'wss://${wsBase.substring(8)}';
    } else if (wsBase.startsWith('http://')) {
      wsBase = 'ws://${wsBase.substring(7)}';
    }

    // Replace /api/v1 with /ws
    if (wsBase.endsWith('/api/v1')) {
      wsBase = '${wsBase.substring(0, wsBase.length - 7)}/ws';
    } else if (!wsBase.endsWith('/ws')) {
      wsBase = '$wsBase/ws';
    }

    return wsBase;
  }

  /// Establishes authenticated WebSocket connection.
  Future<void> connect() async {
    if (_status == RealtimeConnectionStatus.connected ||
        _status == RealtimeConnectionStatus.connecting) {
      return;
    }

    _isExplicitlyDisconnected = false;
    _setStatus(
      _reconnectAttempts > 0
          ? RealtimeConnectionStatus.reconnecting
          : RealtimeConnectionStatus.connecting,
    );

    try {
      final token = await _storage.read(key: ApiClient.keyAccessToken);
      if (token == null || token.isEmpty) {
        debugPrint('[Realtime] No access token found. Cannot connect.');
        _setStatus(RealtimeConnectionStatus.disconnected);
        return;
      }

      final uri = Uri.parse('$activeWsUrl?token=$token');
      debugPrint('[Realtime] Connecting to $activeWsUrl...');

      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;

      _setStatus(RealtimeConnectionStatus.connected);
      _reconnectAttempts = 0;
      _startHeartbeat();

      _channelSubscription = _channel!.stream.listen(
        _handleIncomingMessage,
        onError: _handleConnectionError,
        onDone: _handleConnectionClosed,
        cancelOnError: true,
      );

      debugPrint('[Realtime] Connected and listening for events.');
    } catch (e) {
      debugPrint('[Realtime] Connection failed: $e');
      _handleConnectionClosed();
    }
  }

  void _handleIncomingMessage(dynamic rawData) {
    try {
      final text = rawData.toString();
      final decoded = jsonDecode(text) as Map<String, dynamic>;
      final type = decoded['type'] as String?;

      if (type == 'pong') {
        // Heartbeat confirmed
        return;
      }

      if (type == 'authenticated') {
        debugPrint('[Realtime] Server confirmed authentication: ${decoded['data']}');
        return;
      }

      if (type == 'event') {
        final eventData = decoded['data'] as Map<String, dynamic>?;
        if (eventData == null) return;

        final event = RealtimeEvent.fromJson(eventData);

        // Deduplication: Drop duplicate deliveries
        if (event.eventId.isNotEmpty) {
          if (_processedEventIdSet.contains(event.eventId)) {
            debugPrint('[Realtime Deduplication] Dropping duplicate event: ${event.eventId}');
            return;
          }
          _recordEventId(event.eventId);
        }

        _eventController.add(event);
      }
    } catch (err) {
      debugPrint('[Realtime] Error processing incoming payload: $err');
    }
  }

  void _recordEventId(String id) {
    if (_processedEventIdSet.contains(id)) return;

    _processedEventIdSet.add(id);
    _processedEventIdList.add(id);

    if (_processedEventIdList.length > _maxDeduplicationHistory) {
      final oldest = _processedEventIdList.removeAt(0);
      _processedEventIdSet.remove(oldest);
    }
  }

  void _handleConnectionError(dynamic error) {
    debugPrint('[Realtime] WebSocket error: $error');
    _handleConnectionClosed();
  }

  void _handleConnectionClosed() {
    _cleanupChannel();

    if (_isExplicitlyDisconnected || _isDisposed) {
      _setStatus(RealtimeConnectionStatus.disconnected);
      return;
    }

    _setStatus(RealtimeConnectionStatus.reconnecting);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();

    // Exponential backoff: base 1s * 1.5 ^ attempts (capped at 30s) + jitter
    _reconnectAttempts++;
    final delaySeconds = min(30.0, 1.0 * pow(1.5, min(_reconnectAttempts, 8)));
    final jitterMs = Random().nextInt(500);
    final delay = Duration(milliseconds: (delaySeconds * 1000).toInt() + jitterMs);

    debugPrint('[Realtime] Reconnecting in ${delay.inSeconds}s (attempt #$_reconnectAttempts)...');
    _reconnectTimer = Timer(delay, () {
      if (!_isExplicitlyDisconnected && !_isDisposed) {
        connect();
      }
    });
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      if (_status == RealtimeConnectionStatus.connected && _channel != null) {
        try {
          _channel!.sink.add(jsonEncode({'action': 'ping'}));
        } catch (_) {}
      }
    });
  }

  void _cleanupChannel() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _channelSubscription?.cancel();
    _channelSubscription = null;
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
  }

  /// Sends a subscribe request to observe a contextual channel.
  void subscribe(String channelName) {
    if (_status == RealtimeConnectionStatus.connected && _channel != null) {
      try {
        _channel!.sink.add(jsonEncode({
          'action': 'subscribe',
          'channel': channelName,
        }));
      } catch (_) {}
    }
  }

  /// Sends an unsubscribe request.
  void unsubscribe(String channelName) {
    if (_status == RealtimeConnectionStatus.connected && _channel != null) {
      try {
        _channel!.sink.add(jsonEncode({
          'action': 'unsubscribe',
          'channel': channelName,
        }));
      } catch (_) {}
    }
  }

  /// Responds to app lifecycle changes (mobile foreground / background / resume).
  void handleAppLifecycleState(dynamic lifecycleState) {
    // String or AppLifecycleState
    final stateStr = lifecycleState.toString();

    if (stateStr.contains('paused') || stateStr.contains('detached') || stateStr.contains('hidden')) {
      debugPrint('[Realtime Lifecycle] App backgrounded. Releasing socket connection.');
      _cleanupChannel();
      _setStatus(RealtimeConnectionStatus.disconnected);
    } else if (stateStr.contains('resumed')) {
      debugPrint('[Realtime Lifecycle] App resumed to foreground. Reconnecting realtime...');
      connect();
    }
  }

  /// Disconnects socket cleanly (e.g., on user logout).
  Future<void> disconnect({bool isLogout = false}) async {
    _isExplicitlyDisconnected = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempts = 0;

    _cleanupChannel();
    _setStatus(RealtimeConnectionStatus.disconnected);

    if (isLogout) {
      _processedEventIdList.clear();
      _processedEventIdSet.clear();
    }
  }

  void _setStatus(RealtimeConnectionStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      if (!_statusController.isClosed) {
        _statusController.add(newStatus);
      }
    }
  }

  void dispose() {
    _isDisposed = true;
    disconnect();
    _statusController.close();
    _eventController.close();
  }
}

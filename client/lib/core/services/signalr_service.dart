import 'package:client/core/constants/app_constants.dart';
import 'package:client/core/services/local_storage_service.dart';
import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/signalr_client.dart';

class SignalrService {
  // Nullable thay vì late — tránh LateInitializationError khi connect() chưa được gọi
  HubConnection? _hubConnection;
  HubConnection? _notificationConnection;
  final LocalStorageService _localStorageService;

  // Buffer các event handlers đăng ký TRƯỚC khi connect()
  // Key = tên Hub event, Value = handler function
  final Map<String, Function(List<Object?>?)> _pendingHandlers = {};
  final Map<String, Function(List<Object?>?)> _pendingNotificationHandlers = {};

  SignalrService(this._localStorageService);

  // ── Kiểm tra trạng thái ──────────────────────────────────

  bool get isConnected =>
      _hubConnection != null &&
      _hubConnection!.state == HubConnectionState.Connected;

  // ── Kết nối ────────────────────────────────────────────────

  Future<void> connect() async {
    // Nếu đã Connected rồi thì không cần connect lại
    if (isConnected) return;

    final token = await _localStorageService.getToken();

    final hubUrl = '${AppConstants.baseUrl.replaceAll('/api/', '')}/hubs/chess';

    final notificationHubUrl = '${AppConstants.baseUrl.replaceAll('/api/', '')}/hubs/notification';

    _hubConnection = HubConnectionBuilder()
        .withUrl(
          hubUrl,
          options: HttpConnectionOptions(
            accessTokenFactory: () async => token ?? '',
          ),
        )
        .withAutomaticReconnect()
        .build();

    _notificationConnection = HubConnectionBuilder()
        .withUrl(
          notificationHubUrl,
          options: HttpConnectionOptions(
            accessTokenFactory: () async => token ?? '',
          ),
        )
        .withAutomaticReconnect()
        .build();

    await _hubConnection!.start();
    await _notificationConnection!.start();
    debugPrint("SignalR connected (Chess & Notification)");

    // Đăng ký tất cả handlers đã buffer trước khi connect()
    _pendingHandlers.forEach((event, handler) {
      _hubConnection!.on(event, handler);
      debugPrint("[SignalR] Flushed pending handler: $event");
    });
    _pendingHandlers.clear();

    _pendingNotificationHandlers.forEach((event, handler) {
      _notificationConnection!.on(event, handler);
      debugPrint("[SignalR] Flushed pending notification handler: $event");
    });
    _pendingNotificationHandlers.clear();
  }

  /// Đảm bảo kết nối đang sống, nếu chưa thì tự kết nối lại
  Future<void> ensureConnected() async {
    if (!isConnected) {
      debugPrint('[SignalR] Chưa Connected, đang tự động kết nối lại...');
      await connect();
    }
  }

  /// Helper nội bộ: nếu đã connect thì đăng ký ngay,
  /// chưa connect thì lưu vào buffer chờ flush sau connect()
  void _on(String event, Function(List<Object?>?) handler) {
    if (_hubConnection != null) {
      _hubConnection!.on(event, handler);
    } else {
      _pendingHandlers[event] = handler;
    }
  }

  void _onNotification(String event, Function(List<Object?>?) handler) {
    if (_notificationConnection != null) {
      _notificationConnection!.on(event, handler);
    } else {
      _pendingNotificationHandlers[event] = handler;
    }
  }

  // ── Nhận sự kiện từ Server ────────────────────────────────

  void onReceiveFriendRequest(Function(List<Object?>?) handler) => _onNotification('ReceiveFriendRequest', handler);

  void onReceiveMove(Function(List<Object?>?) handler) => _on('ReceiveMove', handler);

  void onMatchStarted(Function(List<Object?>?) handler) => _on('MatchStarted', handler);

  void onGameOver(Function(List<Object?>?) handler) => _on('GameOver', handler);

  /// Nhận lại toàn bộ state trận đang dở sau khi reconnect
  void onRejoinMatch(Function(List<Object?>?) handler) => _on('RejoinMatch', handler);

  /// Server xác nhận không có trận nào đang dở
  void onNoActiveMatch(Function(List<Object?>?) handler) => _on('NoActiveMatch', handler);

  // ── Nhận sự kiện AI ──────────────────────────────────────

  /// Server trả về khi trận AI được tạo thành công
  void onAiGameStarted(Function(List<Object?>?) handler) => _on('AiGameStarted', handler);

  // ── Gửi lệnh lên Server ───────────────────────────────────

  Future<void> findMatch() async {
    await _hubConnection?.invoke('FindMatch');
  }

  Future<void> makeMove(
    String matchId,
    String fromPosition,
    String toPosition,
    String promotionPiece,
  ) async {
    // debugPrint('promotionPiece: $promotionPiece, type: ${promotionPiece.runtimeType}');
    await _hubConnection?.invoke(
      'MakeMove',
      args: [matchId, fromPosition, toPosition, promotionPiece],
    );
  }

  /// Gọi sau khi connect() để hỏi server có trận nào đang dở không
  Future<void> rejoinMatch() async {
    await _hubConnection?.invoke('RejoinMatch');
  }

  Future<void> cancelMatch() async {
    await _hubConnection?.invoke('CancelMatch');
  }

  Future<void> resign(String matchId) async {
    await _hubConnection?.invoke('Resign', args: [matchId]);
  }

  // ── AI Game ────────────────────────────────────────────────

  /// Gọi Hub method StartAiGame
  Future<void> startAiGame({
    required int difficulty,
    required String colorPreference,
    required int timeMinutes,
  }) async {
    await _hubConnection?.invoke(
      'StartAiGame',
      args: [difficulty, colorPreference, timeMinutes],
    );
  }
}

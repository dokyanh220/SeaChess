import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/presentation/providers/friendship_providers.dart';
import 'package:client/presentation/providers/auth_providers.dart';

class NotificationState {
  final int pendingRequestsCount;

  NotificationState({
    this.pendingRequestsCount = 0,
  });

  NotificationState copyWith({
    int? pendingRequestsCount,
  }) {
    return NotificationState(
      pendingRequestsCount: pendingRequestsCount ?? this.pendingRequestsCount,
    );
  }
}

class NotificationStateNotifier extends Notifier<NotificationState> {
  @override
  NotificationState build() {
    _init();
    return NotificationState();
  }

  Future<void> _init() async {
    final signalR = ref.read(signalRServiceProvider);
    
    // Đảm bảo SignalR đã connect (nếu gọi từ lúc mở app, MainScreen sẽ lo việc ensureConnected hoặc AuthGate)
    
    // Lắng nghe realtime event
    signalR.onReceiveFriendRequest((args) {
      // Khi nhận được thông báo, fetch lại danh sách để biết số lượng chính xác
      fetchPendingCount();
    });

    await fetchPendingCount();
  }

  Future<void> fetchPendingCount() async {
    try {
      final repo = ref.read(friendshipRepositoryProvider);
      final requests = await repo.getPendingRequests();
      state = state.copyWith(pendingRequestsCount: requests.length);
    } catch (e) {
      // Ignored for now
    }
  }

  void incrementPendingCount() {
    state = state.copyWith(pendingRequestsCount: state.pendingRequestsCount + 1);
  }
  
  void decrementPendingCount() {
    if (state.pendingRequestsCount > 0) {
      state = state.copyWith(pendingRequestsCount: state.pendingRequestsCount - 1);
    }
  }
}

final notificationStateProvider =
    NotifierProvider<NotificationStateNotifier, NotificationState>(() {
  return NotificationStateNotifier();
});

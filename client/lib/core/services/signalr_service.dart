import 'package:client/core/constants/app_constants.dart';
import 'package:client/core/services/local_storage_service.dart';
import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/signalr_client.dart';

class SignalrService {
  late HubConnection _hubConnection;
  final LocalStorageService _localStorageService;

  SignalrService(this._localStorageService);

  Future<void> connect() async {
    final token = await _localStorageService.getToken();

    final hubUrl = '${AppConstants.baseUrl.replaceAll('/api/', '')}/hubs/chess';

    _hubConnection = HubConnectionBuilder()
        .withUrl(
          hubUrl,
          options: HttpConnectionOptions(
            accessTokenFactory: () async => token ?? '',
          ),
        )
        .withAutomaticReconnect()
        .build();

    await _hubConnection.start();
    print("SignalR connected");
  }

  void onReceiveMove(Function(List<Object?>?) handler) {
    _hubConnection.on('ReceiveMove', handler);
  }

  void onMatchStarted(Function(List<Object?>?) handler) {
    _hubConnection.on('MatchStarted', handler);
  }

  void onGameOver(Function(List<Object?>?) handler) {
    _hubConnection.on('GameOver', handler);
  }

  Future<void> findMatch() async {
    await _hubConnection.invoke('FindMatch');
  }

  Future<void> makeMove(
    String matchId,
    String fromPosition,
    String toPosition,
    String promotionPiece,
  ) async {
    debugPrint(
      'promotionPiece: $promotionPiece, type: ${promotionPiece.runtimeType}',
    );
    await _hubConnection.invoke(
      'MakeMove',
      args: [matchId, fromPosition, toPosition, promotionPiece],
    );
  }

  Future<void> cancelMatch() async {
    await _hubConnection.invoke('CancelMatch');
  }

  Future<void> resign(String matchId) async {
    await _hubConnection.invoke('Resign', args: [matchId]);
  }
}

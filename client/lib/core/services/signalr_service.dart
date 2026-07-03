import 'package:client/core/constants/app_constants.dart';
import 'package:client/core/services/local_storage_service.dart';
import 'package:signalr_netcore/signalr_client.dart';

class SignalrService {
  late HubConnection _hubConnection;
  final LocalStorageService _localStorageService;

  SignalrService(this._localStorageService);

  Future<void> connect() async {
    final token = await _localStorageService.getToken();

    _hubConnection = HubConnectionBuilder()
        .withUrl(
          '${AppConstans.baseUrl.replaceAll('/api/', '')}/chesshub',
          options: HttpConnectionOptions(
            accessTokenFactory: () async => token ?? '',
          ),
        )
        .build();
  }

  void onReceiveMove(Function(List<Object?>?) handler) {
    _hubConnection.on('ReceiveMove', handler);
  }

  Future<void> makeMove(String move) async {
    await _hubConnection.invoke('MakeMove', args: [move]);
  }
}

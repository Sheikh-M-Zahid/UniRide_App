import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'auth_api_service.dart';

class RiderActivitySocketService {
  static final RiderActivitySocketService instance =
  RiderActivitySocketService._internal();

  RiderActivitySocketService._internal();

  io.Socket? _socket;

  io.Socket? get socket => _socket;

  Future<void> connect() async {
    if (_socket != null && _socket!.connected) return;

    final serverBase = AuthApiService.baseUrl.replaceAll('/api', '');
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');

    _socket = io.io(
      serverBase,
      <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
        'forceNew': true,
      },
    );

    _socket!.onConnect((_) {
      if (userId != null && userId.isNotEmpty) {
        _socket!.emit('join:rider-room', userId);
        _socket!.emit('join:user-room', userId);
      }
    });
  }

  void joinRideRoom(String rideId) {
    if (_socket != null && rideId.isNotEmpty) {
      _socket!.emit('join:ride-room', rideId);
    }
  }

  void on(String event, Function(dynamic) handler) {
    _socket?.off(event);
    _socket?.on(event, handler);
  }

  void off(String event) {
    _socket?.off(event);
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
  }
}
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'auth_api_service.dart';

class ActivitySocketService {
  static final ActivitySocketService instance = ActivitySocketService._internal();

  ActivitySocketService._internal();

  io.Socket? _socket;

  Future<void> connect() async {
    if (_socket != null && _socket!.connected) return;

    final serverBase = AuthApiService.baseUrl.replaceAll('/api', '');

    _socket = io.io(
      serverBase,
      <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
        'forceNew': true,
      },
    );

    _socket!.connect();
  }

  void joinActivityRoom() {
    _socket?.emit('join_activity_room');
  }

  void leaveActivityRoom() {
    _socket?.emit('leave_activity_room');
  }

  void onActivityUpdated(Function(dynamic) handler) {
    _socket?.off('activity_updated');
    _socket?.on('activity_updated', handler);
  }

  void offActivityUpdated() {
    _socket?.off('activity_updated');
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
  }
}
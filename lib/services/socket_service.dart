import 'dart:developer';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'auth_api_service.dart';

class SocketService {
  SocketService._();

  static IO.Socket? _socket;

  static IO.Socket? get socket => _socket;
  static bool get isConnected => _socket?.connected == true;

  static void connect(String token) {
    if (_socket != null && _socket!.connected) return;

    final serverBase = AuthApiService.baseUrl.replaceAll('/api', '');

    _socket = IO.io(
      serverBase,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(999999)
          .setReconnectionDelay(2000)
          .setTimeout(20000)
          .setExtraHeaders({
        'Authorization': 'Bearer $token',
      })
          .build(),
    );

    _socket!.onConnect((_) {
      log('Socket connected');
    });

    _socket!.onDisconnect((_) {
      log('Socket disconnected');
    });

    _socket!.onConnectError((data) {
      log('Socket connect error: $data');
    });

    _socket!.onError((data) {
      log('Socket error: $data');
    });

    _socket!.connect();
  }

  static void off(String event) {
    _socket?.off(event);
  }

  static void on(String event, Function(dynamic) handler) {
    _socket?.off(event);
    _socket?.on(event, handler);
  }

  static void disconnect() {
    _socket?.clearListeners();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
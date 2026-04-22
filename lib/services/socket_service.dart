import 'dart:developer';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'auth_api_service.dart';
import 'dart:convert';

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
          .setAuth({
        'token': token,
      })
          .setExtraHeaders({
        'Authorization': 'Bearer $token',
      })
          .build(),
    );

    _socket!.onConnect((_) {
      log('Socket connected');

      _socket?.emit('join_user_room', {
        'userId': _extractUserIdFromJwt(token),
      });

      _socket?.emit('join_rider_room', {
        'riderId': _extractUserIdFromJwt(token),
      });
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

  static String? _extractUserIdFromJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      String normalized = base64Url.normalize(parts[1]);
      final payload = utf8.decode(base64Url.decode(normalized));
      final Map<String, dynamic> data = jsonDecode(payload);

      return (data['userId'] ?? data['user_id'])?.toString();
    } catch (_) {
      return null;
    }
  }

  static void disconnect() {
    _socket?.clearListeners();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
import 'package:conextar/constants/endpoints.dart';
import 'package:conextar/constants/sp_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  io.Socket? _socket;

  io.Socket get socket {
    if (_socket == null) {
      throw Exception(
        "Socket pipeline has not been initialized. Call init() first.",
      );
    }
    return _socket!;
  }

  bool get isConnected => _socket?.connected ?? false;

  /// Establishes the real-time tunnel connection with the backend engine
  Future<void> init() async {
    if (_socket != null) return;

    try {
      final String? token = await SpHelper.getAccessToken();

      _socket = io.io(
        Endpoints.BASE_URL, // e.g., 'http://192.168.1.15:3000'
        io.OptionBuilder()
            .setTransports(['websocket']) // Forces stable WebSocket upgrade
            .disableAutoConnect() // Manual connection control
            .setAuth({
              'token': token,
            }) // Inject access token if middleware checks it
            .build(),
      );

      _socket!.connect();

      _socket!.onConnect(
        (_) => debugPrint(
          "🌐 [Socket] Connected to backend infrastructure safely.",
        ),
      );
      _socket!.onDisconnect(
        (_) => debugPrint("❌ [Socket] Disconnected from server stream."),
      );
      _socket!.onConnectError(
        (data) => debugPrint("⚠️ [Socket] Connection error block: $data"),
      );
    } catch (e) {
      debugPrint("🚨 [Socket] Structural initialization crash: $e");
    }
  }

  /// Tear down socket connection upon logout/session dropping routines
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    debugPrint(
      "🧼 [Socket] Disposed completely from device memory allocation.",
    );
  }
}

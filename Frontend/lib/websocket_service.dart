import 'dart:async';
import 'dart:convert' show json;
import 'package:websocket_channel/websocket_channel.dart';

/// Manages a single WebSocket connection to FastAPI /ws/predict.
///
/// Auto-reconnects with exponential back-off (1 s → 8 s cap).
/// [sendFrame] silently no-ops when disconnected so the camera
/// timer never throws.
class WebSocketService {
  /// ── Config ─────────────────────────────────────────────────
  /// Android emulator  → 10.0.2.2  (maps to host's localhost)
  /// iOS simulator     → 127.0.0.1
  /// Real device (LAN) → your machine's LAN IP, e.g. 192.168.1.x
  static const String baseUrl = 'ws://10.0.2.2:8000/ws/predict';

  static const Duration _initDelay = Duration(seconds: 1);
  static const Duration _maxDelay = Duration(seconds: 8);

  /// ── State ───────────────────────────────────────────────────
  WebSocketChannel? _channel;
  bool _connected = false;
  bool _disposed = false;
  Duration _delay = _initDelay;

  /// ── Public ──────────────────────────────────────────────────
  /// Emits decoded JSON maps from the server.
  final StreamController<Map<String, dynamic>> _ctrl =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get predictions => _ctrl.stream;
  bool get isConnected => _connected;

  /// ── Lifecycle ───────────────────────────────────────────────
  Future<void> connect() async {
    if (_disposed) return;
    _close();

    try {
      _channel = WebSocketChannel.connect(Uri.parse(baseUrl));
      _connected = true;
      _delay = _initDelay; // reset back-off on success

      _channel!.stream.listen(
        (dynamic raw) {
          try {
            final map = json.decode(raw as String) as Map<String, dynamic>;
            _ctrl.add(map);
          } catch (_) {
            // Malformed frame — skip silently
          }
        },
        onDone: () {
          _connected = false;
          _reconnect();
        },
        onError: (dynamic _) {
          _connected = false;
          _reconnect();
        },
      );
    } catch (_) {
      _connected = false;
      _reconnect();
    }
  }

  /// Send a base64-encoded JPEG string.  No-op if disconnected.
  void sendFrame(String base64Jpeg) {
    if (!_connected || _channel == null) return;
    // Server expects: {"frame":"<base64>"}
    _channel!.sink.add(json.encode({'frame': base64Jpeg}));
  }

  /// Permanently tear down.
  void dispose() {
    _disposed = true;
    _close();
    _ctrl.close();
  }

  /// ── Internal ───────────────────────────────────────────────
  void _close() {
    _channel?.sink.close();
    _channel = null;
    _connected = false;
  }

  void _reconnect() {
    if (_disposed) return;
    Future.delayed(_delay, () {
      if (!_disposed) connect();
    });
    final next = _delay.inMilliseconds * 2;
    _delay = Duration(milliseconds: next.clamp(0, _maxDelay.inMilliseconds));
  }
}
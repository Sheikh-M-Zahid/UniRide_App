// AlumniCallPage.dart
// WebRTC audio call screen — caller এবং callee দুইজনের জন্যই একই widget
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'services/auth_api_service.dart';

class AppColors {
  static const Color primary = Color(0xFF14B8A6);
  static const Color background = Color(0xFF0F172A);
}

class AlumniCallPage extends StatefulWidget {
  final String sessionId;
  final String otherUserId;
  final String otherPersonName;
  final String? otherPersonPhoto;
  final String authToken;
  final String myUserId;
  final bool isIncoming;
  final Map<String, dynamic>? incomingOffer;

  const AlumniCallPage({
    super.key,
    required this.sessionId,
    required this.otherUserId,
    required this.otherPersonName,
    this.otherPersonPhoto,
    required this.authToken,
    required this.myUserId,
    this.isIncoming = false,
    this.incomingOffer,
  });

  @override
  State<AlumniCallPage> createState() => _AlumniCallPageState();
}

class _AlumniCallPageState extends State<AlumniCallPage> {
  IO.Socket? _socket;
  RTCPeerConnection? _pc;
  MediaStream? _localStream;

  String _status = 'Connecting...';
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  Timer? _callTimer;
  int _seconds = 0;

  // ── STUN দিয়ে শুরু, production এ নিচে TURN যোগ করতেই হবে (উপরের নোট দেখো) ──
  static const Map<String, dynamic> _iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      // {
      //   'urls': 'turn:your-turn-server.com:3478',
      //   'username': 'xxx',
      //   'credential': 'xxx',
      // },
    ]
  };

  @override
  void initState() {
    super.initState();
    _setup();
  }

  Future<void> _setup() async {
    await _initLocalStream();
    _connectSignaling();
    await _createPeerConnection();

    if (widget.isIncoming && widget.incomingOffer != null) {
      setState(() => _status = 'Ringing');
      await _handleIncomingOffer(widget.incomingOffer!);
    } else {
      setState(() => _status = 'Calling...');
      await _createOffer();
    }
  }

  Future<void> _initLocalStream() async {
    final stream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': false,
    });
    _localStream = stream;
  }

  void _connectSignaling() {
    final base = AuthApiService.baseUrl.replaceAll('/api', '');
    _socket = IO.io(
      base,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': widget.authToken})
          .disableAutoConnect()
          .build(),
    );
    _socket!.connect();

    _socket!.on('alumni_call:answer', (data) async {
      final d = Map<String, dynamic>.from(data as Map);
      if (d['sessionId'] != widget.sessionId) return;
      final ans = Map<String, dynamic>.from(d['answer']);
      await _pc?.setRemoteDescription(
        RTCSessionDescription(ans['sdp'], ans['type']),
      );
    });

    _socket!.on('alumni_call:ice-candidate', (data) async {
      final d = Map<String, dynamic>.from(data as Map);
      if (d['sessionId'] != widget.sessionId) return;
      final c = Map<String, dynamic>.from(d['candidate']);
      await _pc?.addCandidate(
        RTCIceCandidate(c['candidate'], c['sdpMid'], c['sdpMLineIndex']),
      );
    });

    _socket!.on('alumni_call:end', (data) {
      final d = Map<String, dynamic>.from(data as Map);
      if (d['sessionId'] != widget.sessionId) return;
      _endCall(notifyOther: false);
    });
  }

  Future<void> _createPeerConnection() async {
    _pc = await createPeerConnection(_iceServers);

    _localStream?.getTracks().forEach((track) {
      _pc!.addTrack(track, _localStream!);
    });

    _pc!.onIceCandidate = (candidate) {
      _socket?.emit('alumni_call:ice-candidate', {
        'toUserId': widget.otherUserId,
        'sessionId': widget.sessionId,
        'candidate': {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        },
      });
    };

    _pc!.onConnectionState = (state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        _startCallTimer();
        if (mounted) setState(() => _status = 'In Call');
      } else if (state ==
          RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        _endCall(notifyOther: false);
      }
    };
  }

  Future<void> _createOffer() async {
    final offer = await _pc!.createOffer({'offerToReceiveAudio': 1});
    await _pc!.setLocalDescription(offer);
    _socket?.emit('alumni_call:offer', {
      'toUserId': widget.otherUserId,
      'sessionId': widget.sessionId,
      'offer': {'sdp': offer.sdp, 'type': offer.type},
    });
  }

  Future<void> _handleIncomingOffer(Map<String, dynamic> offer) async {
    await _pc!.setRemoteDescription(
      RTCSessionDescription(offer['sdp'], offer['type']),
    );
    final answer = await _pc!.createAnswer({'offerToReceiveAudio': 1});
    await _pc!.setLocalDescription(answer);
    _socket?.emit('alumni_call:answer', {
      'toUserId': widget.otherUserId,
      'sessionId': widget.sessionId,
      'answer': {'sdp': answer.sdp, 'type': answer.type},
    });
    _startCallTimer();
    if (mounted) setState(() => _status = 'In Call');
  }

  void _startCallTimer() {
    _callTimer?.cancel();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
  }

  String get _formattedDuration {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
    _localStream?.getAudioTracks().forEach((t) => t.enabled = !_isMuted);
  }

  void _toggleSpeaker() {
    setState(() => _isSpeakerOn = !_isSpeakerOn);
    Helper.setSpeakerphoneOn(_isSpeakerOn);
  }

  void _endCall({bool notifyOther = true}) {
    if (notifyOther) {
      _socket?.emit('alumni_call:end', {
        'toUserId': widget.otherUserId,
        'sessionId': widget.sessionId,
      });
    }
    _callTimer?.cancel();
    _pc?.close();
    _localStream?.getTracks().forEach((t) => t.stop());
    _socket?.dispose();
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _pc?.close();
    _localStream?.getTracks().forEach((t) => t.stop());
    _socket?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 60),
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.white24,
                backgroundImage: widget.otherPersonPhoto != null
                    ? NetworkImage(widget.otherPersonPhoto!)
                    : null,
                child: widget.otherPersonPhoto == null
                    ? const Icon(Icons.person, size: 60, color: Colors.white70)
                    : null,
              ),
              const SizedBox(height: 24),
              Text(widget.otherPersonName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                _status == 'In Call' ? _formattedDuration : _status,
                style: const TextStyle(color: Colors.white70, fontSize: 15),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _callButton(
                    icon: _isMuted ? Icons.mic_off : Icons.mic,
                    onTap: _toggleMute,
                    active: _isMuted,
                  ),
                  const SizedBox(width: 24),
                  _callButton(
                    icon: Icons.call_end,
                    onTap: () => _endCall(),
                    background: Colors.red,
                    large: true,
                  ),
                  const SizedBox(width: 24),
                  _callButton(
                    icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                    onTap: _toggleSpeaker,
                    active: _isSpeakerOn,
                  ),
                ],
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _callButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? background,
    bool active = false,
    bool large = false,
  }) {
    final size = large ? 68.0 : 56.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: background ?? (active ? AppColors.primary : Colors.white24),
        ),
        child: Icon(icon, color: Colors.white, size: large ? 30 : 24),
      ),
    );
  }
}
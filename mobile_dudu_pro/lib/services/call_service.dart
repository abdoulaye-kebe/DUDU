import 'dart:async';
import 'package:flutter/foundation.dart'
    show
        debugPrint,
        defaultTargetPlatform,
        TargetPlatform,
        kIsWeb,
        ValueNotifier;
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../config/webrtc_ice_config.dart';
import '../main.dart';

class CallService {
  static final CallService _instance = CallService._internal();
  factory CallService() => _instance;
  CallService._internal();

  dynamic _socket;
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  bool _isCaller = false;
  String? _currentRideId;
  Timer? _callTimer;
  Timer? _statsTimer;
  Duration _callDuration = Duration.zero;

  /// État média pour l’UI (RTP audio) — réinitialisé à chaque fin d’appel.
  final ValueNotifier<String> mediaHealth =
      ValueNotifier<String>('Connexion…');

  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  bool _renderersInitialized = false;

  Future<void> _ensureRenderers() async {
    if (_renderersInitialized) return;
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    _renderersInitialized = true;
  }

  void _showCallError(String message) {
    final ctx = proNavigatorKey.currentContext;
    if (ctx == null) return;
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  /// Normalise la carte SDP issue de [RTCSessionDescription.toMap] ou du réseau JSON.
  Map<String, String>? _normalizeRemoteSdpMap(Map<String, dynamic> raw) {
    final type = raw['type']?.toString();
    final sdp = raw['sdp']?.toString();
    if (type == null || sdp == null || sdp.isEmpty) return null;
    return {'type': type, 'sdp': sdp};
  }

  void attachToSocket(dynamic socket) {
    _socket = socket;
    socket.off('call-offer');
    socket.off('call-answer');
    socket.off('ice-candidate');
    socket.off('call-end');
    socket.on('call-offer', _onCallOffer);
    socket.on('call-answer', _onCallAnswer);
    socket.on('ice-candidate', _onIceCandidate);
    socket.on('call-end', _onCallEnd);
  }

  Future<void> _configureNativeAudioForVoip() async {
    if (kIsWeb) return;
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await Helper.ensureAudioSession();
        await Helper.setAppleAudioIOMode(
          AppleAudioIOMode.localAndRemote,
          preferSpeakerOutput: true,
        );
        await Helper.setSpeakerphoneOn(true);
      }
    } catch (e, st) {
      debugPrint('⚠️ Config audio appel: $e\n$st');
    }
  }

  Future<void> _createPeerConnection() async {
    await _configureNativeAudioForVoip();

    final config = <String, dynamic>{
      'iceServers': buildWebRtcIceServers(),
    };

    _peerConnection = await createPeerConnection(config);

    final mediaConstraints = {
      'audio': true,
      'video': false,
    };

    _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    for (var track in _localStream!.getTracks()) {
      await _peerConnection!.addTrack(track, _localStream!);
    }

    _peerConnection!.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams.first;
        _remoteRenderer.srcObject = _remoteStream;
      }
    };

    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      if (_currentRideId != null && _socket != null) {
        _socket.emit('ice-candidate', {
          'rideId': _currentRideId,
          'candidate': {
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          },
        });
      }
    };

    _peerConnection!.onIceConnectionState = (RTCIceConnectionState state) {
      debugPrint('📶 ICE: $state');
      if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
        _showCallError('Connexion réseau de l’appel impossible.');
      }
    };

    _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
      debugPrint('🔗 PeerConnection: $state');
    };

    _startAudioStatsPolling();
  }

  static int _statInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  /// Compte les octets RTP audio (indicateur fiable que la voix circule).
  static ({int inBytes, int outBytes}) _audioRtpBytes(List<StatsReport> reports) {
    var inB = 0;
    var outB = 0;
    for (final r in reports) {
      final v = r.values;
      final kind = (v['kind'] ?? v['mediaType'])?.toString() ?? '';
      if (kind != 'audio') continue;
      if (r.type == 'inbound-rtp') {
        inB += _statInt(v['bytesReceived']);
      } else if (r.type == 'outbound-rtp') {
        outB += _statInt(v['bytesSent']);
      }
    }
    return (inBytes: inB, outBytes: outB);
  }

  void _startAudioStatsPolling() {
    _statsTimer?.cancel();
    _statsTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      final pc = _peerConnection;
      if (pc == null) return;
      try {
        final reports = await pc.getStats();
        final s = _audioRtpBytes(reports);
        debugPrint(
          '🎙️ RTP audio — envoyé: ${s.outBytes} o, reçu: ${s.inBytes} o',
        );
        scheduleMicrotask(() {
          if (_peerConnection == null) return;
          if (s.inBytes > 0 && s.outBytes > 0) {
            mediaHealth.value =
                'Voix OK — échange actif (↑ ${s.outBytes} o / ↓ ${s.inBytes} o)';
          } else if (s.outBytes > 0) {
            mediaHealth.value =
                'Micro actif — en attente de l’audio distant (↓ 0 o)';
          } else if (s.inBytes > 0) {
            mediaHealth.value =
                'Réception OK — vérifiez le micro (↑ 0 o)';
          } else {
            mediaHealth.value = 'Négociation / média…';
          }
        });
      } catch (e, st) {
        debugPrint('⚠️ getStats: $e\n$st');
      }
    });
  }

  Future<void> startCall(String rideId, dynamic socket) async {
    _socket = socket;
    _isCaller = true;
    _currentRideId = rideId;

    try {
      await _ensureRenderers();
      await _createPeerConnection();

      final offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);

      socket.emit('call-offer', {
        'rideId': rideId,
        'sdp': offer.toMap(),
      });

      _showInCallDialog();
    } catch (e, st) {
      debugPrint('⚠️ startCall: $e\n$st');
      _showCallError(
        'Impossible de démarrer l’appel DuDu (microphone ou connexion).',
      );
      _disposeCall();
    }
  }

  Future<void> answerCall(String rideId, Map<String, dynamic> offer, dynamic socket) async {
    _socket = socket;
    _isCaller = false;
    _currentRideId = rideId;

    final norm = _normalizeRemoteSdpMap(offer);
    if (norm == null) {
      _showCallError('Données d’appel invalides. Réessayez depuis le client.');
      _disposeCall();
      return;
    }

    try {
      await _ensureRenderers();
      await _createPeerConnection();

      final remoteDesc = RTCSessionDescription(norm['sdp']!, norm['type']!);
      await _peerConnection!.setRemoteDescription(remoteDesc);

      final answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);

      socket.emit('call-answer', {
        'rideId': rideId,
        'sdp': answer.toMap(),
      });

      _showInCallDialog();
    } catch (e, st) {
      debugPrint('⚠️ answerCall: $e\n$st');
      _showCallError(
        'Impossible d’accepter l’appel (microphone ou connexion).',
      );
      _disposeCall();
    }
  }

  void endCall([String reason = 'ended_by_user']) {
    if (_currentRideId != null && _socket != null) {
      _socket.emit('call-end', {
        'rideId': _currentRideId,
        'reason': reason,
      });
    }
    _disposeCall();
  }

  void _disposeCall() {
    _callTimer?.cancel();
    _callTimer = null;
    _statsTimer?.cancel();
    _statsTimer = null;
    _callDuration = Duration.zero;
    mediaHealth.value = 'Connexion…';

    _peerConnection?.close();
    _peerConnection = null;

    _localStream?.getTracks().forEach((t) => t.stop());
    _localStream = null;

    _remoteStream?.getTracks().forEach((t) => t.stop());
    _remoteStream = null;

    _localRenderer.srcObject = null;
    _remoteRenderer.srcObject = null;

    _currentRideId = null;
  }

  void _startTimer() {
    _callTimer?.cancel();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _callDuration += const Duration(seconds: 1);
    });
  }

  void _showInCallDialog() {
    final ctx = proNavigatorKey.currentContext;
    if (ctx == null) return;

    _startTimer();

    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(_isCaller ? 'Appel vers le client' : 'Appel du client'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.call, size: 48, color: Colors.green),
                  const SizedBox(height: 12),
                  Text(
                    _currentRideId != null
                        ? 'Course $_currentRideId'
                        : 'Appel audio',
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<int>(
                    stream: Stream<int>.periodic(const Duration(seconds: 1), (x) => x),
                    builder: (context, snapshot) {
                      final minutes = _callDuration.inMinutes.remainder(60).toString().padLeft(2, '0');
                      final seconds = _callDuration.inSeconds.remainder(60).toString().padLeft(2, '0');
                      return Text('$minutes:$seconds');
                    },
                  ),
                  const SizedBox(height: 12),
                  ValueListenableBuilder<String>(
                    valueListenable: mediaHealth,
                    builder: (context, status, _) {
                      return Text(
                        status,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      );
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    endCall();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Raccrocher'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _onCallOffer(dynamic data) async {
    debugPrint('📞 call-offer reçu (chauffeur): $data');

    try {
      final ctx = proNavigatorKey.currentContext;
      if (ctx == null) {
        debugPrint('⚠️ proNavigatorKey.currentContext est NULL');
        return;
      }

      final rideId = (data is Map && data['rideId'] != null)
          ? data['rideId'].toString()
          : 'Course';

      final sdp = (data is Map && data['sdp'] is Map)
          ? Map<String, dynamic>.from(data['sdp'] as Map)
          : <String, dynamic>{};

      showDialog(
        context: ctx,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Appel du client'),
            content: Text(
              'Le client souhaite vous appeler pour la course $rideId.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  endCall('rejected_by_user');
                },
                child: const Text('Refuser'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  if (_socket != null) {
                    answerCall(rideId, sdp, _socket);
                  }
                },
                child: const Text('Accepter'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      debugPrint('⚠️ Erreur affichage popup appel: $e');
    }
  }

  void _onCallAnswer(dynamic data) async {
    debugPrint('📞 call-answer reçu: $data');
    if (_peerConnection == null) return;

    try {
      if (data is Map && data['sdp'] is Map) {
        final sdp = Map<String, dynamic>.from(data['sdp'] as Map);
        final norm = _normalizeRemoteSdpMap(sdp);
        if (norm == null) return;
        final desc = RTCSessionDescription(norm['sdp']!, norm['type']!);
        await _peerConnection!.setRemoteDescription(desc);
      }
    } catch (e, st) {
      debugPrint('⚠️ call-answer: $e\n$st');
      _showCallError('Erreur lors de la connexion audio.');
    }
  }

  void _onIceCandidate(dynamic data) async {
    debugPrint('❄️ ice-candidate reçu: $data');
    if (_peerConnection == null) return;

    try {
      if (data is Map && data['candidate'] is Map) {
        final c = Map<String, dynamic>.from(data['candidate'] as Map);
        final idxRaw = c['sdpMLineIndex'];
        final lineIndex = idxRaw is int
            ? idxRaw
            : (idxRaw is num ? idxRaw.toInt() : null);
        final candidate = RTCIceCandidate(
          c['candidate'] as String?,
          c['sdpMid'] as String?,
          lineIndex,
        );
        await _peerConnection!.addCandidate(candidate);
      }
    } catch (e) {
      debugPrint('⚠️ Erreur ajout ice-candidate: $e');
    }
  }

  void _onCallEnd(dynamic data) {
    debugPrint('📴 call-end reçu: $data');
    _disposeCall();
  }
}

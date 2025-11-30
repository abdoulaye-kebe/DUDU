import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../main.dart';

class CallService {
  static final CallService _instance = CallService._internal();
  factory CallService() => _instance;
  CallService._internal();

  // TODO: ajouter RTCPeerConnection, MediaStream, etc. plus tard

  dynamic _socket; // socket.io courant
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  bool _isCaller = false;
  String? _currentRideId;
  Timer? _callTimer;
  Duration _callDuration = Duration.zero;

  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  Future<void> _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  void attachToSocket(dynamic socket) {
    _socket = socket;
    socket.on('call-offer', _onCallOffer);
    socket.on('call-answer', _onCallAnswer);
    socket.on('ice-candidate', _onIceCandidate);
    socket.on('call-end', _onCallEnd);
  }

  Future<void> _createPeerConnection() async {
    final config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    };
    final constraints = {
      'mandatory': {},
      'optional': [],
    };

    _peerConnection = await createPeerConnection(config, constraints);

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
  }

  Future<void> startCall(String rideId, dynamic socket) async {
    _socket = socket;
    _isCaller = true;
    _currentRideId = rideId;

    await _initRenderers();
    await _createPeerConnection();

    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    socket.emit('call-offer', {
      'rideId': rideId,
      'sdp': offer.toMap(),
    });

    _showInCallDialog();
  }

  Future<void> answerCall(String rideId, Map<String, dynamic> offer, dynamic socket) async {
    _socket = socket;
    _isCaller = false;
    _currentRideId = rideId;

    await _initRenderers();
    await _createPeerConnection();

    final remoteDesc = RTCSessionDescription(offer['sdp'], offer['type']);
    await _peerConnection!.setRemoteDescription(remoteDesc);

    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);

    socket.emit('call-answer', {
      'rideId': rideId,
      'sdp': answer.toMap(),
    });

    _showInCallDialog();
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
    _callDuration = Duration.zero;

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
    final ctx = appNavigatorKey.currentContext;
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
              title: Text(_isCaller ? 'Appel en cours (chauffeur)' : 'Appel en cours'),
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
    print('📞 call-offer reçu: $data');

    try {
      final ctx = appNavigatorKey.currentContext;
      if (ctx == null) {
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
            title: const Text('Appel entrant'),
            content: Text(
              'Le chauffeur souhaite vous appeler pour la course $rideId.',
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
                  } else {
                    debugPrint('⚠️ Impossible d\'envoyer call-answer: socket null');
                  }
                },
                child: const Text('Accepter'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      print('⚠️ Erreur affichage popup appel entrant: $e');
    }
  }

  void _onCallAnswer(dynamic data) async {
    print('📞 call-answer reçu: $data');
    if (_peerConnection == null) return;

    if (data is Map && data['sdp'] is Map) {
      final sdp = Map<String, dynamic>.from(data['sdp'] as Map);
      final desc = RTCSessionDescription(sdp['sdp'], sdp['type']);
      await _peerConnection!.setRemoteDescription(desc);
    }
  }

  void _onIceCandidate(dynamic data) async {
    print('❄️ ice-candidate reçu: $data');
    if (_peerConnection == null) return;

    try {
      if (data is Map && data['candidate'] is Map) {
        final c = Map<String, dynamic>.from(data['candidate'] as Map);
        final candidate = RTCIceCandidate(
          c['candidate'] as String?,
          c['sdpMid'] as String?,
          c['sdpMLineIndex'] as int?,
        );
        await _peerConnection!.addCandidate(candidate);
      }
    } catch (e) {
      print('⚠️ Erreur ajout ice-candidate: $e');
    }
  }

  void _onCallEnd(dynamic data) {
    print('📴 call-end reçu: $data');
    _disposeCall();
  }
}

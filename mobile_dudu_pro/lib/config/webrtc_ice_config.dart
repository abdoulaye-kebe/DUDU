import 'package:flutter_dotenv/flutter_dotenv.dart';

/// STUN public + TURN optionnel (recommandé sur iPhone / 4G / NAT symétrique).
List<Map<String, dynamic>> buildWebRtcIceServers() {
  final servers = <Map<String, dynamic>>[
    {'urls': 'stun:stun.l.google.com:19302'},
  ];

  final turnUrl = dotenv.maybeGet('WEBRTC_TURN_URL')?.trim();
  if (turnUrl == null || turnUrl.isEmpty) {
    return servers;
  }

  final user = dotenv.maybeGet('WEBRTC_TURN_USERNAME')?.trim();
  final pass = dotenv.maybeGet('WEBRTC_TURN_CREDENTIAL')?.trim();

  final turn = <String, dynamic>{'urls': turnUrl};
  if (user != null &&
      user.isNotEmpty &&
      pass != null &&
      pass.isNotEmpty) {
    turn['username'] = user;
    turn['credential'] = pass;
  }
  servers.add(turn);

  return servers;
}

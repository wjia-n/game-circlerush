import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';
import 'game_screen.dart';

void main() => runApp(const CircleRushApp());

class CircleRushApp extends StatelessWidget {
  const CircleRushApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GameShell(
      variant: ShellVariant.softBlob,
      title: 'Circle Rush',
      tagline: 'Spin, dodge and survive the rushing asteroid storm! 🪐',
      emoji: '🪐',
      slug: 'circlerush',
      howToPlay:
          '• Your ship orbits the planet automatically. Tap anywhere!\n• TAP hops between the inner and outer orbit lanes.\n• Dodge the incoming asteroids — one hit and you\'re stardust!\n• Survive as long as you can. It only gets faster… 🪐',
      playerOptions: const [1],
      supportsBots: false,
      gameBuilder: (ctx, players, cb) => CircleRushScreen(players: players, callbacks: cb),
    );
  }
}

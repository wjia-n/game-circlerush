import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';
import 'services/audio_service.dart';
import 'services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  final settings = RushSettings();
  await settings.load();
  final audio = RushAudio();
  audio.configure(
    musicOn: settings.musicOn,
    sfxOn: settings.sfxOn,
    volume: settings.volume,
  );
  runApp(CircleRushApp(settings: settings, audio: audio));
}

class CircleRushApp extends StatefulWidget {
  final RushSettings settings;
  final RushAudio audio;
  const CircleRushApp(
      {super.key, required this.settings, required this.audio});

  @override
  State<CircleRushApp> createState() => _CircleRushAppState();
}

class _CircleRushAppState extends State<CircleRushApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.audio.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause (not stop) on interruption so music resumes exactly where it
    // left off; game screens additionally freeze their engines.
    if (state == AppLifecycleState.paused) {
      widget.audio.onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      widget.audio.onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.settings,
      builder: (_, _) => MaterialApp(
        title: 'Circle Rush',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor:
              widget.settings.theme.deskDark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: widget.settings.theme.brass,
            brightness: Brightness.dark,
          ),
        ),
        home: SplashScreen(
            audio: widget.audio, settings: widget.settings),
      ),
    );
  }
}

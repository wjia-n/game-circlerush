import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/orrery_themes.dart';
import '../theme/orrery_widgets.dart';

/// Circle Rush PRO: Free-vs-Pro comparison, real purchase, restore,
/// and tip jar. All prices come from the store — never hardcoded,
/// never placeholders.
class ProScreen extends StatefulWidget {
  final RushAudio audio;
  final RushSettings settings;
  final StoreService store;

  const ProScreen({
    super.key,
    required this.audio,
    required this.settings,
    required this.store,
  });

  @override
  State<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends State<ProScreen> {
  OrreryThemeDef get _t => widget.settings.theme;

  @override
  void initState() {
    super.initState();
    widget.store.init();
    widget.store.lastThanks.addListener(_onThanks);
  }

  
  void _onThanks() {
    final msg = widget.store.lastThanks.value;
    if (msg == null || !mounted) return;
    widget.audio.win();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: Orrery.body(15, theme: _t)),
        backgroundColor: _t.panel,
        behavior: SnackBarBehavior.floating,
      ),
    );
    widget.store.lastThanks.value = null;
  }

  @override
  void dispose() {
    widget.store.lastThanks.removeListener(_onThanks);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final s = widget.settings;
    final store = widget.store;
    return Scaffold(
      backgroundColor: t.deskDark,
      body: DeskBackdrop(
        theme: t,
        child: SafeArea(
          child: ListenableBuilder(
            listenable: s,
            builder: (_, _) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      DialButton(
                        theme: t,
                        icon: Icons.arrow_back,
                        onTap: () {
                          widget.audio.click();
                          Navigator.of(context).pop();
                        },
                      ),
                      const SizedBox(width: 12),
                      Text('CIRCLE RUSH PRO',
                          style: Orrery.display(24, theme: t)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _TipsCard(
                    theme: t,
                    store: store,
                    audio: widget.audio,
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TipsCard extends StatelessWidget {
  final OrreryThemeDef theme;
  final StoreService store;
  final RushAudio audio;
  const _TipsCard(
      {required this.theme,
      required this.store,
      required this.audio});

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return BrassPanel(
      theme: t,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TIP JAR ☕',
              style: Orrery.label(14, theme: t)),
          const SizedBox(height: 8),
          Text(
            'Circle Rush is free forever. If it made you smile, a coffee or chocolate keeps the orrery winding!',
            style: Orrery.body(13, theme: t, color: t.muted),
          ),
          const SizedBox(height: 12),
          if (!store.storeReady)
            _StoreNote(
              theme: t,
              text: store.error ??
                  'Tips appear here once the game is live on the Play Store.',
            )
          else
            Row(
              children: [
                Expanded(
                    child: _TipButton(
                        theme: t,
                        store: store,
                        audio: audio,
                        product: store.coffeeProduct,
                        label: '☕ COFFEE')),
                const SizedBox(width: 10),
                Expanded(
                    child: _TipButton(
                        theme: t,
                        store: store,
                        audio: audio,
                        product: store.chocolateProduct,
                        label: '🍫 CHOCOLATE')),
              ],
            ),
        ],
      ),
    );
  }
}

class _TipButton extends StatelessWidget {
  final OrreryThemeDef theme;
  final StoreService store;
  final RushAudio audio;
  final ProductDetails? product;
  final String label;
  const _TipButton({
    required this.theme,
    required this.store,
    required this.audio,
    required this.product,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final p = product;
    if (p == null) return const SizedBox.shrink();
    return BrassButton(
      theme: t,
      text: '$label\n${p.price}',
      fontSize: 13,
      onTap: () {
        audio.click();
        store.buyTip(p);
      },
    );
  }
}

class _StoreNote extends StatelessWidget {
  final OrreryThemeDef theme;
  final String text;
  const _StoreNote({required this.theme, required this.text});

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black.withValues(alpha: 0.3),
        border:
            Border.all(color: t.panelEdge.withValues(alpha: 0.5)),
      ),
      child: Text(text,
          style: Orrery.body(13, theme: t, color: t.muted),
          textAlign: TextAlign.center),
    );
  }
}

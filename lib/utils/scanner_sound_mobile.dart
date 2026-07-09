import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

final AudioPlayer _audioPlayer = AudioPlayer()..audioCache.prefix = '';

void playPlatformBeep() {
  try {
    _audioPlayer.play(AssetSource('lib/assets/sound/barcode_beep.mp3'));
  } catch (_) {
    SystemSound.play(SystemSoundType.click);
  }
  HapticFeedback.lightImpact();
}

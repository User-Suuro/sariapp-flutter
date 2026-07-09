import 'package:flutter/services.dart';

void playPlatformBeep() {
  SystemSound.play(SystemSoundType.click);
  HapticFeedback.lightImpact();
}

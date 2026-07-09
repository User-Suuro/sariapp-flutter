import 'scanner_sound_impl.dart'
    if (dart.library.js) 'scanner_sound_web.dart'
    if (dart.library.io) 'scanner_sound_mobile.dart';

class ScannerSound {
  static void playBeep() {
    playPlatformBeep();
  }
}

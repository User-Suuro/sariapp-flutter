import 'dart:js' as js;

void playPlatformBeep() {
  try {
    js.context.callMethod('eval', [
      """
      (function() {
        var audio = new Audio('assets/lib/assets/sound/barcode_beep.mp3');
        audio.volume = 0.5;
        audio.play();
      })();
      """
    ]);
  } catch (_) {}
}

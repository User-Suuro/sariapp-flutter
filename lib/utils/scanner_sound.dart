import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:js' as js;

class ScannerSound {
  static void playBeep() {
    if (kIsWeb) {
      try {
        // Synthesizes a high-quality scanner beep sound directly inside browser
        js.context.callMethod('eval', [
          """
          (function() {
            var ctx = new (window.AudioContext || window.webkitAudioContext)();
            var osc = ctx.createOscillator();
            var gain = ctx.createGain();
            
            osc.type = 'sine';
            osc.frequency.setValueAtTime(1400, ctx.currentTime); // High pitch POS scan beep
            gain.gain.setValueAtTime(0.08, ctx.currentTime); // Reduced volume to prevent distortion
            gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.12); // Short decay
            
            osc.connect(gain);
            gain.connect(ctx.destination);
            
            osc.start();
            osc.stop(ctx.currentTime + 0.12);
          })();
          """
        ]);
      } catch (_) {
        // Fallback to system click if browser throws exception (e.g. before user interaction)
        SystemSound.play(SystemSoundType.click);
      }
    } else {
      // Mobile platforms: trigger system click sound and standard light haptic vibration
      SystemSound.play(SystemSoundType.click);
      HapticFeedback.lightImpact();
    }
  }
}

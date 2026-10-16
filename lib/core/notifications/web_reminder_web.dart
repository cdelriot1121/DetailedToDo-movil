import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

final Map<String, Timer> _timers = {};
const _maxTimerDelay = Duration(days: 24);

Future<bool> requestPermission() async {
  try {
    if (web.Notification.permission == 'granted') return true;
    return (await web.Notification.requestPermission().toDart).toDart == 'granted';
  } catch (_) {
    return false;
  }
}

void schedule(String id, String title, String body, DateTime at) {
  cancel(id);
  void checkTime() {
    final delay = at.difference(DateTime.now());
    if (delay.isNegative || delay == Duration.zero) {
      _timers.remove(id);
      try {
        if (web.Notification.permission == 'granted') {
          web.Notification(title, web.NotificationOptions(body: body, icon: 'icons/Icon-192.png'));
        }
      } catch (_) {}
      return;
    }
    _timers[id] = Timer(delay > _maxTimerDelay ? _maxTimerDelay : delay, checkTime);
  }

  checkTime();
}

void cancel(String id) {
  _timers.remove(id)?.cancel();
}
